import Foundation
import Postbox

public enum TelewhiteChannelDeclutter {
    public static var hideReactions: Bool {
        return UserDefaults.standard.bool(forKey: "telewhite.mods.channelHideReactions")
    }

    public static var hideComments: Bool {
        return UserDefaults.standard.bool(forKey: "telewhite.mods.channelHideComments")
    }

    public static var hideShareButton: Bool {
        return UserDefaults.standard.bool(forKey: "telewhite.mods.channelHideShareButton")
    }

    public static func isBroadcastChannelMessage(_ message: Message) -> Bool {
        if let channel = message.peers[message.id.peerId] as? TelegramChannel, case .broadcast = channel.info {
            return true
        }
        return false
    }

    public static func shouldHideReactions(message: Message) -> Bool {
        return self.hideReactions && self.isBroadcastChannelMessage(message)
    }

    public static func shouldHideComments(message: Message) -> Bool {
        return self.hideComments && self.isBroadcastChannelMessage(message)
    }

    public static func shouldHideShareButton(message: Message) -> Bool {
        return self.hideShareButton && self.isBroadcastChannelMessage(message)
    }
}
