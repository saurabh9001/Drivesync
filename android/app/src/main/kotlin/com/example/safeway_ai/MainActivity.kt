package com.example.safeway_ai

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager
import android.util.Log
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import android.Manifest

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "drivesync/sms"
    private val CALL_CHANNEL = "drivesync/call"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // SMS Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSms") {
                val number = call.argument<String>("number")
                val message = call.argument<String>("message")
                if (number != null && message != null) {
                    try {
                        // Check SEND_SMS permission at runtime
                        val perm = ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
                        Log.d("DriveSync", "SEND_SMS permission status: $perm")
                        if (perm != PackageManager.PERMISSION_GRANTED) {
                            Log.e("DriveSync", "SEND_SMS permission not granted, aborting SMS send")
                            result.error("PERMISSION_DENIED", "SEND_SMS not granted", null)
                        } else {
                            val smsManager = SmsManager.getDefault()
                            val SENT = "SMS_SENT"
                            val DELIVERED = "SMS_DELIVERED"
                            val flags = android.app.PendingIntent.FLAG_IMMUTABLE
                            val sentPI = android.app.PendingIntent.getBroadcast(this, 0, android.content.Intent(SENT), flags)
                            val deliveredPI = android.app.PendingIntent.getBroadcast(this, 0, android.content.Intent(DELIVERED), flags)

                            // Register receivers to log status
                            val sentReceiver = object : android.content.BroadcastReceiver() {
                                override fun onReceive(ctx: android.content.Context?, intent: android.content.Intent?) {
                                    val rc = getResultCode()
                                    when (rc) {
                                        android.app.Activity.RESULT_OK -> Log.d("DriveSync", "Emergency SMS sent successfully to $number")
                                        android.telephony.SmsManager.RESULT_ERROR_GENERIC_FAILURE -> Log.e("DriveSync", "SMS failed - generic failure to $number")
                                        android.telephony.SmsManager.RESULT_ERROR_NO_SERVICE -> Log.e("DriveSync", "SMS failed - no service to $number")
                                        android.telephony.SmsManager.RESULT_ERROR_NULL_PDU -> Log.e("DriveSync", "SMS failed - null PDU to $number")
                                        android.telephony.SmsManager.RESULT_ERROR_RADIO_OFF -> Log.e("DriveSync", "SMS failed - radio off to $number")
                                        else -> Log.e("DriveSync", "SMS failed - unknown result $rc for $number")
                                    }
                                    try { unregisterReceiver(this) } catch (e: Exception) { /* ignore */ }
                                }
                            }

                            val deliveredReceiver = object : android.content.BroadcastReceiver() {
                                override fun onReceive(ctx: android.content.Context?, intent: android.content.Intent?) {
                                    val rc = getResultCode()
                                    when (rc) {
                                        android.app.Activity.RESULT_OK -> Log.d("DriveSync", "Emergency SMS delivered to $number")
                                        else -> Log.e("DriveSync", "SMS delivery failed with result $rc for $number")
                                    }
                                    try { unregisterReceiver(this) } catch (e: Exception) { /* ignore */ }
                                }
                            }

                            registerReceiver(sentReceiver, android.content.IntentFilter(SENT))
                            registerReceiver(deliveredReceiver, android.content.IntentFilter(DELIVERED))

                            // Use multipart SMS for long messages
                            val parts = smsManager.divideMessage(message)
                            val sentIntents = ArrayList<android.app.PendingIntent>()
                            val deliveredIntents = ArrayList<android.app.PendingIntent>()
                            for (i in parts.indices) {
                                sentIntents.add(sentPI)
                                deliveredIntents.add(deliveredPI)
                            }
                            smsManager.sendMultipartTextMessage(number, null, parts, sentIntents, deliveredIntents)
                            Log.d("DriveSync", "Emergency SMS queued to $number; parts=${parts.size}")
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        Log.e("DriveSync", "Exception sending emergency SMS: ", e)
                        result.error("SMS_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing number or message", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Call Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "makeCall") {
                val number = call.argument<String>("number")
                if (number != null) {
                    try {
                        val perm = ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
                        if (perm != PackageManager.PERMISSION_GRANTED) {
                            Log.e("DriveSync", "CALL_PHONE permission not granted")
                            result.error("PERMISSION_DENIED", "CALL_PHONE not granted", null)
                        } else {
                            Log.d("DriveSync", "Making emergency call to $number")
                            val intent = android.content.Intent(android.content.Intent.ACTION_CALL)
                            intent.data = android.net.Uri.parse("tel:$number")
                            intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        Log.e("DriveSync", "Exception making emergency call: ", e)
                        result.error("CALL_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing number", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
