import Foundation
import Postbox

public final class TelewhitePreviousTextMessageAttribute: Equatable, MessageAttribute {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    required public init(decoder: PostboxDecoder) {
        self.text = decoder.decodeStringForKey("t", orElse: "")
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeString(self.text, forKey: "t")
    }

    public static func ==(lhs: TelewhitePreviousTextMessageAttribute, rhs: TelewhitePreviousTextMessageAttribute) -> Bool {
        return lhs.text == rhs.text
    }
}
