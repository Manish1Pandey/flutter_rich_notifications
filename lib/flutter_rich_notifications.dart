import 'dart:io';

import 'package:flutter/services.dart';

/// Display Android and iOS push notifications with a full hero image AND
/// full multi-line body text.
///
/// On Android the plugin renders a custom `RemoteViews` layout that bypasses
/// the stock `BigPictureStyle` body-line limit. On iOS the rich layout is
/// rendered by a Notification Content Extension you add to your app (see
/// README — `ios_setup` section). The OS dispatches directly to the NCE
/// when the APNs payload includes the matching `aps.category`.
class FlutterRichNotifications {
  static const MethodChannel _channel =
      MethodChannel('flutter_rich_notifications/channel');

  static RichNotificationConfig _config = const RichNotificationConfig();

  /// Optional one-time configuration. Pass values that apply to every
  /// notification posted by this app (Android channel ID/name, small icon,
  /// default image height, etc.).
  ///
  /// Safe to call multiple times; the latest value wins. Has no effect on
  /// iOS — iOS configuration lives in the Notification Content Extension's
  /// Info.plist.
  static void configure(RichNotificationConfig config) {
    _config = config;
  }

  /// Post a rich notification.
  ///
  /// On Android this builds a custom-RemoteViews notification with [title],
  /// [body] (multi-line, no truncation), and [imageUrl] rendered as the
  /// hero image. [payload] becomes extras on the tap `Intent`.
  ///
  /// On iOS this method is a no-op: rendering happens entirely inside the
  /// Notification Content Extension at delivery time. To trigger the NCE,
  /// the APNs payload must include `aps.category` matching the extension's
  /// `UNNotificationExtensionCategory` (default `rich_notification`).
  ///
  /// Returns `true` on success. Returns `false` if the platform isn't
  /// supported or the platform call failed.
  static Future<bool> show({
    required String title,
    required String body,
    String? imageUrl,
    String? screenRoute,
    Map<String, String> payload = const {},
  }) async {
    if (!Platform.isAndroid) {
      // iOS rendering is driven by the NCE; no Dart-side work needed.
      return true;
    }
    try {
      final ok = await _channel.invokeMethod<bool>('show', <String, dynamic>{
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'screenRoute': screenRoute,
        'data': payload,
        'channelId': _config.androidChannelId,
        'channelName': _config.androidChannelName,
        'channelDescription': _config.androidChannelDescription,
        'smallIconResName': _config.androidSmallIconResName,
        'imageHeightDp': _config.androidImageHeightDp,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }
}

/// Configuration applied to every notification posted via
/// [FlutterRichNotifications.show].
///
/// All fields have sensible defaults. Override what you need.
class RichNotificationConfig {
  /// Android notification channel ID. Channels are user-visible in
  /// Settings → App → Notifications, so pick something stable.
  final String androidChannelId;

  /// Channel name shown in Settings.
  final String androidChannelName;

  /// Channel description shown in Settings.
  final String androidChannelDescription;

  /// Name of a drawable/mipmap resource in the *consumer app's* `res/`
  /// folder used as the small icon (status bar). If null, the plugin
  /// falls back to `mipmap/ic_launcher`.
  final String? androidSmallIconResName;

  /// Hero image height in dp on Android. Default 200dp.
  final int androidImageHeightDp;

  const RichNotificationConfig({
    this.androidChannelId = 'rich_notifications_default',
    this.androidChannelName = 'Rich Notifications',
    this.androidChannelDescription =
        'Notifications with hero image and full body text',
    this.androidSmallIconResName,
    this.androidImageHeightDp = 200,
  });
}
