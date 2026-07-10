import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import AlertUI
import PromptUI
import TelegramCore
import TelegramUIPreferences

public struct TelewhiteModsSettings: Equatable {
    public static let didChangeNotification = Notification.Name("TelewhiteModsSettingsDidChange")

    public var vpnEnabled: Bool
    public var vpnSubscription: String
    public var ghostMode: Bool
    public var ghostChatButtonEnabled: Bool
    public var preserveDeletedMessages: Bool
    public var hideOnlineStatus: Bool
    public var hideTypingStatus: Bool
    public var hideReadReceipts: Bool
    public var screenshotProtectionBypass: Bool
    public var contentRestrictionBypass: Bool
    public var hidePhoneInSettings: Bool
    public var hideStories: Bool
    public var ghostStories: Bool
    public var compactChatList: Bool
    public var chatSplitLandscape: Bool
    public var amoledMode: Bool
    public var showUserIds: Bool
    public var showChatIds: Bool
    public var showMessageIds: Bool
    public var ghostPeerIds: Set<Int64>
    public var autoTranslateEnglish: Bool
    public var translationTargetLanguage: String
    public var oneTimeMediaUnlimited: Bool
    public var downloadOneTimeMedia: Bool
    public var uploadVoice: Bool
    public var uploadVideoMessage: Bool
    public var downloadStories: Bool
    public var autoRecordCalls: Bool
    public var callRecordButton: Bool
    public var accentColorOverride: Int64?
    public var bubbleColorOverride: Int64?
    public var chatBackgroundColorOverride: Int64?
    public var chatBackgroundGradientOverride: [Int64]?
    public var bubbleCornerRadiusOverride: Int32?
    public var outgoingTranslateButtonEnabled: Bool
    public var outgoingTranslationPeerIds: Set<Int64>
    public var outgoingTranslationLanguages: [Int64: String]
    public var openRouterApiKey: String
    public var outgoingTranslationAutoEnabled: Bool

    private enum Key {
        static let vpnEnabled = "telewhite.mods.vpnEnabled"
        static let vpnSubscription = "telewhite.mods.vpnSubscription"
        static let ghostMode = "telewhite.mods.ghostMode"
        static let ghostChatButtonEnabled = "telewhite.mods.ghostChatButtonEnabled"
        static let preserveDeletedMessages = "telewhite.mods.preserveDeletedMessages"
        static let hideOnlineStatus = "telewhite.mods.hideOnlineStatus"
        static let hideTypingStatus = "telewhite.mods.hideTypingStatus"
        static let hideReadReceipts = "telewhite.mods.hideReadReceipts"
        static let screenshotProtectionBypass = "telewhite.mods.screenshotProtectionBypass"
        static let contentRestrictionBypass = "telewhite.mods.contentRestrictionBypass"
        static let hidePhoneInSettings = "telewhite.mods.hidePhoneInSettings"
        static let hideStories = "telewhite.mods.hideStories"
        static let ghostStories = "telewhite.mods.ghostStories"
        static let compactChatList = "telewhite.mods.compactChatList"
        static let chatSplitLandscape = "telewhite.mods.chatSplitLandscape"
        static let amoledMode = "telewhite.mods.amoledMode"
        static let showUserIds = "telewhite.mods.showUserIds"
        static let showChatIds = "telewhite.mods.showChatIds"
        static let showMessageIds = "telewhite.mods.showMessageIds"
        static let ghostPeerIds = "telewhite.mods.ghostPeerIds"
        static let autoTranslateEnglish = "telewhite.mods.autoTranslateEnglish"
        static let translationTargetLanguage = "telewhite.mods.translationTargetLanguage"
        static let oneTimeMediaUnlimited = "telewhite.mods.oneTimeMediaUnlimited"
        static let downloadOneTimeMedia = "telewhite.mods.downloadOneTimeMedia"
        static let uploadVoice = "telewhite.mods.uploadVoice"
        static let uploadVideoMessage = "telewhite.mods.uploadVideoMessage"
        static let downloadStories = "telewhite.mods.downloadStories"
        static let autoRecordCalls = "telewhite.mods.autoRecordCalls"
        static let callRecordButton = "telewhite.mods.callRecordButton"
        static let accentColor = "telewhite.mods.accentColor"
        static let bubbleColor = "telewhite.mods.bubbleColor"
        static let chatBackgroundColor = "telewhite.mods.chatBackgroundColor"
        static let chatBackgroundGradient = "telewhite.mods.chatBackgroundGradient"
        static let bubbleCornerRadius = "telewhite.mods.bubbleCornerRadius"
        static let outgoingTranslateButtonEnabled = "telewhite.mods.outgoingTranslateButtonEnabled"
        static let outgoingTranslationPeerIds = "telewhite.mods.outgoingTranslationPeerIds"
        static let outgoingTranslationLanguages = "telewhite.mods.outgoingTranslationLanguages"
        static let openRouterApiKey = "telewhite.mods.openRouterApiKey"
        static let outgoingTranslationAutoEnabled = "telewhite.mods.outgoingTranslationAutoEnabled"
    }
    
    public static var current: TelewhiteModsSettings {
        let defaults = UserDefaults.standard
        return TelewhiteModsSettings(
            vpnEnabled: defaults.bool(forKey: Key.vpnEnabled),
            vpnSubscription: defaults.string(forKey: Key.vpnSubscription) ?? "",
            ghostMode: defaults.bool(forKey: Key.ghostMode),
            ghostChatButtonEnabled: defaults.object(forKey: Key.ghostChatButtonEnabled) as? Bool ?? true,
            preserveDeletedMessages: defaults.bool(forKey: Key.preserveDeletedMessages),
            hideOnlineStatus: defaults.bool(forKey: Key.hideOnlineStatus),
            hideTypingStatus: defaults.bool(forKey: Key.hideTypingStatus),
            hideReadReceipts: defaults.bool(forKey: Key.hideReadReceipts),
            screenshotProtectionBypass: defaults.bool(forKey: Key.screenshotProtectionBypass),
            contentRestrictionBypass: defaults.bool(forKey: Key.contentRestrictionBypass),
            hidePhoneInSettings: defaults.bool(forKey: Key.hidePhoneInSettings),
            hideStories: defaults.bool(forKey: Key.hideStories),
            ghostStories: defaults.bool(forKey: Key.ghostStories),
            compactChatList: defaults.bool(forKey: Key.compactChatList),
            chatSplitLandscape: defaults.bool(forKey: Key.chatSplitLandscape),
            amoledMode: defaults.bool(forKey: Key.amoledMode),
            showUserIds: defaults.bool(forKey: Key.showUserIds),
            showChatIds: defaults.bool(forKey: Key.showChatIds),
            showMessageIds: defaults.bool(forKey: Key.showMessageIds),
            ghostPeerIds: Set((defaults.array(forKey: Key.ghostPeerIds) as? [NSNumber] ?? []).map { $0.int64Value }),
            autoTranslateEnglish: defaults.bool(forKey: Key.autoTranslateEnglish),
            translationTargetLanguage: defaults.string(forKey: Key.translationTargetLanguage) ?? "ru",
            oneTimeMediaUnlimited: defaults.bool(forKey: Key.oneTimeMediaUnlimited),
            downloadOneTimeMedia: defaults.bool(forKey: Key.downloadOneTimeMedia),
            uploadVoice: defaults.bool(forKey: Key.uploadVoice),
            uploadVideoMessage: defaults.bool(forKey: Key.uploadVideoMessage),
            downloadStories: defaults.bool(forKey: Key.downloadStories),
            autoRecordCalls: defaults.bool(forKey: Key.autoRecordCalls),
            callRecordButton: defaults.object(forKey: Key.callRecordButton) as? Bool ?? true,
            accentColorOverride: (defaults.object(forKey: Key.accentColor) as? NSNumber)?.int64Value,
            bubbleColorOverride: (defaults.object(forKey: Key.bubbleColor) as? NSNumber)?.int64Value,
            chatBackgroundColorOverride: (defaults.object(forKey: Key.chatBackgroundColor) as? NSNumber)?.int64Value,
            chatBackgroundGradientOverride: (defaults.array(forKey: Key.chatBackgroundGradient) as? [NSNumber]).flatMap { numbers in numbers.count >= 2 ? numbers.map { $0.int64Value } : nil },
            bubbleCornerRadiusOverride: (defaults.object(forKey: Key.bubbleCornerRadius) as? NSNumber)?.int32Value,
            outgoingTranslateButtonEnabled: defaults.object(forKey: Key.outgoingTranslateButtonEnabled) as? Bool ?? true,
            outgoingTranslationPeerIds: Set((defaults.array(forKey: Key.outgoingTranslationPeerIds) as? [NSNumber] ?? []).map { $0.int64Value }),
            outgoingTranslationLanguages: {
                var result: [Int64: String] = [:]
                if let stored = defaults.dictionary(forKey: Key.outgoingTranslationLanguages) as? [String: String] {
                    for (key, value) in stored {
                        if let rawId = Int64(key) {
                            result[rawId] = value
                        }
                    }
                }
                return result
            }(),
            openRouterApiKey: defaults.string(forKey: Key.openRouterApiKey) ?? "",
            outgoingTranslationAutoEnabled: defaults.bool(forKey: Key.outgoingTranslationAutoEnabled)
        )
    }

    public func isGhostEnabled(for peerId: EnginePeer.Id?) -> Bool {
        guard let peerId else {
            return false
        }
        return self.ghostPeerIds.contains(peerId.toInt64())
    }

    public func withToggledGhostPeer(_ peerId: EnginePeer.Id) -> TelewhiteModsSettings {
        var updated = self
        let rawId = peerId.toInt64()
        if updated.ghostPeerIds.contains(rawId) {
            updated.ghostPeerIds.remove(rawId)
        } else {
            updated.ghostPeerIds.insert(rawId)
        }
        return updated
    }

    public func isOutgoingTranslationEnabled(for peerId: EnginePeer.Id?) -> Bool {
        guard let peerId else {
            return false
        }
        return self.outgoingTranslationPeerIds.contains(peerId.toInt64())
    }

