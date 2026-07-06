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
    let openTab: (TelewhiteModsTab) -> Void
    
    init(
        updateSettings: @escaping ((TelewhiteModsSettings) -> TelewhiteModsSettings) -> Void,
        updateTranslationSettings: @escaping (@escaping (TranslationSettings) -> TranslationSettings) -> Void,
        startVpn: @escaping () -> Void,
        openTab: @escaping (TelewhiteModsTab) -> Void = { _ in }
    ) {
        self.updateSettings = updateSettings
        self.updateTranslationSettings = updateTranslationSettings
        self.startVpn = startVpn
        self.openTab = openTab
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

private enum TelewhiteModsMenuIcon: Int32, Equatable {
    case privacy
    case ghost
    case messages
    case groups
    case media
    case calls
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
    case pushStatus(String, String)
    case pushToken(String, String)
    case apsEnvironment(String, String)
    case appGroup(String, String)
    case developerInfo(String)
    
    var section: ItemListSectionId {
        switch self {
        case .menuItem:
            return TelewhiteModsSection.menu.rawValue
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
        case .mediaHeader, .downloadStories, .hideStories, .mediaInfo:
            return TelewhiteModsSection.media.rawValue
        case .callsHeader, .autoRecordCalls, .callRecordButton, .callsInfo:
            return TelewhiteModsSection.calls.rawValue
        case .appearanceHeader, .compactChatList, .amoledMode:
            return TelewhiteModsSection.appearance.rawValue
        case .developerHeader, .showUserIds, .showChatIds, .showMessageIds, .pushStatus, .pushToken, .apsEnvironment, .appGroup, .developerInfo:
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
        case .pushStatus:
            return 804
        case .pushToken:
            return 805
        case .apsEnvironment:
            return 806
        case .appGroup:
            return 807
        case .developerInfo:
            return 808
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
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: telewhiteMenuIcon(icon), title: title, titleFont: .bold, label: subtitle, labelStyle: .multilineDetailText, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openTab(tab)
            })
        case let .messengerHeader(text), let .vpnHeader(text), let .privacyHeader(text), let .stealthHeader(text), let .channelsHeader(text), let .mediaHeader(text), let .callsHeader(text), let .appearanceHeader(text), let .developerHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
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
            return self.switchItem(presentationData: presentationData, arguments: arguments, text: text, value: value) { settings, value in
                settings.vpnEnabled = value
            }
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
        case let .apsEnvironment(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
        case let .appGroup(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
        }
    }
}

private func telewhiteProvisioningEntitlements() -> [String: Any]? {
    guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
          let data = try? Data(contentsOf: url) else {
        return nil
    }
    // embedded.mobileprovision is a CMS/PKCS7 signed container. The embedded
    // property list is stored as plain text between <?xml ...> and </plist>.
    guard let raw = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .isoLatin1) else {
        return nil
    }
    guard let plistStart = raw.range(of: "<?xml"),
          let plistEnd = raw.range(of: "</plist>") else {
        return nil
    }
    let plistString = String(raw[plistStart.lowerBound..<plistEnd.upperBound])
    guard let plistData = plistString.data(using: .isoLatin1),
          let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
        return nil
    }
    return plist["Entitlements"] as? [String: Any]
}

private func telewhiteApsEnvironmentValue() -> String? {
    guard let entitlements = telewhiteProvisioningEntitlements() else {
        return nil
    }
    return entitlements["aps-environment"] as? String
}

// Telewhite: the app groups the resigned profile actually grants. Telegram's
// background notifications need the main app and the NotificationService
// extension to share the SAME app group container (default:
// group.ph.telegra.Telegraph) so the extension can read the decryption key the
// app stored. Re-signing tools (ESign etc.) frequently strip or rewrite this
// entitlement, which silently breaks background pushes while foreground still
// works over the live connection.
private func telewhiteProvisioningAppGroups() -> [String]? {
    guard let entitlements = telewhiteProvisioningEntitlements() else {
        return nil
    }
    return entitlements["com.apple.security.application-groups"] as? [String]
}

