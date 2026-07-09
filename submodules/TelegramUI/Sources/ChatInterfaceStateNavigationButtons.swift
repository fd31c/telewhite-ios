import Foundation
import UIKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import ChatPresentationInterfaceState
import ChatNavigationButton
import Display
import AsyncDisplayKit
import SettingsUI

private func telewhiteGhostModeIcon(theme: PresentationTheme, isEnabled: Bool) -> UIImage? {
    let color = theme.rootController.navigationBar.buttonColor

    return generateImage(CGSize(width: 30.0, height: 30.0), contextGenerator: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))

        // Flip to UIKit coordinates (origin top-left)
        context.translateBy(x: 0.0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        let rect = CGRect(x: 5.5, y: 4.0, width: 19.0, height: 22.0)
        let lineWidth: CGFloat = 1.8
        let minX = rect.minX
        let maxX = rect.maxX
        let midX = rect.midX
        let minY = rect.minY
        let maxY = rect.maxY
        let waveTop = maxY - 3.0

        let path = UIBezierPath()
        // Left side going up
        path.move(to: CGPoint(x: minX, y: waveTop))
        path.addLine(to: CGPoint(x: minX, y: minY + 9.5))
        // Rounded head (dome)
        path.addCurve(to: CGPoint(x: midX, y: minY), controlPoint1: CGPoint(x: minX, y: minY + 4.25), controlPoint2: CGPoint(x: minX + 4.25, y: minY))
        path.addCurve(to: CGPoint(x: maxX, y: minY + 9.5), controlPoint1: CGPoint(x: maxX - 4.25, y: minY), controlPoint2: CGPoint(x: maxX, y: minY + 4.25))
        // Right side going down
        path.addLine(to: CGPoint(x: maxX, y: waveTop))
        // Wavy bottom: 3 smooth scallops (down-up-down-up pattern)
        let segment = rect.width / 3.0
        let waveDepth: CGFloat = 2.6
        var x = maxX
        for i in 0..<3 {
            let isDown = (i % 2 == 0)
            let targetX = x - segment
            let controlY = isDown ? (waveTop + waveDepth) : (waveTop - waveDepth)
            path.addQuadCurve(to: CGPoint(x: targetX, y: waveTop), controlPoint: CGPoint(x: x - segment / 2.0, y: controlY))
            x = targetX
        }
        path.close()

        context.setLineWidth(lineWidth)
        context.setLineJoin(.round)
        context.setLineCap(.round)

        if isEnabled {
            // Filled ghost with punched-out eyes
            context.addPath(path.cgPath)
            context.setFillColor(color.cgColor)
            context.fillPath()
            context.setStrokeColor(color.cgColor)
            context.addPath(path.cgPath)
            context.strokePath()

            context.setBlendMode(.clear)
            context.fillEllipse(in: CGRect(x: midX - 4.7, y: minY + 8.0, width: 2.8, height: 4.4))
            context.fillEllipse(in: CGRect(x: midX + 1.9, y: minY + 8.0, width: 2.8, height: 4.4))
            context.setBlendMode(.normal)
        } else {
            // Outlined ghost with solid eyes
            context.setStrokeColor(color.cgColor)
            context.addPath(path.cgPath)
            context.strokePath()

            context.setFillColor(color.cgColor)
            context.fillEllipse(in: CGRect(x: midX - 4.7, y: minY + 8.0, width: 2.8, height: 4.4))
            context.fillEllipse(in: CGRect(x: midX + 1.9, y: minY + 8.0, width: 2.8, height: 4.4))
        }
    })
}

private func telewhiteTranslateIcon(theme: PresentationTheme, isEnabled: Bool) -> UIImage? {
    let foregroundColor = isEnabled ? theme.list.itemAccentColor : theme.rootController.navigationBar.buttonColor
    return generateTintedImage(image: UIImage(bundleImageName: "Chat/Title Panels/Translate"), color: foregroundColor)
}

