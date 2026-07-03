import Foundation
import UIKit
import SwiftSignalKit
import TelegramCore
import TelegramUIPreferences

// Telewhite mod: AMOLED mode.
// Transforms a dark presentation theme so that all large background surfaces
// become pure black (0x000000), which saves power on OLED displays and gives a
// true-black look. Cards / cells use a slightly elevated near-black so they stay
// distinguishable from the background.
//
// The transform is only applied to themes that are already dark
// (`overallDarkAppearance == true`). Applying it to a light theme would keep the
// dark text and make it unreadable, so light themes are returned unchanged.

private let telewhiteAmoledBackgroundColor = UIColor(rgb: 0x000000)
private let telewhiteAmoledElevatedColor = UIColor(rgb: 0x1c1c1e)

public func telewhiteAmoledModeEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "telewhite.mods.amoledMode")
}

// Emits the current AMOLED mode flag and re-emits whenever the Telewhite mods
// settings change, so the presentation theme can be rebuilt live when the user
// toggles the switch. `distinctUntilChanged` ensures unrelated mod toggles do
// not needlessly rebuild the theme.
//
// The notification name mirrors `TelewhiteModsSettings.didChangeNotification`
// from the SettingsUI module. It is duplicated here as a string constant because
// SettingsUI depends on TelegramPresentationData, so importing it would create a
// circular dependency (same reasoning as the raw UserDefaults key access above).
public func telewhiteAmoledModeUpdated() -> Signal<Bool, NoError> {
    return (Signal<Bool, NoError> { subscriber in
        subscriber.putNext(telewhiteAmoledModeEnabled())
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name("TelewhiteModsSettingsDidChange"), object: nil, queue: .main, using: { _ in
            subscriber.putNext(telewhiteAmoledModeEnabled())
        })
        return ActionDisposable {
            NotificationCenter.default.removeObserver(observer)
        }
    })
    |> distinctUntilChanged
}

public func makeTelewhiteAmoledPresentationTheme(_ theme: PresentationTheme) -> PresentationTheme {
    guard theme.overallDarkAppearance else {
        return theme
    }

    let black = telewhiteAmoledBackgroundColor
    let elevated = telewhiteAmoledElevatedColor

    let rootController = theme.rootController.withUpdated(
        tabBar: theme.rootController.tabBar.withUpdated(backgroundColor: black),
        navigationBar: theme.rootController.navigationBar.withUpdated(blurredBackgroundColor: black, opaqueBackgroundColor: black),
        navigationSearchBar: theme.rootController.navigationSearchBar.withUpdated(backgroundColor: black)
    )

    let list = theme.list.withUpdated(
        blocksBackgroundColor: black,
        modalBlocksBackgroundColor: black,
        plainBackgroundColor: black,
        modalPlainBackgroundColor: black,
        itemBlocksBackgroundColor: elevated,
        itemModalBlocksBackgroundColor: elevated
    )

    let chatList = theme.chatList.withUpdated(
        backgroundColor: black,
        pinnedItemBackgroundColor: elevated
    )

    let chat = theme.chat.withUpdated(
        defaultWallpaper: .color(0x000000),
        inputPanel: theme.chat.inputPanel.withUpdated(
            panelBackgroundColor: black,
            panelBackgroundColorNoWallpaper: black
        )
    )

    let actionSheet = theme.actionSheet.withUpdated(
        opaqueItemBackgroundColor: black
    )

    let contextMenu = theme.contextMenu.withUpdated(
        backgroundColor: black
    )

    let result = PresentationTheme(
        name: theme.name,
        index: theme.index,
        referenceTheme: theme.referenceTheme,
        overallDarkAppearance: theme.overallDarkAppearance,
        intro: theme.intro,
        passcode: theme.passcode,
        rootController: rootController,
        list: list,
        chatList: chatList,
        chat: chat,
        actionSheet: actionSheet,
        contextMenu: contextMenu,
        inAppNotification: theme.inAppNotification,
        chart: theme.chart,
        preview: theme.preview
    )
    result.forceSync = theme.forceSync
    result.starGift = theme.starGift
    return result
}
