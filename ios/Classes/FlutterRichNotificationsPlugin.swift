import Flutter
import UIKit

public class FlutterRichNotificationsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_rich_notifications/channel",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterRichNotificationsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "show":
            // On iOS the rich layout is rendered by the Notification Content
            // Extension at delivery time. The Dart `show` call is a no-op
            // here: the OS dispatches to the NCE when the APNs payload
            // includes `aps.category` matching the extension's
            // `UNNotificationExtensionCategory`. The category is optional —
            // without it the notification still shows in the system's default
            // layout. See README for setup.
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
