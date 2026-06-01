import UserNotifications

/// Notification Service Extension template for flutter_rich_notifications.
///
/// Copy this file into a Notification Service Extension target inside your
/// iOS app. The extension downloads the image referenced by the FCM payload
/// (`fcm_options.image` or top-level `image`) and attaches it to the
/// notification so the system layout (and any Notification Content Extension)
/// can render it.
///
/// Required APNs payload field: `aps.mutable-content: 1`
class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        let urlString = (bestAttemptContent.userInfo["fcm_options"] as? [String: Any])?["image"] as? String
            ?? bestAttemptContent.userInfo["image"] as? String

        guard let urlString = urlString, let url = URL(string: urlString) else {
            contentHandler(bestAttemptContent)
            return
        }

        URLSession.shared.downloadTask(with: url) { tempUrl, _, _ in
            defer { contentHandler(bestAttemptContent) }
            guard let tempUrl = tempUrl else { return }

            let suggestedName = url.lastPathComponent.isEmpty ? "image.jpg" : url.lastPathComponent
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let localUrl = cacheDir.appendingPathComponent(suggestedName)
            try? FileManager.default.removeItem(at: localUrl)

            do {
                try FileManager.default.moveItem(at: tempUrl, to: localUrl)
                let attachment = try UNNotificationAttachment(
                    identifier: "frn_image",
                    url: localUrl,
                    options: nil
                )
                bestAttemptContent.attachments = [attachment]
            } catch {
                // Fall through to text-only notification.
            }
        }.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
