import Foundation
import Network
import Display
import SwiftSignalKit
import TelegramCore
import Postbox
import AccountContext
import AlertUI
import PresentationDataUtils
import OverlayStatusController

/// Telewhite VPN: a "Telegram-only VPN" built on top of Telegram's native
/// MTProto/SOCKS5 proxy engine. Only Telegram traffic is routed through the
/// selected server; other apps are unaffected.
///
/// Flow:
/// 1. Fetch the user's subscription URL (list of proxy links) if present.
/// 2. Merge with the built-in fallback server list.
/// 3. Ping all candidates concurrently over TCP and measure latency.
/// 4. Activate the fastest working server via Telegram's proxy settings.
public final class TelewhiteVpnEngine {
    public static var lastStatus: String = ""

    public enum ConnectResult {
        case connected(host: String, port: Int32, latencyMs: Int, totalTested: Int)
        case noWorkingServers(totalTested: Int)
        case subscriptionError(String)
    }

    // Fallback public MTProto proxies used when the subscription is empty or
    // unreachable. The subscription is always the preferred source.
    private static let builtInProxyLinks: [String] = [
        "tg://proxy?server=proxy.digitalresistance.dog&port=443&secret=d41d8cd98f00b204e9800998ecf8427e",
        "tg://proxy?server=proxy.mtproto.co&port=443&secret=11112222333344445555666677778888",
        "tg://proxy?server=mtproxy.telegram-drpc.org&port=443&secret=dd00000000000000000000000000000000",
    ]

    public static func parseProxyLink(_ raw: String) -> ProxyServerSettings? {
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("//") {
            return nil
        }

        var urlString = line
        if line.hasPrefix("tg://") {
            urlString = line.replacingOccurrences(of: "tg://", with: "https://t.me/")
        }

        if urlString.lowercased().contains("t.me/proxy") || urlString.lowercased().contains("t.me/socks") {
            guard let components = URLComponents(string: urlString), let queryItems = components.queryItems else {
                return nil
            }
            var server: String?
            var port: Int32?
            var secret: String?
            var user: String?
            var pass: String?
            for item in queryItems {
                switch item.name.lowercased() {
                case "server", "proxy":
                    server = item.value
                case "port":
                    port = item.value.flatMap { Int32($0) }
                case "secret":
                    secret = item.value
                case "user", "username":
                    user = item.value
                case "pass", "password":
                    pass = item.value
                default:
                    break
                }
            }
            guard let host = server, !host.isEmpty, let portValue = port, portValue > 0 else {
                return nil
            }
            if urlString.lowercased().contains("t.me/socks") {
                return ProxyServerSettings(host: host, port: portValue, connection: .socks5(username: user, password: pass))
            }
            guard let secretString = secret, let secretData = parseSecret(secretString) else {
                return nil
            }
            return ProxyServerSettings(host: host, port: portValue, connection: .mtp(secret: secretData))
        }

        // Plain "host:port:secret" format.
        let parts = line.split(separator: ":").map(String.init)
        if parts.count == 3, let portValue = Int32(parts[1]), let secretData = parseSecret(parts[2]) {
            return ProxyServerSettings(host: parts[0], port: portValue, connection: .mtp(secret: secretData))
        }
        return nil
    }

    private static func parseSecret(_ secret: String) -> Data? {
        let cleaned = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        // Hex secret (possibly with dd/ee prefix for obfuscation).
        if cleaned.count % 2 == 0, cleaned.range(of: "^[0-9a-fA-F]+$", options: .regularExpression) != nil {
            var data = Data(capacity: cleaned.count / 2)
            var index = cleaned.startIndex
            while index < cleaned.endIndex {
                let next = cleaned.index(index, offsetBy: 2)
                guard let byte = UInt8(cleaned[index..<next], radix: 16) else {
                    return nil
                }
                data.append(byte)
                index = next
            }
            return data
        }
        // Base64 / base64url secret.
        var base64 = cleaned.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        return Data(base64Encoded: base64)
    }

