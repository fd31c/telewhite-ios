import Foundation
import UIKit
import ComponentFlow
import ChatListTitleView
import TelegramPresentationData
import Display
import MoreHeaderButton

private func generateVpnIcon(color: UIColor) -> UIImage? {
    return generateImage(CGSize(width: 30.0, height: 30.0), contextGenerator: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2.2)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        let shieldRect = CGRect(x: 5.5, y: 4.0, width: 19.0, height: 22.0)
        context.beginPath()
        context.move(to: CGPoint(x: shieldRect.midX, y: shieldRect.minY))
        context.addCurve(to: CGPoint(x: shieldRect.maxX, y: shieldRect.minY + 5.0), control1: CGPoint(x: shieldRect.midX + 3.4, y: shieldRect.minY + 1.0), control2: CGPoint(x: shieldRect.maxX - 2.0, y: shieldRect.minY + 1.5))
        context.addLine(to: CGPoint(x: shieldRect.maxX, y: shieldRect.minY + 12.3))
        context.addCurve(to: CGPoint(x: shieldRect.midX, y: shieldRect.maxY), control1: CGPoint(x: shieldRect.maxX, y: shieldRect.minY + 18.4), control2: CGPoint(x: shieldRect.midX + 4.6, y: shieldRect.maxY - 1.4))
        context.addCurve(to: CGPoint(x: shieldRect.minX, y: shieldRect.minY + 12.3), control1: CGPoint(x: shieldRect.midX - 4.6, y: shieldRect.maxY - 1.4), control2: CGPoint(x: shieldRect.minX, y: shieldRect.minY + 18.4))
        context.addLine(to: CGPoint(x: shieldRect.minX, y: shieldRect.minY + 5.0))
        context.addCurve(to: CGPoint(x: shieldRect.midX, y: shieldRect.minY), control1: CGPoint(x: shieldRect.minX + 2.0, y: shieldRect.minY + 1.5), control2: CGPoint(x: shieldRect.midX - 3.4, y: shieldRect.minY + 1.0))
        context.closePath()
        context.strokePath()

        context.setLineWidth(2.0)
        context.beginPath()
        context.move(to: CGPoint(x: 10.1, y: 16.7))
        context.addLine(to: CGPoint(x: 13.0, y: 19.7))
        context.addLine(to: CGPoint(x: 20.1, y: 11.6))
        context.strokePath()
    })
}

public final class NavigationButtonComponentEnvironment: Equatable {
    public let theme: PresentationTheme
    
    public init(theme: PresentationTheme) {
        self.theme = theme
    }
    
    public static func ==(lhs: NavigationButtonComponentEnvironment, rhs: NavigationButtonComponentEnvironment) -> Bool {
        if lhs.theme != rhs.theme {
            return false
        }
        return true
    }
}

public final class NavigationButtonComponent: Component {
    public typealias EnvironmentType = NavigationButtonComponentEnvironment
    
    public enum Content: Equatable {
        case text(title: String, isBold: Bool)
        case more
        case icon(imageName: String)
        case vpn
        case proxy(status: ChatTitleProxyStatus)
    }
    
    public let content: Content
    public let pressed: (UIView) -> Void
    public let contextAction: ((UIView, ContextGesture?) -> Void)?
    
    public init(
        content: Content,
        pressed: @escaping (UIView) -> Void,
        contextAction: ((UIView, ContextGesture?) -> Void)? = nil
    ) {
        self.content = content
        self.pressed = pressed
        self.contextAction = contextAction
    }
    
    public static func ==(lhs: NavigationButtonComponent, rhs: NavigationButtonComponent) -> Bool {
        if lhs.content != rhs.content {
            return false
        }
        return true
    }
    
    public final class View: HighlightTrackingButton {
        private var textView: ImmediateTextView?
        
        private var iconView: UIImageView?
        private var iconImageName: String?
        
        private var proxyNode: ChatTitleProxyNode?
        
        private var moreButton: MoreHeaderButton?
        
