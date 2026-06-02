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

        URLSession.shared.downloadTask(with: url) { tempUrl, response, _ in
            defer { contentHandler(bestAttemptContent) }
            guard let tempUrl = tempUrl else { return }

            let fileExt = Self.fileExtension(for: url, response: response)
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let localUrl = cacheDir.appendingPathComponent("frn_image_\(UUID().uuidString)\(fileExt)")
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

    /// Pick a file extension iOS will accept. Order: URL path → MIME type → .jpg fallback.
    /// `UNNotificationAttachment` rejects files without recognizable extensions, so this
    /// avoids the silent "no image" failure mode when image URLs (e.g. `picsum.photos/600/400`)
    /// have no extension in their path.
    private static func fileExtension(for url: URL, response: URLResponse?) -> String {
        let pathExt = (url.lastPathComponent as NSString).pathExtension
        if !pathExt.isEmpty { return "." + pathExt }

        let mimeType = (response as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        if mimeType.contains("png") { return ".png" }
        if mimeType.contains("gif") { return ".gif" }
        return ".jpg"
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
