import Foundation
import Postbox

public enum TelewhiteMessageFilters {
    private enum Key {
        static let enabled = "telewhite.mods.messageFiltersEnabled"
        static let useRegex = "telewhite.mods.messageFiltersUseRegex"
        static let rules = "telewhite.mods.messageFilterRules"
    }

    private struct CompiledRules {
        let rawRules: String
        let useRegex: Bool
        let keywordRules: [String]
        let regexRules: [NSRegularExpression]
    }

    private static let compiledRulesLock = NSLock()
    private static var compiledRulesCache: CompiledRules?

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

    private static func compiledRules() -> CompiledRules {
        let rawRules = self.rawRules
        let useRegex = self.useRegex

        self.compiledRulesLock.lock()
        if let cached = self.compiledRulesCache, cached.rawRules == rawRules, cached.useRegex == useRegex {
            self.compiledRulesLock.unlock()
            return cached
        }
        self.compiledRulesLock.unlock()

        let rules = self.parsedRules(from: rawRules)
        let compiled = CompiledRules(
            rawRules: rawRules,
            useRegex: useRegex,
            keywordRules: useRegex ? [] : rules,
            regexRules: useRegex ? rules.compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) } : []
        )

        self.compiledRulesLock.lock()
        self.compiledRulesCache = compiled
        self.compiledRulesLock.unlock()

        return compiled
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
        let rules = self.compiledRules()
        if rules.useRegex {
            guard !rules.regexRules.isEmpty else {
                return false
            }
            let range = NSRange(text.startIndex ..< text.endIndex, in: text)
            for expression in rules.regexRules {
                if expression.firstMatch(in: text, options: [], range: range) != nil {
                    return true
                }
            }
            return false
        } else {
            guard !rules.keywordRules.isEmpty else {
                return false
            }
            for rule in rules.keywordRules {
                if text.range(of: rule, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                    return true
                }
            }
            return false
        }
    }
}