    public func outgoingTranslationLanguage(for peerId: EnginePeer.Id?) -> String {
        guard let peerId else {
            return "en"
        }
        return self.outgoingTranslationLanguages[peerId.toInt64()] ?? "en"
    }

    public func withToggledOutgoingTranslationPeer(_ peerId: EnginePeer.Id) -> TelewhiteModsSettings {
        var updated = self
        let rawId = peerId.toInt64()
        if updated.outgoingTranslationPeerIds.contains(rawId) {
            updated.outgoingTranslationPeerIds.remove(rawId)
        } else {
            updated.outgoingTranslationPeerIds.insert(rawId)
        }
        return updated
    }

    public func withOutgoingTranslationLanguage(_ language: String, for peerId: EnginePeer.Id) -> TelewhiteModsSettings {
        var updated = self
        let rawId = peerId.toInt64()
        updated.outgoingTranslationLanguages[rawId] = language
        updated.outgoingTranslationPeerIds.insert(rawId)
        return updated
    }
    
    public func save() {
        let defaults = UserDefaults.standard
        defaults.set(self.vpnEnabled, forKey: Key.vpnEnabled)
        defaults.set(self.vpnSubscription, forKey: Key.vpnSubscription)
        defaults.set(self.ghostMode, forKey: Key.ghostMode)
        defaults.set(self.ghostChatButtonEnabled, forKey: Key.ghostChatButtonEnabled)
        defaults.set(self.preserveDeletedMessages, forKey: Key.preserveDeletedMessages)
        defaults.set(self.hideOnlineStatus, forKey: Key.hideOnlineStatus)
        defaults.set(self.hideTypingStatus, forKey: Key.hideTypingStatus)
        defaults.set(self.hideReadReceipts, forKey: Key.hideReadReceipts)
        defaults.set(self.screenshotProtectionBypass, forKey: Key.screenshotProtectionBypass)
        defaults.set(self.contentRestrictionBypass, forKey: Key.contentRestrictionBypass)
        defaults.set(self.hidePhoneInSettings, forKey: Key.hidePhoneInSettings)
        defaults.set(self.hideStories, forKey: Key.hideStories)
        defaults.set(self.ghostStories, forKey: Key.ghostStories)
        defaults.set(self.compactChatList, forKey: Key.compactChatList)
        defaults.set(self.chatSplitLandscape, forKey: Key.chatSplitLandscape)
        TelewhiteSplitViewSettings.splitInCompactLandscape = self.chatSplitLandscape
        defaults.set(self.amoledMode, forKey: Key.amoledMode)
        defaults.set(self.showUserIds, forKey: Key.showUserIds)
        defaults.set(self.showChatIds, forKey: Key.showChatIds)
        defaults.set(self.showMessageIds, forKey: Key.showMessageIds)
        defaults.set(self.ghostPeerIds.map { NSNumber(value: $0) }, forKey: Key.ghostPeerIds)
        defaults.set(self.autoTranslateEnglish, forKey: Key.autoTranslateEnglish)
        defaults.set(self.translationTargetLanguage, forKey: Key.translationTargetLanguage)
        defaults.set(self.oneTimeMediaUnlimited, forKey: Key.oneTimeMediaUnlimited)
        defaults.set(self.downloadOneTimeMedia, forKey: Key.downloadOneTimeMedia)
        defaults.set(self.uploadVoice, forKey: Key.uploadVoice)
        defaults.set(self.uploadVideoMessage, forKey: Key.uploadVideoMessage)
        defaults.set(self.downloadStories, forKey: Key.downloadStories)
        defaults.set(self.autoRecordCalls, forKey: Key.autoRecordCalls)
        defaults.set(self.callRecordButton, forKey: Key.callRecordButton)
        if let value = self.accentColorOverride {
            defaults.set(NSNumber(value: value), forKey: Key.accentColor)
        } else {
            defaults.removeObject(forKey: Key.accentColor)
        }
        if let value = self.bubbleColorOverride {
            defaults.set(NSNumber(value: value), forKey: Key.bubbleColor)
        } else {
            defaults.removeObject(forKey: Key.bubbleColor)
        }
        if let value = self.chatBackgroundColorOverride {
            defaults.set(NSNumber(value: value), forKey: Key.chatBackgroundColor)
        } else {
            defaults.removeObject(forKey: Key.chatBackgroundColor)
        }
        if let value = self.chatBackgroundGradientOverride, value.count >= 2 {
            defaults.set(value.map { NSNumber(value: $0) }, forKey: Key.chatBackgroundGradient)
        } else {
            defaults.removeObject(forKey: Key.chatBackgroundGradient)
        }
        if let value = self.bubbleCornerRadiusOverride {
            defaults.set(NSNumber(value: value), forKey: Key.bubbleCornerRadius)
        } else {
            defaults.removeObject(forKey: Key.bubbleCornerRadius)
        }
        defaults.set(self.outgoingTranslateButtonEnabled, forKey: Key.outgoingTranslateButtonEnabled)
        defaults.set(self.outgoingTranslationPeerIds.map { NSNumber(value: $0) }, forKey: Key.outgoingTranslationPeerIds)
        defaults.set(Dictionary(uniqueKeysWithValues: self.outgoingTranslationLanguages.map { (String($0.key), $0.value) }), forKey: Key.outgoingTranslationLanguages)
        defaults.set(self.openRouterApiKey, forKey: Key.openRouterApiKey)
        defaults.set(self.outgoingTranslationAutoEnabled, forKey: Key.outgoingTranslationAutoEnabled)
        NotificationCenter.default.post(name: TelewhiteModsSettings.didChangeNotification, object: nil)
    }

