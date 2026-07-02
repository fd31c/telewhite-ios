import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import AlertUI
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
            callRecordButton: defaults.object(forKey: Key.callRecordButton) as? Bool ?? true
        )
    }

    public func isGhostEnabled(for peerId: EnginePeer.Id?) -> Bool {
        if self.ghostMode {
            return true
        }
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

private final class TelewhiteModsControllerArguments {
    let updateSettings: ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void
    let updateTranslationSettings: (@escaping (TranslationSettings) -> TranslationSettings) -> Void
    let startVpn: () -> Void
    
    init(
        updateSettings: @escaping ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void,
        updateTranslationSettings: @escaping (@escaping (TranslationSettings) -> TranslationSettings) -> Void,
        startVpn: @escaping () -> Void
    ) {
        self.updateSettings = updateSettings
        self.updateTranslationSettings = updateTranslationSettings
        self.startVpn = startVpn
    }
}

private enum TelewhiteModsSection: Int32 {
    case messenger
    case privacy
    case stealth
    case channels
    case media
    case calls
    case vpn
    case appearance
    case developer
}

private enum TelewhiteModsTab: Int32, Equatable {
    case messenger
    case privacy
    case stealth
    case channels
    case media
    case calls
    case appearance
    case developer
}

private enum TelewhiteModsEntry: ItemListNodeEntry, Equatable {
    case messengerHeader(String)
    case preserveDeletedMessages(String, Bool)
    case translateMessages(String, Bool)
    case translateChats(String, Bool)
    case autoTranslateEnglish(String, Bool)
    case translationTargetLanguage(String, String)
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
    case amoledMode(String, Bool)
    
    case developerHeader(String)
    case showUserIds(String, Bool)
    case showChatIds(String, Bool)
    case showMessageIds(String, Bool)
    case developerInfo(String)
    
    var section: ItemListSectionId {
        switch self {
        case .messengerHeader, .preserveDeletedMessages, .translateMessages, .translateChats, .autoTranslateEnglish, .translationTargetLanguage, .messengerInfo, .oneTimeMediaUnlimited, .downloadOneTimeMedia, .uploadVoice, .voiceChangeSettings, .uploadVideoMessage:
            return TelewhiteModsSection.messenger.rawValue
        case .vpnHeader, .vpnEnabled, .vpnSubscription, .vpnStatus, .vpnStart, .vpnInfo:
            return TelewhiteModsSection.vpn.rawValue
        case .privacyHeader, .hideOnlineStatus, .ghostMode, .ghostChatButtonEnabled, .hideTypingStatus, .hideReadReceipts, .screenshotProtectionBypass, .contentRestrictionBypass, .hidePhoneInSettings, .showProfileIds, .privacyInfo:
            return TelewhiteModsSection.privacy.rawValue
        case .stealthHeader, .ghostMessages, .ghostStories, .stealthInfo:
            return TelewhiteModsSection.stealth.rawValue
        case .channelsHeader, .channelContentRestrictionBypass, .channelsInfo:
            return TelewhiteModsSection.channels.rawValue
        case .mediaHeader, .downloadStories, .mediaInfo:
            return TelewhiteModsSection.media.rawValue
        case .callsHeader, .autoRecordCalls, .callRecordButton, .callsInfo:
            return TelewhiteModsSection.calls.rawValue
        case .appearanceHeader, .hideStories, .compactChatList, .amoledMode:
            return TelewhiteModsSection.appearance.rawValue
        case .developerHeader, .showUserIds, .showChatIds, .showMessageIds, .developerInfo:
            return TelewhiteModsSection.developer.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
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
        case .messengerInfo:
            return 11
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
        case .developerHeader:
            return 800
        case .showUserIds:
            return 801
        case .showChatIds:
            return 802
        case .showMessageIds:
            return 803
        case .developerInfo:
            return 804
        }
    }
    
    static func <(lhs: TelewhiteModsEntry, rhs: TelewhiteModsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! TelewhiteModsControllerArguments
        switch self {
        case let .messengerHeader(text), let .vpnHeader(text), let .privacyHeader(text), let .stealthHeader(text), let .channelsHeader(text), let .mediaHeader(text), let .callsHeader(text), let .appearanceHeader(text), let .developerHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .preserveDeletedMessages(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.preserveDeletedMessages = value
                    return updated
                }
            })
        case let .translateMessages(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateTranslationSettings { current in
                    var updated = current.withUpdatedShowTranslate(value)
                    if !updated.showTranslate && !updated.translateChats {
                        updated = updated.withUpdatedIgnoredLanguages(nil)
                    }
                    return updated
                }
            })
        case let .translateChats(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateTranslationSettings { current in
                    var updated = current.withUpdatedTranslateChats(value)
                    if !updated.showTranslate && !updated.translateChats {
                        updated = updated.withUpdatedIgnoredLanguages(nil)
                    }
                    return updated
                }
            })
        case let .autoTranslateEnglish(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
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
        case let .oneTimeMediaUnlimited(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.oneTimeMediaUnlimited = value
                    return updated
                }
            })
        case let .downloadOneTimeMedia(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.downloadOneTimeMedia = value
                    return updated
                }
            })
        case let .uploadVoice(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.uploadVoice = value
                    return updated
                }
            })
        case let .voiceChangeSettings(text):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: "", labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: nil)
        case let .uploadVideoMessage(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.uploadVideoMessage = value
                    return updated
                }
            })
        case let .vpnEnabled(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.vpnEnabled = value
                    return updated
                }
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
        case let .messengerInfo(text), let .vpnInfo(text), let .privacyInfo(text), let .stealthInfo(text), let .channelsInfo(text), let .mediaInfo(text), let .callsInfo(text), let .developerInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .hideOnlineStatus(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.hideOnlineStatus = value
                    return updated
                }
            })
        case let .ghostMode(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.ghostMode = value
                    return updated
                }
            })
        case let .ghostChatButtonEnabled(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.ghostChatButtonEnabled = value
                    return updated
                }
            })
        case let .hideTypingStatus(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.hideTypingStatus = value
                    return updated
                }
            })
        case let .hideReadReceipts(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.hideReadReceipts = value
                    return updated
                }
            })
        case let .screenshotProtectionBypass(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.screenshotProtectionBypass = value
                    return updated
                }
            })
        case let .contentRestrictionBypass(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.contentRestrictionBypass = value
                    return updated
                }
            })
        case let .hidePhoneInSettings(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.hidePhoneInSettings = value
                    return updated
                }
            })
        case let .showProfileIds(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.showUserIds = value
                    updated.showChatIds = value
                    return updated
                }
            })
        case let .ghostMessages(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.hideReadReceipts = value
                    return updated
                }
            })
        case let .ghostStories(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.ghostStories = value
                    return updated
                }
            })
        case let .channelContentRestrictionBypass(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.contentRestrictionBypass = value
                    return updated
                }
            })
        case let .downloadStories(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.downloadStories = value
                    return updated
                }
            })
        case let .autoRecordCalls(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.autoRecordCalls = value
                    return updated
                }
            })
        case let .callRecordButton(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.callRecordButton = value
                    return updated
                }
            })
        case let .hideStories(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.hideStories = value
                    return updated
                }
            })
        case let .compactChatList(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.compactChatList = value
                    return updated
                }
            })
        case let .amoledMode(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.amoledMode = value
                    return updated
                }
            })
        case let .showUserIds(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.showUserIds = value
                    return updated
                }
            })
        case let .showChatIds(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.showChatIds = value
                    return updated
                }
            })
        case let .showMessageIds(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.showMessageIds = value
                    return updated
                }
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