        private var component: NavigationButtonComponent?
        private var theme: PresentationTheme?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.addTarget(self, action: #selector(self.pressed), for: .touchUpInside)
            
            self.highligthedChanged = { [weak self] highlighted in
                guard let self else {
                    return
                }
                if highlighted {
                    self.textView?.alpha = 0.6
                    self.proxyNode?.alpha = 0.6
                    self.iconView?.alpha = 0.6
                } else {
                    self.textView?.alpha = 1.0
                    self.textView?.layer.animateAlpha(from: 0.6, to: 1.0, duration: 0.2)
                    
                    self.proxyNode?.alpha = 1.0
                    self.proxyNode?.layer.animateAlpha(from: 0.6, to: 1.0, duration: 0.2)
                    
                    self.iconView?.alpha = 1.0
                    self.iconView?.layer.animateAlpha(from: 0.6, to: 1.0, duration: 0.2)
                }
            }
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func pressed() {
            self.component?.pressed(self)
        }
        
        func update(component: NavigationButtonComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<NavigationButtonComponentEnvironment>, transition: ComponentTransition) -> CGSize {
            self.component = component
            
            let theme = environment[NavigationButtonComponentEnvironment.self].value.theme
            var themeUpdated = false
            if self.theme !== theme {
                self.theme = theme
                themeUpdated = true
            }
            
            var textString: NSAttributedString?
            var imageName: String?
            var proxyStatus: ChatTitleProxyStatus?
            var isMore: Bool = false
            
            switch component.content {
            case let .text(title, isBold):
                if title == "___done" {
                    imageName = "Navigation/Done"
                } else {
                    textString = NSAttributedString(string: title, font: isBold ? Font.bold(17.0) : Font.medium(17.0), textColor: theme.chat.inputPanel.panelControlColor)
                }
            case .more:
                isMore = true
            case let .icon(imageNameValue):
                imageName = imageNameValue
            case .vpn:
                imageName = "__telewhite_vpn"
            case let .proxy(status):
                proxyStatus = status
            }
            
            var size = CGSize(width: 0.0, height: availableSize.height)
            
            if let textString = textString {
                let textView: ImmediateTextView
                if let current = self.textView {
                    textView = current
                } else {
                    textView = ImmediateTextView()
                    textView.isUserInteractionEnabled = false
                    self.textView = textView
                    self.addSubview(textView)
                }
                
                textView.attributedText = textString
                let textSize = textView.updateLayout(availableSize)
                let textInset: CGFloat = 12.0
                size.width = max(44.0, textSize.width + textInset * 2.0)
                
                textView.frame = CGRect(origin: CGPoint(x: floor((size.width - textSize.width) / 2.0), y: floor((availableSize.height - textSize.height) / 2.0)), size: textSize)
            } else if let textView = self.textView {
                self.textView = nil
                textView.removeFromSuperview()
            }
            
            if let imageName = imageName {
                let iconView: UIImageView
                if let current = self.iconView {
                    iconView = current
                } else {
                    iconView = UIImageView()
                    iconView.isUserInteractionEnabled = false
                    self.iconView = iconView
                    self.addSubview(iconView)
                }
                if self.iconImageName != imageName || themeUpdated {
                    self.iconImageName = imageName
                    if imageName == "__telewhite_vpn" {
                        iconView.image = generateVpnIcon(color: theme.chat.inputPanel.panelControlColor)
                    } else {
                        iconView.image = generateTintedImage(image: UIImage(bundleImageName: imageName), color: theme.chat.inputPanel.panelControlColor)
                    }
                }
                
                if let iconSize = iconView.image?.size {
                    size.width = 44.0
                    
                    iconView.frame = CGRect(origin: CGPoint(x: floor((size.width - iconSize.width) / 2.0), y: floor((availableSize.height - iconSize.height) / 2.0)), size: iconSize)
                }
            } else if let iconView = self.iconView {
                self.iconView = nil
                iconView.removeFromSuperview()
                self.iconImageName = nil
            }
            
            if let proxyStatus = proxyStatus {
                let proxyNode: ChatTitleProxyNode
                if let current = self.proxyNode {
                    proxyNode = current
                } else {
                    proxyNode = ChatTitleProxyNode(theme: theme)
                    proxyNode.isUserInteractionEnabled = false
                    self.proxyNode = proxyNode
                    self.addSubnode(proxyNode)
                }
                
                let proxySize = CGSize(width: 30.0, height: 30.0)
                size.width = 44.0
                
                proxyNode.theme = theme
                proxyNode.status = proxyStatus
                
                proxyNode.frame = CGRect(origin: CGPoint(x: floor((size.width - proxySize.width) / 2.0), y: floor((availableSize.height - proxySize.height) / 2.0)), size: proxySize)
            } else if let proxyNode = self.proxyNode {
                self.proxyNode = nil
                proxyNode.removeFromSupernode()
            }
            
            if isMore {
                let moreButton: MoreHeaderButton
                if let current = self.moreButton, !themeUpdated {
                    moreButton = current
                } else {
                    if let moreButton = self.moreButton {
                        moreButton.removeFromSupernode()
                        self.moreButton = nil
                    }
                    
                    moreButton = MoreHeaderButton(color: theme.chat.inputPanel.panelControlColor)
                    moreButton.isUserInteractionEnabled = true
                    moreButton.setContent(.more(MoreHeaderButton.optionsCircleImage(color: theme.chat.inputPanel.panelControlColor)))
                    moreButton.onPressed = { [weak self] in
                        guard let self, let component = self.component else {
                            return
                        }
                        self.moreButton?.play()
                        component.pressed(self)
                    }
                    moreButton.contextAction = { [weak self] sourceNode, gesture in
                        guard let self, let component = self.component else {
                            return
                        }
                        self.moreButton?.play()
                        component.contextAction?(self, gesture)
                    }
                    self.moreButton = moreButton
                    self.addSubnode(moreButton)
                }
                
                let buttonSize = CGSize(width: 44.0, height: 44.0)
                size.width = 44.0
                
                moreButton.setContent(.more(MoreHeaderButton.optionsCircleImage(color: theme.rootController.navigationBar.buttonColor)))
                
                moreButton.frame = CGRect(origin: CGPoint(x: floor((size.width - buttonSize.width) / 2.0), y: floor((size.height - buttonSize.height) / 2.0)), size: buttonSize)
            } else if let moreButton = self.moreButton {
                self.moreButton = nil
                moreButton.removeFromSupernode()
            }
            
            return size
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<NavigationButtonComponentEnvironment>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
