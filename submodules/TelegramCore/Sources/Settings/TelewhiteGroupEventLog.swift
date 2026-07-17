import Foundation
import Postbox

public enum TelewhiteGroupEventLog {
    private enum Key {
        static let entries = "telewhite.mods.groupEventLogEntries"
    }

    public static var entries: [String] {
        return UserDefaults.standard.stringArray(forKey: Key.entries) ?? []
    }

    public static func recordRemovedFromGroup(peerId: PeerId) {
        let timestamp = Int32(Date().timeIntervalSince1970)
        var entries = self.entries
        entries.insert("removed:\(peerId.toInt64()):\(timestamp)", at: 0)
        if entries.count > 100 {
            entries = Array(entries.prefix(100))
        }
        UserDefaults.standard.set(entries, forKey: Key.entries)
    }

    public static func clear() {
        UserDefaults.standard.removeObject(forKey: Key.entries)
    }
}
