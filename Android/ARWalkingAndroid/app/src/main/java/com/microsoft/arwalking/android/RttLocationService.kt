package com.microsoft.arwalking.android

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.MacAddress
import android.net.wifi.aware.*
import android.net.wifi.rtt.RangingRequest
import android.net.wifi.rtt.RangingResult
import android.net.wifi.rtt.RangingResultCallback
import android.net.wifi.rtt.WifiRttManager
import android.os.Handler
import android.os.IBinder
import android.os.PowerManager
import android.os.PowerManager.WakeLock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.preference.PreferenceManager
import java.nio.ByteBuffer

data class Location(val x: Double, val y: Double, val z: Double)

class RttLocationService : Service() {
    companion object {
        private const val LOG_TAG = "RttLocationService"

        private const val NOTIFICATION_CHANNEL_ID = "general"
        private const val NOTIFICATION_CHANNEL_NAME = "General"
        private const val NOTIFICATION_ID = 1

        private const val WIFI_AWARE_SERVICE_NAME = "General"

        const val ACTION_START = "action_start"
        const val ACTION_STOP = "action_stop"
    }

    private val mWifiAwareManager: WifiAwareManager? by lazy {
        getSystemService(WIFI_AWARE_SERVICE) as WifiAwareManager?
    }
    private val mWifiRttManager: WifiRttManager? by lazy {
        getSystemService(WIFI_RTT_RANGING_SERVICE) as WifiRttManager?
    }
    private val mNotificationManager: NotificationManager by lazy {
        getSystemService(NOTIFICATION_SERVICE) as NotificationManager
    }

    private val mPreferences: SharedPreferences by lazy {
        PreferenceManager.getDefaultSharedPreferences(this)
    }

    private var mWifiAwareSession: WifiAwareSession? = null
    private var mLastNotificationId = NOTIFICATION_ID
    private var mLoopRangingRequest = false

    private var mActivePublishSession: PublishDiscoverySession? = null
    private var mActiveSubscribeSession: SubscribeDiscoverySession? = null

