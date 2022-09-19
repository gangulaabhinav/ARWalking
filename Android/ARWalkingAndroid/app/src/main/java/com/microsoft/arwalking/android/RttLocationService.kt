package com.microsoft.arwalking.android

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.net.wifi.aware.*
import android.net.wifi.rtt.WifiRttManager
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class RttLocationService : Service() {
    companion object {
        private const val LOG_TAG = "RttLocationService"

        private const val NOTIFICATION_CHANNEL_ID = "general"
        private const val NOTIFICATION_CHANNEL_NAME = "General"
        private const val NOTIFICATION_ID = 1

        private const val WIFI_AWARE_SERVICE_NAME = "General"

        const val ACTION_START_PUBLISH = "action_start_publish"
        const val ACTION_START_SUBSCRIBE = "action_start_subscribe"
        const val ACTION_STOP = "action_stop"
    }

    private val mWifiAwareManager: WifiAwareManager? by lazy {
        getSystemService(WIFI_AWARE_SERVICE) as WifiAwareManager?
    }
    private val mWifiRttManager: WifiRttManager? by lazy {
        getSystemService(WIFI_RTT_RANGING_SERVICE) as WifiRttManager?
    }

    private var mWifiAwareSession: WifiAwareSession? = null
    private var mShouldPublish = false

    override fun onDestroy() {
        mWifiAwareSession?.close()
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                updateNotification("Stopping Service")
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START_PUBLISH -> {
                mShouldPublish = true
            }
            ACTION_START_SUBSCRIBE -> {
                mShouldPublish = false
            }
            else -> {
                mShouldPublish = false
            }
        }

        val notificationChannel = NotificationChannel(NOTIFICATION_CHANNEL_ID, NOTIFICATION_CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH)
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(notificationChannel)

        updateNotification("Service Started")

        startWifiAware()

        return START_REDELIVER_INTENT
    }

    private fun updateNotification(message: String) {
        Log.i(LOG_TAG, "Update notification: $message")

        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("RTT Location Service")
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun startWifiAware() {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE) || mWifiAwareManager == null) {
            updateNotification("Wifi Aware feature not available")
            return
        }
        else if(!packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_RTT) || mWifiRttManager == null) {
            updateNotification("Wifi RTT feature not available")
            return
        }
        else if (!mWifiAwareManager!!.isAvailable) {
            updateNotification("Wifi Aware not enabled")
            return
        }
        else if (!mWifiRttManager!!.isAvailable) {
            updateNotification("Wifi RTT not enabled")
            return
        }

        mWifiAwareManager!!.attach(object: AttachCallback() {
            override fun onAttachFailed() {
                super.onAttachFailed()
                updateNotification("Wifi Aware attach failed")
            }

            override fun onAttached(session: WifiAwareSession?) {
                super.onAttached(session)
                mWifiAwareSession = session

                updateNotification("Wifi Aware attached")

                if (mShouldPublish) {
                    publish()
                }
                else {
                    subscribe()
                }
            }
        }, null)
    }

    private fun publish() {
        val config = PublishConfig.Builder()
            .setServiceName(WIFI_AWARE_SERVICE_NAME)
            .build()

        mWifiAwareSession?.publish(config, object: DiscoverySessionCallback() {
            override fun onPublishStarted(session: PublishDiscoverySession) {
                updateNotification("Wifi Aware publish started")
            }

            override fun onSessionTerminated() {
                updateNotification("Wifi Aware session terminated")
            }
        }, null)
    }

    private fun subscribe() {
        val config = SubscribeConfig.Builder()
            .setServiceName(WIFI_AWARE_SERVICE_NAME)
            .build()

        mWifiAwareSession?.subscribe(config, object: DiscoverySessionCallback() {
            override fun onSubscribeStarted(session: SubscribeDiscoverySession) {
                updateNotification("Wifi Aware subscribe started")
            }

            override fun onServiceDiscovered(
                peerHandle: PeerHandle?,
                serviceSpecificInfo: ByteArray?,
                matchFilter: MutableList<ByteArray>?
            ) {
                Log.i(LOG_TAG, "Wifi Aware Service Discovered: $peerHandle")
            }

            override fun onSessionTerminated() {
                updateNotification("Wifi Aware session terminated")
            }
        }, null)
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }
}