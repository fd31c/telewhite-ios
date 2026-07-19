import Foundation
import Postbox

public struct TelewhiteEditHistoryEntry: PostboxCoding, Equatable {
    public let text: String
    public let timestamp: Int32

    public init(text: String, timestamp: Int32) {
        self.text = text
        self.timestamp = timestamp
    }

    public init(decoder: PostboxDecoder) {
        self.text = decoder.decodeStringForKey("x", orElse: "")
        self.timestamp = decoder.decodeInt32ForKey("t", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeString(self.text, forKey: "x")
        encoder.encodeInt32(self.timestamp, forKey: "t")
    }

    public static func ==(lhs: TelewhiteEditHistoryEntry, rhs: TelewhiteEditHistoryEntry) -> Bool {
        return lhs.text == rhs.text && lhs.timestamp == rhs.timestamp
    }
}

public final class TelewhiteEditHistoryAttribute: Equatable, MessageAttribute {
    public let versions: [TelewhiteEditHistoryEntry]

    public init(versions: [TelewhiteEditHistoryEntry]) {
        self.versions = versions
    }

    required public init(decoder: PostboxDecoder) {
        self.versions = decoder.decodeObjectArrayWithDecoderForKey("v")
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeObjectArray(self.versions, forKey: "v")
    }

    public func withAppendedVersion(_ entry: TelewhiteEditHistoryEntry, limit: Int = 20) -> TelewhiteEditHistoryAttribute {
        var updated = self.versions
        updated.append(entry)
        if updated.count > limit {
            updated.removeFirst(updated.count - limit)
        }
        return TelewhiteEditHistoryAttribute(versions: updated)
    }

    public static func ==(lhs: TelewhiteEditHistoryAttribute, rhs: TelewhiteEditHistoryAttribute) -> Bool {
        return lhs.versions == rhs.versions
    }
}
