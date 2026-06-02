# Changelog

## 0.1.2

* iOS NCE: redesigned default layout for a polished look out of the box —
  hero image on top (200pt, rounded corners), title in 17pt semibold, body
  in 14pt regular with 3pt line spacing, semantic colors that adapt to
  light/dark mode.
* iOS NCE: exposed design knobs at the top of `NotificationViewController`
  (image position/height/corner radius, title and body fonts/colors,
  padding, optional brand-color accent stripe). Tweak constants or subclass
  and override `applyTitle` / `applyBody` for deeper customization.
* iOS NCE: switched body label to attributed text so `lineSpacing` is
  honored, giving a more readable multi-line body.

## 0.1.1

* iOS NSE: fix silent failure when image URLs lack a file extension in the path
  (e.g. `https://picsum.photos/600/400`). `UNNotificationAttachment` rejects
  files without a recognizable extension, so the saved file now uses an
  extension derived from URL path → response MIME type → `.jpg` fallback.
  Without this fix, images at extension-less URLs would never attach despite
  the NSE running successfully.
* Use a UUID-based filename so concurrent notifications don't collide on the
  same cache path.

## 0.1.0

* Initial release.
* Android: custom `RemoteViews` notification (`DecoratedCustomViewStyle`) with hero image and full multi-line body. Light + dark mode text colors. Configurable channel ID/name/description and small icon.
* iOS: Notification Content Extension template (programmatic `UIViewController`, no storyboard) for hero image + full multi-line body in expanded notifications. Notification Service Extension template for image attachment.
* Public Dart API: `FlutterRichNotifications.show(...)` and `RichNotificationConfig`.
