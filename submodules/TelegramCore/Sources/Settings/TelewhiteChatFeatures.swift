import Foundation
import Postbox

public struct TelewhiteChatMetadata: Codable, Equatable {
    public var note: String
    public var tags: [String]
    public var isHidden: Bool

    public init(note: String = "", tags: [String] = [], isHidden: Bool = false) {
        self.note = note
        self.tags = tags
        self.isHidden = isHidden
    }
}

public enum TelewhiteChatFeatures {
    private static let lock = NSLock()

    private static func key(accountPeerId: PeerId) -> String {
        return "telewhite.chatFeatures.\(accountPeerId.toInt64())"
    }

    public static func all(accountPeerId: PeerId) -> [Int64: TelewhiteChatMetadata] {
        lock.lock()
        defer { lock.unlock() }
        guard let data = UserDefaults.standard.data(forKey: key(accountPeerId: accountPeerId)),
              let value = try? JSONDecoder().decode([Int64: TelewhiteChatMetadata].self, from: data) else {
            return [:]
        }
        return value
    }

    public static func metadata(accountPeerId: PeerId, peerId: PeerId) -> TelewhiteChatMetadata {
        return all(accountPeerId: accountPeerId)[peerId.toInt64()] ?? TelewhiteChatMetadata()
    }

    public static func update(accountPeerId: PeerId, peerId: PeerId, _ update: (inout TelewhiteChatMetadata) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        let storageKey = key(accountPeerId: accountPeerId)
        var values: [Int64: TelewhiteChatMetadata] = [:]
        if let data = UserDefaults.standard.data(forKey: storageKey), let decoded = try? JSONDecoder().decode([Int64: TelewhiteChatMetadata].self, from: data) {
            values = decoded
        }
        let peerKey = peerId.toInt64()
        var value = values[peerKey] ?? TelewhiteChatMetadata()
        update(&value)
        if value.note.isEmpty && value.tags.isEmpty && !value.isHidden {
            values.removeValue(forKey: peerKey)
        } else {
            values[peerKey] = value
        }
        if let data = try? JSONEncoder().encode(values) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        NotificationCenter.default.post(name: Notification.Name("TelewhiteChatFeaturesChanged"), object: nil)
    }

    public static func hiddenPeerIds(accountPeerId: PeerId) -> Set<Int64> {
        return Set(all(accountPeerId: accountPeerId).compactMap { $0.value.isHidden ? $0.key : nil })
    }
}