private func telewhiteOutgoingTranslationIcon(theme: PresentationTheme, isEnabled: Bool) -> UIImage? {
    let color = UIColor.white
    return generateImage(CGSize(width: 30.0, height: 30.0), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        UIGraphicsPushContext(context)
        let hanzi = NSAttributedString(string: "\u{6587}", attributes: [
            NSAttributedString.Key.font: Font.medium(12.0),
            NSAttributedString.Key.foregroundColor: color
        ])
        hanzi.draw(at: CGPoint(x: 2.0, y: 1.5))
        let latin = NSAttributedString(string: "A", attributes: [
            NSAttributedString.Key.font: Font.semibold(13.0),
            NSAttributedString.Key.foregroundColor: color
        ])
        latin.draw(at: CGPoint(x: 18.5, y: 12.5))
        UIGraphicsPopContext()
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.8)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.beginPath()
        context.move(to: CGPoint(x: 5.5, y: 24.5))
        context.addLine(to: CGPoint(x: 13.5, y: 24.5))
        context.strokePath()
        context.beginPath()
        context.move(to: CGPoint(x: 10.5, y: 21.0))
        context.addLine(to: CGPoint(x: 13.5, y: 24.5))
        context.addLine(to: CGPoint(x: 10.5, y: 28.0))
        context.strokePath()
        
        if isEnabled {
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: CGRect(x: 23.5, y: 25.0, width: 4.5, height: 4.5))
        }
    })
}

final class TelewhiteOutgoingTranslationButtonNode: HighlightableButtonNode, NavigationButtonCustomDisplayNode {
    var isHighlightable: Bool {
        return true
    }
    
    var pressed: (() -> Void)?
    var longPressed: (() -> Void)?
    
    private var longPressRecognizer: UILongPressGestureRecognizer?
    
    override init(pointerStyle: PointerStyle? = nil) {
        super.init(pointerStyle: pointerStyle)
        self.addTarget(self, action: #selector(self.tapAction), forControlEvents: .touchUpInside)
    }
    
    override func didLoad() {
        super.didLoad()
        if self.longPressRecognizer == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture(_:)))
            recognizer.minimumPressDuration = 0.35
            self.longPressRecognizer = recognizer
            self.view.addGestureRecognizer(recognizer)
        }
    }
    
    @objc private func tapAction() {
        self.pressed?()
    }
    
    @objc private func longPressGesture(_ recognizer: UILongPressGestureRecognizer) {
        if case .began = recognizer.state {
            self.longPressed?()
        }
    }
    
    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: 34.0, height: 44.0)
    }
}

