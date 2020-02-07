//
//  Utils.swift
//  infobip-mobile-messaging-react-native-plugin
//
//  Created by Olga Koroleva on 04.02.2020.
//

import Foundation
import MobileMessaging

extension MTMessage {
    override func dictionary() -> [String: Any] {
        var result = [String: Any]()
        result["messageId"] = messageId
        result["body"] = text
        result["sound"] = sound
        result["silent"] = isSilent
        result["receivedTimestamp"] = UInt64(sendDateTime * 1000)
        result["customPayload"] = customPayload
        result["originalPayload"] = originalPayload
        result["contentUrl"] = contentUrl
        result["seen"] = seenStatus != .NotSeen
        result["seenDate"] = seenDate?.timeIntervalSince1970
        result["geo"] = isGeoMessage
        return result
    }

    var isGeoMessage: Bool {
        let geoAreasDicts = (originalPayload["internalData"] as? [String: Any])?["geo"] as? [[String: Any]]
        return geoAreasDicts != nil
    }
}

extension BaseMessage {
    class func createFrom(dictionary: [String: Any]) -> BaseMessage? {
        guard let messageId = dictionary["messageId"] as? String,
            let originalPayload = dictionary["originalPayload"] as? StringKeyPayload else
        {
            return nil
        }

        return BaseMessage(messageId: messageId, direction: MessageDirection.MT, originalPayload: originalPayload, deliveryMethod: .undefined)
    }

    func dictionary() -> [String: Any] {
        var result = [String: Any]()
        result["messageId"] = messageId
        result["customPayload"] = originalPayload["customPayload"]
        result["originalPayload"] = originalPayload

        if let aps = originalPayload["aps"] as? StringKeyPayload {
            result["body"] = aps["body"]
            result["sound"] = aps["sound"]
        }

        if let internalData = originalPayload["internalData"] as? StringKeyPayload,
            let _ = internalData["silent"] as? StringKeyPayload {
            result["silent"] = true
        } else if let silent = originalPayload["silent"] as? Bool {
            result["silent"] = silent
        }

        return result
    }
}

//extension MMRegion {
//    func dictionary() -> [String: Any] {
//        var areaCenter = [String: Any]()
//        areaCenter["lat"] = center.latitude
//        areaCenter["lon"] = center.longitude
//
//        var area = [String: Any]()
//        area["id"] = identifier
//        area["center"] = areaCenter
//        area["radius"] = radius
//        area["title"] = title
//
//        var result = [String: Any]()
//        result["area"] = area
//        return result
//    }
//}

extension Optional {
    func unwrap<T>(orDefault fallbackValue: T) -> T {
        switch self {
        case .some(let val as T):
            return val
        default:
            return fallbackValue
        }
    }
}