    public static func signal() -> Signal<TelewhiteModsSettings, NoError> {
        return Signal { subscriber in
            subscriber.putNext(TelewhiteModsSettings.current)
            let observer = NotificationCenter.default.addObserver(forName: TelewhiteModsSettings.didChangeNotification, object: nil, queue: .main, using: { _ in
                subscriber.putNext(TelewhiteModsSettings.current)
            })
            return ActionDisposable {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

enum TelewhiteCustomColorTarget {
    case accent
    case bubble
    case background
}

private final class TelewhiteModsControllerArguments {
    let updateSettings: ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void
    let updateTranslationSettings: (@escaping (TranslationSettings) -> TranslationSettings) -> Void
    let startVpn: () -> Void
    let openTab: (TelewhiteModsTab) -> Void
    let promptCustomColor: (TelewhiteCustomColorTarget) -> Void
    let openDebug: () -> Void
    let promptOpenRouterKey: () -> Void
    
    init(
        updateSettings: @escaping ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void,
        updateTranslationSettings: @escaping (@escaping (TranslationSettings) -> TranslationSettings) -> Void,
        startVpn: @escaping () -> Void,
        openTab: @escaping (TelewhiteModsTab) -> Void = { _ in },
        promptCustomColor: @escaping (TelewhiteCustomColorTarget) -> Void = { _ in },
        openDebug: @escaping () -> Void = {},
        promptOpenRouterKey: @escaping () -> Void = {}
    ) {
        self.updateSettings = updateSettings
        self.updateTranslationSettings = updateTranslationSettings
        self.startVpn = startVpn
        self.openTab = openTab
        self.promptCustomColor = promptCustomColor
        self.openDebug = openDebug
        self.promptOpenRouterKey = promptOpenRouterKey
    }
}

private enum TelewhiteModsSection: Int32 {
    case menu
    case messenger
    case privacy
    case stealth
    case channels
    case media
    case calls
    case vpn
    case appearance
    case accentColor
    case bubbleColor
    case backgroundColor
    case cornerRadius
    case developer
}

private enum TelewhiteModsTab: Int32, Equatable {
    case messenger
    case privacy
    case stealth
    case channels
    case media
    case calls
    case proxy
    case appearance
    case developer
}

private enum TelewhiteModsMenuIcon: Int32, Equatable {
    case privacy
    case ghost
    case messages
    case groups
    case media
    case calls
    case proxy
    case appearance
    case developer
}

private enum TelewhiteModsEntry: ItemListNodeEntry, Equatable {
    case menuItem(Int32, TelewhiteModsMenuIcon, String, String, TelewhiteModsTab)

    case messengerHeader(String)
    case preserveDeletedMessages(String, Bool)
    case translateMessages(String, Bool)
    case translateChats(String, Bool)
    case autoTranslateEnglish(String, Bool)
    case translationTargetLanguage(String, String)
    case outgoingTranslateButtonEnabled(String, Bool)
    case outgoingTranslationAutoEnabled(String, Bool)
    case openRouterApiKey(String, String)
    case messengerInfo(String)
    case oneTimeMediaUnlimited(String, Bool)
    case downloadOneTimeMedia(String, Bool)
    case uploadVoice(String, Bool)
    case voiceChangeSettings(String)
    case uploadVideoMessage(String, Bool)

    case vpnHeader(String)
    case vpnEnabled(String, Bool)
    case vpnSubscription(String, String)
    case vpnStatus(String, String)
    case vpnStart(String)
    case vpnInfo(String)
    
    case privacyHeader(String)
    case hideOnlineStatus(String, Bool)
    case ghostMode(String, Bool)
    case ghostChatButtonEnabled(String, Bool)
    case hideTypingStatus(String, Bool)
    case hideReadReceipts(String, Bool)
    case screenshotProtectionBypass(String, Bool)
    case contentRestrictionBypass(String, Bool)
    case hidePhoneInSettings(String, Bool)
    case showProfileIds(String, Bool)
    case privacyInfo(String)
    
    case stealthHeader(String)
    case ghostMessages(String, Bool)
    case ghostStories(String, Bool)
    case stealthInfo(String)

    case channelsHeader(String)
    case channelContentRestrictionBypass(String, Bool)
    case channelsInfo(String)

    case mediaHeader(String)
    case downloadStories(String, Bool)
    case mediaInfo(String)

    case callsHeader(String)
    case autoRecordCalls(String, Bool)
    case callRecordButton(String, Bool)
    case callsInfo(String)

    case appearanceHeader(String)
    case hideStories(String, Bool)
    case compactChatList(String, Bool)
    case chatSplitLandscape(String, Bool)
    case amoledMode(String, Bool)
    case accentColorHeader(String)
    case accentColorOption(Int32, String, Int64?, Bool)
    case accentColorCustom(String, Int64?, Bool)
    case bubbleColorHeader(String)
    case bubbleColorOption(Int32, String, Int64?, Bool)
    case bubbleColorCustom(String, Int64?, Bool)
    case backgroundColorHeader(String)
    case backgroundColorOption(Int32, String, Int64?, Bool)
    case backgroundGradientOption(Int32, String, [Int64], Bool)
    case backgroundColorCustom(String, Int64?, Bool)
    case cornerRadiusHeader(String)
    case cornerRadiusOption(Int32, String, Int32?, Bool)
    case appearanceInfo(String)
    
    case developerHeader(String)
    case showUserIds(String, Bool)
    case showChatIds(String, Bool)
    case showMessageIds(String, Bool)
    case pushStatus(String, String)
    case pushToken(String, String)
    case debugMenu(String)
    case developerInfo(String)
    
    var section: ItemListSectionId {
        switch self {
        case .menuItem:
            return TelewhiteModsSection.menu.rawValue
        case .messengerHeader, .preserveDeletedMessages, .translateMessages, .translateChats, .autoTranslateEnglish, .translationTargetLanguage, .outgoingTranslateButtonEnabled, .outgoingTranslationAutoEnabled, .openRouterApiKey, .messengerInfo, .oneTimeMediaUnlimited, .downloadOneTimeMedia, .uploadVoice, .voiceChangeSettings, .uploadVideoMessage:
            return TelewhiteModsSection.messenger.rawValue
        case .vpnHeader, .vpnEnabled, .vpnSubscription, .vpnStatus, .vpnStart, .vpnInfo:
            return TelewhiteModsSection.vpn.rawValue
        case .privacyHeader, .hideOnlineStatus, .ghostMode, .ghostChatButtonEnabled, .hideTypingStatus, .hideReadReceipts, .screenshotProtectionBypass, .contentRestrictionBypass, .hidePhoneInSettings, .showProfileIds, .privacyInfo:
            return TelewhiteModsSection.privacy.rawValue
        case .stealthHeader, .ghostMessages, .ghostStories, .stealthInfo:
            return TelewhiteModsSection.stealth.rawValue
        case .channelsHeader, .channelContentRestrictionBypass, .channelsInfo:
            return TelewhiteModsSection.channels.rawValue
        case .mediaHeader, .downloadStories, .hideStories, .mediaInfo:
            return TelewhiteModsSection.media.rawValue
        case .callsHeader, .autoRecordCalls, .callRecordButton, .callsInfo:
            return TelewhiteModsSection.calls.rawValue
        case .appearanceHeader, .compactChatList, .chatSplitLandscape, .amoledMode:
            return TelewhiteModsSection.appearance.rawValue
        case .accentColorHeader, .accentColorOption, .accentColorCustom:
            return TelewhiteModsSection.accentColor.rawValue
        case .bubbleColorHeader, .bubbleColorOption, .bubbleColorCustom:
            return TelewhiteModsSection.bubbleColor.rawValue
        case .backgroundColorHeader, .backgroundColorOption, .backgroundGradientOption, .backgroundColorCustom:
            return TelewhiteModsSection.backgroundColor.rawValue
        case .cornerRadiusHeader, .cornerRadiusOption, .appearanceInfo:
            return TelewhiteModsSection.cornerRadius.rawValue
        case .developerHeader, .showUserIds, .showChatIds, .showMessageIds, .pushStatus, .pushToken, .debugMenu, .developerInfo:
            return TelewhiteModsSection.developer.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case let .menuItem(index, _, _, _, _):
            return -1000 + index
        case .messengerHeader:
            return 0
        case .preserveDeletedMessages:
            return 1
        case .oneTimeMediaUnlimited:
            return 2
        case .downloadOneTimeMedia:
            return 3
        case .uploadVoice:
            return 4
        case .voiceChangeSettings:
            return 5
        case .uploadVideoMessage:
            return 6
        case .translateMessages:
            return 7
        case .translateChats:
            return 8
        case .autoTranslateEnglish:
            return 9
        case .translationTargetLanguage:
            return 10
        case .outgoingTranslateButtonEnabled:
            return 11
        case .outgoingTranslationAutoEnabled:
            return 12
        case .openRouterApiKey:
            return 13
        case .messengerInfo:
            return 14
        case .privacyHeader:
            return 100
        case .hideOnlineStatus:
            return 101
        case .ghostMode:
            return 102
        case .ghostChatButtonEnabled:
            return 103
        case .hideTypingStatus:
            return 104
        case .hideReadReceipts:
            return 105
        case .screenshotProtectionBypass:
            return 106
        case .contentRestrictionBypass:
            return 107
        case .hidePhoneInSettings:
            return 108
        case .showProfileIds:
            return 109
        case .privacyInfo:
            return 110
        case .vpnHeader:
            return 200
        case .vpnEnabled:
            return 201
        case .vpnSubscription:
            return 202
        case .vpnStatus:
            return 203
        case .vpnStart:
            return 204
        case .vpnInfo:
            return 205
        case .stealthHeader:
            return 300
        case .ghostMessages:
            return 301
        case .ghostStories:
            return 302
        case .stealthInfo:
            return 303
        case .channelsHeader:
            return 400
        case .channelContentRestrictionBypass:
            return 401
        case .channelsInfo:
            return 402
        case .mediaHeader:
            return 500
        case .downloadStories:
            return 501
        case .mediaInfo:
            return 502
        case .callsHeader:
            return 600
        case .autoRecordCalls:
            return 601
        case .callRecordButton:
            return 602
        case .callsInfo:
            return 603
        case .appearanceHeader:
            return 700
        case .hideStories:
            return 701
        case .compactChatList:
            return 702
        case .amoledMode:
            return 703
        case .chatSplitLandscape:
            return 704
        case .accentColorHeader:
            return 710
        case let .accentColorOption(index, _, _, _):
            return 711 + index
        case .accentColorCustom:
            return 729
        case .bubbleColorHeader:
            return 730
        case let .bubbleColorOption(index, _, _, _):
            return 731 + index
        case .bubbleColorCustom:
            return 749
        case .backgroundColorHeader:
            return 750
        case let .backgroundColorOption(index, _, _, _):
            return 751 + index
        case let .backgroundGradientOption(index, _, _, _):
            return 761 + index
        case .backgroundColorCustom:
            return 769
        case .cornerRadiusHeader:
            return 770
        case let .cornerRadiusOption(index, _, _, _):
            return 771 + index
        case .appearanceInfo:
            return 790
        case .developerHeader:
            return 800
        case .showUserIds:
            return 801
        case .showChatIds:
            return 802
        case .showMessageIds:
            return 803
        case .pushStatus:
            return 804
        case .pushToken:
            return 805
        case .debugMenu:
            return 806
        case .developerInfo:
            return 807
        }
    }
    
    static func <(lhs: TelewhiteModsEntry, rhs: TelewhiteModsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    private func switchItem(presentationData: ItemListPresentationData, arguments: TelewhiteModsControllerArguments, text: String, value: Bool, apply: @escaping (inout TelewhiteModsSettings, Bool) -> Void) -> ListViewItem {
        return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, text: telewhiteEntryDescription(self, presentationData: presentationData), value: value, maximumNumberOfLines: 3, sectionId: self.section, style: .blocks, updated: { newValue in
            arguments.updateSettings { current in
                var updated = current
                apply(&updated, newValue)
                return updated
            }
        })
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! TelewhiteModsControllerArguments
        switch self {
        case let .menuItem(_, icon, title, subtitle, tab):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteMenuIcon(icon, color: presentationData.theme.list.itemPrimaryTextColor), title: title, titleFont: .bold, label: subtitle, labelStyle: .multilineDetailText, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(tab)
            })
        case let .messengerHeader(text), let .vpnHeader(text), let .privacyHeader(text), let .stealthHeader(text), let .channelsHeader(text), let .mediaHeader(text), let .callsHeader(text), let .appearanceHeader(text), let .developerHeader(text), let .accentColorHeader(text), let .bubbleColorHeader(text), let .backgroundColorHeader(text), let .cornerRadiusHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .accentColorOption(_, title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(value), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.accentColorOverride = value
                    return updated
                }
            })
        case let .bubbleColorOption(_, title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(value), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.bubbleColorOverride = value
                    return updated
                }
            })
        case let .backgroundColorOption(_, title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(value), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.chatBackgroundColorOverride = value
                    updated.chatBackgroundGradientOverride = nil
                    return updated
                }
            })
        case let .backgroundGradientOption(_, title, colors, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteGradientSwatchImage(colors), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.chatBackgroundColorOverride = nil
                    updated.chatBackgroundGradientOverride = colors
                    return updated
                }
            })
        case let .accentColorCustom(title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(selected ? value : nil), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.promptCustomColor(.accent)
            })
        case let .bubbleColorCustom(title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(selected ? value : nil), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.promptCustomColor(.bubble)
            })
        case let .backgroundColorCustom(title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteColorSwatchImage(selected ? value : nil), iconSize: CGSize(width: 22.0, height: 22.0), title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.promptCustomColor(.background)
            })
        case let .cornerRadiusOption(_, title, value, selected):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: title, style: .right, checked: selected, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.updateSettings { current in
                    var updated = current
                    updated.bubbleCornerRadiusOverride = value
                    return updated
                }
            })
        case let .preserveDeletedMessages(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.preserveDeletedMessages = value
            }
        case let .translateMessages(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, text: telewhiteEntryDescription(self, presentationData: presentationData), value: value, maximumNumberOfLines: 3, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateTranslationSettings { current in
                    var updated = current.withUpdatedShowTranslate(value)
                    if !updated.showTranslate && !updated.translateChats {
                        updated = updated.withUpdatedIgnoredLanguages(nil)
                    }
                    return updated
                }
            })
        case let .translateChats(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, text: telewhiteEntryDescription(self, presentationData: presentationData), value: value, maximumNumberOfLines: 3, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateTranslationSettings { current in
                    var updated = current.withUpdatedTranslateChats(value)
                    if !updated.showTranslate && !updated.translateChats {
                        updated = updated.withUpdatedIgnoredLanguages(nil)
                    }
                    return updated
                }
            })
        case let .autoTranslateEnglish(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, text: telewhiteEntryDescription(self, presentationData: presentationData), value: value, maximumNumberOfLines: 3, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.autoTranslateEnglish = value
                    return updated
                }
                arguments.updateTranslationSettings { current in
                    var updated = current
                    if value {
                        updated = updated.withUpdatedIgnoredLanguages(["ru"])
                    }
                    return updated
                }
            })
        case let .translationTargetLanguage(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value.uppercased(), labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
        case let .outgoingTranslateButtonEnabled(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.outgoingTranslateButtonEnabled = value
            }
        case let .outgoingTranslationAutoEnabled(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.outgoingTranslationAutoEnabled = value
            }
        case let .openRouterApiKey(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value.isEmpty ? "" : "•••" + String(value.suffix(4)), labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.promptOpenRouterKey()
            })
        case let .oneTimeMediaUnlimited(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.oneTimeMediaUnlimited = value
            }
        case let .downloadOneTimeMedia(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.downloadOneTimeMedia = value
            }
        case let .uploadVoice(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.uploadVoice = value
            }
        case let .voiceChangeSettings(text):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: nil)
        case let .uploadVideoMessage(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.uploadVideoMessage = value
            }
        case let .vpnEnabled(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { _ in
                // Toggling runs the smart connect / disconnect flow; the flag is
                // set by that flow once the proxy is actually (de)activated.
                arguments.startVpn()
            })
        case let .vpnSubscription(placeholder, text):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(), text: text, placeholder: placeholder, type: .regular(capitalization: false, autocorrection: false), returnKeyType: .done, clearType: .onFocus, maxLength: 4096, sectionId: self.section, textUpdated: { text in
                arguments.updateSettings { current in
                    var updated = current
                    updated.vpnSubscription = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    return updated
                }
            }, action: {})
        case let .vpnStatus(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
        case let .vpnStart(text):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.startVpn()
            })
        case let .debugMenu(text):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openDebug()
            })
        case let .messengerInfo(text), let .vpnInfo(text), let .privacyInfo(text), let .stealthInfo(text), let .channelsInfo(text), let .mediaInfo(text), let .callsInfo(text), let .developerInfo(text), let .appearanceInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .hideOnlineStatus(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hideOnlineStatus = value
            }
        case let .ghostMode(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.ghostMode = value
            }
        case let .ghostChatButtonEnabled(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.ghostChatButtonEnabled = value
            }
        case let .hideTypingStatus(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hideTypingStatus = value
            }
        case let .hideReadReceipts(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hideReadReceipts = value
            }
        case let .screenshotProtectionBypass(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.screenshotProtectionBypass = value
            }
        case let .contentRestrictionBypass(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.contentRestrictionBypass = value
            }
        case let .hidePhoneInSettings(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hidePhoneInSettings = value
            }
        case let .showProfileIds(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.showUserIds = value
                settings.showChatIds = value
            }
        case let .ghostMessages(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hideReadReceipts = value
            }
        case let .ghostStories(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.ghostStories = value
            }
        case let .channelContentRestrictionBypass(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.contentRestrictionBypass = value
            }
        case let .downloadStories(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.downloadStories = value
            }
        case let .autoRecordCalls(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.autoRecordCalls = value
            }
        case let .callRecordButton(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.callRecordButton = value
            }
        case let .hideStories(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.hideStories = value
            }
        case let .compactChatList(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.compactChatList = value
            }
        case let .chatSplitLandscape(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.chatSplitLandscape = value
            }
        case let .amoledMode(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.amoledMode = value
            }
        case let .showUserIds(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.showUserIds = value
            }
        case let .showChatIds(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.showChatIds = value
            }
        case let .showMessageIds(text, value):
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.showMessageIds = value
            }
        case let .pushStatus(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
        case let .pushToken(text, value):
            let fullToken = UserDefaults.standard.string(forKey: "telewhite.push.token") ?? ""
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: fullToken.isEmpty ? .none : .arrow, action: fullToken.isEmpty ? nil : {
                UIPasteboard.general.string = fullToken
            })
        }
    }
}

