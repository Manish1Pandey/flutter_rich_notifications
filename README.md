# flutter_rich_notifications

Display Android and iOS push notifications with a **full hero image AND full multi-line body text** — bypassing the body-line limits that stock `BigPictureStyle` (Android) and standard alert layouts (iOS) impose.

| | flutter_local_notifications | awesome_notifications | **flutter_rich_notifications** |
|---|---|---|---|
| Hero image | ✓ | ✓ | ✓ |
| Multi-line body alongside image | ✗ | ✗ | **✓** |
| iOS custom UI in expanded notification | ✗ | ✗ | **✓** (NCE) |

## How it works

| Platform | Mechanism |
|---|---|
| **Android** | Custom `RemoteViews` layout with `setCustomBigContentView` + `DecoratedCustomViewStyle`. Plugin downloads the image, builds the layout, and posts the notification. |
| **iOS** | Notification Content Extension (NCE) you add to your app. The NCE renders a programmatic `UIViewController` with `UIImageView` (hero) + multi-line `UILabel` (full body). The OS routes the notification to the NCE when the APNs payload includes a matching `aps.category`. |

## Installation

```yaml
dependencies:
  flutter_rich_notifications: ^0.1.0
```

```bash
flutter pub get
```

## Android setup

Zero changes to your `MainActivity` — the plugin auto-registers its MethodChannel.

The plugin ships its own notification channel; users can customize the channel name via `RichNotificationConfig` (see Usage). If you want a custom small status-bar icon, add it under `android/app/src/main/res/drawable/` and pass its name via `androidSmallIconResName`.

## iOS setup

