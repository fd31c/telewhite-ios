import Foundation
import UIKit
import SwiftSignalKit
import Display
import AsyncDisplayKit
import TelegramCore
import SafariServices
import MobileCoreServices
import Intents
import LegacyComponents
import TelegramPresentationData
import TelegramUIPreferences
import DeviceAccess
import TextFormat
import TelegramBaseController
import AccountContext
import TelegramStringFormatting
import OverlayStatusController
import DeviceLocationManager
import UrlEscaping
import ContextUI
import AlertUI
import PresentationDataUtils
import UndoUI
import TelegramCallsUI
import TelegramNotices
import GameUI
import ScreenCaptureDetection
import GalleryUI
import OpenInExternalAppUI
import LegacyUI
import InstantPageUI
import LocationUI
import BotPaymentsUI
import DeleteChatPeerActionSheetItem
import HashtagSearchUI
import LegacyMediaPickerUI
import Emoji
import PeerAvatarGalleryUI
import PeerInfoUI
import RaiseToListen
import UrlHandling
import AvatarNode
import AppBundle
import LocalizedPeerData
import PhoneNumberFormat
import SettingsUI
import UrlWhitelist
import TelegramIntents
import TooltipUI
import StatisticsUI
import MediaResources
import GalleryData
import ChatInterfaceState
import InviteLinksUI
import Markdown
import TelegramPermissionsUI
import Speak
import TranslateUI
import UniversalMediaPlayer
import WallpaperBackgroundNode
import ChatListUI
import CalendarMessageScreen
import ReactionSelectionNode
import ReactionListContextMenuContent
import AttachmentUI
import AttachmentTextInputPanelNode
import MediaPickerUI
import ChatPresentationInterfaceState
import Pasteboard
import ChatSendMessageActionUI
import ChatTextLinkEditUI
import WebUI
import PremiumUI
import ImageTransparency
import StickerPackPreviewUI
import TextNodeWithEntities
import EntityKeyboard
import ChatTitleView
import EmojiStatusComponent
import ChatTimerScreen
import MediaPasteboardUI
import ChatListHeaderComponent
import ChatControllerInteraction
import FeaturedStickersScreen
import ChatEntityKeyboardInputNode
import StorageUsageScreen
import AvatarEditorScreen
import ChatScheduleTimeController
import ICloudResources
import StoryContainerScreen
import MoreHeaderButton
import VolumeButtons
import ChatAvatarNavigationNode
import ChatContextQuery
import PeerReportScreen
import PeerSelectionController
import SaveToCameraRoll
import ChatMessageDateAndStatusNode
import ReplyAccessoryPanelNode
import TextSelectionNode
import ChatMessagePollBubbleContentNode
import ChatMessageItem
import ChatMessageItemImpl
import ChatMessageItemView
import ChatMessageItemCommon
import ChatMessageAnimatedStickerItemNode
import ChatMessageBubbleItemNode
import ChatNavigationButton
import WebsiteType
import PeerInfoScreen
import MediaEditorScreen
import WallpaperGalleryScreen
import WallpaperGridScreen
import VideoMessageCameraScreen
import TopMessageReactions
import AudioWaveform
import PeerNameColorScreen
import ChatEmptyNode
import ChatMediaInputStickerGridItem