private struct TelewhiteModsStrings {
    let isRussian: Bool

    init(presentationData: PresentationData) {
        self.isRussian = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
    }

    func text(_ en: String, _ ru: String) -> String {
        return self.isRussian ? ru : en
    }
}

private func telewhiteCustomColorTitle(strings: TelewhiteModsStrings, value: Int64?) -> String {
    let base = strings.text("Custom Color (HEX)", "Свой цвет (HEX)")
    if let value = value {
        return base + String(format: " — #%06X", UInt32(truncatingIfNeeded: value) & 0xffffff)
    }
    return base
}

func telewhiteParseHexColor(_ input: String) -> Int64? {
    var cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
    if cleaned.hasPrefix("#") {
        cleaned = String(cleaned.dropFirst())
    }
    if cleaned.hasPrefix("0x") || cleaned.hasPrefix("0X") {
        cleaned = String(cleaned.dropFirst(2))
    }
    if cleaned.count == 3 {
        cleaned = cleaned.map { "\($0)\($0)" }.joined()
    }
    guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
        return nil
    }
    return Int64(value)
}

private func telewhiteGradientSwatchImage(_ colors: [Int64]) -> UIImage? {
    let size = CGSize(width: 22.0, height: 22.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(ovalIn: rect.insetBy(dx: 1.0, dy: 1.0))
        path.addClip()
        let cgColors = colors.map { UIColor(rgb: UInt32(truncatingIfNeeded: $0)).cgColor }
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors as CFArray, locations: nil) {
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: size.width, y: size.height), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
        path.lineWidth = 1.0
        UIColor(white: 0.5, alpha: 0.35).setStroke()
        path.stroke()
    }
}

private func telewhiteColorSwatchImage(_ value: Int64?) -> UIImage? {
    let size = CGSize(width: 22.0, height: 22.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(ovalIn: rect.insetBy(dx: 1.0, dy: 1.0))
        if let value = value {
            UIColor(rgb: UInt32(truncatingIfNeeded: value)).setFill()
            path.fill()
            path.lineWidth = 1.0
            UIColor(white: 0.5, alpha: 0.35).setStroke()
            path.stroke()
        } else {
            path.lineWidth = 1.5
            UIColor(white: 0.5, alpha: 0.35).setStroke()
            path.stroke()
            let line = UIBezierPath()
            line.move(to: CGPoint(x: 5.0, y: 17.0))
            line.addLine(to: CGPoint(x: 17.0, y: 5.0))
            line.lineWidth = 1.5
            UIColor(white: 0.5, alpha: 0.5).setStroke()
            line.stroke()
        }
    }
}

private var telewhiteMenuIconCache: [String: UIImage] = [:]

