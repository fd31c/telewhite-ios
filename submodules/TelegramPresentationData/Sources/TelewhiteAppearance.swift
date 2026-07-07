import Foundation
import UIKit
import SwiftSignalKit
import TelegramCore
import TelegramUIPreferences

// Telewhite mod: theme customization overrides.
// Stores user-selected accent color, outgoing bubble color, chat background
// color and bubble corner radius. The values are persisted in UserDefaults by
// the Telewhite Mods settings screen (SettingsUI module) and read here when
// the presentation theme is built.
//
// The UserDefaults keys mirror `TelewhiteModsSettings` from SettingsUI. They
// are duplicated as string constants because SettingsUI depends on
// TelegramPresentationData, so importing it here would create a circular
// dependency (same reasoning as TelewhiteAmoledTheme.swift).

public struct TelewhiteAppearanceOverrides: Equatable {
    public var accentColor: UInt32?
    public var bubbleColor: UInt32?
    public var chatBackgroundColor: UInt32?
    public var bubbleCornerRadius: Int32?
    public var amoledMode: Bool
}

private enum TelewhiteAppearanceKey {
    static let accentColor = "telewhite.mods.accentColor"
    static let bubbleColor = "telewhite.mods.bubbleColor"
    static let chatBackgroundColor = "telewhite.mods.chatBackgroundColor"
    static let bubbleCornerRadius = "telewhite.mods.bubbleCornerRadius"
    static let amoledMode = "telewhite.mods.amoledMode"
}

private func telewhiteReadColor(_ key: String) -> UInt32? {
    guard let number = UserDefaults.standard.object(forKey: key) as? NSNumber else {
        return nil
    }
    return UInt32(truncatingIfNeeded: number.int64Value)
}

public func telewhiteAppearanceOverrides() -> TelewhiteAppearanceOverrides {
    let defaults = UserDefaults.standard
    var cornerRadius: Int32?
    if let number = defaults.object(forKey: TelewhiteAppearanceKey.bubbleCornerRadius) as? NSNumber {
        cornerRadius = number.int32Value
    }
    return TelewhiteAppearanceOverrides(
        accentColor: telewhiteReadColor(TelewhiteAppearanceKey.accentColor),
        bubbleColor: telewhiteReadColor(TelewhiteAppearanceKey.bubbleColor),
        chatBackgroundColor: telewhiteReadColor(TelewhiteAppearanceKey.chatBackgroundColor),
        bubbleCornerRadius: cornerRadius,
        amoledMode: defaults.bool(forKey: TelewhiteAppearanceKey.amoledMode)
    )
}

// Emits the current appearance overrides snapshot and re-emits whenever the
// Telewhite mods settings change, so the presentation theme is rebuilt live
// when the user picks a color or radius. `distinctUntilChanged` ensures
// unrelated mod toggles do not needlessly rebuild the theme. The snapshot
// includes the AMOLED flag, so this signal supersedes
// `telewhiteAmoledModeUpdated()` in the presentation data pipeline.
public func telewhiteAppearanceUpdated() -> Signal<TelewhiteAppearanceOverrides, NoError> {
    return (Signal<TelewhiteAppearanceOverrides, NoError> { subscriber in
        subscriber.putNext(telewhiteAppearanceOverrides())
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name("TelewhiteModsSettingsDidChange"), object: nil, queue: .main, using: { _ in
            subscriber.putNext(telewhiteAppearanceOverrides())
        })
        return ActionDisposable {
            NotificationCenter.default.removeObserver(observer)
        }
    })
    |> distinctUntilChanged
}

// Applies the Telewhite accent / bubble color overrides on top of the accent
// colors stored in the regular theme settings. Called right before the
// presentation theme is constructed, so the overrides win over both the
// default theme colors and any per-theme accent the user picked in the stock
// appearance settings.
public func telewhiteOverriddenAccentColors(_ colors: PresentationThemeAccentColor?) -> PresentationThemeAccentColor? {
    let overrides = telewhiteAppearanceOverrides()
    guard overrides.accentColor != nil || overrides.bubbleColor != nil else {
        return colors
    }

    var accentColor = colors?.accentColor
    var bubbleColors = colors?.bubbleColors ?? []
    if let accent = overrides.accentColor {
        accentColor = accent
    }
    if let bubble = overrides.bubbleColor {
        bubbleColors = [bubble]
    }

    if var result = colors {
        result.accentColor = accentColor
        result.bubbleColors = bubbleColors
        return result
    } else {
        // No stored accent for this theme: construct a fresh one. If only the
        // bubble color is overridden, keep the `.blue` base so `colorFor`
        // still resolves to the default accent instead of `.clear`.
        let baseColor: PresentationThemeBaseColor = accentColor != nil ? .custom : .blue
        return PresentationThemeAccentColor(index: -1, baseColor: baseColor, accentColor: accentColor, bubbleColors: bubbleColors, wallpaper: nil)
    }
}