// Telewhite: the app group the code expects at runtime, mirroring how
// AppDelegate / NotificationService resolve it: try group.<bundleId> first,
// then fall back to whatever group the provisioning profile actually provides.
private func telewhiteExpectedAppGroup() -> String {
    let bundleId = Bundle.main.bundleIdentifier ?? "ph.telegra.Telegraph"
    let defaultName = "group.\(bundleId)"
    if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: defaultName) != nil {
        return defaultName
    }
    if let groups = telewhiteProvisioningAppGroups() {
        for candidate in groups {
            if !candidate.isEmpty, FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: candidate) != nil {
                return candidate
            }
        }
    }
    return defaultName
}

// Telewhite: whether the shared app group container is actually reachable. If the
// entitlement was stripped/rewritten by the re-signer, this returns false and the
// NotificationService extension cannot read the decryption key -> no background push.
private func telewhiteAppGroupContainerAccessible() -> Bool {
    return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: telewhiteExpectedAppGroup()) != nil
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

private func telewhiteMenuIcon(_ icon: TelewhiteModsMenuIcon) -> UIImage? {
    switch icon {
    case .privacy:
        return PresentationResourcesSettings.security
    case .ghost:
        return PresentationResourcesSettings.faceId
    case .messages:
        return PresentationResourcesSettings.privateChats
    case .groups:
        return PresentationResourcesSettings.groups
    case .media:
        return PresentationResourcesSettings.stories
    case .calls:
        return PresentationResourcesSettings.recentCalls
    case .appearance:
        return PresentationResourcesSettings.appearance
    case .developer:
        return PresentationResourcesSettings.support
    }
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
        .menuItem(5, .calls, telewhiteTabTitle(.calls, strings: strings), strings.text("Call recording preferences and controls.", "\u{0417}\u{0430}\u{043f}\u{0438}\u{0441}\u{044c} \u{0437}\u{0432}\u{043e}\u{043d}\u{043a}\u{043e}\u{0432} \u{0438} \u{0443}\u{043f}\u{0440}\u{0430}\u{0432}\u{043b}\u{0435}\u{043d}\u{0438}\u{0435}."), .calls),
        .menuItem(6, .appearance, telewhiteTabTitle(.appearance, strings: strings), strings.text("Chat list density and visual mode.", "\u{041f}\u{043b}\u{043e}\u{0442}\u{043d}\u{043e}\u{0441}\u{0442}\u{044c} \u{0441}\u{043f}\u{0438}\u{0441}\u{043a}\u{0430} \u{0447}\u{0430}\u{0442}\u{043e}\u{0432} \u{0438} \u{0432}\u{0438}\u{0434}."), .appearance),
        .menuItem(7, .developer, telewhiteTabTitle(.developer, strings: strings), strings.text("User, chat and message IDs.", "ID \u{043f}\u{043e}\u{043b}\u{044c}\u{0437}\u{043e}\u{0432}\u{0430}\u{0442}\u{0435}\u{043b}\u{0435}\u{0439}, \u{0447}\u{0430}\u{0442}\u{043e}\u{0432} \u{0438} \u{0441}\u{043e}\u{043e}\u{0431}\u{0449}\u{0435}\u{043d}\u{0438}\u{0439}."), .developer)
    ]
}

