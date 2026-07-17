import Foundation
import Postbox

public enum TelewhiteMessageFilters {
    private enum Key {
        static let enabled = "telewhite.mods.messageFiltersEnabled"
        static let useRegex = "telewhite.mods.messageFiltersUseRegex"
        static let rules = "telewhite.mods.messageFilterRules"
    }

    public static var enabled: Bool {
        return UserDefaults.standard.bool(forKey: Key.enabled)
    }

    public static var useRegex: Bool {
        return UserDefaults.standard.bool(forKey: Key.useRegex)
    }

    public static var rawRules: String {
        return UserDefaults.standard.string(forKey: Key.rules) ?? ""
    }

    public static func parsedRules(from value: String? = nil) -> [String] {
        return (value ?? self.rawRules)
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    public static func shouldHideMessage(_ message: Message, accountPeerId: PeerId) -> Bool {
        guard self.enabled else {
            return false
        }
        guard message.effectivelyIncoming(accountPeerId) else {
            return false
        }
        for media in message.media {
            if media is TelegramMediaAction {
                return false
            }
        }
        let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return false
        }
        let rules = self.parsedRules()
        guard !rules.isEmpty else {
            return false
        }
        if self.useRegex {
            let range = NSRange(text.startIndex ..< text.endIndex, in: text)
            for rule in rules {
                guard let expression = try? NSRegularExpression(pattern: rule, options: [.caseInsensitive]) else {
                    continue
                }
                if expression.firstMatch(in: text, options: [], range: range) != nil {
                    return true
                }
            }
            return false
        } else {
            for rule in rules {
                if text.range(of: rule, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                    return true
                }
            }
            return false
        }
    }
}
