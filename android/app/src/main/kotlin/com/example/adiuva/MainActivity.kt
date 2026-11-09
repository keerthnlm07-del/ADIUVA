package com.example.adiuva

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import java.io.File
import java.io.FileOutputStream
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.adiuva/emergency"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendDirectSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")

                    if (phoneNumber.isNullOrBlank() || message.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENTS", "Phone number and message cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    // Check SEND_SMS runtime permission
                    val permissionCheck = ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
                    if (permissionCheck != PackageManager.PERMISSION_GRANTED) {
                        result.success(mapOf(
                            "success" to false,
                            "status" to "permission_denied",
                            "message" to "android.permission.SEND_SMS is not granted"
                        ))
                        return@setMethodCallHandler
                    }

                    try {
                        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            applicationContext.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        if (smsManager == null) {
                            result.success(mapOf(
                                "success" to false,
                                "status" to "no_sms_manager",
                                "message" to "SmsManager service is unavailable on this device"
                            ))
                            return@setMethodCallHandler
                        }

                        if (message.length > 160) {
                            val parts = smsManager.divideMessage(message)
                            smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
                        } else {
                            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                        }

                        result.success(mapOf(
                            "success" to true,
                            "status" to "sent",
                            "message" to "SMS transmitted successfully to $phoneNumber"
                        ))
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "success" to false,
                            "status" to "failed",
                            "message" to (e.localizedMessage ?: e.message ?: "Unknown SMS sending error")
                        ))
                    }
                }

                "makeDirectCall" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")

                    if (phoneNumber.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENTS", "Phone number cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    // Check CALL_PHONE runtime permission
                    val permissionCheck = ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
                    if (permissionCheck != PackageManager.PERMISSION_GRANTED) {
                        result.success(mapOf(
                            "success" to false,
                            "status" to "permission_denied",
                            "message" to "android.permission.CALL_PHONE is not granted"
                        ))
                        return@setMethodCallHandler
                    }

                    try {
                        val cleanNumber = phoneNumber.replace(Regex("[^0-9+]"), "")
                        val callIntent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$cleanNumber")).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(callIntent)

                        result.success(mapOf(
                            "success" to true,
                            "status" to "call_initiated",
                            "message" to "Emergency phone call initiated to $cleanNumber"
                        ))
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "success" to false,
                            "status" to "failed",
                            "message" to (e.localizedMessage ?: e.message ?: "Unknown phone call error")
                        ))
                    }
                }

                "checkEmergencyCapabilities" -> {
                    val hasTelephony = packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
                    val hasSmsPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED
                    val hasCallPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED

                    result.success(mapOf(
                        "hasTelephony" to hasTelephony,
                        "hasSmsPermission" to hasSmsPermission,
                        "hasCallPermission" to hasCallPermission
                    ))
                }

                "extractVideoFrames" -> {
                    val videoPath = call.argument<String>("videoPath")
                    val maxFrames = call.argument<Int>("maxFrames") ?: 20
                    if (videoPath.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENTS", "videoPath cannot be null or empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val retriever = MediaMetadataRetriever()
                        retriever.setDataSource(videoPath)
                        val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                        val durationMs = durationStr?.toLongOrNull() ?: 3000L
                        val framePaths = ArrayList<String>()
                        val tempDir = File(cacheDir, "isl_extracted_frames")
                        if (!tempDir.exists()) tempDir.mkdirs()

                        val stepMs = if (maxFrames > 1) durationMs / (maxFrames + 1) else durationMs / 2
                        for (i in 1..maxFrames) {
                            val timeUs = (i * stepMs) * 1000L
                            val bitmap = retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                            if (bitmap != null) {
                                val frameFile = File(tempDir, "frame_${System.currentTimeMillis()}_$i.jpg")
                                FileOutputStream(frameFile).use { fos ->
                                    bitmap.compress(Bitmap.CompressFormat.JPEG, 85, fos)
                                }
                                framePaths.add(frameFile.absolutePath)
                            }
                        }
                        retriever.release()
                        result.success(framePaths)
                    } catch (e: Exception) {
                        result.error("EXTRACTION_ERROR", e.localizedMessage ?: "Failed to extract frames", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