func leftNavigationButtonForChatInterfaceState(_ presentationInterfaceState: ChatPresentationInterfaceState, subject: ChatControllerSubject?, strings: PresentationStrings, currentButton: ChatNavigationButton?, target: Any?, selector: Selector?) -> ChatNavigationButton? {
    if let _ = presentationInterfaceState.interfaceState.selectionState {
        if case .messageOptions = presentationInterfaceState.subject {
            return nil
        }
        if let _ = presentationInterfaceState.reportReason {
            return ChatNavigationButton(action: .spacer, buttonItem: UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil))
        }
        if case .replyThread = presentationInterfaceState.chatLocation {
            return nil
        }
        if let currentButton = currentButton, currentButton.action == .clearHistory {
            return currentButton
        } else if let peer = presentationInterfaceState.renderedPeer?.peer {
            let canClear: Bool
            var title = strings.Conversation_ClearAll
            if case .scheduledMessages = presentationInterfaceState.subject {
                canClear = true
                title = strings.ScheduledMessages_ClearAll
            } else {
                if peer is TelegramUser || peer is TelegramGroup || peer is TelegramSecretChat {
                    canClear = true
                } else if let peer = peer as? TelegramChannel, case .group = peer.info, peer.addressName == nil && presentationInterfaceState.peerGeoLocation == nil {
                    canClear = true
                } else if let peer = peer as? TelegramChannel {
                    if case .broadcast = peer.info {
                        title = strings.Conversation_ClearChannel
                    }
                    if peer.hasPermission(.changeInfo) {
                        canClear = true
                    } else {
                        canClear = false
                    }
                } else {
                    canClear = false
                }
            }

            if canClear {
                let buttonItem = UIBarButtonItem(title: strings.Conversation_ClearAll, style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = title
                return ChatNavigationButton(action: .clearHistory, buttonItem: buttonItem)
            } else {
                title = strings.Conversation_ClearCache
                let buttonItem = UIBarButtonItem(title: strings.Conversation_ClearCache, style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = title
                return ChatNavigationButton(action: .clearCache, buttonItem: buttonItem)
            }
        }
    }

    if case let .customChatContents(customChatContents) = presentationInterfaceState.subject {
        switch customChatContents.kind {
        case .hashTagSearch:
            break
        case .quickReplyMessageInput, .businessLinkSetup:
            if let currentButton = currentButton, currentButton.action == .dismiss {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(title: "___close", style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Common_Close
                return ChatNavigationButton(action: .dismiss, buttonItem: buttonItem)
            }
        }
    }

    return nil
}

func rightNavigationButtonForChatInterfaceState(context: AccountContext, presentationInterfaceState: ChatPresentationInterfaceState, strings: PresentationStrings, currentButton: ChatNavigationButton?, target: Any?, selector: Selector?, chatInfoNavigationButton: ChatNavigationButton?, moreInfoNavigationButton: ChatNavigationButton?) -> ChatNavigationButton? {
    if case .standard(.previewing) = presentationInterfaceState.mode {
        return nil
    }
    var hasMessages = false
    if let chatHistoryState = presentationInterfaceState.chatHistoryState {
        if case .loaded(false, _) = chatHistoryState {
            hasMessages = true
        }
    }

    if let _ = presentationInterfaceState.interfaceState.selectionState {
        if case .messageOptions = presentationInterfaceState.subject {
            return nil
        }
        if let currentButton = currentButton, currentButton.action == .cancelMessageSelection {
            return currentButton
        } else {
            let buttonItem = UIBarButtonItem(title: "___done", style: .plain, target: target, action: selector)
            buttonItem.accessibilityLabel = strings.Common_Cancel
            return ChatNavigationButton(action: .cancelMessageSelection, buttonItem: buttonItem)
        }
    }

    if case let .replyThread(message) = presentationInterfaceState.chatLocation, message.peerId == context.account.peerId {
        let isTags = presentationInterfaceState.hasSearchTags

        if case .search(isTags) = currentButton?.action {
            return currentButton
        } else {
            let buttonItem = UIBarButtonItem(image: isTags ? PresentationResourcesRootController.navigationCompactTagsSearchIcon(presentationInterfaceState.theme) : PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
            buttonItem.accessibilityLabel = strings.Conversation_Search
            return ChatNavigationButton(action: .search(hasTags: isTags), buttonItem: buttonItem)
        }
    }

    if let channel = presentationInterfaceState.renderedPeer?.peer as? TelegramChannel, channel.isMonoForum, case .peer = presentationInterfaceState.chatLocation {
        let displaySearch = hasMessages

        if displaySearch {
            if case .search(false) = currentButton?.action {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Conversation_Search
                return ChatNavigationButton(action: .search(hasTags: false), buttonItem: buttonItem)
            }
        } else {
            return nil
        }
    }

    if let user = presentationInterfaceState.renderedPeer?.peer as? TelegramUser, user.isForum, case .peer = presentationInterfaceState.chatLocation {
        let displaySearch = hasMessages

        if displaySearch {
            if case .search(false) = currentButton?.action {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Conversation_Search
                return ChatNavigationButton(action: .search(hasTags: false), buttonItem: buttonItem)
            }
        } else {
            return nil
        }
    }

    if let channel = presentationInterfaceState.renderedPeer?.peer as? TelegramChannel, channel.isForumOrMonoForum, let moreInfoNavigationButton = moreInfoNavigationButton {
        if case .replyThread = presentationInterfaceState.chatLocation {
        } else {
            if case .pinnedMessages = presentationInterfaceState.subject {
            } else {
                return moreInfoNavigationButton
            }
        }
    }

    if let user = presentationInterfaceState.renderedPeer?.peer as? TelegramUser, let botInfo = user.botInfo, botInfo.flags.contains(.hasForum), let moreInfoNavigationButton = moreInfoNavigationButton {
        if case .pinnedMessages = presentationInterfaceState.subject {
        } else {
            return moreInfoNavigationButton
        }
    }

    if case .messageOptions = presentationInterfaceState.subject {
        return nil
    }

    if case .pinnedMessages = presentationInterfaceState.subject {
        return nil
    }

    if case let .customChatContents(customChatContents) = presentationInterfaceState.subject {
        switch customChatContents.kind {
        case .hashTagSearch:
            return nil
        case let .quickReplyMessageInput(_, shortcutType):
            switch shortcutType {
            case .generic:
                if let currentButton = currentButton, currentButton.action == .edit {
                    return currentButton
                } else {
                    let buttonItem = UIBarButtonItem(title: strings.Common_Edit, style: .plain, target: target, action: selector)
                    buttonItem.accessibilityLabel = strings.Common_Done
                    return ChatNavigationButton(action: .edit, buttonItem: buttonItem)
                }
            case .greeting, .away:
                return nil
            }
        case .businessLinkSetup:
            if let currentButton = currentButton, currentButton.action == .edit {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(title: strings.Common_Edit, style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Common_Done
                return ChatNavigationButton(action: .edit, buttonItem: buttonItem)
            }
        }
    }

    if case .replyThread = presentationInterfaceState.chatLocation {
        if let channel = presentationInterfaceState.renderedPeer?.peer as? TelegramChannel, channel.isForumOrMonoForum {
        } else if hasMessages {
            if case .search = currentButton?.action {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = strings.Conversation_Search
                return ChatNavigationButton(action: .search(hasTags: false), buttonItem: buttonItem)
            }
        } else {
            if case .spacer = currentButton?.action {
                return currentButton
            } else {
                return ChatNavigationButton(action: .spacer, buttonItem: UIBarButtonItem(title: "", style: .plain, target: target, action: selector))
            }
        }
    }
    if case let .peer(peerId) = presentationInterfaceState.chatLocation {
        if peerId.isRepliesOrVerificationCodes {
            if hasMessages {
                if case .search = currentButton?.action {
                    return currentButton
                } else {
                    let buttonItem = UIBarButtonItem(image: PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                    buttonItem.accessibilityLabel = strings.Conversation_Search
                    return ChatNavigationButton(action: .search(hasTags: false), buttonItem: buttonItem)
                }
            } else {
                if case .spacer = currentButton?.action {
                    return currentButton
                } else {
                    return ChatNavigationButton(action: .spacer, buttonItem: UIBarButtonItem(title: "", style: .plain, target: target, action: selector))
                }
            }
        }
    }

    if case .scheduledMessages = presentationInterfaceState.subject {
        return chatInfoNavigationButton
    }

    if case .standard(.previewing) = presentationInterfaceState.mode {
        return chatInfoNavigationButton
    } else if let peerId = presentationInterfaceState.chatLocation.peerId {
        if presentationInterfaceState.accountPeerId == peerId {
            var displaySearchButton = false

            if case .replyThread = presentationInterfaceState.chatLocation {
                displaySearchButton = true
            }

            if case .scheduledMessages = presentationInterfaceState.subject {
                return chatInfoNavigationButton
            } else {
                displaySearchButton = true
            }

            if displaySearchButton {
                let isTags = presentationInterfaceState.hasSearchTags

                if case .search(isTags) = currentButton?.action {
                    return currentButton
                } else {
                    let buttonItem = UIBarButtonItem(image: isTags ? PresentationResourcesRootController.navigationCompactTagsSearchIcon(presentationInterfaceState.theme) : PresentationResourcesRootController.navigationCompactSearchIcon(presentationInterfaceState.theme), style: .plain, target: target, action: selector)
                    buttonItem.accessibilityLabel = strings.Conversation_Search
                    return ChatNavigationButton(action: .search(hasTags: isTags), buttonItem: buttonItem)
                }
            }
        }
    }

    return chatInfoNavigationButton
}

func secondaryRightNavigationButtonForChatInterfaceState(context: AccountContext, presentationInterfaceState: ChatPresentationInterfaceState, strings: PresentationStrings, currentButton: ChatNavigationButton?, target: Any?, selector: Selector?, chatInfoNavigationButton: ChatNavigationButton?, moreInfoNavigationButton: ChatNavigationButton?) -> ChatNavigationButton? {
    if presentationInterfaceState.interfaceState.selectionState != nil {
        return nil
    }

    if case .standard(.default) = presentationInterfaceState.mode, presentationInterfaceState.subject == nil, let user = presentationInterfaceState.renderedPeer?.chatMainPeer as? TelegramUser, user.id != context.account.peerId, !user.id.isSecretChat, user.isGenericUser {
        let settings = TelewhiteModsSettings.current
        if settings.ghostChatButtonEnabled {
            let isEnabled = settings.isGhostEnabled(for: user.id)
            let rawPeerId = user.id.toInt64()
            if currentButton?.action == .toggleGhostMode(peerId: rawPeerId, isEnabled: isEnabled) {
                return currentButton
            } else {
                let buttonItem = UIBarButtonItem(image: telewhiteGhostModeIcon(theme: presentationInterfaceState.theme, isEnabled: isEnabled), style: .plain, target: target, action: selector)
                buttonItem.accessibilityLabel = isEnabled ? "Disable Ghost Mode for this chat" : "Enable Ghost Mode for this chat"
                return ChatNavigationButton(action: .toggleGhostMode(peerId: rawPeerId, isEnabled: isEnabled), buttonItem: buttonItem)
            }
        }
    }

    if case .standard(.default) = presentationInterfaceState.mode {
        if case .peer(context.account.peerId) = presentationInterfaceState.chatLocation, presentationInterfaceState.subject != .scheduledMessages, presentationInterfaceState.hasSavedChats {
            return moreInfoNavigationButton
        }
    }

    return nil
}

func tertiaryRightNavigationButtonForChatInterfaceState(context: AccountContext, presentationInterfaceState: ChatPresentationInterfaceState, currentButton: ChatNavigationButton?, target: Any?, selector: Selector?) -> ChatNavigationButton? {
    if presentationInterfaceState.interfaceState.selectionState != nil {
        return nil
    }
    guard case .standard(.default) = presentationInterfaceState.mode, presentationInterfaceState.subject == nil else {
        return nil
    }
    guard let translationState = presentationInterfaceState.translationState else {
        return nil
    }
    if translationState.fromLang.lowercased() != "en" {
        return nil
    }

    let isEnabled = translationState.isEnabled && translationState.toLang.lowercased() == "ru"
    if currentButton?.action == .toggleTranslation(isEnabled: isEnabled) {
        return currentButton
    } else {
        let buttonItem = UIBarButtonItem(image: telewhiteTranslateIcon(theme: presentationInterfaceState.theme, isEnabled: isEnabled), style: .plain, target: target, action: selector)
        buttonItem.accessibilityLabel = isEnabled ? "Show original text" : "Translate English to Russian"
        return ChatNavigationButton(action: .toggleTranslation(isEnabled: isEnabled), buttonItem: buttonItem)
    }
}

func quaternaryRightNavigationButtonForChatInterfaceState(context: AccountContext, presentationInterfaceState: ChatPresentationInterfaceState, currentButton: ChatNavigationButton?, target: Any?, selector: Selector?, longPressSelector: Selector?) -> ChatNavigationButton? {
    if presentationInterfaceState.interfaceState.selectionState != nil {
        return nil
    }
    guard case .standard(.default) = presentationInterfaceState.mode, presentationInterfaceState.subject == nil else {
        return nil
    }
    guard let user = presentationInterfaceState.renderedPeer?.chatMainPeer as? TelegramUser, user.id != context.account.peerId, !user.id.isSecretChat, user.isGenericUser else {
        return nil
    }
    let settings = TelewhiteModsSettings.current
    guard settings.outgoingTranslateButtonEnabled else {
        return nil
    }
    
    let isEnabled = settings.isOutgoingTranslationEnabled(for: user.id)
    let rawPeerId = user.id.toInt64()
    
    if currentButton?.action == .toggleOutgoingTranslation(peerId: rawPeerId, isEnabled: isEnabled) {
        return currentButton
    } else {
        let buttonNode = TelewhiteOutgoingTranslationButtonNode()
        buttonNode.setImage(telewhiteOutgoingTranslationIcon(theme: presentationInterfaceState.theme, isEnabled: isEnabled), for: [])
        guard let buttonItem = UIBarButtonItem(customDisplayNode: buttonNode) else {
            return nil
        }
        buttonItem.target = target as AnyObject?
        buttonItem.action = selector
        buttonNode.pressed = { [weak buttonItem] in
            buttonItem?.performActionOnTarget()
        }
        if let targetObject = target as? NSObject {
            buttonNode.longPressed = { [weak targetObject] in
                if let targetObject, let longPressSelector {
                    let _ = targetObject.perform(longPressSelector)
                }
            }
        }
        buttonItem.accessibilityLabel = isEnabled ? "Disable outgoing message translation for this chat" : "Enable outgoing message translation for this chat"
        return ChatNavigationButton(action: .toggleOutgoingTranslation(peerId: rawPeerId, isEnabled: isEnabled), buttonItem: buttonItem)
    }
}
