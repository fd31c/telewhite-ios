import Foundation
import SwiftSignalKit
import Postbox
import TelegramApi


public enum NotificationTokenType {
    case aps(encrypt: Bool)
    case voip
}

func _internal_unregisterNotificationToken(account: Account, token: Data, type: NotificationTokenType, otherAccountUserIds: [PeerId.Id]) -> Signal<Never, NoError> {
    let mappedType: Int32
    switch type {
        case .aps:
            mappedType = 1
        case .voip:
            mappedType = 9
    }
    return account.network.request(Api.functions.account.unregisterDevice(tokenType: mappedType, token: hexString(token), otherUids: otherAccountUserIds.map({ $0._internalGetInt64Value() })))
    |> retryRequest
    |> ignoreValues
}

func _internal_registerNotificationToken(account: Account, token: Data, type: NotificationTokenType, sandbox: Bool, otherAccountUserIds: [PeerId.Id], excludeMutedChats: Bool) -> Signal<Bool, NoError> {
    return masterNotificationsKey(account: account, ignoreDisabled: false)
    |> mapToSignal { masterKey -> Signal<Bool, NoError> in
        let mappedType: Int32
        var keyData = Data()
        switch type {
            case let .aps(encrypt):
                mappedType = 1
                if encrypt {
                    keyData = masterKey.data
                }
            case .voip:
                mappedType = 9
                keyData = masterKey.data
        }
        var flags: Int32 = 0
        if excludeMutedChats {
            flags |= 1 << 0
        }
        return account.network.request(Api.functions.account.registerDevice(flags: flags, tokenType: mappedType, token: hexString(token), appSandbox: sandbox ? .boolTrue : .boolFalse, secret: Buffer(data: keyData), otherUids: otherAccountUserIds.map({ $0._internalGetInt64Value() })))
        |> map { _ -> Bool in
            if mappedType == 1 {
                telewhiteRecordRegisterDeviceResult("OK", token: token)
            }
            return true
        }
        |> `catch` { error -> Signal<Bool, NoError> in
            if mappedType == 1 {
                telewhiteRecordRegisterDeviceResult("ERROR: \(error.errorDescription ?? "unknown")", token: token)
            }
            if error.errorDescription == "TOKEN_WAS_INVALIDATED" {
                return .single(false)
            } else {
                return .single(true)
            }
        }
    }
}

// Telewhite: expose the actual server response of account.registerDevice for the
// APNs token so the Developer screen can confirm the token really reached Telegram.
private func telewhiteRecordRegisterDeviceResult(_ result: String, token: Data) {
    let tokenPrefix = hexString(token).prefix(8)
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    UserDefaults.standard.set("\(result) [\(tokenPrefix)…] @ \(formatter.string(from: Date()))", forKey: "telewhite.push.registerResult")
}