    private val mWakeLock: WakeLock by lazy {
        (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ARWalking:RttLocationService")
    }

    private val mPeerList: HashMap<PeerHandle, Location> = HashMap()

    override fun onDestroy() {
        mLoopRangingRequest = false

        if (mWakeLock.isHeld) {
            mWakeLock.release()
        }

        mWifiAwareSession?.close()
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            updateNotification("Stopping Service")
            mLoopRangingRequest = false

            mWifiAwareSession?.close()
            mWifiAwareSession = null

            if (mWakeLock.isHeld) {
                mWakeLock.release()
            }

            stopSelf()
            return START_NOT_STICKY
        }
        else {
            // Continue
        }

        val notificationChannel = NotificationChannel(NOTIFICATION_CHANNEL_ID, NOTIFICATION_CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH)
        mNotificationManager.createNotificationChannel(notificationChannel)

        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE) || mWifiAwareManager == null) {
            updateNotification("Wifi Aware feature not available")
            stopSelf()
            return START_NOT_STICKY
        }
        else if(!packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_RTT) || mWifiRttManager == null) {
            updateNotification("Wifi RTT feature not available")
            stopSelf()
            return START_NOT_STICKY
        }
        else if (!mWifiAwareManager!!.isAvailable) {
            updateNotification("Wifi Aware not enabled")
            stopSelf()
            return START_NOT_STICKY
        }
        else if (!mWifiRttManager!!.isAvailable) {
            updateNotification("Wifi RTT not enabled")
            stopSelf()
            return START_NOT_STICKY
        }
        else {
            updateNotification("Service Started")

            startWifiAware()
        }

        return START_REDELIVER_INTENT
    }

    private fun updateNotification(message: String, newNotification: Boolean = false) {
        Log.i(LOG_TAG, "Update notification: $message")

        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID).run {
            setContentTitle("RTT Location Service")
            setContentText(message)
            setOngoing(!newNotification)
            setSmallIcon(R.drawable.ic_launcher_foreground)
            build()
        }

        if (newNotification) {
            mNotificationManager.notify(++mLastNotificationId, notification)
        }
        else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun startWifiAware() {
        mWakeLock.acquire()
        mPeerList.clear()
        mWifiAwareManager!!.attach(object: AttachCallback() {
            override fun onAttachFailed() {
                super.onAttachFailed()
                updateNotification("Wifi Aware attach failed")
            }

            override fun onAttached(session: WifiAwareSession?) {
                super.onAttached(session)
                mWifiAwareSession = session

                updateNotification("Wifi Aware attached")

                if (mPreferences.getBoolean("publish", false)) {
                    publish()
                }
                if (mPreferences.getBoolean("subscribe", false)) {
                    subscribe()
                }
            }
        }, object: IdentityChangedListener() {
            override fun onIdentityChanged(macBytes: ByteArray) {
                val mac = MacAddress.fromBytes(macBytes)
                Log.i(LOG_TAG, "Wifi Aware Mac Address: $mac")
            }
        }, null)
    }

    private fun publish() {
        val byteBuffer = ByteBuffer.allocate(3 * java.lang.Double.BYTES)

        byteBuffer.putDouble(mPreferences.getString("coordinateX", "0")!!.toDouble())
        byteBuffer.putDouble(mPreferences.getString("coordinateY", "0")!!.toDouble())
        byteBuffer.putDouble(mPreferences.getString("coordinateZ", "0")!!.toDouble())

        val config = PublishConfig.Builder().run {
            setServiceName(WIFI_AWARE_SERVICE_NAME)
            setServiceSpecificInfo(byteBuffer.array())
            setRangingEnabled(false)
            build()
        }

        mWifiAwareSession?.publish(config, object: DiscoverySessionCallback() {
            override fun onPublishStarted(session: PublishDiscoverySession) {
                mActivePublishSession = session

                updateNotification("Wifi Aware publish started", true)

                val configUpdated = PublishConfig.Builder().run {
                    setServiceName(WIFI_AWARE_SERVICE_NAME)
                    setServiceSpecificInfo(byteBuffer.array())
                    setRangingEnabled(true)
                    build()
                }
                session.updatePublish(configUpdated)
            }

            override fun onSessionConfigUpdated() {
                Log.i(LOG_TAG, "Wifi Aware publish enabled ranging")
            }

            override fun onMessageReceived(peerHandle: PeerHandle, message: ByteArray) {
                Log.i(LOG_TAG, "Message received from peer: $peerHandle, message: ${message.decodeToString()}")

                mActivePublishSession?.sendMessage(peerHandle, 2, "Pong".toByteArray())
            }

            override fun onMessageSendFailed(messageId: Int) {
                Log.i(LOG_TAG, "Message send failed")
            }

            override fun onMessageSendSucceeded(messageId: Int) {
                Log.i(LOG_TAG, "Message send succeeded")
            }

            override fun onSessionTerminated() {
                mActivePublishSession = null
                updateNotification("Wifi Aware session terminated", true)
            }
        }, null)
    }

    private fun subscribe() {
        val config = SubscribeConfig.Builder()
            .setServiceName(WIFI_AWARE_SERVICE_NAME)
//            .setMaxDistanceMm(50000)
            .build()

        mWifiAwareSession?.subscribe(config, object: DiscoverySessionCallback() {
            override fun onSubscribeStarted(session: SubscribeDiscoverySession) {
                mActiveSubscribeSession = session

                updateNotification("Wifi Aware subscribe started", true)

                mLoopRangingRequest = true
                startRangingRequest()
            }

            override fun onServiceDiscoveredWithinRange(peerHandle: PeerHandle?, serviceSpecificInfo: ByteArray?, matchFilter: MutableList<ByteArray>?, distanceMm: Int) {
                handleServiceDiscovered(peerHandle, serviceSpecificInfo, matchFilter, distanceMm)
            }

            override fun onServiceDiscovered(peerHandle: PeerHandle?, serviceSpecificInfo: ByteArray?, matchFilter: MutableList<ByteArray>?) {
                handleServiceDiscovered(peerHandle, serviceSpecificInfo, matchFilter)
            }

            //override fun onServiceLost(peerHandle: PeerHandle, reason: Int) {
            //    mPeerList.remove(peerHandle)
            //    Log.i(LOG_TAG, "Wifi Aware Service Lost: $peerHandle, reason: $reason")
            //}

            override fun onMessageReceived(peerHandle: PeerHandle, message: ByteArray) {
                Log.i(LOG_TAG, "Message received from peer: $peerHandle, message: ${message.decodeToString()}")
            }

            override fun onMessageSendFailed(messageId: Int) {
                Log.i(LOG_TAG, "Message send failed")
            }

            override fun onMessageSendSucceeded(messageId: Int) {
                Log.i(LOG_TAG, "Message send succeeded")
            }

            override fun onSessionTerminated() {
                mActiveSubscribeSession = null

                updateNotification("Wifi Aware session terminated", true)
            }
        }, null)
    }

    private fun handleServiceDiscovered(peerHandle: PeerHandle?, serviceSpecificInfo: ByteArray?, matchFilter: MutableList<ByteArray>?, distanceMm: Int = -1) {
        if (peerHandle == null) {
            return
        }

        Log.i(LOG_TAG, "Wifi Aware Service Discovered: $peerHandle")

//        mActiveSubscribeSession?.sendMessage(peerHandle, 1, "Ping".toByteArray())

        serviceSpecificInfo?.let {
//            val bytesBuffer = ByteBuffer.wrap(it)
//            val x = bytesBuffer.double
//            val y = bytesBuffer.double
//            val z = bytesBuffer.double

            val x = 0.0
            val y = 0.0
            val z = 0.0

            Log.i(LOG_TAG, "Wifi Aware Service Discovered: $peerHandle, x: $x, y: $y, z: $z")

            mPeerList.putIfAbsent(peerHandle, Location(x, y, z))
        }
    }

    @SuppressLint("MissingPermission")
    private fun startRangingRequest() {
        if (!mLoopRangingRequest) {
            return
        }

        if (mPeerList.size <= 0) {
            Log.i(LOG_TAG, "Peer list is empty, skipping ranging")
            Handler(mainLooper).postDelayed({
                startRangingRequest()
            }, 1000)
            return
        }

        val request = RangingRequest.Builder().run {
            mPeerList.forEach { (peerHandle, location) ->
                addWifiAwarePeer(peerHandle)
            }
            build()
        }

        mWifiRttManager!!.startRanging(request, mainExecutor, object: RangingResultCallback() {
            override fun onRangingFailure(result: Int) {
                Log.i(LOG_TAG, "Ranging Request failed with: $result")
                Handler(mainLooper).postDelayed({
                    startRangingRequest()
                }, 1000)
            }

            override fun onRangingResults(results: MutableList<RangingResult>) {
                results.forEach { result ->
                    if (result.status != RangingResult.STATUS_SUCCESS) {
                        Log.i(LOG_TAG, "Ranging failed for peer: ${result.peerHandle}, status: ${result.status}")
                    }
                    else {
                        Log.i(LOG_TAG, "Distance from peer: ${result.peerHandle}, mm: ${result.distanceMm}, stdDevMm: ${result.distanceStdDevMm}, attempts: ${result.numAttemptedMeasurements}, successful attempts: ${result.numSuccessfulMeasurements}")
                    }
                }

                Handler(mainLooper).postDelayed({
                    startRangingRequest()
                }, 1000)
            }
        })
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }
}