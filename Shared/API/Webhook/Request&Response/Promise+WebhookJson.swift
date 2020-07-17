import Foundation
import Sodium
import PromiseKit

enum WebhookJsonParseError: Error, Equatable {
    case empty
    case base64
    case missingKey
    case decrypt
}

extension Promise where T == Data? {
    func webhookJson(
        on queue: DispatchQueue? = nil,
        statusCode: Int? = nil,
        sodium: Sodium = Sodium(),
        secretGetter: @escaping () -> String? = { Current.settingsStore.connectionInfo?.webhookSecret },
        options: JSONSerialization.ReadingOptions = [.allowFragments]
    ) -> Promise<Any> {
        return then { optionalData -> Promise<Any> in
            if let data = optionalData {
                return Promise<Data>.value(data).definitelyWebhookJson(
                    on: queue,
                    statusCode: statusCode,
                    sodium: sodium,
                    secretGetter: secretGetter,
                    options: options
                )
            } else {
                throw WebhookJsonParseError.empty
            }
        }
    }
}

extension Promise where T == Data {
    func webhookJson(
        on queue: DispatchQueue? = nil,
        statusCode: Int? = nil,
        sodium: Sodium = Sodium(),
        secretGetter: @escaping () -> String? = { Current.settingsStore.connectionInfo?.webhookSecret },
        options: JSONSerialization.ReadingOptions = [.allowFragments]
    ) -> Promise<Any> {
        definitelyWebhookJson(
            on: queue,
            statusCode: statusCode,
            sodium: sodium,
            secretGetter: secretGetter,
            options: options
        )
    }

    // Exists so that the Data? -> Data one doesn't accidentally refer to itself
    // swiftlint:disable:next cyclomatic_complexity
    fileprivate func definitelyWebhookJson(
        on queue: DispatchQueue?,
        statusCode: Int?,
        sodium: Sodium,
        secretGetter: @escaping () -> String?,
        options: JSONSerialization.ReadingOptions = [.allowFragments]
    ) -> Promise<Any> {
        switch statusCode ?? -1 {
        case 204, 205:
            return .value(())
        case 404:
            // mobile_app not loaded
            return .init(error: HomeAssistantAPI.APIError.mobileAppComponentNotLoaded)
        case 410:
            // config entry removed
            return .init(error: HomeAssistantAPI.APIError.webhookGone)
        case 400...:
            // some other error occurred that we don't want to parse as success
            return .init(error: HomeAssistantAPI.APIError.unacceptableStatusCode(statusCode ?? -1))
        default:
            break
        }

        return map(on: queue) { data -> Any in
            if data.isEmpty {
                return ()
            } else {
                return try JSONSerialization.jsonObject(with: data, options: options)
            }
        }.map { object in
            guard let dictionary = object as? [String: Any],
                let encoded = dictionary["encrypted_data"] as? String
            else {
                return object
            }

            guard let secret = secretGetter() else {
                throw WebhookJsonParseError.missingKey
            }

            guard let decoded = sodium.utils.base642bin(encoded, variant: .ORIGINAL, ignore: nil) else {
                throw WebhookJsonParseError.base64
            }

            guard let decrypted = sodium.secretBox.open(
                nonceAndAuthenticatedCipherText: decoded,
                secretKey: secret.bytes
            ) else {
                throw WebhookJsonParseError.decrypt
            }

            if decrypted.isEmpty {
                return ()
            } else {
                return try JSONSerialization.jsonObject(with: Data(decrypted), options: options)
            }
        }
    }
}