private func telewhiteModsEntries(tab: TelewhiteModsTab, settings: TelewhiteModsSettings, translationSettings: TranslationSettings, strings: TelewhiteModsStrings) -> [TelewhiteModsEntry] {
    var entries: [TelewhiteModsEntry] = []

    switch tab {
    case .messenger:
        entries.append(.messengerHeader(strings.text("Messages", "Сообщения")))
        entries.append(.preserveDeletedMessages(strings.text("Keep Deleted Messages", "Сохранять удалённые сообщения"), settings.preserveDeletedMessages))
        entries.append(.oneTimeMediaUnlimited(strings.text("Unlimited One-Time View", "Одноразовый просмотр без ограничений"), settings.oneTimeMediaUnlimited))
        entries.append(.downloadOneTimeMedia(strings.text("Download One-Time Media", "Скачать одноразовые медиа"), settings.downloadOneTimeMedia))
        entries.append(.uploadVoice(strings.text("Upload Voice Message", "Загрузить голосовое"), settings.uploadVoice))
        entries.append(.voiceChangeSettings(strings.text("Voice Change Settings", "Настройки изменения голоса")))
        entries.append(.uploadVideoMessage(strings.text("Upload Video Message", "Загрузить видеосообщение"), settings.uploadVideoMessage))
        entries.append(.translateMessages(strings.text("Show Translate Button", "Показывать кнопку перевода"), translationSettings.showTranslate))
        entries.append(.translateChats(strings.text("Translate Entire Chats", "Перевод чатов"), translationSettings.translateChats))
        entries.append(.autoTranslateEnglish(strings.text("Translate Before Sending", "Перевод перед отправкой"), settings.autoTranslateEnglish))
        entries.append(.translationTargetLanguage(strings.text("Translation Language", "Язык перевода"), settings.translationTargetLanguage))
        entries.append(.messengerInfo(strings.text("Deleted cloud messages stay visible and dimmed locally. Translation settings use Telegram's existing translation engine.", "Удалённые сообщения остаются видимыми и отмечаются локально. Перевод использует уже существующий движок Telegram.")))

    case .privacy:
        entries.append(.privacyHeader(strings.text("Privacy", "Конфиденциальность")))
        entries.append(.hideOnlineStatus(strings.text("Hide Online Status", "Скрыть статус онлайн"), settings.hideOnlineStatus))
        entries.append(.screenshotProtectionBypass(strings.text("Screenshot Protection Bypass", "Обход защиты скриншотов"), settings.screenshotProtectionBypass))
        entries.append(.contentRestrictionBypass(strings.text("Content Restriction Bypass", "Обход ограничений контента"), settings.contentRestrictionBypass))
        entries.append(.hidePhoneInSettings(strings.text("Hide Phone in Settings", "Скрыть номер телефона в настр."), settings.hidePhoneInSettings))
        entries.append(.showProfileIds(strings.text("Show Profile ID", "Показать ID профиля"), settings.showUserIds && settings.showChatIds))
        entries.append(.ghostChatButtonEnabled(strings.text("Per-Chat Ghost Button", "Кнопка невидимки в чатах"), settings.ghostChatButtonEnabled))
        entries.append(.privacyInfo(strings.text("The online switch is separate from read receipts. Profile IDs can be tapped or long-pressed to copy.", "Скрытие онлайна работает отдельно от прочтения. ID профиля можно скопировать обычным или долгим нажатием.")))

    case .stealth:
        entries.append(.stealthHeader(strings.text("Ghost Mode", "Режим невидимки")))
        entries.append(.ghostMessages(strings.text("Ghost Mode (Messages)", "Режим невидимки (сообщения)"), settings.hideReadReceipts))
        entries.append(.ghostStories(strings.text("Ghost Mode (Stories)", "Режим невидимки (истории)"), settings.ghostStories))
        entries.append(.ghostMode(strings.text("Global Ghost Mode", "Глобальный режим невидимки"), settings.ghostMode))
        entries.append(.hideTypingStatus(strings.text("Hide Typing Status", "Скрыть набор текста"), settings.hideTypingStatus))
        entries.append(.stealthInfo(strings.text("The chat ghost button still toggles Ghost Mode only for one selected private chat.", "Кнопка призрака в чате включает невидимку только для выбранного личного чата.")))

    case .channels:
        entries.append(.channelsHeader(strings.text("Channels and Groups", "Каналы и группы")))
        entries.append(.channelContentRestrictionBypass(strings.text("Content Restriction Bypass", "Обход ограничений контента"), settings.contentRestrictionBypass))
        entries.append(.channelsInfo(strings.text("This prepares the settings surface for channel and group content controls.", "Этот раздел подготавливает настройки для функций каналов и групп.")))

    case .media:
        entries.append(.mediaHeader(strings.text("Media and Stories", "Медиа и истории")))
        entries.append(.downloadStories(strings.text("Download Stories", "Скачать истории"), settings.downloadStories))
        entries.append(.hideStories(strings.text("Hide Stories Row", "Скрыть блок историй"), settings.hideStories))
        entries.append(.mediaInfo(strings.text("Story download controls are separated from general chat appearance.", "Скачивание историй вынесено отдельно от общего внешнего вида чатов.")))

    case .calls:
        entries.append(.callsHeader(strings.text("Calls", "Звонки")))
        entries.append(.autoRecordCalls(strings.text("Auto-Record Calls", "Авто-запись звонков"), settings.autoRecordCalls))
        entries.append(.callRecordButton(strings.text("Call Record Button", "Кнопка записи звонка"), settings.callRecordButton))
        entries.append(.callsInfo(strings.text("Recording controls are shown here; call recording needs an explicit call UI/audio pipeline implementation.", "Здесь находятся настройки записи. Для самой записи нужен отдельный UI и аудио-пайплайн звонка.")))

    case .appearance:
        entries.append(.appearanceHeader(strings.text("Look", "Внешний вид")))
        entries.append(.compactChatList(strings.text("Compact Chat List", "Компактный список чатов"), settings.compactChatList))
        entries.append(.amoledMode(strings.text("AMOLED Mode", "AMOLED режим"), settings.amoledMode))

    case .developer:
        entries.append(.developerHeader(strings.text("Developer", "Разработчик")))
        entries.append(.showUserIds(strings.text("Show User IDs", "Показывать ID пользователей"), settings.showUserIds))
        entries.append(.showChatIds(strings.text("Show Chat IDs", "Показывать ID чатов"), settings.showChatIds))
        entries.append(.showMessageIds(strings.text("Show Message IDs", "Показывать ID сообщений"), settings.showMessageIds))
        entries.append(.developerInfo(strings.text("IDs are shown in profile/context surfaces when enabled. Message IDs are available from the message context menu.", "ID отображаются в профилях и контекстных меню. ID сообщений доступны из меню сообщения.")))
    }

    return entries
}

