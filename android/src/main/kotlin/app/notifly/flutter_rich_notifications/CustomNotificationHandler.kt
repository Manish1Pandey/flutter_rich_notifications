package app.notifly.flutter_rich_notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL

internal class CustomNotificationHandler(
    private val context: Context,
    private val config: RichNotificationConfig
) {

    companion object {
        private const val TAG = "RichNotifHandler"
    }

    init {
        createChannel()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                config.channelId,
                config.channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = config.channelDescription
                enableLights(true)
                enableVibration(true)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    fun show(
        title: String,
        body: String,
        imageUrl: String?,
        screenRoute: String?,
        dataPayload: Map<String, String>
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            val bitmap = imageUrl?.let { downloadBitmap(it) }
            withContext(Dispatchers.Main) {
                postNotification(title, body, bitmap, screenRoute, dataPayload)
            }
        }
    }

    private fun postNotification(
        title: String,
        body: String,
        bitmap: Bitmap?,
        screenRoute: String?,
        dataPayload: Map<String, String>
    ) {
        val notificationId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        val pkg = context.packageName

        val collapsed = RemoteViews(pkg, R.layout.frn_notification_collapsed)
        collapsed.setTextViewText(R.id.frn_title, title)
        collapsed.setTextViewText(R.id.frn_body, body)
        if (bitmap != null) {
            collapsed.setImageViewBitmap(R.id.frn_thumbnail, bitmap)
            collapsed.setViewVisibility(R.id.frn_thumbnail, View.VISIBLE)
        } else {
            collapsed.setViewVisibility(R.id.frn_thumbnail, View.GONE)
        }

        val expanded = RemoteViews(pkg, R.layout.frn_notification_expanded)
        expanded.setTextViewText(R.id.frn_title, title)
        expanded.setTextViewText(R.id.frn_body, body)
        if (bitmap != null) {
            expanded.setImageViewBitmap(R.id.frn_image, bitmap)
            expanded.setViewVisibility(R.id.frn_image, View.VISIBLE)
        } else {
            expanded.setViewVisibility(R.id.frn_image, View.GONE)
        }

        val pendingIntent = buildTapIntent(notificationId, screenRoute, dataPayload)

        val notification = NotificationCompat.Builder(context, config.channelId)
            .setSmallIcon(resolveSmallIcon())
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setCustomHeadsUpContentView(collapsed)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(notificationId, notification)
        } catch (e: SecurityException) {
            Log.w(TAG, "Notification permission missing: ${e.message}")
        }
    }

    private fun resolveSmallIcon(): Int {
        config.smallIconResName?.let { name ->
            val resId = context.resources.getIdentifier(
                name, "drawable", context.packageName
            )
            if (resId != 0) return resId
            val mipmapId = context.resources.getIdentifier(
                name, "mipmap", context.packageName
            )
            if (mipmapId != 0) return mipmapId
        }
        val defaultIcon = context.resources.getIdentifier(
            "ic_launcher", "mipmap", context.packageName
        )
        return if (defaultIcon != 0) defaultIcon
            else android.R.drawable.ic_dialog_info
    }

    private fun buildTapIntent(
        notificationId: Int,
        screenRoute: String?,
        dataPayload: Map<String, String>
    ): PendingIntent {
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent()

        launchIntent.flags =
            Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        screenRoute?.let { launchIntent.putExtra("screen_route", it) }
        for ((k, v) in dataPayload) launchIntent.putExtra(k, v)

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else
            PendingIntent.FLAG_UPDATE_CURRENT

        return PendingIntent.getActivity(context, notificationId, launchIntent, flags)
    }

    private fun downloadBitmap(urlString: String): Bitmap? {
        var connection: HttpURLConnection? = null
        return try {
            val url = URL(urlString)
            connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 8000
            connection.readTimeout = 8000
            connection.instanceFollowRedirects = true
            connection.connect()
            BitmapFactory.decodeStream(connection.inputStream)
        } catch (e: Exception) {
            Log.w(TAG, "Image download failed for $urlString: ${e.message}")
            null
        } finally {
            connection?.disconnect()
        }
    }
}