private func telewhiteMenuIcon(_ icon: TelewhiteModsMenuIcon, color: UIColor) -> UIImage? {
    let cacheKey = "\(icon.rawValue)-\(color.argb)"
    if let cached = telewhiteMenuIconCache[cacheKey] {
        return cached
    }
    
    let size = CGSize(width: 29.0, height: 29.0)
    let lineWidth: CGFloat = 1.7
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { _ in
        color.setStroke()
        color.setFill()
        
        switch icon {
        case .privacy:
            // Lock: rounded body + shackle
            let body = UIBezierPath(roundedRect: CGRect(x: 7.5, y: 13.0, width: 14.0, height: 10.5), cornerRadius: 3.0)
            body.lineWidth = lineWidth
            body.stroke()
            let shackle = UIBezierPath(arcCenter: CGPoint(x: 14.5, y: 13.0), radius: 4.5, startAngle: .pi, endAngle: 0.0, clockwise: true)
            shackle.lineWidth = lineWidth
            shackle.stroke()
            let keyhole = UIBezierPath(ovalIn: CGRect(x: 13.3, y: 16.8, width: 2.4, height: 2.4))
            keyhole.fill()
        case .ghost:
            // Ghost (TeleDark style): rounded dome, gentle scalloped bottom, two vertical oval eyes
            let ghostLineWidth: CGFloat = 2.0
            let ghost = UIBezierPath()
            ghost.move(to: CGPoint(x: 7.0, y: 22.5))
            ghost.addLine(to: CGPoint(x: 7.0, y: 13.5))
            ghost.addArc(withCenter: CGPoint(x: 14.5, y: 13.5), radius: 7.5, startAngle: .pi, endAngle: 0.0, clockwise: true)
            ghost.addLine(to: CGPoint(x: 22.0, y: 22.5))
            // Gentle scalloped bottom: three soft rounded bumps
            ghost.addCurve(to: CGPoint(x: 17.5, y: 22.5), controlPoint1: CGPoint(x: 21.0, y: 24.2), controlPoint2: CGPoint(x: 18.5, y: 24.2))
            ghost.addCurve(to: CGPoint(x: 11.5, y: 22.5), controlPoint1: CGPoint(x: 16.3, y: 21.2), controlPoint2: CGPoint(x: 12.7, y: 21.2))
            ghost.addCurve(to: CGPoint(x: 7.0, y: 22.5), controlPoint1: CGPoint(x: 10.5, y: 24.2), controlPoint2: CGPoint(x: 8.0, y: 24.2))
            ghost.lineWidth = ghostLineWidth
            ghost.lineJoinStyle = .round
            ghost.lineCapStyle = .round
            ghost.stroke()
            // Vertical oval eyes
            UIBezierPath(ovalIn: CGRect(x: 10.7, y: 11.0, width: 2.4, height: 4.2)).fill()
            UIBezierPath(ovalIn: CGRect(x: 15.9, y: 11.0, width: 2.4, height: 4.2)).fill()
        case .messages:
            // Messenger-style speech bubble: rounded bubble with a tail at the
            // bottom-left and three typing dots inside
            let bubble = UIBezierPath()
            // Rounded rectangle bubble
            bubble.move(to: CGPoint(x: 10.5, y: 6.5))
            bubble.addLine(to: CGPoint(x: 18.5, y: 6.5))
            bubble.addArc(withCenter: CGPoint(x: 18.5, y: 11.0), radius: 4.5, startAngle: -.pi / 2.0, endAngle: 0.0, clockwise: true)
            bubble.addLine(to: CGPoint(x: 23.0, y: 14.5))
            bubble.addArc(withCenter: CGPoint(x: 18.5, y: 14.5), radius: 4.5, startAngle: 0.0, endAngle: .pi / 2.0, clockwise: true)
            // Bottom edge going left, then the tail
            bubble.addLine(to: CGPoint(x: 13.0, y: 19.0))
            bubble.addLine(to: CGPoint(x: 8.5, y: 23.0))
            bubble.addLine(to: CGPoint(x: 8.5, y: 19.0))
            bubble.addArc(withCenter: CGPoint(x: 10.5, y: 14.5), radius: 4.5, startAngle: .pi / 2.0, endAngle: .pi, clockwise: true)
            bubble.addLine(to: CGPoint(x: 6.0, y: 11.0))
            bubble.addArc(withCenter: CGPoint(x: 10.5, y: 11.0), radius: 4.5, startAngle: .pi, endAngle: -.pi / 2.0, clockwise: true)
            bubble.close()
            bubble.lineWidth = lineWidth
            bubble.lineJoinStyle = .round
            bubble.stroke()
            // Three typing dots
            UIBezierPath(ovalIn: CGRect(x: 9.4, y: 11.7, width: 2.0, height: 2.0)).fill()
            UIBezierPath(ovalIn: CGRect(x: 13.5, y: 11.7, width: 2.0, height: 2.0)).fill()
            UIBezierPath(ovalIn: CGRect(x: 17.6, y: 11.7, width: 2.0, height: 2.0)).fill()
        case .groups:
            // Megaphone
            let horn = UIBezierPath()
            horn.move(to: CGPoint(x: 7.0, y: 12.5))
            horn.addLine(to: CGPoint(x: 15.0, y: 8.0))
            horn.addLine(to: CGPoint(x: 21.5, y: 5.5))
            horn.addLine(to: CGPoint(x: 21.5, y: 20.5))
            horn.addLine(to: CGPoint(x: 15.0, y: 18.0))
            horn.addLine(to: CGPoint(x: 7.0, y: 17.5))
            horn.close()
            horn.lineWidth = lineWidth
            horn.lineJoinStyle = .round
            horn.stroke()
            let handle = UIBezierPath()
            handle.move(to: CGPoint(x: 9.5, y: 17.8))
            handle.addLine(to: CGPoint(x: 11.5, y: 24.0))
            handle.addLine(to: CGPoint(x: 14.5, y: 24.0))
            handle.addLine(to: CGPoint(x: 12.8, y: 18.0))
            handle.lineWidth = lineWidth
            handle.lineJoinStyle = .round
            handle.stroke()
        case .media:
            // Circle with a wave through it
            let circle = UIBezierPath(ovalIn: CGRect(x: 6.0, y: 6.0, width: 17.0, height: 17.0))
            circle.lineWidth = lineWidth
            circle.stroke()
            let wave = UIBezierPath()
            wave.move(to: CGPoint(x: 7.0, y: 16.5))
            wave.addCurve(to: CGPoint(x: 14.5, y: 15.0), controlPoint1: CGPoint(x: 9.5, y: 12.5), controlPoint2: CGPoint(x: 12.0, y: 12.5))
            wave.addCurve(to: CGPoint(x: 22.0, y: 13.5), controlPoint1: CGPoint(x: 17.0, y: 17.5), controlPoint2: CGPoint(x: 19.5, y: 17.5))
            wave.lineWidth = lineWidth
            wave.stroke()
        case .calls:
            // Phone handset
            let handset = UIBezierPath()
            handset.move(to: CGPoint(x: 8.0, y: 7.5))
            handset.addCurve(to: CGPoint(x: 12.5, y: 12.0), controlPoint1: CGPoint(x: 11.0, y: 7.0), controlPoint2: CGPoint(x: 12.5, y: 9.0))
            handset.addCurve(to: CGPoint(x: 11.5, y: 15.5), controlPoint1: CGPoint(x: 12.5, y: 13.5), controlPoint2: CGPoint(x: 11.5, y: 14.0))
            handset.addCurve(to: CGPoint(x: 13.5, y: 18.5), controlPoint1: CGPoint(x: 11.8, y: 16.5), controlPoint2: CGPoint(x: 12.5, y: 17.5))
            handset.addCurve(to: CGPoint(x: 17.0, y: 17.5), controlPoint1: CGPoint(x: 15.0, y: 17.5), controlPoint2: CGPoint(x: 15.5, y: 16.5))
            handset.addCurve(to: CGPoint(x: 21.5, y: 21.0), controlPoint1: CGPoint(x: 20.0, y: 16.5), controlPoint2: CGPoint(x: 22.0, y: 18.0))
            handset.addCurve(to: CGPoint(x: 17.0, y: 24.0), controlPoint1: CGPoint(x: 21.0, y: 23.0), controlPoint2: CGPoint(x: 19.5, y: 24.0))
            handset.addCurve(to: CGPoint(x: 8.0, y: 16.0), controlPoint1: CGPoint(x: 13.0, y: 23.5), controlPoint2: CGPoint(x: 8.5, y: 20.0))
            handset.addCurve(to: CGPoint(x: 8.0, y: 7.5), controlPoint1: CGPoint(x: 7.5, y: 13.0), controlPoint2: CGPoint(x: 6.5, y: 9.0))
            handset.lineWidth = lineWidth
            handset.lineJoinStyle = .round
            handset.stroke()
        case .appearance:
            // Circle half-filled (contrast/appearance)
            let circle = UIBezierPath(ovalIn: CGRect(x: 6.0, y: 6.0, width: 17.0, height: 17.0))
            circle.lineWidth = lineWidth
            circle.stroke()
            let half = UIBezierPath(arcCenter: CGPoint(x: 14.5, y: 14.5), radius: 6.5, startAngle: -.pi / 2.0, endAngle: .pi / 2.0, clockwise: true)
            half.close()
            half.fill()
        case .proxy:
            // Globe: circle + vertical meridian ellipse + horizontal equator line
            let circle = UIBezierPath(ovalIn: CGRect(x: 6.0, y: 6.0, width: 17.0, height: 17.0))
            circle.lineWidth = lineWidth
            circle.stroke()
            let meridian = UIBezierPath(ovalIn: CGRect(x: 10.5, y: 6.0, width: 8.0, height: 17.0))
            meridian.lineWidth = lineWidth
            meridian.stroke()
            let equator = UIBezierPath()
            equator.move(to: CGPoint(x: 6.0, y: 14.5))
            equator.addLine(to: CGPoint(x: 23.0, y: 14.5))
            equator.lineWidth = lineWidth
            equator.stroke()
        case .developer:
            // Angle brackets </> 
            let left = UIBezierPath()
            left.move(to: CGPoint(x: 10.0, y: 9.5))
            left.addLine(to: CGPoint(x: 5.5, y: 14.5))
            left.addLine(to: CGPoint(x: 10.0, y: 19.5))
            left.lineWidth = lineWidth
            left.lineJoinStyle = .round
            left.stroke()
            let right = UIBezierPath()
            right.move(to: CGPoint(x: 19.0, y: 9.5))
            right.addLine(to: CGPoint(x: 23.5, y: 14.5))
            right.addLine(to: CGPoint(x: 19.0, y: 19.5))
            right.lineWidth = lineWidth
            right.lineJoinStyle = .round
            right.stroke()
            let slash = UIBezierPath()
            slash.move(to: CGPoint(x: 16.3, y: 8.0))
            slash.addLine(to: CGPoint(x: 12.7, y: 21.0))
            slash.lineWidth = lineWidth
            slash.stroke()
        }
    }
    telewhiteMenuIconCache[cacheKey] = image
    return image
}

private func telewhiteTabTitle(_ tab: TelewhiteModsTab, strings: TelewhiteModsStrings) -> String {
    switch tab {
    case .messenger:
        return strings.text("Messages", "\u{0421}\u{043e}\u{043e}\u{0431}\u{0449}\u{0435}\u{043d}\u{0438}\u{044f}")
    case .privacy:
        return strings.text("Privacy", "\u{041a}\u{043e}\u{043d}\u{0444}\u{0438}\u{0434}\u{0435}\u{043d}\u{0446}\u{0438}\u{0430}\u{043b}\u{044c}\u{043d}\u{043e}\u{0441}\u{0442}\u{044c}")
    case .stealth:
        return strings.text("Ghost Mode", "\u{0420}\u{0435}\u{0436}\u{0438}\u{043c} \u{043d}\u{0435}\u{0432}\u{0438}\u{0434}\u{0438}\u{043c}\u{043a}\u{0438}")
    case .channels:
        return strings.text("Channels and Groups", "\u{041a}\u{0430}\u{043d}\u{0430}\u{043b}\u{044b} \u{0438} \u{0433}\u{0440}\u{0443}\u{043f}\u{043f}\u{044b}")
    case .media:
        return strings.text("Media and Stories", "\u{041c}\u{0435}\u{0434}\u{0438}\u{0430} \u{0438} \u{0438}\u{0441}\u{0442}\u{043e}\u{0440}\u{0438}\u{0438}")
    case .calls:
        return strings.text("Calls", "\u{0417}\u{0432}\u{043e}\u{043d}\u{043a}\u{0438}")
    case .proxy:
        return strings.text("Smart Proxy", "Умный прокси")
    case .appearance:
        return strings.text("Look", "\u{0412}\u{043d}\u{0435}\u{0448}\u{043d}\u{0438}\u{0439} \u{0432}\u{0438}\u{0434}")
    case .developer:
        return strings.text("Developer", "\u{0420}\u{0430}\u{0437}\u{0440}\u{0430}\u{0431}\u{043e}\u{0442}\u{0447}\u{0438}\u{043a}")
    }
}