private func telewhiteVpnEntries(settings: TelewhiteModsSettings) -> [TelewhiteModsEntry] {
    let vpnStatus: String
    if settings.vpnSubscription.isEmpty {
        vpnStatus = "No subscription"
    } else if settings.vpnEnabled {
        vpnStatus = "Ready"
    } else {
        vpnStatus = "Configured"
    }

    var entries: [TelewhiteModsEntry] = []
    entries.append(.vpnHeader("Telegram-only VPN"))
    entries.append(.vpnEnabled("Enable VPN Profile", settings.vpnEnabled))
    entries.append(.vpnSubscription("Subscription URL", settings.vpnSubscription))
    entries.append(.vpnStatus("Status", vpnStatus))
    entries.append(.vpnStart("Start VPN"))
    entries.append(.vpnInfo("Subscription storage is ready. Actual Telegram-only tunneling requires an iOS Packet Tunnel extension plus Network Extension entitlement; this screen is the configuration surface."))
    return entries
}

public func telewhiteModsController(context: AccountContext) -> ViewController {
    let initialSettings = TelewhiteModsSettings.current
    let stateValue = Atomic(value: initialSettings)
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)
    let selectedTab = ValuePromise<TelewhiteModsTab>(.messenger, ignoreRepeated: true)
    
    let updateSettings: ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void = { f in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save()
            return updated
        }
        if updated.hideOnlineStatus || updated.ghostMode || !updated.ghostPeerIds.isEmpty {
            context.account.shouldKeepOnlinePresence.set(.single(false))
        }
        statePromise.set(updated)
    }
    
    var presentControllerImpl: ((ViewController) -> Void)?
    
    let arguments = TelewhiteModsControllerArguments(updateSettings: updateSettings, updateTranslationSettings: { f in
        let _ = updateTranslationSettingsInteractively(accountManager: context.sharedContext.accountManager, f).start()
    }, startVpn: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let settings = stateValue.with { $0 }
        let text: String
        if settings.vpnSubscription.isEmpty {
            text = "Paste a VPN subscription first. After that, the next step is adding a Packet Tunnel extension for a real iOS VPN connection."
        } else {
            text = "Your subscription is saved. To actually start VPN, Telewhite needs a Packet Tunnel extension and a tunnel engine such as sing-box, Xray, or WireGuard."
        }
        presentControllerImpl?(textAlertController(context: context, title: "VPN", text: text, actions: [
            TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})
        ]))
    })
    
    let translationSettings = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.translationSettings])
    |> map { sharedData -> TranslationSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.translationSettings]?.get(TranslationSettings.self) ?? TranslationSettings.defaultSettings
    }

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get(), translationSettings, selectedTab.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings, translationSettings, tab -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let strings = TelewhiteModsStrings(presentationData: presentationData)
        let segments = [
            strings.text("Messages", "Сообщения"),
            strings.text("Privacy", "Приватность"),
            strings.text("Ghost", "Невидимка"),
            strings.text("Groups", "Группы"),
            strings.text("Media", "Медиа"),
            strings.text("Calls", "Звонки"),
            strings.text("Look", "Вид"),
            strings.text("Dev", "Dev")
        ]
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .sectionControl(segments, Int(tab.rawValue)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: telewhiteModsEntries(tab: tab, settings: settings, translationSettings: translationSettings, strings: strings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments as Any))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.titleControlValueChanged = { index in
        switch index {
        case 0:
            selectedTab.set(.messenger)
        case 1:
            selectedTab.set(.privacy)
        case 2:
            selectedTab.set(.stealth)
        case 3:
            selectedTab.set(.channels)
        case 4:
            selectedTab.set(.media)
        case 5:
            selectedTab.set(.calls)
        case 6:
            selectedTab.set(.appearance)
        default:
            selectedTab.set(.developer)
        }
    }
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}

public func telewhiteVpnController(context: AccountContext) -> ViewController {
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

    var presentControllerImpl: ((ViewController) -> Void)?

    let arguments = TelewhiteModsControllerArguments(updateSettings: updateSettings, updateTranslationSettings: { _ in
    }, startVpn: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let settings = stateValue.with { $0 }
        let text: String
        if settings.vpnSubscription.isEmpty {
            text = "Paste a VPN subscription first."
        } else {
            text = "Telewhite saved the VPN profile. Starting a real Telegram-only tunnel needs a Packet Tunnel extension and Network Extension entitlement in the app bundle."
        }
        presentControllerImpl?(textAlertController(context: context, title: "Telewhite VPN", text: text, actions: [
            TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})
        ]))
    })

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Telewhite VPN"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: telewhiteVpnEntries(settings: settings), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments as Any))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
