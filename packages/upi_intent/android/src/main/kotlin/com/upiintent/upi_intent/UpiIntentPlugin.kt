package com.upiintent.upi_intent

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream

class UpiIntentPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null

    companion object {
        private const val CHANNEL = "upi_intent"
        private const val UPI_PAYMENT_REQUEST_CODE = 7896
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getInstalledUpiApps" -> handleGetInstalledApps(result)
            "launchUpiApp" -> {
                val upiUrl = call.argument<String>("upiUrl")
                val packageName = call.argument<String>("packageName")
                if (upiUrl == null) {
                    result.error("INVALID_ARGS", "upiUrl is required", null)
                    return
                }
                handleLaunchUpiApp(upiUrl, packageName, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleGetInstalledApps(result: Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay"))
            val pm: PackageManager = context.packageManager

            @Suppress("DEPRECATION")
            val resolvedApps = pm.queryIntentActivities(intent, 0)

            val appList = resolvedApps.map { resolveInfo ->
                val icon = resolveInfo.loadIcon(pm)
                val iconBytes = drawableToBytes(icon)
                mapOf(
                    "name" to resolveInfo.loadLabel(pm).toString(),
                    "packageName" to resolveInfo.activityInfo.packageName,
                    "icon" to iconBytes
                )
            }
            result.success(appList)
        } catch (e: Exception) {
            result.error("GET_APPS_ERROR", e.message, null)
        }
    }

    private fun handleLaunchUpiApp(upiUrl: String, packageName: String?, result: Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse(upiUrl)
                if (packageName != null) setPackage(packageName)
            }

            if (activity == null) {
                result.error("NO_ACTIVITY", "No activity available", null)
                return
            }

            pendingResult = result
            activity!!.startActivityForResult(intent, UPI_PAYMENT_REQUEST_CODE)
        } catch (e: Exception) {
            result.error("LAUNCH_ERROR", "Failed to launch UPI app: ${e.message}", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != UPI_PAYMENT_REQUEST_CODE) return false

        val result = pendingResult ?: return false
        pendingResult = null

        try {
            // Parse UPI response from intent data
            val response = data?.let { intent ->
                val extras = intent.extras
                if (extras != null) {
                    val responseBuilder = StringBuilder()
                    val keys = listOf("Status", "txnId", "responseCode", "ApprovalRefNo")
                    keys.forEach { key ->
                        val value = extras.getString(key)
                        if (value != null) {
                            if (responseBuilder.isNotEmpty()) responseBuilder.append("&")
                            responseBuilder.append("$key=$value")
                        }
                    }
                    responseBuilder.toString().ifEmpty { null }
                } else null
            }

            result.success(response)
        } catch (e: Exception) {
            result.error("RESPONSE_ERROR", e.message, null)
        }
        return true
    }

    private fun drawableToBytes(drawable: Drawable): ByteArray {
        val bitmap = Bitmap.createBitmap(
            drawable.intrinsicWidth.coerceAtLeast(1),
            drawable.intrinsicHeight.coerceAtLeast(1),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
