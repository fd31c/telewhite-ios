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
    public var preserveDeletedMessages: Bool
    public var hideTypingStatus: Bool
    public var hideReadReceipts: Bool
    public var hideStories: Bool
    public var compactChatList: Bool
    public var amoledMode: Bool
    public var showUserIds: Bool
    public var showChatIds: Bool
    public var showMessageIds: Bool
    public var ghostPeerIds: Set<Int64>
    public var autoTranslateEnglish: Bool
    public var translationTargetLanguage: String

    private enum Key {
        static let vpnEnabled = "telewhite.mods.vpnEnabled"
        static let vpnSubscription = "telewhite.mods.vpnSubscription"
        static let ghostMode = "telewhite.mods.ghostMode"
        static let preserveDeletedMessages = "telewhite.mods.preserveDeletedMessages"
        static let hideTypingStatus = "telewhite.mods.hideTypingStatus"
        static let hideReadReceipts = "telewhite.mods.hideReadReceipts"
        static let hideStories = "telewhite.mods.hideStories"
        static let compactChatList = "telewhite.mods.compactChatList"
        static let amoledMode = "telewhite.mods.amoledMode"
        static let showUserIds = "telewhite.mods.showUserIds"
        static let showChatIds = "telewhite.mods.showChatIds"
        static let showMessageIds = "telewhite.mods.showMessageIds"
        static let ghostPeerIds = "telewhite.mods.ghostPeerIds"
        static let autoTranslateEnglish = "telewhite.mods.autoTranslateEnglish"
        static let translationTargetLanguage = "telewhite.mods.translationTargetLanguage"
    }
    
    public static var current: TelewhiteModsSettings {
        let defaults = UserDefaults.standard
        return TelewhiteModsSettings(
            vpnEnabled: defaults.bool(forKey: Key.vpnEnabled),
            vpnSubscription: defaults.string(forKey: Key.vpnSubscription) ?? "",
            ghostMode: defaults.bool(forKey: Key.ghostMode),
            preserveDeletedMessages: defaults.bool(forKey: Key.preserveDeletedMessages),
            hideTypingStatus: defaults.bool(forKey: Key.hideTypingStatus),
            hideReadReceipts: defaults.bool(forKey: Key.hideReadReceipts),
            hideStories: defaults.bool(forKey: Key.hideStories),
            compactChatList: defaults.bool(forKey: Key.compactChatList),
            amoledMode: defaults.bool(forKey: Key.amoledMode),
            showUserIds: defaults.bool(forKey: Key.showUserIds),
            showChatIds: defaults.bool(forKey: Key.showChatIds),
            showMessageIds: defaults.bool(forKey: Key.showMessageIds),
            ghostPeerIds: Set((defaults.array(forKey: Key.ghostPeerIds) as? [NSNumber] ?? []).map { $0.int64Value }),
            autoTranslateEnglish: defaults.bool(forKey: Key.autoTranslateEnglish),
            translationTargetLanguage: defaults.string(forKey: Key.translationTargetLanguage) ?? "ru"
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
        defaults.set(self.preserveDeletedMessages, forKey: Key.preserveDeletedMessages)
        defaults.set(self.hideTypingStatus, forKey: Key.hideTypingStatus)
        defaults.set(self.hideReadReceipts, forKey: Key.hideReadReceipts)
        defaults.set(self.hideStories, forKey: Key.hideStories)
        defaults.set(self.compactChatList, forKey: Key.compactChatList)
        defaults.set(self.amoledMode, forKey: Key.amoledMode)
        defaults.set(self.showUserIds, forKey: Key.showUserIds)
        defaults.set(self.showChatIds, forKey: Key.showChatIds)
        defaults.set(self.showMessageIds, forKey: Key.showMessageIds)
        defaults.set(self.ghostPeerIds.map { NSNumber(value: $0) }, forKey: Key.ghostPeerIds)
        defaults.set(self.autoTranslateEnglish, forKey: Key.autoTranslateEnglish)
        defaults.set(self.translationTargetLanguage, forKey: Key.translationTargetLanguage)
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
    case vpn
    case appearance
    case developer
}

private enum TelewhiteModsTab: Int32, Equatable {
    case messenger
    case privacy
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

    case vpnHeader(String)
    case vpnEnabled(String, Bool)
    case vpnSubscription(String, String)
    case vpnStatus(String, String)
    case vpnStart(String)
    case vpnInfo(String)
    
    case privacyHeader(String)
    case ghostMode(String, Bool)
    case hideTypingStatus(String, Bool)
    case hideReadReceipts(String, Bool)
    case privacyInfo(String)
    
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
        case .messengerHeader, .preserveDeletedMessages, .translateMessages, .translateChats, .autoTranslateEnglish, .translationTargetLanguage, .messengerInfo:
            return TelewhiteModsSection.messenger.rawValue
        case .vpnHeader, .vpnEnabled, .vpnSubscription, .vpnStatus, .vpnStart, .vpnInfo:
            return TelewhiteModsSection.vpn.rawValue
        case .privacyHeader, .ghostMode, .hideTypingStatus, .hideReadReceipts, .privacyInfo:
            return TelewhiteModsSection.privacy.rawValue
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
        case .translateMessages:
            return 2
        case .translateChats:
            return 3
        case .messengerInfo:
            return 4
        case .autoTranslateEnglish:
            return 5
        case .translationTargetLanguage:
            return 6
        case .vpnHeader:
            return 20
        case .vpnEnabled:
            return 21
        case .vpnSubscription:
            return 22
        case .vpnStatus:
            return 23
        case .vpnStart:
            return 24
        case .vpnInfo:
            return 25
        case .privacyHeader:
            return 10
        case .ghostMode:
            return 11
        case .hideTypingStatus:
            return 12
        case .hideReadReceipts:
            return 13
        case .privacyInfo:
            return 14
        case .appearanceHeader:
            return 30
        case .hideStories:
            return 31
        case .compactChatList:
            return 32
        case .amoledMode:
            return 33
        case .developerHeader:
            return 40
        case .showUserIds:
            return 41
        case .showChatIds:
            return 42
        case .showMessageIds:
            return 43
        case .developerInfo:
            return 44
        }
    }
    
    static func <(lhs: TelewhiteModsEntry, rhs: TelewhiteModsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! TelewhiteModsControllerArguments
        switch self {
        case let .messengerHeader(text), let .vpnHeader(text), let .privacyHeader(text), let .appearanceHeader(text), let .developerHeader(text):
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
        case let .messengerInfo(text), let .vpnInfo(text), let .privacyInfo(text), let .developerInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .ghostMode(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateSettings { current in
                    var updated = current
                    updated.ghostMode = value
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

private func telewhiteModsEntries(tab: TelewhiteModsTab, settings: TelewhiteModsSettings, translationSettings: TranslationSettings) -> [TelewhiteModsEntry] {
    var entries: [TelewhiteModsEntry] = []

    switch tab {
    case .messenger:
    entries.append(.messengerHeader("Messenger"))
    entries.append(.preserveDeletedMessages("Keep Deleted Messages", settings.preserveDeletedMessages))
    entries.append(.translateMessages("Show Translate Button", translationSettings.showTranslate))
    entries.append(.translateChats("Translate Entire Chats", translationSettings.translateChats))
    entries.append(.autoTranslateEnglish("Auto-translate English", settings.autoTranslateEnglish))
    entries.append(.translationTargetLanguage("Translation Language", settings.translationTargetLanguage))
    entries.append(.messengerInfo("Deleted cloud messages stay in chat and are dimmed locally. English auto-translate targets Russian by default and does not touch Russian messages."))

    case .privacy:
    entries.append(.privacyHeader("Privacy"))
    entries.append(.ghostMode("Ghost Mode", settings.ghostMode))
    entries.append(.hideTypingStatus("Hide Typing Status", settings.hideTypingStatus))
    entries.append(.hideReadReceipts("Hide Read Receipts", settings.hideReadReceipts))
    entries.append(.privacyInfo("Ghost Mode blocks read receipts and typing activity. The chat button toggles it for one private chat."))

    case .appearance:
    entries.append(.appearanceHeader("Appearance"))
    entries.append(.hideStories("Hide Stories", settings.hideStories))
    entries.append(.compactChatList("Compact Chat List", settings.compactChatList))
    entries.append(.amoledMode("AMOLED Mode", settings.amoledMode))

    case .developer:
    entries.append(.developerHeader("Developer"))
    entries.append(.showUserIds("Show User IDs", settings.showUserIds))
    entries.append(.showChatIds("Show Chat IDs", settings.showChatIds))
    entries.append(.showMessageIds("Show Message IDs", settings.showMessageIds))
    entries.append(.developerInfo("IDs are shown in profile/context surfaces when enabled. Message IDs are available from the message context menu."))
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
        if updated.ghostMode || !updated.ghostPeerIds.isEmpty {
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
        let segments = ["Messenger", "Privacy", "Look", "Dev"]
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .sectionControl(segments, Int(tab.rawValue)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: telewhiteModsEntries(tab: tab, settings: settings, translationSettings: translationSettings), style: .blocks, animateChanges: false)
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
