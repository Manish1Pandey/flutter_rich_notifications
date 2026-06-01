package app.notifly.flutter_rich_notifications

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterRichNotificationsPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(
            binding.binaryMessenger,
            "flutter_rich_notifications/channel"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "show" -> handleShow(call, result)
            else -> result.notImplemented()
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleShow(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any?> ?: emptyMap()
        val config = RichNotificationConfig(
            channelId = args["channelId"] as? String
                ?: "rich_notifications_default",
            channelName = args["channelName"] as? String
                ?: "Rich Notifications",
            channelDescription = args["channelDescription"] as? String
                ?: "Notifications with hero image and full body text",
            smallIconResName = args["smallIconResName"] as? String,
            imageHeightDp = (args["imageHeightDp"] as? Number)?.toInt() ?: 200,
        )
        val title = args["title"] as? String ?: ""
        val body = args["body"] as? String ?: ""
        val imageUrl = args["imageUrl"] as? String
        val screenRoute = args["screenRoute"] as? String
        val data = (args["data"] as? Map<String, String>) ?: emptyMap()

        CustomNotificationHandler(applicationContext, config)
            .show(title, body, imageUrl, screenRoute, data)
        result.success(true)
    }
}

data class RichNotificationConfig(
    val channelId: String,
    val channelName: String,
    val channelDescription: String,
    val smallIconResName: String?,
    val imageHeightDp: Int,
)