extension ChatControllerImpl {
    func openViewOnceMediaMessage(_ message: EngineMessage) {
        let telewhiteAllowsOneTimeMedia = TelewhiteModsSettings.current.oneTimeMediaUnlimited || TelewhiteModsSettings.current.downloadOneTimeMedia || TelewhiteModsSettings.current.screenshotProtectionBypass
        if !telewhiteAllowsOneTimeMedia && self.screenCaptureManager?.isRecordingActive == true {
            let controller = textAlertController(context: self.context, updatedPresentationData: self.updatedPresentationData, title: nil, text: self.presentationData.strings.Chat_PlayOnceMesasge_DisableScreenCapture, actions: [TextAlertAction(type: .defaultAction, title: self.presentationData.strings.Common_OK, action: {
            })])
            self.present(controller, in: .window(.root))
            return
        }
        
        let isIncoming = message.effectivelyIncoming(self.context.account.peerId)
        
        var oneTimeMediaActions: [ContextMenuItem] = []
        if TelewhiteModsSettings.current.downloadOneTimeMedia {
            let rawMessage = message._asMessage()
            if let image = rawMessage.effectiveMedia.first(where: { $0 is TelegramMediaImage }) as? TelegramMediaImage {
                let mediaReference = ImageMediaReference.message(message: MessageReference(rawMessage), media: image).abstract
                oneTimeMediaActions.append(.action(ContextMenuActionItem(text: self.presentationData.strings.Gallery_SaveImage, icon: { theme in
                    return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Save"), color: theme.contextMenu.primaryColor)
                }, action: { [weak self] _, f in
                    guard let self else {
                        f(.default)
                        return
                    }
                    let _ = (saveToCameraRoll(context: self.context, userLocation: .peer(message.id.peerId), mediaReference: mediaReference)
                    |> deliverOnMainQueue).startStandalone(completed: { [weak self] in
                        guard let self else {
                            return
                        }
                        Queue.mainQueue().after(0.2) {
                            let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
                            self.present(UndoOverlayController(presentationData: presentationData, content: .mediaSaved(text: presentationData.strings.Gallery_ImageSaved), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return true }), in: .current)
                        }
                    })
                    f(.default)
                })))
            } else if let file = rawMessage.effectiveMedia.first(where: { ($0 as? TelegramMediaFile)?.isVideo == true }) as? TelegramMediaFile {
                let mediaReference = FileMediaReference.message(message: MessageReference(rawMessage), media: file).abstract
                oneTimeMediaActions.append(.action(ContextMenuActionItem(text: self.presentationData.strings.Gallery_SaveVideo, icon: { theme in
                    return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Save"), color: theme.contextMenu.primaryColor)
                }, action: { [weak self] _, f in
                    guard let self else {
                        f(.default)
                        return
                    }
                    let _ = (saveToCameraRoll(context: self.context, userLocation: .peer(message.id.peerId), mediaReference: mediaReference)
                    |> deliverOnMainQueue).startStandalone(completed: { [weak self] in
                        guard let self else {
                            return
                        }
                        Queue.mainQueue().after(0.2) {
                            let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
                            self.present(UndoOverlayController(presentationData: presentationData, content: .mediaSaved(text: presentationData.strings.Gallery_VideoSaved), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return true }), in: .current)
                        }
                    })
                    f(.default)
                })))
            } else if let file = rawMessage.effectiveMedia.first(where: { $0 is TelegramMediaFile }) as? TelegramMediaFile {
                let fileReference = FileMediaReference.message(message: MessageReference(rawMessage), media: file)
                oneTimeMediaActions.append(.action(ContextMenuActionItem(text: self.presentationData.strings.Conversation_SaveToFiles, icon: { theme in
                    return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Save"), color: theme.contextMenu.primaryColor)
                }, action: { [weak self] _, f in
                    guard let self else {
                        f(.default)
                        return
                    }
                    let _ = saveMediaToFiles(context: self.context, fileReference: fileReference, present: { [weak self] c, a in
                        self?.present(c, in: .window(.root), with: a)
                    })
                    f(.default)
                })))
            }
        }

        var presentImpl: ((ViewController) -> Void)?
        let configuration = ContextController.Configuration(
            sources: [
                ContextController.Source(
                    id: 0,
                    title: "",
                    source: .extracted(ChatViewOnceMessageContextExtractedContentSource(
                        context: self.context,
                        presentationData: self.presentationData,
                        chatNode: self.chatDisplayNode,
                        backgroundNode: self.chatBackgroundNode,
                        engine: self.context.engine,
                        message: message,
                        present: { c in
                            presentImpl?(c)
                        }
                    )),
                    items: .single(ContextController.Items(content: .list(oneTimeMediaActions))),
                    closeActionTitle: isIncoming && !telewhiteAllowsOneTimeMedia ? self.presentationData.strings.Chat_PlayOnceMesasgeCloseAndDelete : self.presentationData.strings.Chat_PlayOnceMesasgeClose,
                    closeAction: { [weak self] in
                        if let self {
                            self.context.sharedContext.mediaManager.setPlaylist(nil, type: .voice, control: .playback(.pause))
                        }
                    }
                )
            ], initialId: 0
        )
        
        let contextController = makeContextController(presentationData: self.presentationData, configuration: configuration)
        contextController.getOverlayViews = { [weak self] in
            guard let self else {
                return []
            }
            return [self.chatDisplayNode.navigateButtons.view]
        }
        self.currentContextController = contextController
        self.presentInGlobalOverlay(contextController)
        
        presentImpl = { [weak contextController] c in
            contextController?.present(c, in: .current)
        }
        
        let _ = self.context.sharedContext.openChatMessage(OpenChatMessageParams(context: self.context, chatLocation: nil, chatFilterTag: nil, chatLocationContextHolder: nil, message: message._asMessage(), standalone: false, reverseMessageGalleryOrder: false, navigationController: nil, dismissInput: { }, present: { _, _, _ in }, transitionNode: { _, _, _ in return nil }, addToTransitionSurface: { _ in }, openUrl: { _ in }, openPeer: { _, _ in }, callPeer: { _, _ in }, openConferenceCall: { _ in
        }, enqueueMessage: { _ in }, sendSticker: nil, sendEmoji: nil, setupTemporaryHiddenMedia: { _, _, _ in }, chatAvatarHiddenMedia: { _, _ in }, playlistLocation: .singleMessage(message.id)))
    }
}
