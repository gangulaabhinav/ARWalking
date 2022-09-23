package com.microsoft.arwalking.android

import android.content.SharedPreferences
import android.net.wifi.aware.PeerHandle
import android.net.wifi.rtt.RangingResult
import android.net.wifi.rtt.RangingResultCallback
import android.os.Bundle
import android.os.Handler
import android.os.SystemClock
import android.util.Log
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.preference.PreferenceManager
import com.google.android.apps.location.rtt.nanrttlib.*
import com.lemmingapex.trilateration.NonLinearLeastSquaresSolver
import com.lemmingapex.trilateration.TrilaterationFunction
import org.apache.commons.math3.fitting.leastsquares.LevenbergMarquardtOptimizer
import org.apache.commons.math3.linear.RealVector
import java.time.Duration
import java.time.Instant

data class Location(val x: Double, val y: Double);

class MainActivity : AppCompatActivity(), NanClientCallback, NanPublisherCallback, NanSubscriberCallback, NanContinuousRangerCallback {
    companion object {
        private const val LOG_TAG = "ARWalkingRTTActivity"

        private const val SERVICE_NAME = "General"

        private val deviceToLocation = hashMapOf<String, Location>(
            "4a" to Location(0.0, 0.6),
            "3a" to Location(6.0, 0.0),
        )
    }

    private var mode = 0;

    private val mPreferences: SharedPreferences by lazy {
        PreferenceManager.getDefaultSharedPreferences(this)
    }

    private val nanClient: NanClient by lazy {
        NanClient(this, Handler(mainLooper), this)
    }
    private val nanRanger: NanContinuousRanger by lazy {
        NanContinuousRanger(this, 1000, Handler(mainLooper))
    }
    private val devices: HashMap<PeerHandle, NanDeviceModel> = HashMap()

    private var deviceName = "Device"
    private var enableRanging = false

    // NanClientCallback
    override fun onAttachedFailed() {
        showToast("Attach failed")
    }

    override fun onInvalidService() {
        showToast("Invalid Service")
    }

    override fun onMessageSendFailed(i: Int, str: String?, i2: Int) {
        showToast("Message Send Failed")
    }

    override fun onMessageSendSucceeded(i: Int, str: String?, i2: Int) {
//        showToast("Message Send Succeeded")
    }

    override fun onMessagedReceived(
        mode: Int,
        service: String,
        peerHandle: PeerHandle,
        message: ByteArray
    ) {
//        showToast("Message Received")
        val newReceivedMessage: Message = Message.fromBytes(message)
        when (newReceivedMessage.requestType) {
            Message.NAME_REQUEST_MESSAGE -> {
                Log.d(LOG_TAG, "Received name request")
                val str: String = service
                nanClient.sendMessage(
                    mode,
                    str,
                    peerHandle,
                    Message.NAME_REQUEST_ACK_MESSAGE,
                    Message(deviceName, Message.NAME_REQUEST_ACK_MESSAGE, Message.NAME_REQUEST_ACK_MESSAGE.toString()).toBytes()
                )

                handleNewDeviceIfNeeded(0, peerHandle, newReceivedMessage.deviceName)

                return
            }
            Message.PING_MESSAGE -> {
                Log.d(LOG_TAG, "Received ping")
                val str2: String = service
                nanClient.sendMessage(
                    0,
                    str2,
                    peerHandle,
                    Message.PING_ACK_MESSAGE,
                    Message(deviceName, Message.PING_ACK_MESSAGE, Message.PING_ACK_MESSAGE.toString()).toBytes()
                )

                if (devices.get(peerHandle) != null) {
                    val nanDeviceModel: NanDeviceModel = devices.get(peerHandle)!!
                    nanDeviceModel.setLastCheckIn(Instant.ofEpochMilli(SystemClock.elapsedRealtime()))
                    return
                }

                return
            }
//                3 -> {
//                    if (this.newMessageHandler.addedNewMessage(
//                            peerHandle,
//                            service,
//                            newReceivedMessage
//                        )
//                    ) {
//                        this.newMessageHandler.updateUIMessageNotification()
//                        return
//                    }
//                    return
//                }
            Message.NAME_REQUEST_ACK_MESSAGE -> {
                Log.d(LOG_TAG, "Received name request ack")
                handleNewDeviceIfNeeded(1, peerHandle, newReceivedMessage.deviceName)
                return
            }
            Message.PING_ACK_MESSAGE -> {
                Log.d(LOG_TAG, "Received ping ack")
                if (devices.get(peerHandle) != null) {
                    val nanDeviceModel: NanDeviceModel = devices.get(peerHandle)!!
                    nanDeviceModel.setLastCheckIn(Instant.ofEpochMilli(SystemClock.elapsedRealtime()))
                    return
                }
                return
            }
            else -> {
                Log.e(LOG_TAG, "Cannot identify message request type")
                return
            }
        }

    }

