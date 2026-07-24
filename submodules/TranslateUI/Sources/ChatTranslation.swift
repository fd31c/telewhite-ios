import Foundation
import NaturalLanguage
import SwiftSignalKit
import TelegramCore
import AccountContext
import TelegramUIPreferences

public struct ChatTranslationState: Codable {
    enum CodingKeys: String, CodingKey {
        case baseLang
        case fromLang
        case timestamp
        case toLang
        case isEnabled
    }
    
    public let baseLang: String
    public let fromLang: String
    public let timestamp: Int32?
    public let toLang: String?
    public let isEnabled: Bool
    
    public init(
        baseLang: String,
        fromLang: String,
        timestamp: Int32?,
        toLang: String?,
        isEnabled: Bool
    ) {
        self.baseLang = baseLang
        self.fromLang = fromLang
        self.timestamp = timestamp
        self.toLang = toLang
        self.isEnabled = isEnabled
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.baseLang = try container.decode(String.self, forKey: .baseLang)
        self.fromLang = try container.decode(String.self, forKey: .fromLang)
        self.timestamp = try container.decodeIfPresent(Int32.self, forKey: .timestamp)
        self.toLang = try container.decodeIfPresent(String.self, forKey: .toLang)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.baseLang, forKey: .baseLang)
        try container.encode(self.fromLang, forKey: .fromLang)
        try container.encodeIfPresent(self.timestamp, forKey: .timestamp)
        try container.encodeIfPresent(self.toLang, forKey: .toLang)
        try container.encode(self.isEnabled, forKey: .isEnabled)
    }

    public func withToLang(_ toLang: String?) -> ChatTranslationState {
        return ChatTranslationState(
            baseLang: self.baseLang,
            fromLang: self.fromLang,
            timestamp: self.timestamp,
            toLang: toLang,
            isEnabled: self.isEnabled
        )
    }
    
    public func withIsEnabled(_ isEnabled: Bool) -> ChatTranslationState {
        // Telewhite mod: refresh the timestamp when the user toggles translation,
        // otherwise a stale (>1h) cached state makes the panel disappear right
        // after tapping "Show Original".
        return ChatTranslationState(
            baseLang: self.baseLang,
            fromLang: self.fromLang,
            timestamp: Int32(CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970),
            toLang: self.toLang,
            isEnabled: isEnabled
        )
    }
}

private func cachedChatTranslationState(engine: TelegramEngine, peerId: EnginePeer.Id, threadId: Int64?) -> Signal<ChatTranslationState?, NoError> {
    let key: EngineDataBuffer
    if let threadId {
        key = EngineDataBuffer(length: 16)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
        key.setInt64(8, value: threadId)
    } else {
        key = EngineDataBuffer(length: 8)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
    }
    
    return engine.data.subscribe(TelegramEngine.EngineData.Item.ItemCache.Item(collectionId: ApplicationSpecificItemCacheCollectionId.translationState, id: key))
    |> map { entry -> ChatTranslationState? in
        return entry?.get(ChatTranslationState.self)
    }
}

private func updateChatTranslationState(engine: TelegramEngine, peerId: EnginePeer.Id, threadId: Int64?, state: ChatTranslationState?) -> Signal<Never, NoError> {
    let key: EngineDataBuffer
    if let threadId {
        key = EngineDataBuffer(length: 16)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
        key.setInt64(8, value: threadId)
    } else {
        key = EngineDataBuffer(length: 8)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
    }
    
    if let state {
        return engine.itemCache.put(collectionId: ApplicationSpecificItemCacheCollectionId.translationState, id: key, item: state)
    } else {
        return engine.itemCache.remove(collectionId: ApplicationSpecificItemCacheCollectionId.translationState, id: key)
    }
}