private func telewhiteMenuEntries(strings: TelewhiteModsStrings) -> [TelewhiteModsEntry] {
    return [
        .menuItem(0, .privacy, telewhiteTabTitle(.privacy, strings: strings), strings.text("Online, screenshots, restrictions, phone and profile ID.", "\u{041e}\u{043d}\u{043b}\u{0430}\u{0439}\u{043d}, \u{0441}\u{043a}\u{0440}\u{0438}\u{043d}\u{0448}\u{043e}\u{0442}\u{044b}, \u{043e}\u{0433}\u{0440}\u{0430}\u{043d}\u{0438}\u{0447}\u{0435}\u{043d}\u{0438}\u{044f}, \u{043d}\u{043e}\u{043c}\u{0435}\u{0440} \u{0438} ID."), .privacy),
        .menuItem(1, .ghost, telewhiteTabTitle(.stealth, strings: strings), strings.text("Messages, stories, per-chat ghost and typing status.", "\u{0421}\u{043e}\u{043e}\u{0431}\u{0449}\u{0435}\u{043d}\u{0438}\u{044f}, \u{0438}\u{0441}\u{0442}\u{043e}\u{0440}\u{0438}\u{0438}, \u{043f}\u{0440}\u{0438}\u{0437}\u{0440}\u{0430}\u{043a} \u{0434}\u{043b}\u{044f} \u{0447}\u{0430}\u{0442}\u{0430} \u{0438} \u{043d}\u{0430}\u{0431}\u{043e}\u{0440}."), .stealth),
        .menuItem(2, .messages, telewhiteTabTitle(.messenger, strings: strings), strings.text("Deleted messages, one-time media, uploads and translation.", "\u{0423}\u{0434}\u{0430}\u{043b}\u{0451}\u{043d}\u{043d}\u{044b}\u{0435} \u{0441}\u{043e}\u{043e}\u{0431}\u{0449}\u{0435}\u{043d}\u{0438}\u{044f}, \u{043e}\u{0434}\u{043d}\u{043e}\u{0440}\u{0430}\u{0437}\u{043e}\u{0432}\u{044b}\u{0435} \u{043c}\u{0435}\u{0434}\u{0438}\u{0430}, \u{0437}\u{0430}\u{0433}\u{0440}\u{0443}\u{0437}\u{043a}\u{0438} \u{0438} \u{043f}\u{0435}\u{0440}\u{0435}\u{0432}\u{043e}\u{0434}."), .messenger),
        .menuItem(3, .groups, telewhiteTabTitle(.channels, strings: strings), strings.text("Channel and group content controls.", "\u{0424}\u{0443}\u{043d}\u{043a}\u{0446}\u{0438}\u{0438} \u{0434}\u{043b}\u{044f} \u{043a}\u{0430}\u{043d}\u{0430}\u{043b}\u{043e}\u{0432} \u{0438} \u{0433}\u{0440}\u{0443}\u{043f}\u{043f}."), .channels),
        .menuItem(4, .media, telewhiteTabTitle(.media, strings: strings), strings.text("Stories, downloads and media actions.", "\u{0418}\u{0441}\u{0442}\u{043e}\u{0440}\u{0438}\u{0438}, \u{0441}\u{043a}\u{0430}\u{0447}\u{0438}\u{0432}\u{0430}\u{043d}\u{0438}\u{0435} \u{0438} \u{043c}\u{0435}\u{0434}\u{0438}\u{0430}-\u{0434}\u{0435}\u{0439}\u{0441}\u{0442}\u{0432}\u{0438}\u{044f}."), .media),
        .menuItem(5, .proxy, telewhiteTabTitle(.proxy, strings: strings), strings.text("Auto-picks the fastest working proxy server.", "Сам выбирает самый быстрый рабочий прокси-сервер."), .proxy),
        .menuItem(6, .appearance, telewhiteTabTitle(.appearance, strings: strings), strings.text("Colors, chat list and split view.", "Цвета, список чатов и сплит-режим."), .appearance),
        .menuItem(7, .developer, telewhiteTabTitle(.developer, strings: strings), strings.text("IDs and technical tools.", "ID и технические инструменты."), .developer)
    ]
}

private func telewhiteEntryDescription(_ entry: TelewhiteModsEntry, presentationData: ItemListPresentationData) -> String? {
    let isRussian = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
    func text(_ en: String, _ ru: String) -> String {
        return isRussian ? ru : en
    }
    switch entry {
    case .preserveDeletedMessages:
        return text("Messages deleted by others stay visible on this device.", "Сообщения, удалённые собеседником, остаются видны на этом устройстве.")
    case .translateMessages:
        return text("Adds a Translate button to the message menu.", "Добавляет кнопку «Перевести» в меню сообщения.")
    case .translateChats:
        return text("Shows a translate bar at the top of foreign-language chats.", "Показывает панель перевода сверху в чатах на иностранном языке.")
    case .autoTranslateEnglish:
        return text("Automatically translates your messages before sending.", "Автоматически переводит ваши сообщения перед отправкой.")
    case .outgoingTranslateButtonEnabled:
        return text("Shows the translator button in private chats; tap toggles per-chat outgoing translation, long press picks the language.", "Показывает кнопку перевод��ика в личных чатах: тап включает перевод исходящих для чата, долгий тап выбирает язык.")
    case .outgoingTranslationAutoEnabled:
        return text("Automatically translates outgoing messages when your language differs from the chat partner's language (detected from their recent messages). No need to toggle translation manually per chat. Messages already in the target language are never touched.", "Автоматически переводит исходящие, когда ваш язык отличается от языка собеседника (определяется по его последним сообщениям). Не нужно вручную включать перевод в каждом чате. Сообщения уже на целевом языке не трогаются.")
    case .openRouterApiKey:
        return text("Free key from openrouter.ai for high-quality AI translation of outgoing messages. Without it the standard Telegram translator is used.", "Бесплатный ключ с openrouter.ai для качественного AI-перевода исходящих сообщений. Без него используется стандартный переводчик Telegram.")
    case .uploadVideoMessage:
        return text("Videos from the gallery are sent as round video messages.", "Видео из галереи отправляются как круглые видеосообщения.")
    case .oneTimeMediaUnlimited:
        return text("View-once photos and videos can be opened multiple times.", "Одноразовые фото и видео можно открывать сколько угодно раз.")
    case .downloadOneTimeMedia:
        return text("Lets you save view-once photos and videos.", "Позволяет сохранять одноразовые фото и видео.")
    case .vpnEnabled:
        return text("Routes Telegram traffic through a proxy server. Other apps are not affected.", "Пропускает трафик Telegram через прокси-сервер. Другие приложения не затрагиваются.")
    case .hideOnlineStatus:
        return text("Others won't see you online.", "Другие не будут видеть вас в сети.")
    case .ghostMode:
        return text("Full invisibility: hides reads, typing and online status.", "Полная невидимость: скрывает прочтение, набор текста и онлайн.")
    case .ghostChatButtonEnabled:
        return text("Adds a ghost button inside private chats and groups to go invisible in that chat only.", "Добавляет кнопку призрака в личных чатах и группах — невидимость только в этом чате.")
    case .hideTypingStatus:
        return text("Others won't see when you're typing or recording.", "Другие не увидят, что вы печатаете или записываете.")
    case .hideReadReceipts, .ghostMessages:
        return text("Works everywhere in Telegram: private chats, groups and channels. Read messages and play voice/video notes without anyone seeing read checkmarks.", "Действует на всё в Telegram: личные чаты, группы и каналы. Читайте сообщения и слушайте голосовые/видео — никто не увидит галочки прочтения.")
    case .ghostStories:
        return text("Watch stories without the author knowing.", "Смотрите истории так, что автор об этом не узнает.")
    case .screenshotProtectionBypass:
        return text("Removes screenshot blocks in protected chats.", "Убирает блокировку скриншотов в защищённых чатах.")
    case .contentRestrictionBypass, .channelContentRestrictionBypass:
        return text("Lets you forward, copy and save from protected chats and channels.", "Позволяет пересылать, копировать и сохранять из защищённых чатов и каналов.")
    case .hidePhoneInSettings:
        return text("Hides your phone number in Settings and your profile.", "Скрывает ваш номер телефона в настройках и профиле.")
    case .showProfileIds, .showUserIds, .showChatIds, .showMessageIds:
        return text("Shows user and chat IDs in profiles. Tap an ID to copy it.", "Показывает ID пользователей и чатов в профилях. Нажмите на ID, чтобы скопировать.")
    case .downloadStories:
        return text("Adds a save button to stories.", "Добавляет кнопку сохранения в истории.")
    case .hideStories:
        return text("Hides the stories row above the chat list.", "Скрывает ленту историй над списком чатов.")
    case .compactChatList:
        return text("Makes chat list rows smaller so more chats fit on screen.", "Уменьшает строки чатов — на экране помещается больше.")
    case .chatSplitLandscape:
        return text("In landscape, shows the chat list next to the open chat, like on a computer.", "В альбомной ориентации показывает список чатов рядом с открытым чатом — как на компьютере.")
    case .amoledMode:
        return text("Pure black theme for OLED screens.", "Чисто-чёрная тема для OLED-экранов.")
    default:
        return nil
    }
}