    private static func fetchSubscription(url: String, completion: @escaping ([ProxyServerSettings], String?) -> Void) {
        guard let subscriptionUrl = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            completion([], "Invalid subscription URL")
            return
        }
        var request = URLRequest(url: subscriptionUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion([], error.localizedDescription)
                return
            }
            guard let data = data, var body = String(data: data, encoding: .utf8) else {
                completion([], "Empty subscription response")
                return
            }
            // Some subscriptions serve the whole list base64-encoded.
            let compact = body.trimmingCharacters(in: .whitespacesAndNewlines)
            if !compact.contains("://"), !compact.contains("\n"), let decoded = Data(base64Encoded: compact), let decodedString = String(data: decoded, encoding: .utf8) {
                body = decodedString
            }
            var servers: [ProxyServerSettings] = []
            for line in body.components(separatedBy: .newlines) {
                if let server = parseProxyLink(line) {
                    servers.append(server)
                }
            }
            completion(servers, nil)
        }
        task.resume()
    }

    /// TCP-pings a single server, returning latency in milliseconds or nil.
    private static func pingServer(_ server: ProxyServerSettings, timeout: TimeInterval, completion: @escaping (Int?) -> Void) {
        guard let port = NWEndpoint.Port(rawValue: UInt16(clamping: server.port)) else {
            completion(nil)
            return
        }
        let connection = NWConnection(host: NWEndpoint.Host(server.host), port: port, using: .tcp)
        let started = CFAbsoluteTimeGetCurrent()
        let lock = NSLock()
        var finished = false
        let finish: (Int?) -> Void = { latency in
            lock.lock()
            let wasFinished = finished
            finished = true
            lock.unlock()
            if !wasFinished {
                connection.cancel()
                completion(latency)
            }
        }
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                finish(Int((CFAbsoluteTimeGetCurrent() - started) * 1000.0))
            case .failed, .cancelled:
                finish(nil)
            default:
                break
            }
        }
        connection.start(queue: DispatchQueue.global(qos: .userInitiated))
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + timeout) {
            finish(nil)
        }
    }

    /// Smart connect: gathers servers, pings all in parallel, activates the fastest.
    public static func smartConnect(subscriptionUrl: String, accountManager: AccountManager<TelegramAccountManagerTypes>, completion: @escaping (ConnectResult) -> Void) {
        lastStatus = "Testing servers..."

        let proceed: ([ProxyServerSettings], String?) -> Void = { subscriptionServers, subscriptionError in
            var candidates: [ProxyServerSettings] = subscriptionServers
            for link in builtInProxyLinks {
                if let server = parseProxyLink(link), !candidates.contains(server) {
                    candidates.append(server)
                }
            }
            guard !candidates.isEmpty else {
                DispatchQueue.main.async {
                    lastStatus = "No servers"
                    completion(.subscriptionError(subscriptionError ?? "No servers found"))
                }
                return
            }

            let group = DispatchGroup()
            let resultLock = NSLock()
            var results: [(server: ProxyServerSettings, latency: Int)] = []
            for server in candidates {
                group.enter()
                pingServer(server, timeout: 4.0) { latency in
                    if let latency = latency {
                        resultLock.lock()
                        results.append((server, latency))
                        resultLock.unlock()
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                guard let best = results.min(by: { $0.latency < $1.latency }) else {
                    lastStatus = "No working servers"
                    completion(.noWorkingServers(totalTested: candidates.count))
                    return
                }
                let _ = updateProxySettingsInteractively(accountManager: accountManager, { settings in
                    var settings = settings
                    if !settings.servers.contains(best.server) {
                        settings.servers.insert(best.server, at: 0)
                    }
                    settings.activeServer = best.server
                    settings.enabled = true
                    settings.useForCalls = true
                    return settings
                }).start()
                lastStatus = "Connected: \(best.server.host):\(best.server.port) (\(best.latency) ms)"
                completion(.connected(host: best.server.host, port: best.server.port, latencyMs: best.latency, totalTested: candidates.count))
            }
        }

        let trimmed = subscriptionUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            proceed([], nil)
        } else {
            fetchSubscription(url: trimmed) { servers, error in
                proceed(servers, error)
            }
        }
    }

    /// Disables the Telegram proxy (turns Telewhite VPN off).
    public static func disable(accountManager: AccountManager<TelegramAccountManagerTypes>) {
        let _ = updateProxySettingsInteractively(accountManager: accountManager, { settings in
            var settings = settings
            settings.enabled = false
            return settings
        }).start()
        lastStatus = "Disabled"
    }
}

/// Shared entry point used by both the standalone Telewhite VPN controller and
/// the Telewhite Mods section. Shows a progress spinner, runs the smart connect,
/// then reports the outcome.
func telewhiteRunVpnConnect(context: AccountContext, stateValue: Atomic<TelewhiteModsSettings>, updateSettings: @escaping ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void, present: @escaping (ViewController) -> Void) {
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let settings = stateValue.with { $0 }

    // Toggle off if the profile is currently enabled.
    if settings.vpnEnabled {
        TelewhiteVpnEngine.disable(accountManager: context.sharedContext.accountManager)
        updateSettings { current in
            var updated = current
            updated.vpnEnabled = false
            return updated
        }
        present(textAlertController(context: context, title: "Telewhite VPN", text: "VPN отключён. Трафик Telegram снова идёт напрямую.", actions: [
            TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})
        ]))
        return
    }

    let progressController = OverlayStatusController(theme: presentationData.theme, type: .loading(cancelled: nil))
    present(progressController)

    TelewhiteVpnEngine.smartConnect(subscriptionUrl: settings.vpnSubscription, accountManager: context.sharedContext.accountManager) { result in
        progressController.dismiss()
        let message: String
        switch result {
        case let .connected(host, port, latencyMs, totalTested):
            updateSettings { current in
                var updated = current
                updated.vpnEnabled = true
                return updated
            }
            message = "Подключено к \(host):\(port)\nЗадержка: \(latencyMs) мс\nПроверено серверов: \(totalTested)\n\nЧерез этот сервер идёт только трафик Telegram."
        case let .noWorkingServers(totalTested):
            message = "Не найдено ни одного рабочего сервера (проверено \(totalTested)). Попробуйте другую подписку или повторите позже."
        case let .subscriptionError(error):
            message = "Ошибка подписки: \(error)"
        }
        present(textAlertController(context: context, title: "Telewhite VPN", text: message, actions: [
            TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})
        ]))
    }
}