public func updateChatTranslationStateInteractively(engine: TelegramEngine, peerId: EnginePeer.Id, threadId: Int64?, _ f: @escaping (ChatTranslationState?) -> ChatTranslationState?) -> Signal<Never, NoError> {
    let key: EngineDataBuffer
    if let threadId {
        key = EngineDataBuffer(length: 16)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
        key.setInt64(8, value: threadId)
    } else {
        key = EngineDataBuffer(length: 8)
        key.setInt64(0, value: peerId.id._internalGetInt64Value())
    }
    
    return engine.data.get(TelegramEngine.EngineData.Item.ItemCache.Item(collectionId: ApplicationSpecificItemCacheCollectionId.translationState, id: key))
    |> map { entry -> ChatTranslationState? in
        return entry?.get(ChatTranslationState.self)
    }
    |> mapToSignal { current -> Signal<Never, NoError> in
        if let current {
            return updateChatTranslationState(engine: engine, peerId: peerId, threadId: threadId, state: f(current))
        } else {
            return .never()
        }
    }
}


// Telewhite: single source of truth for the incoming-translation mod settings.
// Always read them through these helpers — reading UserDefaults.standard.bool(...)
// directly returns `false` for users who never opened the mods settings screen,
// while TelewhiteModsSettings defaults to `true`, which made translation behave
// differently for different users.
public func telewhiteAutoTranslateEnabled() -> Bool {
    return (UserDefaults.standard.object(forKey: "telewhite.mods.autoTranslateEnglish") as? Bool) ?? true
}

// Telewhite: the target language for incoming translation always comes from the
// "Translation Language" setting (default "ru", matching the settings screen),
// never from the app interface language. Falls back to the interface language
// only if the stored value is not a supported translation language.
public func telewhiteTranslationTargetLanguage(fallback baseLang: String) -> String {
    let stored = UserDefaults.standard.string(forKey: "telewhite.mods.translationTargetLanguage") ?? "ru"
    let normalized = normalizeTranslationLanguage(stored.lowercased())
    if supportedTranslationLanguages.contains(normalized) {
        return normalized
    }
    let base = normalizeTranslationLanguage(baseLang)
    if supportedTranslationLanguages.contains(base) {
        return base
    }
    return "ru"
}

@available(iOS 12.0, *)
private let languageRecognizer = NLLanguageRecognizer()

// Telewhite: skip messages that are already in the target language (e.g. a Russian
// message when translating to Russian). Per-message detection matters because a
// mostly-foreign chat still contains Russian messages the user reads fine — sending
// them to translation only wastes a round-trip and time. Short texts are left in
// (detection is unreliable and translating them is cheap).
private func telewhiteIsAlreadyTargetLanguage(_ text: String, toLang: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 4 else {
        return false
    }
    let target = toLang.components(separatedBy: "-").first?.lowercased() ?? toLang.lowercased()
    languageRecognizer.reset()
    languageRecognizer.processString(String(trimmed.prefix(200)))
    let hypotheses = languageRecognizer.languageHypotheses(withMaximum: 1)
    guard let best = hypotheses.max(by: { $0.value < $1.value }), best.value >= 0.6 else {
        return false
    }
    let detected = best.key.rawValue.components(separatedBy: "-").first?.lowercased() ?? ""
    return detected == target
}