private func telewhiteModsEntries(tab: TelewhiteModsTab, settings: TelewhiteModsSettings, translationSettings: TranslationSettings, strings: TelewhiteModsStrings) -> [TelewhiteModsEntry] {
    var entries: [TelewhiteModsEntry] = []

    switch tab {
    case .messenger:
        entries.append(.messengerHeader(telewhiteTabTitle(.messenger, strings: strings)))
        entries.append(.preserveDeletedMessages(strings.text("Keep Deleted Messages", "Сохранять удалённые сообщения"), settings.preserveDeletedMessages))
        entries.append(.oneTimeMediaUnlimited(strings.text("Unlimited One-Time View", "Одноразовый просмотр без ограничений"), settings.oneTimeMediaUnlimited))
        entries.append(.downloadOneTimeMedia(strings.text("Download One-Time Media", "Скачать одноразовые медиа"), settings.downloadOneTimeMedia))
        entries.append(.uploadVideoMessage(strings.text("Upload Video Message", "Загрузить видеосообщение"), settings.uploadVideoMessage))
        entries.append(.translateMessages(strings.text("Show Translate Button", "Показывать кнопку перевода"), translationSettings.showTranslate))
        entries.append(.translateChats(strings.text("Translate Entire Chats", "Перевод чатов"), translationSettings.translateChats))
        entries.append(.autoTranslateEnglish(strings.text("Translate Before Sending", "Перевод перед отправкой"), settings.autoTranslateEnglish))
        entries.append(.translationTargetLanguage(strings.text("Translation Language", "Язык перевода"), settings.translationTargetLanguage))
        entries.append(.outgoingTranslateButtonEnabled(strings.text("Per-Chat Translator Button", "Кнопка переводчика в чатах"), settings.outgoingTranslateButtonEnabled))
        entries.append(.outgoingTranslationAutoEnabled(strings.text("Smart Auto-Translate", "Умный автоперевод"), settings.outgoingTranslationAutoEnabled))
        entries.append(.openRouterApiKey(strings.text("OpenRouter API Key", "Ключ OpenRouter API"), settings.openRouterApiKey))
        entries.append(.messengerInfo(strings.text("Message features are split here: deleted messages, one-time media, uploads and translation.", "Здесь собраны функции сообщений: удалённые сообщения, одноразовые медиа, загрузка и перевод.")))

    case .privacy:
        entries.append(.privacyHeader(telewhiteTabTitle(.privacy, strings: strings)))
        entries.append(.hideOnlineStatus(strings.text("Hide Online Status", "Скрыть статус онлайн"), settings.hideOnlineStatus))
        entries.append(.screenshotProtectionBypass(strings.text("Screenshot Protection Bypass", "Обход защиты скриншотов"), settings.screenshotProtectionBypass))
        entries.append(.contentRestrictionBypass(strings.text("Content Restriction Bypass", "Обход ограничений контента"), settings.contentRestrictionBypass))
        entries.append(.hidePhoneInSettings(strings.text("Hide Phone in Settings", "Скрыть номер в настройках"), settings.hidePhoneInSettings))
        entries.append(.showProfileIds(strings.text("Show Profile ID", "Показать ID профиля"), settings.showUserIds && settings.showChatIds))
        entries.append(.ghostChatButtonEnabled(strings.text("Per-Chat Ghost Button", "Кнопка невидимки в чатах"), settings.ghostChatButtonEnabled))
        entries.append(.privacyInfo(strings.text("Online, screenshot and content controls live here.", "Здесь находятся настройки онлайна, скриншотов и ограничений контента.")))

    case .stealth:
        entries.append(.stealthHeader(telewhiteTabTitle(.stealth, strings: strings)))
        entries.append(.ghostMessages(strings.text("Ghost Mode (Messages)", "Режим невидимки (сообщения)"), settings.hideReadReceipts))
        entries.append(.ghostStories(strings.text("Ghost Mode (Stories)", "Режим невидимки (истории)"), settings.ghostStories))
        entries.append(.hideTypingStatus(strings.text("Hide Typing Status", "Скрыть набор текста"), settings.hideTypingStatus))
        entries.append(.stealthInfo(strings.text("The chat ghost button toggles stealth for one selected private chat.", "Кнопка призрака в чате включает невидимку только для выбранного личного чата.")))

    case .channels:
        entries.append(.channelsHeader(telewhiteTabTitle(.channels, strings: strings)))
        entries.append(.channelContentRestrictionBypass(strings.text("Content Restriction Bypass", "Обход ограничений контента"), settings.contentRestrictionBypass))
        entries.append(.channelsInfo(strings.text("Channel and group restrictions are controlled here.", "Здесь управляются ограничения каналов и групп.")))

    case .media:
        entries.append(.mediaHeader(telewhiteTabTitle(.media, strings: strings)))
        entries.append(.downloadStories(strings.text("Download Stories", "Скачать истории"), settings.downloadStories))
        entries.append(.hideStories(strings.text("Hide Stories Row", "Скрыть блок историй"), settings.hideStories))
        entries.append(.mediaInfo(strings.text("Story controls are separated from message controls.", "Настройки историй вынесены отдельно от сообщений.")))

    case .calls:
        entries.append(.callsHeader(telewhiteTabTitle(.calls, strings: strings)))
        entries.append(.callsInfo(strings.text("Recordings are saved to your Saved Messages. When the record button is on, it appears on the call screen so you can start and stop recording manually.", "Записи сохраняются в «Избранное». Если кнопка записи включена, она появляется на экране звонка — можно начинать и останавливать запись вручную.")))

    case .proxy:
        let proxyStatus: String
        if !TelewhiteVpnEngine.lastStatus.isEmpty {
            proxyStatus = TelewhiteVpnEngine.lastStatus
        } else if settings.vpnEnabled {
            proxyStatus = strings.text("Connected", "Подключён")
        } else {
            proxyStatus = strings.text("Off", "Выключен")
        }
        entries.append(.vpnHeader(strings.text("Smart Proxy — Telegram only", "Умный прокси — только Telegram")))
        entries.append(.vpnEnabled(strings.text("Smart Proxy", "Умный прокси"), settings.vpnEnabled))
        entries.append(.vpnSubscription(strings.text("Server list URL (optional)", "Ссылка на список серверов (опц.)"), settings.vpnSubscription))
        entries.append(.vpnStatus(strings.text("Status", "Статус"), proxyStatus))
        entries.append(.vpnStart(settings.vpnEnabled ? strings.text("Disconnect", "Отключить") : strings.text("Connect", "Подключить")))
        entries.append(.vpnInfo(strings.text("Telewhite pings every server (your list plus built-in ones) and automatically connects to the fastest working proxy. Only Telegram traffic goes through it. Formats: tg://proxy or t.me/proxy links, or host:port:secret, one per line.", "Telewhite пингует все серверы (ваш список плюс встроенные) и автоматически подключается к самому быстрому рабочему прокси. Через него идёт только трафик Telegram. Форматы: ссылки tg://proxy или t.me/proxy, либо host:port:secret, по одному в строке.")))

    case .appearance:
        entries.append(.appearanceHeader(telewhiteTabTitle(.appearance, strings: strings)))
        entries.append(.compactChatList(strings.text("Compact Chat List", "Компактный список чатов"), settings.compactChatList))
        entries.append(.chatSplitLandscape(strings.text("Split View in Landscape", "Сплит чатов (альбомная)"), settings.chatSplitLandscape))
        entries.append(.amoledMode(strings.text("AMOLED Mode", "AMOLED режим"), settings.amoledMode))

        let accentPresets: [(String, Int64?)] = [
            (strings.text("Default", "По умолчанию"), nil),
            (strings.text("Blue", "Синий"), 0x007aff),
            (strings.text("Cyan", "Голубой"), 0x5ac8fa),
            (strings.text("Teal", "Бирюзовый"), 0x30b0c7),
            (strings.text("Mint", "Мятный"), 0x00c7be),
            (strings.text("Green", "Зелёный"), 0x34c759),
            (strings.text("Yellow", "Жёлтый"), 0xffcc00),
            (strings.text("Orange", "Оранжевый"), 0xff9500),
            (strings.text("Red", "Красный"), 0xff3b30),
            (strings.text("Pink", "Розовый"), 0xff2d55),
            (strings.text("Coral", "Коралловый"), 0xff6b6b),
            (strings.text("Indigo", "Индиго"), 0x5856d6),
            (strings.text("Brown", "Коричневый"), 0xa2845e)
        ]
        entries.append(.accentColorHeader(strings.text("Accent Color", "Акцентный цвет")))
        for (index, preset) in accentPresets.enumerated() {
            entries.append(.accentColorOption(Int32(index), preset.0, preset.1, settings.accentColorOverride == preset.1))
        }
        let accentIsCustom = settings.accentColorOverride != nil && !accentPresets.contains(where: { $0.1 == settings.accentColorOverride })
        entries.append(.accentColorCustom(telewhiteCustomColorTitle(strings: strings, value: accentIsCustom ? settings.accentColorOverride : nil), settings.accentColorOverride, accentIsCustom))

        let bubblePresets: [(String, Int64?)] = [
            (strings.text("Default", "По умолчанию"), nil),
            (strings.text("Blue", "Синий"), 0x007aff),
            (strings.text("Teal", "Бирюзовый"), 0x30b0c7),
            (strings.text("Green", "Зелёный"), 0x34c759),
            (strings.text("Yellow", "Жёлтый"), 0xffcc00),
            (strings.text("Orange", "Оранжевый"), 0xff9500),
            (strings.text("Red", "Красный"), 0xff3b30),
            (strings.text("Pink", "Розовый"), 0xff2d55),
            (strings.text("Indigo", "Индиго"), 0x5856d6),
            (strings.text("Graphite", "Графит"), 0x3a3a3c),
            (strings.text("Dark Green", "Тёмно-зелёный"), 0x1f3d2b)
        ]
        entries.append(.bubbleColorHeader(strings.text("Outgoing Bubble Color", "Цвет исходящих сообщений")))
        for (index, preset) in bubblePresets.enumerated() {
            entries.append(.bubbleColorOption(Int32(index), preset.0, preset.1, settings.bubbleColorOverride == preset.1))
        }
        let bubbleIsCustom = settings.bubbleColorOverride != nil && !bubblePresets.contains(where: { $0.1 == settings.bubbleColorOverride })
        entries.append(.bubbleColorCustom(telewhiteCustomColorTitle(strings: strings, value: bubbleIsCustom ? settings.bubbleColorOverride : nil), settings.bubbleColorOverride, bubbleIsCustom))

        let backgroundPresets: [(String, Int64?)] = [
            (strings.text("Default", "По умолчанию"), nil),
            (strings.text("Black", "Чёрный"), 0x000000),
            (strings.text("Dark Blue", "Тёмно-синий"), 0x18222d),
            (strings.text("Graphite", "Графит"), 0x1c1c1e),
            (strings.text("Deep Green", "Тёмно-зелёный"), 0x0e1f16),
            (strings.text("Coffee", "Кофейный"), 0x241a12),
            (strings.text("Plum", "Сливовый"), 0x241726),
            (strings.text("Light", "Светлый"), 0xf2f2f7),
            (strings.text("Cream", "Кремовый"), 0xf7f2e7)
        ]
        entries.append(.backgroundColorHeader(strings.text("Chat Background", "Фон чата")))
        for (index, preset) in backgroundPresets.enumerated() {
            let selected = settings.chatBackgroundGradientOverride == nil && settings.chatBackgroundColorOverride == preset.1
            entries.append(.backgroundColorOption(Int32(index), preset.0, preset.1, selected))
        }

        let gradientPresets: [(String, [Int64])] = [
            (strings.text("Midnight", "Полночь"), [0x0f1621, 0x1c2b3a]),
            (strings.text("Northern Lights", "Северное сияние"), [0x0b1e2d, 0x14453d]),
            (strings.text("Sunset", "Закат"), [0x2d1b2f, 0x6b2d3c]),
            (strings.text("Ocean", "Океан"), [0x0d2137, 0x1b4965]),
            (strings.text("Morning", "Утро"), [0xdfe9f3, 0xf6f8fb]),
            (strings.text("Peach", "Персик"), [0xf9e0c7, 0xf6cfcf])
        ]
        for (index, preset) in gradientPresets.enumerated() {
            entries.append(.backgroundGradientOption(Int32(index), preset.0, preset.1, settings.chatBackgroundGradientOverride == preset.1))
        }
        let backgroundIsCustom = settings.chatBackgroundGradientOverride == nil && settings.chatBackgroundColorOverride != nil && !backgroundPresets.contains(where: { $0.1 == settings.chatBackgroundColorOverride })
        entries.append(.backgroundColorCustom(telewhiteCustomColorTitle(strings: strings, value: backgroundIsCustom ? settings.chatBackgroundColorOverride : nil), settings.chatBackgroundColorOverride, backgroundIsCustom))

        let radiusPresets: [(String, Int32?)] = [
            (strings.text("Default", "По умолчанию"), nil),
            (strings.text("Small", "Маленькое"), 8),
            (strings.text("Medium", "Среднее"), 12),
            (strings.text("Large", "Большое"), 17)
        ]
        entries.append(.cornerRadiusHeader(strings.text("Bubble Corner Radius", "Скругление сообщений")))
        for (index, preset) in radiusPresets.enumerated() {
            entries.append(.cornerRadiusOption(Int32(index), preset.0, preset.1, settings.bubbleCornerRadiusOverride == preset.1))
        }

        entries.append(.appearanceInfo(strings.text("Color and radius overrides apply on top of the selected Telegram theme and update instantly.", "Настройки цвета и скругления применяются поверх выбранной темы Telegram и обновляются мгновенно.")))

    case .developer:
        entries.append(.developerHeader(telewhiteTabTitle(.developer, strings: strings)))
        entries.append(.showUserIds(strings.text("Show User IDs", "Показывать ID пользователей"), settings.showUserIds))
        entries.append(.showChatIds(strings.text("Show Chat IDs", "Показывать ID чатов"), settings.showChatIds))
        entries.append(.showMessageIds(strings.text("Show Message IDs", "Показывать ID сообщений"), settings.showMessageIds))

        let defaults = UserDefaults.standard
        let pushStatus = defaults.string(forKey: "telewhite.push.status") ?? strings.text("Not requested yet", "Ещё не запрошено")
        entries.append(.pushStatus(strings.text("Push status", "Статус пушей"), pushStatus))
        let pushToken = defaults.string(forKey: "telewhite.push.token") ?? ""
        let shortToken: String
        if pushToken.isEmpty {
            shortToken = strings.text("None", "Нет")
        } else if pushToken.count > 16 {
            shortToken = "\(pushToken.prefix(8))…\(pushToken.suffix(8))"
        } else {
            shortToken = pushToken
        }
        entries.append(.pushToken(strings.text("APNs token", "APNs токен"), pushToken.isEmpty ? shortToken : "\(shortToken) — \(strings.text("tap to copy", "нажмите чтобы скопировать"))"))
        entries.append(.debugMenu(strings.text("Debug Menu", "Меню отладки")))
        entries.append(.developerInfo(strings.text("If push status is not \"Registered\", Apple did not issue a token for this signing profile — messages will not push. IDs are shown in profile/context surfaces when enabled.", "Если статус пушей не \"Registered\", Apple не выдал токен для этого профиля подписи — пуши работать не будут. ID отображаются в профилях и контекстных меню.")))
    }

    return entries
}

