# Changelog

## 0.1.0

* Initial release.
* Android: custom `RemoteViews` notification (`DecoratedCustomViewStyle`) with hero image and full multi-line body. Light + dark mode text colors. Configurable channel ID/name/description and small icon.
* iOS: Notification Content Extension template (programmatic `UIViewController`, no storyboard) for hero image + full multi-line body in expanded notifications. Notification Service Extension template for image attachment.
* Public Dart API: `FlutterRichNotifications.show(...)` and `RichNotificationConfig`.