public func translateMessageIds(context: AccountContext, messageIds: [EngineMessage.Id], fromLang: String?, toLang: String) -> Signal<Never, NoError> {
    return context.account.postbox.transaction { transaction -> Signal<Never, NoError> in
        var messageIdsToTranslate: [EngineMessage.Id] = []
        var messageIdsSet = Set<EngineMessage.Id>()
        for messageId in messageIds {
            if let message = transaction.getMessage(messageId) {
                if let replyAttribute = message.attributes.first(where: { $0 is ReplyMessageAttribute }) as? ReplyMessageAttribute, let replyMessage = message.associatedMessages[replyAttribute.messageId] {
                    if !replyMessage.text.isEmpty {
                        if let translation = replyMessage.attributes.first(where: { $0 is TranslationMessageAttribute }) as? TranslationMessageAttribute, translation.toLang == toLang {
                        } else {
                            if !messageIdsSet.contains(replyMessage.id) {
                                messageIdsToTranslate.append(replyMessage.id)
                                messageIdsSet.insert(replyMessage.id)
                            }
                        }
                    }
                }
                guard message.author?.id != context.account.peerId else {
                    continue
                }
                if let translation = message.attributes.first(where: { $0 is TranslationMessageAttribute }) as? TranslationMessageAttribute, translation.toLang == toLang {
                    continue
                }
                
                if !message.text.isEmpty {
                    // Telewhite: never translate messages already in the target language.
                    if telewhiteIsAlreadyTargetLanguage(message.text, toLang: toLang) {
                        continue
                    }
                    if !messageIdsSet.contains(messageId) {
                        messageIdsToTranslate.append(messageId)
                        messageIdsSet.insert(messageId)
                    }
                } else if let _ = message.media.first(where: { $0 is TelegramMediaPoll }) {
                    if !messageIdsSet.contains(messageId) {
                        messageIdsToTranslate.append(messageId)
                        messageIdsSet.insert(messageId)
                    }
                } else if let audioTranscription = message.attributes.first(where: { $0 is AudioTranscriptionMessageAttribute }) as? AudioTranscriptionMessageAttribute, !audioTranscription.text.isEmpty && !audioTranscription.isPending {
                    if !messageIdsSet.contains(messageId) {
                        messageIdsToTranslate.append(messageId)
                        messageIdsSet.insert(messageId)
                    }
                }
            } else {
                if !messageIdsSet.contains(messageId) {
                    messageIdsToTranslate.append(messageId)
                    messageIdsSet.insert(messageId)
                }
            }
        }
        
        let translationConfiguration = TranslationConfiguration.with(appConfiguration: context.currentAppConfiguration.with { $0 })
        var enableLocalIfPossible = false
        switch translationConfiguration.auto {
        case .system:
            if #available(iOS 18.0, *) {
                enableLocalIfPossible = true
            }
        default:
            break
        }
        return context.engine.messages.translateMessages(messageIds: messageIdsToTranslate, fromLang: fromLang, toLang: toLang, enableLocalIfPossible: enableLocalIfPossible)
        |> `catch` { _ -> Signal<Never, NoError> in
            return .complete()
        }
    } |> switchToLatest
}