    override fun onNanAvailable() {
        showToast("NAN Available")
    }

    override fun onNanUnavailable() {
        showToast("NAN Unavailable")
    }

    override fun onSessionTerminated(i: Int, str: String?) {
        devices.clear()
        updateDevicesDisplay()
        showToast("Session Terminated")
    }

    override fun onServiceDiscovered(
        str: String?,
        peerHandle: PeerHandle?,
        bArr: ByteArray?,
        list: MutableList<ByteArray>?
    ) {
        showToast("Service Discovered: $peerHandle")

        nanClient.sendMessage(
            1,
            str,
            peerHandle,
            Message.NAME_REQUEST_MESSAGE,
            Message(deviceName, Message.NAME_REQUEST_MESSAGE, Message.NAME_REQUEST_MESSAGE.toString()).toBytes()
        )
    }

    override fun onSubscribeStarted(str: String?) {
        showToast("Subscribe Started")
    }

    override fun onPublishStarted(str: String?) {
        showToast("Publish Started")
        nanClient.enableRangingForPublishedService(SERVICE_NAME, this)
    }

    override fun onRangingDisabled(str: String?) {
        showToast("Ranging Disabled")
    }

    override fun onRangingEnabled(str: String?) {
        showToast("Ranging Enabled")
    }

    private fun ensureDeviceAlive(peerHandle: PeerHandle): Boolean {
        val nanDeviceModel: NanDeviceModel = devices.get(peerHandle) ?: return false

        if (Duration.between(
                        nanDeviceModel.getLastCheckIn(),
                        Instant.ofEpochMilli(SystemClock.elapsedRealtime())
                ).compareTo(Message.TIMEOUT) > 0
        ) {
            showToast("Device removed: $peerHandle")
            devices.remove(peerHandle)
            updateDevicesDisplay()
            return false
        }

        return true
    }

    private fun sendPingLoop(peerHandle: PeerHandle) {
        if (!ensureDeviceAlive(peerHandle)) {
            return
        }

        nanClient.sendMessage(
            1,
            SERVICE_NAME,
            peerHandle,
            Message.PING_MESSAGE,
            Message(deviceName, Message.PING_MESSAGE, Message.PING_MESSAGE.toString()).toBytes()
        )

        Handler(mainLooper).postDelayed({
            sendPingLoop(peerHandle)
        }, Message.PING_DELAY.toMillis())
    }

    private fun ensureDeviceAliveLoop(peerHandle: PeerHandle) {
        if (!ensureDeviceAlive(peerHandle)) {
            return
        }

        Handler(mainLooper).postDelayed({
            ensureDeviceAliveLoop(peerHandle)
        }, Message.PING_DELAY.toMillis())
    }

    private fun handleNewDeviceIfNeeded(mode: Int, peerHandle: PeerHandle, deviceName: String) {
        if (!this.devices.containsKey(peerHandle)) {
            val newDevice = NanDeviceModel(deviceName, peerHandle, SERVICE_NAME).apply {
                setLastCheckIn(Instant.ofEpochMilli(SystemClock.elapsedRealtime()))

                deviceToLocation[deviceName]?.let { location ->
                    x = location.x
                    y = location.y
                }
            }

            showToast("Device Added: $peerHandle, name: $deviceName")
            devices.put(peerHandle, newDevice)
            updateDevicesDisplay()

            when (mode) {
                0 -> {
                    // Publishing
                    ensureDeviceAliveLoop(peerHandle)
                }
                1 -> {
                    // Subscribing
                    sendPingLoop(peerHandle)
                }
            }
        }
    }