iOS uses two **Notification extensions** (Apple's mechanism for app extensions). The plugin can't auto-create Xcode targets in your app, so you add them manually — **5–10 minutes total**.

### Step 1: Add the Notification Service Extension (handles image)

1. Open `ios/Runner.xcworkspace` in Xcode (workspace, not xcodeproj).
2. **File → New → Target → iOS → Notification Service Extension** → **Next**.
3. Product Name: `ImageNotification` · Language: **Swift** · Project: `Runner` · Embed in Application: `Runner` → **Finish**.
4. Cancel the "Activate scheme?" prompt.
5. Replace the auto-generated `NotificationService.swift` with the contents of:
   ```
   ios/.symlinks/plugins/flutter_rich_notifications/ios/ExtensionTemplates/NotificationServiceExtension/NotificationService.swift
   ```
6. Set the target's **Minimum Deployments** to match Runner (iOS 12.0 or whatever Runner uses).

### Step 2: Add the Notification Content Extension (renders the rich UI)

1. **File → New → Target → iOS → Notification Content Extension** → **Next**.
2. Product Name: `RichNotificationContent` · Language: **Swift** · Project: `Runner` · Embed in Application: `Runner` → **Finish**.
3. Cancel the "Activate scheme?" prompt.
4. **Delete** the auto-generated `MainInterface.storyboard` (we use programmatic UI).
5. Replace the auto-generated `NotificationViewController.swift` with the contents of:
   ```
   ios/.symlinks/plugins/flutter_rich_notifications/ios/ExtensionTemplates/NotificationContentExtension/NotificationViewController.swift
   ```
6. Open the auto-generated `Info.plist` and either:
   - Replace its contents with [`ios/ExtensionTemplates/NotificationContentExtension/Info.plist`](ios/ExtensionTemplates/NotificationContentExtension/Info.plist), **or**
   - Set these keys manually in Xcode's plist editor:
     - `NSExtension → NSExtensionAttributes → UNNotificationExtensionCategory` = `rich_notification`
     - `NSExtension → NSExtensionAttributes → UNNotificationExtensionInitialContentSizeRatio` = `1.0`
     - `NSExtension → NSExtensionAttributes → UNNotificationExtensionDefaultContentHidden` = `YES`
     - `NSExtension → NSExtensionAttributes → UNNotificationExtensionUserInteractionEnabled` = `NO`
7. Set this target's **Minimum Deployments** to match Runner.
8. Build the Runner scheme (⌘B) — both targets compile alongside.

**Notification extensions don't render remote pushes in the iOS Simulator.** Test on a real device.

## Backend (FCM) payload

Both platforms read the same FCM message, but each platform's "render rich" trigger is different — your backend sends both.

```json
{
  "message": {
    "token": "<device_fcm_token>",
    "notification": {
      "title": "Payment Successful",
      "body": "Hi Manish, your rent payment of ₹12,500 has been processed via UPI...",
      "image": "https://example.com/receipt.jpg"
    },
    "data": {
      "screen_route": "/post_payment_screen"
    },
    "android": { "priority": "high" },
    "apns": {
      "headers": { "apns-priority": "10" },
      "payload": {
        "aps": {
          "mutable-content": 1,
          "category": "rich_notification"
        }
      }
    }
  }
}
```

| Field | Why it's needed |
|---|---|
| `notification.image` (or `notification.android.image` / `apns.fcm_options.image`) | Image URL; consumed by Android plugin and iOS NSE |
| `apns.payload.aps.mutable-content: 1` | Triggers iOS NSE (image download) |
| `apns.payload.aps.category: "rich_notification"` | Triggers iOS NCE (rich UI) — must match `UNNotificationExtensionCategory` in the NCE's Info.plist |

## Usage

### One-time configuration

Optional. Defaults work out of the box.

```dart
import 'package:flutter_rich_notifications/flutter_rich_notifications.dart';

void main() {
  FlutterRichNotifications.configure(
    const RichNotificationConfig(
      androidChannelId: 'payments',
      androidChannelName: 'Payment Updates',
      androidChannelDescription: 'Receipts, refunds, and reminders',
      androidSmallIconResName: 'ic_notification', // optional, in res/drawable/
      androidImageHeightDp: 220,
    ),
  );
  runApp(const MyApp());
}
```

### Posting from FCM foreground handler

When your app is in the foreground, FCM delivers the message to your Dart code — call `show()` to render the rich notification (Android only — iOS uses the NCE automatically).

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_rich_notifications/flutter_rich_notifications.dart';

FirebaseMessaging.onMessage.listen((message) {
  final n = message.notification;
  if (n == null) return;
  FlutterRichNotifications.show(
    title: n.title ?? '',
    body: n.body ?? '',
    imageUrl: n.android?.imageUrl ?? n.apple?.imageUrl,
    screenRoute: message.data['screen_route'],
    payload: message.data.map((k, v) => MapEntry(k, v.toString())),
  );
});
```

### Posting a local rich notification (no FCM)

```dart
await FlutterRichNotifications.show(
  title: 'Booking confirmed',
  body: 'Your stay at Krishna Apartments from 12 Jun – 18 Jun is confirmed. '
        'Check-in instructions have been sent to your email.',
  imageUrl: 'https://cdn.example.com/booking-banner.jpg',
  screenRoute: '/booking/123',
);
```

## Customizing the iOS rich layout

The NCE ships with a polished default — hero image (200pt rounded), title in semibold, body in regular with comfortable line spacing, semantic colors that adapt to light/dark mode.

To tweak it, open the `NotificationViewController.swift` you copied into your NCE target and edit the "Design knobs" block at the top of the class:

```swift
// Image-related knobs
var imagePosition: ImagePosition = .top         // .top, .bottom, or .none
var imageHeight: CGFloat = 200
var imageCornerRadius: CGFloat = 12

// Typography
var titleFont: UIFont = .systemFont(ofSize: 17, weight: .semibold)
var bodyFont: UIFont = .systemFont(ofSize: 14, weight: .regular)
var bodyLineSpacing: CGFloat = 3

// Colors (defaults adapt to dark mode)
var titleColor: UIColor = .resolveLabel()
var bodyColor: UIColor = .resolveSecondaryLabel()
var cardBackgroundColor: UIColor = .clear
var accentColor: UIColor? = nil   // set to a brand UIColor to show a left stripe

// Spacing
var horizontalPadding: CGFloat = 16
var verticalPadding: CGFloat = 14
var titleBodySpacing: CGFloat = 6
var imageToTextSpacing: CGFloat = 12
```

For deeper layout changes (e.g. custom typography per-notification based on payload data), override the `open` hooks:

```swift
override func applyTitle(_ text: String) {
    titleLabel.attributedText = NSAttributedString(
        string: text,
        attributes: [.font: UIFont(name: "Inter-Bold", size: 18)!,
                     .kern: 0.3]
    )
}

override func applyBody(_ text: String) {
    super.applyBody(text)
    // post-process bodyLabel further...
}
```

For a fully bespoke layout, override `installConstraints()` in a subclass — but at that point you're rebuilding the renderer, which is usually overkill.

## Caveats

| Platform | Caveat |
|---|---|
| **Android (MIUI / HyperOS)** | Xiaomi devices sometimes strip custom RemoteViews and fall back to their own template. The notification will still display correctly, just with the OEM layout. Stock Android / Pixel / Samsung / OnePlus / Realme render the custom layout as designed. |
| **iOS heads-up banner** | The brief banner that appears at the top of the screen when a notification arrives is system-controlled and shows the standard layout. The NCE only renders when the user long-presses / pulls down to expand. This is an Apple platform constraint, not a plugin limitation. |
| **iOS Simulator** | NCE doesn't fire for remote pushes in the simulator. Test on a real device. |
| **Background / killed app** | On both platforms, notifications delivered while the app is backgrounded / killed are routed by the OS, not the Flutter foreground handler. On iOS the NCE still fires for the rich layout. On Android, the plugin's `show()` won't run because Dart isn't executing — the system renders the standard notification. To get the rich layout in background/killed on Android too, send the FCM message as **data-only** (omit the `notification` block) and add a `FirebaseMessaging.onBackgroundMessage` handler that calls `FlutterRichNotifications.show`. |

## Links

- **Documentation:** [flutterdev.in/packages/flutter_rich_notifications](https://flutterdev.in/packages/flutter_rich_notifications/)
- **More Flutter packages:** [flutterdev.in](https://flutterdev.in)
- **Learn data structures & algorithms in Dart:** [Algoistan](https://algoistan.flutterdev.in)

## License

MIT. See [LICENSE](LICENSE).
