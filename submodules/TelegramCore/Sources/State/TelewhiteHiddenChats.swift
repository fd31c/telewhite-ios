import Foundation

public enum TelewhiteHiddenChats {
    private static let hiddenKey = "telewhite.mods.hiddenPeerIds"
    private static let passcodeKey = "telewhite.mods.hiddenChatsPasscode"

    public static let didChangeNotification = Notification.Name("TelewhiteHiddenChatsDidChange")

    private static var revealedInSession: Bool = false
    private static let lock = NSLock()

    public static var isRevealed: Bool {
        lock.lock()
        defer { lock.unlock() }
        return revealedInSession
    }

    public static func setRevealed(_ value: Bool) {
        lock.lock()
        revealedInSession = value
        lock.unlock()
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    public static func hiddenPeerIds() -> Set<Int64> {
        let values = UserDefaults.standard.array(forKey: hiddenKey) as? [NSNumber] ?? []
        return Set(values.map { $0.int64Value })
    }

    public static func isHidden(_ peerId: Int64) -> Bool {
        return hiddenPeerIds().contains(peerId)
    }

    public static func setHidden(_ peerId: Int64, hidden: Bool) {
        var current = hiddenPeerIds()
        if hidden {
            current.insert(peerId)
        } else {
            current.remove(peerId)
        }
        UserDefaults.standard.set(current.map { NSNumber(value: $0) }, forKey: hiddenKey)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    public static var passcode: String? {
        get {
            let value = UserDefaults.standard.string(forKey: passcodeKey)
            if let value, !value.isEmpty {
                return value
            }
            return nil
        }
        set {
            if let newValue, !newValue.isEmpty {
                UserDefaults.standard.set(newValue, forKey: passcodeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: passcodeKey)
            }
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }
}

public enum TelewhiteAccountProtection {
    private static let enabledKey = "telewhite.mods.deleteAccountProtection"

    public static var isEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: enabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
        }
    }
}