public func chatTranslationState(context: AccountContext, peerId: EnginePeer.Id, threadId: Int64?) -> Signal<ChatTranslationState?, NoError> {
    if peerId.id == EnginePeer.Id.Id._internalFromInt64Value(777000) {
        return .single(nil)
    }
    
    guard canTranslateChats(context: context) else {
        return .single(nil)
    }
    
    let loggingEnabled = context.sharedContext.immediateExperimentalUISettings.logLanguageRecognition
    
    if #available(iOS 12.0, *) {
        var baseLang = context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode
        let rawSuffix = "-raw"
        if baseLang.hasSuffix(rawSuffix) {
            baseLang = String(baseLang.dropLast(rawSuffix.count))
        }

        return combineLatest(
            context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.translationSettings])
            |> map { sharedData -> TranslationSettings in
                return sharedData.entries[ApplicationSpecificSharedDataKeys.translationSettings]?.get(TranslationSettings.self) ?? TranslationSettings.defaultSettings
            },
            context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.AutoTranslateEnabled(id: peerId))
        )
        |> mapToSignal { settings, autoTranslateEnabled in
            let telewhiteIncomingTranslationEnabled = telewhiteAutoTranslateEnabled()
            if !settings.translateChats && !autoTranslateEnabled && !telewhiteIncomingTranslationEnabled {
                return .single(nil)
            }
            
            var dontTranslateLanguages = Set<String>()
            if let ignoredLanguages = settings.ignoredLanguages {
                dontTranslateLanguages = Set(ignoredLanguages)
            } else {
                dontTranslateLanguages.insert(baseLang)
                for language in systemLanguageCodes() {
                    dontTranslateLanguages.insert(language)
                }
            }
            
            return cachedChatTranslationState(engine: context.engine, peerId: peerId, threadId: threadId)
            |> mapToSignal { cached in
                let currentTime = Int32(CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970)
                // Telewhite: unified rule for when a chat is translatable.
                // A chat whose detected language equals the target language
                // (e.g. a Russian chat with a Russian target) must NEVER be
                // translated or show the translation panel — translation only
                // makes sense between two different languages.
                let isDisplayable: (ChatTranslationState) -> Bool = { state in
                    guard !state.fromLang.isEmpty else {
                        return false
                    }
                    if let toLang = state.toLang, state.fromLang == toLang {
                        return false
                    }
                    // Telewhite: never auto-translate a message that is already in
                    // the target language (e.g. Russian when the target is Russian).
                    let targetLanguage = telewhiteTranslationTargetLanguage(fallback: baseLang)
                    if normalizeTranslationLanguage(state.fromLang) == normalizeTranslationLanguage(targetLanguage) {
                        return false
                    }
                    // Telewhite: also respect the ignored-language list even in
                    // auto mode — languages the user reads (Russian, the app
                    // language, system languages) are left untouched.
                    if dontTranslateLanguages.contains(state.fromLang) {
                        return false
                    }
                    if state.isEnabled {
                        return true
                    }
                    if telewhiteIncomingTranslationEnabled {
                        return true
                    }
                    return !dontTranslateLanguages.contains(state.fromLang)
                }
                if let cached, let timestamp = cached.timestamp, cached.baseLang == baseLang && currentTime - timestamp < 60 * 60 {
                    if isDisplayable(cached) {
                        return .single(cached)
                    } else {
                        return .single(nil)
                    }
                } else {
                    // Keep showing the last known state while language re-detection
                    // runs, instead of blinking the panel out with nil.
                    var initialState: ChatTranslationState?
                    if let cached, cached.baseLang == baseLang, !cached.fromLang.isEmpty {
                        if isDisplayable(cached) {
                            initialState = cached
                        }
                    }
                    return .single(initialState)
                    |> then(
                        context.account.viewTracker.aroundMessageHistoryViewForLocation(.peer(peerId: peerId, threadId: threadId), index: .upperBound, anchorIndex: .upperBound, count: 32, fixedCombinedReadStates: nil)
                        |> filter { messageHistoryView -> Bool in
                            return messageHistoryView.0.entries.count > 1
                        }
                        |> take(1)
                        |> map { messageHistoryView, _, _ -> ChatTranslationState? in
                            let messages = messageHistoryView.entries.map(\.message)
                            
                            if loggingEnabled {
                                Logger.shared.log("ChatTranslation", "Start language recognizing for \(peerId)")
                            }
                            var fromLangs: [String: Int] = [:]
                            var count = 0
                            for message in messages {
                                if message.effectivelyIncoming(context.account.peerId), message.text.count >= 10 {
                                    if let summaryAttribute = message.attributes.first(where: { $0 is SummarizationMessageAttribute }) as? SummarizationMessageAttribute, !summaryAttribute.fromLang.isEmpty {
                                        let fromLang = normalizeTranslationLanguage(summaryAttribute.fromLang)
                                        if supportedTranslationLanguages.contains(fromLang) {
                                            fromLangs[fromLang] = (fromLangs[fromLang] ?? 0) + message.text.count
                                            count += 1
                                        }
                                    } else {
                                        var text = String(message.text.prefix(256))
                                        if var entities = message.textEntitiesAttribute?.entities.filter({ entity in
                                            switch entity.type {
                                            case .Pre, .Code, .Url, .Email, .Mention, .Hashtag, .BotCommand:
                                                return true
                                            default:
                                                return false
                                            }
                                        }) {
                                            entities = entities.sorted(by: { $0.range.lowerBound > $1.range.lowerBound })
                                            var ranges: [Range<String.Index>] = []
                                            for entity in entities {
                                                if entity.range.lowerBound > text.count || entity.range.upperBound > text.count {
                                                    continue
                                                }
                                                ranges.append(text.index(text.startIndex, offsetBy: entity.range.lowerBound) ..< text.index(text.startIndex, offsetBy: entity.range.upperBound))
                                            }
                                            for range in ranges {
                                                if range.upperBound < text.endIndex {
                                                    text.removeSubrange(range)
                                                }
                                            }
                                        }
                                        
                                        if message.text.count < 10 {
                                            continue
                                        }
                                        
                                        languageRecognizer.processString(text)
                                        let hypotheses = languageRecognizer.languageHypotheses(withMaximum: 4)
                                        languageRecognizer.reset()
                                        
                                        let filteredLanguages = hypotheses.filter { supportedTranslationLanguages.contains(normalizeTranslationLanguage($0.key.rawValue)) }.sorted(by: { $0.value > $1.value })
                                        if let language = filteredLanguages.first {
                                            let fromLang = normalizeTranslationLanguage(language.key.rawValue)
                                            if loggingEnabled && !["en", "ru"].contains(fromLang) && !dontTranslateLanguages.contains(fromLang) {
                                                Logger.shared.log("ChatTranslation", "\(text)")
                                                Logger.shared.log("ChatTranslation", "Recognized as: \(fromLang), other hypotheses: \(hypotheses.map { $0.key.rawValue }.joined(separator: ",")) ")
                                            }
                                            fromLangs[fromLang] = (fromLangs[fromLang] ?? 0) + message.text.count
                                            count += 1
                                        }
                                    }
                                }
                                if count >= 16 {
                                    break
                                }
                            }
                                                        
                            var mostFrequent: (String, Int)?
                            for (lang, count) in fromLangs {
                                if let current = mostFrequent {
                                    if count > current.1 {
                                        mostFrequent = (lang, count)
                                    }
                                } else {
                                    mostFrequent = (lang, count)
                                }
                            }
                            let fromLang = mostFrequent?.0 ?? ""
                            if loggingEnabled {
                                Logger.shared.log("ChatTranslation", "Ended with: \(fromLang)")
                            }

                            if telewhiteIncomingTranslationEnabled && !settings.showTranslate && fromLang.isEmpty {
                                return nil
                            }

                            // Telewhite: always derive the target from the global
                            // "Translation Language" setting instead of the interface
                            // language. On re-detection we intentionally do NOT reuse
                            // cached.toLang: old caches were populated with the
                            // interface language and would keep the wrong target
                            // forever. A manual per-chat "Translate to" choice still
                            // wins while its cache entry is fresh (< 1h, refreshed on
                            // every toggle).
                            let targetLanguage = telewhiteTranslationTargetLanguage(fallback: baseLang)
                            // Telewhite: with auto incoming translation on, non-target
                            // languages are translated automatically (no manual tap);
                            // otherwise the bar is shown but nothing is translated until
                            // the user turns it on for this chat.
                            var isEnabled = cached?.isEnabled ?? false
                            if telewhiteIncomingTranslationEnabled, !fromLang.isEmpty, normalizeTranslationLanguage(fromLang) != normalizeTranslationLanguage(targetLanguage) {
                                isEnabled = true
                            }
                            // Never translate a chat that is already in the target
                            // language (e.g. Russian chats with a Russian target),
                            // and never auto-enable when detection failed.
                            if fromLang.isEmpty || normalizeTranslationLanguage(fromLang) == normalizeTranslationLanguage(targetLanguage) {
                                isEnabled = false
                            }
                            let state = ChatTranslationState(
                                baseLang: baseLang,
                                fromLang: fromLang,
                                timestamp: currentTime,
                                toLang: targetLanguage,
                                isEnabled: isEnabled
                            )
                            let _ = updateChatTranslationState(engine: context.engine, peerId: peerId, threadId: threadId, state: state).start()
                            if isDisplayable(state) {
                                return state
                            } else {
                                return nil
                            }
                        }
                    )
                }
            }
        }
    } else {
        return .single(nil)
    }
}