    override fun getPeerHandles(): List<PeerHandle> {
        if (!enableRanging) {
            return listOf()
        }

        return devices.values.map {
            it.peerHandle
        }
    }

    override fun onRangingFailure(status: Int) {
        showToast("Ranging failed: $status")
    }

    override fun onRangingResults(results: MutableList<RangingResult>) {
        results.forEach { result ->
            if (result.status != RangingResult.STATUS_SUCCESS) {
                showToast("Ranging failed for peer: ${result.peerHandle}, status: ${result.status}")
            }
            else {
                devices[result.peerHandle]?.distance = result.distanceMm
                showToast("Distance from peer: ${result.peerHandle}, mm: ${result.distanceMm}, stdDevMm: ${result.distanceStdDevMm}, attempts: ${result.numAttemptedMeasurements}, successful attempts: ${result.numSuccessfulMeasurements}")
            }
        }

        computeLocation()
    }

    private fun computeLocation() {
        val positionsWithDistances = devices.values

        if (positionsWithDistances.size < 2) {
            Log.i(LOG_TAG, "Not enough positions for computing location: ${positionsWithDistances.size} found")
            return
        }

        val positions = positionsWithDistances.map {
            doubleArrayOf(it.x, it.y)
        }.toTypedArray()

        val distances = positionsWithDistances.map {
            it.distance.toDouble()
        }.toDoubleArray()

        val solver = NonLinearLeastSquaresSolver(TrilaterationFunction(positions, distances), LevenbergMarquardtOptimizer())
        val optimum = solver.solve()

        // the answer
        val centroid = optimum.point
        updateLocationDisplay(centroid)
        Log.i(LOG_TAG, "Location computed: $centroid")
        try {
            // error and geometry information; may throw SingularMatrixException depending the threshold argument provided
            val standardDeviation = optimum.getSigma(0.0)
            val covarianceMatrix = optimum.getCovariances(0.0)
            Log.i(LOG_TAG, "standardDeviation: $standardDeviation, covarianceMatrix: $covarianceMatrix")
        }
        catch (e: java.lang.Exception) {
            Log.i(LOG_TAG, "Exception calculating stdDev or covariance: ${e.message}")
        }
    }

    private fun showToast(message: String) {
        Log.i(LOG_TAG, "Toast: $message")
//        Toast.makeText(this@MainActivity, message, Toast.LENGTH_SHORT).show()
    }

    override fun onPause() {
        nanRanger.stopRanging()
        super.onPause()
    }

    override fun onResume() {
        nanRanger.rangePeer(this)
        super.onResume()
    }

    private val mConnectedDevicesView: TextView by lazy {
        findViewById(R.id.connected_devices)
    }
    private val mLocationView: TextView by lazy {
        findViewById(R.id.location)
    }

    private fun updateDevicesDisplay() {
        var deviceDisplayText: String = "Connected Devices: ${devices.size}\n"

        deviceDisplayText += devices.map { (_, device) ->
            "${device.deviceName}, location: {${device.x}; ${device.y}}, distance: ${device.distance}"
        }
        .joinToString("\n")

        mConnectedDevicesView.setText(deviceDisplayText)
    }

    private fun updateLocationDisplay(location: RealVector?) {
        mLocationView.setText("Location: $location")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        updateDevicesDisplay()
        updateLocationDisplay(null)

        findViewById<Button>(R.id.start).setOnClickListener {
            deviceName = mPreferences.getString("device_name", null) ?: "Device"
            enableRanging = mPreferences.getBoolean("enable_ranging", false)

            if (mPreferences.getBoolean("publish", false)) {
                mode = 0
                nanClient.publishService(SERVICE_NAME, this, null)
            }
            else if (mPreferences.getBoolean("subscribe", false)) {
                mode = 1
                nanClient.subscribeService(SERVICE_NAME, this, null)
            }
            else {
                showToast("Please select a mode")
            }

//            val intent = Intent(this, RttLocationService::class.java)
//            intent.action = RttLocationService.ACTION_START
//
//            startForegroundService(intent)
        }

        findViewById<Button>(R.id.stop).setOnClickListener {
            nanClient.stopSession(mode, SERVICE_NAME, this)
//            val intent = Intent(this, RttLocationService::class.java)
//            intent.action = RttLocationService.ACTION_STOP
//
//            startForegroundService(intent)
        }
    }

}