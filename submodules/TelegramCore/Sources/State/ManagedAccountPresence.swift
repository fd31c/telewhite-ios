import Foundation
import TelegramApi
import Postbox
import SwiftSignalKit
import MtProtoKit

private typealias SignalKitTimer = SwiftSignalKit.Timer

// Telewhite: presence is suppressed when "Hide Online Status" is on, or while at
// least one chat has per-chat ghost enabled. Telegram has no per-contact online
// visibility, so as long as any ghost chat exists the account must stay offline —
// otherwise sending a message in that chat would instantly reveal you as online.
// (Global Ghost Mode was removed — per-chat ghost is the only ghost control.)
private func telewhiteGhostPresenceEnabled() -> Bool {
    let defaults = UserDefaults.standard
    if defaults.bool(forKey: "telewhite.mods.hideOnlineStatus") {
        return true
    }
    return !(defaults.array(forKey: "telewhite.mods.ghostPeerIds") as? [NSNumber] ?? []).isEmpty
}

private final class AccountPresenceManagerImpl {
    private let queue: Queue
    private let network: Network
    let isPerformingUpdate = ValuePromise<Bool>(false, ignoreRepeated: true)
    
    private var shouldKeepOnlinePresenceDisposable: Disposable?
    private let currentRequestDisposable = MetaDisposable()
    private var onlineTimer: SignalKitTimer?
    
    private var wasOnline: Bool = false
    private var ghostOfflineUpdateCount: Int = 0
    
    init(queue: Queue, shouldKeepOnlinePresence: Signal<Bool, NoError>, network: Network) {
        self.queue = queue
        self.network = network
        
        self.shouldKeepOnlinePresenceDisposable = (shouldKeepOnlinePresence
        |> distinctUntilChanged
        |> deliverOn(self.queue)).start(next: { [weak self] value in
            guard let `self` = self else {
                return
            }
            if self.wasOnline != value {
                self.wasOnline = value
                self.updatePresence(value)
            }
        })
    }
    
    deinit {
        assert(self.queue.isCurrent())
        self.shouldKeepOnlinePresenceDisposable?.dispose()
        self.currentRequestDisposable.dispose()
        self.onlineTimer?.invalidate()
    }
    
    private func updatePresence(_ isOnline: Bool) {
        let ghostEnabled = telewhiteGhostPresenceEnabled()
        let isOnline = isOnline && !ghostEnabled
        let request: Signal<Api.Bool, MTRpcError>
        if isOnline {
            self.ghostOfflineUpdateCount = 0
            let timer = SignalKitTimer(timeout: 30.0, repeat: false, completion: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.updatePresence(true)
            }, queue: self.queue)
            self.onlineTimer = timer
            timer.start()
            request = self.network.request(Api.functions.account.updateStatus(offline: .boolFalse))
        } else {
            self.onlineTimer?.invalidate()
            self.onlineTimer = nil
            if ghostEnabled && self.wasOnline {
                // Sending can briefly mark the account online on the server. Reassert
                // offline quickly around the send, then keep a slower maintenance pulse.
                let timeout: Double
                if self.ghostOfflineUpdateCount < 8 {
                    timeout = 0.25
                    self.ghostOfflineUpdateCount += 1
                } else {
                    timeout = 3.0
                }
                let timer = SignalKitTimer(timeout: timeout, repeat: false, completion: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.updatePresence(strongSelf.wasOnline)
                }, queue: self.queue)
                self.onlineTimer = timer
                timer.start()
            } else {
                self.ghostOfflineUpdateCount = 0
            }
            request = self.network.request(Api.functions.account.updateStatus(offline: .boolTrue))
        }
        self.isPerformingUpdate.set(true)
        self.currentRequestDisposable.set((request
        |> `catch` { _ -> Signal<Api.Bool, NoError> in
            return .single(.boolFalse)
        }
        |> deliverOn(self.queue)).start(completed: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isPerformingUpdate.set(false)
        }))
    }
}

final class AccountPresenceManager {
    private let queue = Queue()
    private let impl: QueueLocalObject<AccountPresenceManagerImpl>
    
    init(shouldKeepOnlinePresence: Signal<Bool, NoError>, network: Network) {
        let queue = self.queue
        self.impl = QueueLocalObject(queue: self.queue, generate: {
            return AccountPresenceManagerImpl(queue: queue, shouldKeepOnlinePresence: shouldKeepOnlinePresence, network: network)
        })
    }
    
    func isPerformingUpdate() -> Signal<Bool, NoError> {
        return Signal { subscriber in
            let disposable = MetaDisposable()
            self.impl.with { impl in
                disposable.set(impl.isPerformingUpdate.get().start(next: { value in
                    subscriber.putNext(value)
                }))
            }
            return disposable
        }
    }
}
