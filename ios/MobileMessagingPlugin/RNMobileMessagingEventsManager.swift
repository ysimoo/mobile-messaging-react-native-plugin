//
//  RNRNMobileMessagingEventsManager.swift
//  infobip-mobile-messaging-react-native-plugin
//
//  Created by Olga Koroleva on 04.02.2020.
//

import Foundation
import MobileMessaging

class RNMobileMessagingEventsManager {
    private var eventEmitter: RCTEventEmitter!
    private var hasEventListeners = false

    private let supportedNotifications: [String: String] = [
        EventName.messageReceived: MMNotificationMessageReceived,
        EventName.tokenReceived:  MMNotificationDeviceTokenReceived,
        EventName.registrationUpdated:  MMNotificationRegistrationUpdated,
        EventName.geofenceEntered: MMNotificationGeographicalRegionDidEnter,
        EventName.notificationTapped: MMNotificationMessageTapped,
        EventName.actionTapped: MMNotificationActionTapped,
        EventName.depersonalized: MMNotificationDepersonalized,
        EventName.personalized: MMNotificationPersonalized,
        EventName.installationUpdated: MMNotificationInstallationSynced,
        EventName.userUpdated: MMNotificationUserSynced,
        EventName.inAppChat_availabilityUpdated: MMNotificationInAppChatAvailabilityUpdated
    ]

    func startObserving() {
        hasEventListeners = true
    }

    func stopObserving() {
        hasEventListeners = false
    }

    init(eventEmitter: RCTEventEmitter) {
        self.eventEmitter = eventEmitter
        setupObservingMMNotifications()
    }

    func stop() {
        setupObservingMMNotifications(stopObservations: true)
    }

    private func setupObservingMMNotifications(stopObservations: Bool = false) {
        supportedNotifications.forEach { (kv) in
            let name = NSNotification.Name(rawValue: kv.value)
            NotificationCenter.default.removeObserver(self, name: name, object: nil)
            if !stopObservations {
                NotificationCenter.default.addObserver(self, selector: #selector(handleMMNotification(notification:)), name: name, object: nil)
            }
        }
    }

    @objc func handleMMNotification(notification: Notification) {
        guard hasEventListeners else {
            return
        }

        var eventName: String?
        var notificationResult: Any?
        switch notification.name.rawValue {
        case MMNotificationMessageReceived:
            eventName = EventName.messageReceived
            if let message = notification.userInfo?[MMNotificationKeyMessage] as? MTMessage {
                notificationResult = message.dictionary()
            }
        case MMNotificationDeviceTokenReceived:
            eventName = EventName.tokenReceived
            if let token = notification.userInfo?[MMNotificationKeyDeviceToken] as? String {
                notificationResult = token
            }
        case MMNotificationRegistrationUpdated:
            eventName = EventName.registrationUpdated
            if let internalId = notification.userInfo?[MMNotificationKeyRegistrationInternalId] as? String {
                notificationResult = internalId
            }
        case MMNotificationGeographicalRegionDidEnter:
            eventName = EventName.geofenceEntered
           if let region = notification.userInfo?[MMNotificationKeyGeographicalRegion] as? MMRegion {
               notificationResult = region.dictionary()
           }
        case MMNotificationMessageTapped:
            eventName = EventName.notificationTapped
            if let message = notification.userInfo?[MMNotificationKeyMessage] as? MTMessage {
                notificationResult = message.dictionary()
            }
        case MMNotificationActionTapped:
            eventName = EventName.actionTapped
            if let message = notification.userInfo?[MMNotificationKeyMessage] as? MTMessage, let actionIdentifier = notification.userInfo?[MMNotificationKeyActionIdentifier] as? String {
                var parameters = [message.dictionary(), actionIdentifier] as [Any]
                if let textInput = notification.userInfo?[MMNotificationKeyActionTextInput] as? String {
                    parameters.append(textInput)
                }
                notificationResult = parameters
            }
        case MMNotificationDepersonalized:
            eventName = EventName.depersonalized
        case MMNotificationPersonalized:
            eventName = EventName.personalized
        case MMNotificationInstallationSynced, MMNotificationUserSynced :
            eventName = EventName.installationUpdated
            if let installation = notification.userInfo?[MMNotificationKeyInstallation] as? Installation {
                notificationResult = installation.dictionaryRepresentation
            } else if let user = notification.userInfo?[MMNotificationKeyUser] as? User {
                eventName = EventName.userUpdated
                notificationResult = user.dictionaryRepresentation
            }
        case MMNotificationInAppChatAvailabilityUpdated:
            eventName = EventName.inAppChat_availabilityUpdated
            notificationResult = notification.userInfo?[MMNotificationKeyInAppChatEnabled] as? Bool
        default: break
        }

        eventEmitter.sendEvent(withName: eventName, body: [eventName, notificationResult])
    }
}