public func telewhiteModsController(context: AccountContext) -> ViewController {
    let initialSettings = TelewhiteModsSettings.current
    let stateValue = Atomic(value: initialSettings)
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)

    let updateSettings: ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void = { f in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save()
            return updated
        }
        let shouldHidePresence = updated.hideOnlineStatus || !updated.ghostPeerIds.isEmpty
        context.account.shouldKeepOnlinePresence.set(.single(!shouldHidePresence))
        statePromise.set(updated)
    }

    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = TelewhiteModsControllerArguments(updateSettings: updateSettings, updateTranslationSettings: { _ in
    }, startVpn: {
    }, openTab: { tab in
        pushControllerImpl?(telewhiteModsSectionController(context: context, tab: tab, statePromise: statePromise, stateValue: stateValue, updateSettings: updateSettings))
    })

    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let title = strings.text("Telewhite Settings", "\u{041d}\u{0430}\u{0441}\u{0442}\u{0440}\u{043e}\u{0439}\u{043a}\u{0438} Telewhite")
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: telewhiteMenuEntries(strings: strings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments as Any))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}

private func telewhiteModsSectionController(context: AccountContext, tab: TelewhiteModsTab, statePromise: ValuePromise<TelewhiteModsSettings>, stateValue: Atomic<TelewhiteModsSettings>, updateSettings: @escaping ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void) -> ViewController {
    var presentControllerImpl: ((ViewController) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = TelewhiteModsControllerArguments(updateSettings: updateSettings, updateTranslationSettings: { f in
        let _ = updateTranslationSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }, startVpn: {
        telewhiteRunVpnConnect(context: context, stateValue: stateValue, updateSettings: updateSettings, present: { c in
            presentControllerImpl?(c)
        })
    }, promptCustomColor: { target in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let settings = stateValue.with { $0 }
        let currentValue: Int64?
        switch target {
        case .accent:
            currentValue = settings.accentColorOverride
        case .bubble:
            currentValue = settings.bubbleColorOverride
        case .background:
            currentValue = settings.chatBackgroundColorOverride
        }
        let initialText = currentValue.flatMap { String(format: "#%06X", UInt32(truncatingIfNeeded: $0) & 0xffffff) } ?? ""
        let prompt = promptController(
            context: context,
            text: strings.text("Custom Color", "Свой цвет"),
            subtitle: strings.text("Enter a HEX code, e.g. #1E90FF", "Введите HEX-код, например #1E90FF"),
            value: initialText,
            placeholder: "#RRGGBB",
            characterLimit: 9,
            apply: { value in
                guard let value = value, let parsed = telewhiteParseHexColor(value) else {
                    return
                }
                updateSettings { current in
                    var updated = current
                    switch target {
                    case .accent:
                        updated.accentColorOverride = parsed
                    case .bubble:
                        updated.bubbleColorOverride = parsed
                    case .background:
                        updated.chatBackgroundColorOverride = parsed
                        updated.chatBackgroundGradientOverride = nil
                    }
                    return updated
                }
            }
        )
        presentControllerImpl?(prompt)
    }, openDebug: {
        if let debugController = context.sharedContext.makeDebugSettingsController(context: context) {
            pushControllerImpl?(debugController)
        }
    }, promptOpenRouterKey: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let settings = stateValue.with { $0 }
        let prompt = promptController(
            context: context,
            text: strings.text("OpenRouter API Key", "Ключ OpenRouter API"),
            subtitle: strings.text("Paste your key from openrouter.ai (starts with sk-or-). Leave empty to use the standard translator.", "Вставьте ключ с openrouter.ai (начинается с sk-or-). Оставьте пустым для стандартного переводчика."),
            value: settings.openRouterApiKey,
            placeholder: "sk-or-v1-...",
            characterLimit: 256,
            apply: { value in
                guard let value = value else {
                    return
                }
                updateSettings { current in
                    var updated = current
                    updated.openRouterApiKey = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    return updated
                }
            }
        )
        presentControllerImpl?(prompt)
    })

    let translationSettings = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.translationSettings])
    |> map { sharedData -> TranslationSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.translationSettings]?.get(TranslationSettings.self) ?? TranslationSettings.defaultSettings
    }

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get(), translationSettings)
    |> deliverOnMainQueue
    |> map { presentationData, settings, translationSettings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(telewhiteTabTitle(tab, strings: strings)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: telewhiteModsEntries(tab: tab, settings: settings, translationSettings: translationSettings, strings: strings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments as Any))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    return controller
}

public func telewhiteVpnController(context: AccountContext) -> ViewController {
    // The old standalone VPN screen is gone; open the Smart Proxy tab instead.
    let initialSettings = TelewhiteModsSettings.current
    let stateValue = Atomic(value: initialSettings)
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)

    let updateSettings: ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void = { f in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save()
            return updated
        }
        statePromise.set(updated)
    }

    return telewhiteModsSectionController(context: context, tab: .proxy, statePromise: statePromise, stateValue: stateValue, updateSettings: updateSettings)
}