private func telewhiteEntryDescription(_ entry: TelewhiteModsEntry, presentationData: ItemListPresentationData) -> String? {
    let isRussian = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
    func text(_ en: String, _ ru: String) -> String {
        return isRussian ? ru : en
    }
    switch entry {
    case .preserveDeletedMessages:
        return text("Keeps deleted cloud messages visible locally; deleting the marked copy again removes it from this device.", "\u{0423}\u{0434}\u{0430}\u{043b}\u{0451}\u{043d}\u{043d}\u{044b}\u{0435} \u{043e}\u{0431}\u{043b}\u{0430}\u{0447}\u{043d}\u{044b}\u{0435} \u{0441}\u{043e}\u{043e}\u{0431}\u{0449}\u{0435}\u{043d}\u{0438}\u{044f} \u{043e}\u{0441}\u{0442}\u{0430}\u{044e}\u{0442}\u{0441}\u{044f} \u{043b}\u{043e}\u{043a}\u{0430}\u{043b}\u{044c}\u{043d}\u{043e}; \u{043f}\u{043e}\u{0432}\u{0442}\u{043e}\u{0440}\u{043d}\u{043e}\u{0435} \u{0443}\u{0434}\u{0430}\u{043b}\u{0435}\u{043d}\u{0438}\u{0435} \u{0443}\u{0431}\u{0438}\u{0440}\u{0430}\u{0435}\u{0442} \u{043a}\u{043e}\u{043f}\u{0438}\u{044e}.")
    case .translateMessages:
        return text("Shows the manual translate action in message menus.", "Показывает ручную кнопку перевода в меню сообщений.")
    case .translateChats:
        return text("Enables full chat translation when Telegram exposes the translation pipeline.", "Включает перевод чата, когда в клиенте доступна система перевода.")
    case .autoTranslateEnglish:
        return text("Prepares outgoing messages for automatic translation to the selected language.", "Готовит исходящие сообщения к автопереводу на выбранный язык.")
    case .oneTimeMediaUnlimited, .downloadOneTimeMedia:
        return text("Loosens local view-once media limits and screenshot blocking where the client controls the UI.", "\u{041e}\u{0441}\u{043b}\u{0430}\u{0431}\u{043b}\u{044f}\u{0435}\u{0442} \u{043b}\u{043e}\u{043a}\u{0430}\u{043b}\u{044c}\u{043d}\u{044b}\u{0435} \u{043b}\u{0438}\u{043c}\u{0438}\u{0442}\u{044b} \u{043e}\u{0434}\u{043d}\u{043e}\u{0440}\u{0430}\u{0437}\u{043e}\u{0432}\u{044b}\u{0445} \u{043c}\u{0435}\u{0434}\u{0438}\u{0430} \u{0438} \u{0431}\u{043b}\u{043e}\u{043a} \u{0441}\u{043a}\u{0440}\u{0438}\u{043d}\u{0448}\u{043e}\u{0442}\u{043e}\u{0432}.")
    case .uploadVoice:
        return text("Keeps the upload preference for sending local audio/video as voice messages.", "Сохраняет настройку отправки локальных аудио/видео как голосовых.")
    case .uploadVideoMessage:
        return text("Keeps the upload preference for sending gallery video as a round video message.", "Сохраняет настро��ку отправки видео из галереи как круглого видеосообщения.")
    case .vpnEnabled:
        return text("Stores whether the Telegram-only VPN profile should be active.", "Сохраняет, должен ли Telegram-only VPN быть активен.")
    case .hideOnlineStatus:
        return text("Stops the app from keeping your account online while enabled.", "\u{041d}\u{0435} \u{0434}\u{0430}\u{0451}\u{0442} \u{043f}\u{0440}\u{0438}\u{043b}\u{043e}\u{0436}\u{0435}\u{043d}\u{0438}\u{044e} \u{0434}\u{0435}\u{0440}\u{0436}\u{0430}\u{0442}\u{044c} \u{0430}\u{043a}\u{043a}\u{0430}\u{0443}\u{043d}\u{0442} \u{043e}\u{043d}\u{043b}\u{0430}\u{0439}\u{043d}.")
    case .ghostMode:
        return text("Global stealth combines hidden reads, typing and online presence.", "\u{0413}\u{043b}\u{043e}\u{0431}\u{0430}\u{043b}\u{044c}\u{043d}\u{0430}\u{044f} \u{043d}\u{0435}\u{0432}\u{0438}\u{0434}\u{0438}\u{043c}\u{043a}\u{0430}: \u{0447}\u{0442}\u{0435}\u{043d}\u{0438}\u{0435}, \u{043d}\u{0430}\u{0431}\u{043e}\u{0440} \u{0438} \u{043e}\u{043d}\u{043b}\u{0430}\u{0439}\u{043d}.")
    case .ghostChatButtonEnabled:
        return text("Shows the ghost button in private chats for per-peer stealth.", "\u{041f}\u{043e}\u{043a}\u{0430}\u{0437}\u{044b}\u{0432}\u{0430}\u{0435}\u{0442} \u{043a}\u{043d}\u{043e}\u{043f}\u{043a}\u{0443} \u{043f}\u{0440}\u{0438}\u{0437}\u{0440}\u{0430}\u{043a}\u{0430} \u{0432} \u{043b}\u{0438}\u{0447}\u{043d}\u{044b}\u{0445} \u{0447}\u{0430}\u{0442}\u{0430}\u{0445}.")
    case .hideTypingStatus:
        return text("Blocks outgoing typing and recording activity updates.", "\u{0411}\u{043b}\u{043e}\u{043a}\u{0438}\u{0440}\u{0443}\u{0435}\u{0442} \u{043d}\u{0430}\u{0431}\u{043e}\u{0440} \u{0442}\u{0435}\u{043a}\u{0441}\u{0442}\u{0430} \u{0438} \u{0441}\u{0442}\u{0430}\u{0442}\u{0443}\u{0441} \u{0437}\u{0430}\u{043f}\u{0438}\u{0441}\u{0438}.")
    case .hideReadReceipts, .ghostMessages:
        return text("Prevents automatic read-state sync for messages.", "\u{041d}\u{0435} \u{043e}\u{0442}\u{043f}\u{0440}\u{0430}\u{0432}\u{043b}\u{044f}\u{0435}\u{0442} \u{0430}\u{0432}\u{0442}\u{043e}\u{043f}\u{0440}\u{043e}\u{0447}\u{0442}\u{0435}\u{043d}\u{0438}\u{0435} \u{0441}\u{043e}\u{043e}\u{0431}\u{0449}\u{0435}\u{043d}\u{0438}\u{0439}.")
    case .ghostStories:
        return text("Skips story view sync so authors do not receive your view.", "\u{041d}\u{0435} \u{043e}\u{0442}\u{043f}\u{0440}\u{0430}\u{0432}\u{043b}\u{044f}\u{0435}\u{0442} \u{043f}\u{0440}\u{043e}\u{0441}\u{043c}\u{043e}\u{0442}\u{0440} \u{0438}\u{0441}\u{0442}\u{043e}\u{0440}\u{0438}\u{0439} \u{0430}\u{0432}\u{0442}\u{043e}\u{0440}\u{0443}.")
    case .screenshotProtectionBypass:
        return text("Disables local screenshot warnings and screen-recording blocks where possible.", "\u{041e}\u{0442}\u{043a}\u{043b}\u{044e}\u{0447}\u{0430}\u{0435}\u{0442} \u{043b}\u{043e}\u{043a}\u{0430}\u{043b}\u{044c}\u{043d}\u{044b}\u{0435} \u{0431}\u{043b}\u{043e}\u{043a}\u{0438} \u{0438} \u{0443}\u{0432}\u{0435}\u{0434}\u{043e}\u{043c}\u{043b}\u{0435}\u{043d}\u{0438}\u{044f} \u{0441}\u{043a}\u{0440}\u{0438}\u{043d}\u{0448}\u{043e}\u{0442}\u{043e}\u{0432}.")
    case .contentRestrictionBypass, .channelContentRestrictionBypass:
        return text("Restores local forward/share/reply actions when copy protection hides them.", "\u{0412}\u{043e}\u{0437}\u{0432}\u{0440}\u{0430}\u{0449}\u{0430}\u{0435}\u{0442} \u{043f}\u{0435}\u{0440}\u{0435}\u{0441}\u{044b}\u{043b}\u{043a}\u{0443}, \u{0448}\u{0430}\u{0440}\u{0438}\u{043d}\u{0433} \u{0438} \u{043e}\u{0442}\u{0432}\u{0435}\u{0442}, \u{0435}\u{0441}\u{043b}\u{0438} copy protection \u{0438}\u{0445} \u{0441}\u{043a}\u{0440}\u{044b}\u{0432}\u{0430}\u{0435}\u{0442}.")
    case .hidePhoneInSettings:
        return text("Hides your phone number from settings/profile header.", "\u{0421}\u{043a}\u{0440}\u{044b}\u{0432}\u{0430}\u{0435}\u{0442} \u{043d}\u{043e}\u{043c}\u{0435}\u{0440} \u{0432} \u{043d}\u{0430}\u{0441}\u{0442}\u{0440}\u{043e}\u{0439}\u{043a}\u{0430}\u{0445} \u{0438} \u{0448}\u{0430}\u{043f}\u{043a}\u{0435} \u{043f}\u{0440}\u{043e}\u{0444}\u{0438}\u{043b}\u{044f}.")
    case .showProfileIds, .showUserIds, .showChatIds, .showMessageIds:
        return text("Shows IDs and lets you copy them from profile/context surfaces.", "\u{041f}\u{043e}\u{043a}\u{0430}\u{0437}\u{044b}\u{0432}\u{0430}\u{0435}\u{0442} ID \u{0438} \u{0434}\u{0430}\u{0451}\u{0442} \u{043a}\u{043e}\u{043f}\u{0438}\u{0440}\u{043e}\u{0432}\u{0430}\u{0442}\u{044c} \u{0438}\u{0445} \u{0438}\u{0437} \u{043f}\u{0440}\u{043e}\u{0444}\u{0438}\u{043b}\u{044f} \u{0438} \u{043c}\u{0435}\u{043d}\u{044e}.")
    case .downloadStories, .hideStories:
        return text("Controls story visibility/download surfaces in the client.", "\u{0423}\u{043f}\u{0440}\u{0430}\u{0432}\u{043b}\u{044f}\u{0435}\u{0442} \u{0438}\u{0441}\u{0442}\u{043e}\u{0440}\u{0438}\u{044f}\u{043c}\u{0438}, \u{0438}\u{0445} \u{043f}\u{043e}\u{043a}\u{0430}\u{0437}\u{043e}\u{043c} \u{0438} \u{0441}\u{043a}\u{0430}\u{0447}\u{0438}\u{0432}\u{0430}\u{043d}\u{0438}\u{0435}\u{043c}.")
    case .autoRecordCalls, .callRecordButton:
        return text("Stores call recording preferences; full recording needs the call audio pipeline hook.", "\u{0421}\u{043e}\u{0445}\u{0440}\u{0430}\u{043d}\u{044f}\u{0435}\u{0442} \u{043d}\u{0430}\u{0441}\u{0442}\u{0440}\u{043e}\u{0439}\u{043a}\u{0438} \u{0437}\u{0432}\u{043e}\u{043d}\u{043a}\u{043e}\u{0432}; \u{0434}\u{043b}\u{044f} \u{0437}\u{0430}\u{043f}\u{0438}\u{0441}\u{0438} \u{043d}\u{0443}\u{0436}\u{0435}\u{043d} \u{0445}\u{0443}\u{043a} \u{0430}\u{0443}\u{0434}\u{0438}\u{043e}.")
    case .compactChatList:
        return text("Reduces visual spacing in the chat list for a denser Telegram layout.", "\u{0423}\u{043c}\u{0435}\u{043d}\u{044c}\u{0448}\u{0430}\u{0435}\u{0442} \u{043e}\u{0442}\u{0441}\u{0442}\u{0443}\u{043f}\u{044b} \u{0432} \u{0441}\u{043f}\u{0438}\u{0441}\u{043a}\u{0435} \u{0447}\u{0430}\u{0442}\u{043e}\u{0432}.")
    case .amoledMode:
        return text("Keeps the AMOLED visual preference for darker surfaces.", "\u{0421}\u{043e}\u{0445}\u{0440}\u{0430}\u{043d}\u{044f}\u{0435}\u{0442} AMOLED-\u{0440}\u{0435}\u{0436}\u{0438}\u{043c} \u{0434}\u{043b}\u{044f} \u{0431}\u{043e}\u{043b}\u{0435}\u{0435} \u{0442}\u{0451}\u{043c}\u{043d}\u{044b}\u{0445} \u{044d}\u{043a}\u{0440}\u{0430}\u{043d}\u{043e}\u{0432}.")
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
        entries.append(.uploadVoice(strings.text("Upload Voice Message", "Загрузить голосовое"), settings.uploadVoice))
        entries.append(.voiceChangeSettings(strings.text("Voice Change Settings", "Настройки изменения голоса")))
        entries.append(.uploadVideoMessage(strings.text("Upload Video Message", "Загрузить видеосообщение"), settings.uploadVideoMessage))
        entries.append(.translateMessages(strings.text("Show Translate Button", "Показывать кнопку перевода"), translationSettings.showTranslate))
        entries.append(.translateChats(strings.text("Translate Entire Chats", "Перевод чатов"), translationSettings.translateChats))
        entries.append(.autoTranslateEnglish(strings.text("Translate Before Sending", "Перевод перед отправкой"), settings.autoTranslateEnglish))
        entries.append(.translationTargetLanguage(strings.text("Translation Language", "Язык перевода"), settings.translationTargetLanguage))
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
        entries.append(.autoRecordCalls(strings.text("Auto-Record Calls", "Авто-запись звонков"), settings.autoRecordCalls))
        entries.append(.callRecordButton(strings.text("Call Record Button", "Кнопка записи звонка"), settings.callRecordButton))
        entries.append(.callsInfo(strings.text("Call recording still needs the call UI and audio pipeline hook.", "Для записи звонков ещё нужен хук UI и аудио-пайплайна звонка.")))

    case .appearance:
        entries.append(.appearanceHeader(telewhiteTabTitle(.appearance, strings: strings)))
        entries.append(.compactChatList(strings.text("Compact Chat List", "Компактный список чатов"), settings.compactChatList))
        entries.append(.amoledMode(strings.text("AMOLED Mode", "AMOLED режим"), settings.amoledMode))

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

        let apsValue = telewhiteApsEnvironmentValue()
        let apsDisplay: String
        switch apsValue {
        case "production":
            apsDisplay = strings.text("production → production APNs", "production → боевой APNs")
        case "development":
            apsDisplay = strings.text("development → sandbox APNs", "development → sandbox APNs")
        case .some(let other):
            apsDisplay = other
        case .none:
            apsDisplay = strings.text("Unknown (no provisioning profile)", "Неизвестно (нет профиля)")
        }
        entries.append(.apsEnvironment(strings.text("APNs environment", "APNs окружение"), apsDisplay))

        let expectedGroup = telewhiteExpectedAppGroup()
        let profileGroups = telewhiteProvisioningAppGroups()
        let containerOk = telewhiteAppGroupContainerAccessible()
        let appGroupDisplay: String
        if !containerOk {
            appGroupDisplay = strings.text("Not shared — plaintext push mode", "Не расшарен — режим открытых пушей")
        } else if let groups = profileGroups {
            if groups.contains(expectedGroup) {
                appGroupDisplay = strings.text("OK (shared)", "OK (расшарен)")
            } else if groups.isEmpty {
                appGroupDisplay = strings.text("Empty in profile", "Пусто в профиле")
            } else {
                appGroupDisplay = strings.text("Mismatch: \(groups.joined(separator: ", "))", "Не совпадает: \(groups.joined(separator: ", "))")
            }
        } else {
            appGroupDisplay = strings.text("Container OK, no profile info", "Контейнер OK, нет данных профиля")
        }
        entries.append(.appGroup(strings.text("App Group", "App Group"), appGroupDisplay))

        entries.append(.developerInfo(strings.text("Push delivery depends on the APNs environment of the signing profile, not on api_id. Telewhite auto-detects aps-environment from the embedded provisioning profile and tells Telegram the matching sandbox/production flag. Encrypted background pushes need the App Group (group.<bundleId>) shared between the app and its NotificationService extension. If your re-signer (e.g. ESign) stripped that entitlement, Telewhite automatically falls back to plaintext pushes: the token is registered without an encryption secret, so Telegram's server sends readable notifications that iOS shows natively without the extension. Note: in this mode notification text passes through APNs unencrypted. If status stays not \"Registered\", Apple did not issue a token for this profile at all.", "Доставка пушей зависит от APNs окружения профиля подписи, а не от api_id. Telewhite сам определяет aps-environment из встроенного профиля и сообщает Telegram правильный флаг sandbox/production. Зашифрованным фоновым пушам нужен App Group (group.<bundleId>), общий у приложения и его NotificationService extension. Если ре-сайнер (например ESign) срезал этот entitlement, Telewhite автоматически переключается на открытые пуши: токен регистрируется без ключа шифрования, и сервер Telegram шлёт готовые уведомления, которые iOS показывает сама, без extension. Учти: в этом режиме текст уведомлений проходит через APNs в открытом виде. Если статус так и не \"Registered\", значит Apple вообще не выдал токен для этого профиля.")))
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
