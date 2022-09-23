package com.microsoft.arwalking.android

import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.SharedPreferences
import android.net.wifi.aware.PeerHandle
import android.net.wifi.rtt.RangingResult
import android.os.Bundle
import android.os.Handler
import android.os.ParcelUuid
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
import java.util.*
import kotlin.collections.HashMap

data class Location(val x: Double, val y: Double);

class MainActivity : AppCompatActivity(), NanClientCallback, NanPublisherCallback, NanSubscriberCallback, NanContinuousRangerCallback {
    companion object {
        private const val LOG_TAG = "ARWalkingRTTActivity"

        private const val SERVICE_UUID = "25AE1441-05D3-4C5B-8281-93D4E07420CF"
        private const val CHAR_FOR_READ_UUID = "25AE1442-05D3-4C5B-8281-93D4E07420CF"
        private const val CHAR_FOR_WRITE_UUID = "25AE1443-05D3-4C5B-8281-93D4E07420CF"
        private const val CHAR_FOR_INDICATE_UUID = "25AE1444-05D3-4C5B-8281-93D4E07420CF"
        private const val CCC_DESCRIPTOR_UUID = "00002902-0000-1000-8000-00805f9b34fb"

        private const val SERVICE_NAME = "General"
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

    private var deviceToLocation: HashMap<String, Location> = HashMap()

    // NanClientCallback
    override fun onAttachedFailed() {
        logMessage("Attach failed")
    }

    override fun onInvalidService() {
        logMessage("Invalid Service")
    }

    override fun onMessageSendFailed(i: Int, str: String?, i2: Int) {
        logMessage("Message Send Failed")
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
        logMessage("NAN Available")
    }

    override fun onNanUnavailable() {
        logMessage("NAN Unavailable")
    }

    override fun onSessionTerminated(i: Int, str: String?) {
        devices.clear()
        updateDevicesDisplay()
        logMessage("Session Terminated")
    }

    override fun onServiceDiscovered(
        str: String?,
        peerHandle: PeerHandle?,
        bArr: ByteArray?,
        list: MutableList<ByteArray>?
    ) {
        logMessage("Service Discovered: $peerHandle")

        nanClient.sendMessage(
            1,
            str,
            peerHandle,
            Message.NAME_REQUEST_MESSAGE,
            Message(deviceName, Message.NAME_REQUEST_MESSAGE, Message.NAME_REQUEST_MESSAGE.toString()).toBytes()
        )
    }

    override fun onSubscribeStarted(str: String?) {
        logMessage("Subscribe Started")
    }

    override fun onPublishStarted(str: String?) {
        logMessage("Publish Started")
        nanClient.enableRangingForPublishedService(SERVICE_NAME, this)
    }

    override fun onRangingDisabled(str: String?) {
        logMessage("Ranging Disabled")
    }

    override fun onRangingEnabled(str: String?) {
        logMessage("Ranging Enabled")
    }

    private fun ensureDeviceAlive(peerHandle: PeerHandle): Boolean {
        val nanDeviceModel: NanDeviceModel = devices.get(peerHandle) ?: return false

        if (Duration.between(
                        nanDeviceModel.getLastCheckIn(),
                        Instant.ofEpochMilli(SystemClock.elapsedRealtime())
                ).compareTo(Message.TIMEOUT) > 0
        ) {
            logMessage("Device removed: $peerHandle")
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

            logMessage("Device Added: $peerHandle, name: $deviceName")
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
        logMessage("Ranging failed: $status")
    }

    override fun onRangingResults(results: MutableList<RangingResult>) {
        results.forEach { result ->
            if (result.status != RangingResult.STATUS_SUCCESS) {
                logMessage("Ranging failed for peer: ${result.peerHandle}, status: ${result.status}")
            }
            else {
                devices[result.peerHandle]?.distance = result.distanceMm
                logMessage("Distance from peer: ${result.peerHandle}, mm: ${result.distanceMm}, stdDevMm: ${result.distanceStdDevMm}, attempts: ${result.numAttemptedMeasurements}, successful attempts: ${result.numSuccessfulMeasurements}")
            }
        }

        updateDevicesDisplay()
        computeLocation()
    }

    private fun computeLocation() {
        val positionsWithDistances = devices.values

        if (positionsWithDistances.size < 2) {
            logMessage("Not enough positions for computing location: ${positionsWithDistances.size} found")
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
        val centroid = optimum.point.map { x -> x/1000.0 }

        bleIndicate(centroid.toArray().joinToString(","))

        updateLocationDisplay(centroid)
        logMessage("Location computed: $centroid")

        try {
            // error and geometry information; may throw SingularMatrixException depending the threshold argument provided
            val standardDeviation = optimum.getSigma(0.0)
            val covarianceMatrix = optimum.getCovariances(0.0)
            logMessage("standardDeviation: $standardDeviation, covarianceMatrix: $covarianceMatrix")
        }
        catch (e: java.lang.Exception) {
            logMessage("Exception calculating stdDev or covariance: ${e.message}")
        }
    }

    private fun logMessage(message: String) {
        Log.i(LOG_TAG, "Log: $message")
    }

    //
    // Bluetooth LE handling
    //
    private var isBleAdvertising = false
        set(value) {
            field = value

            updateBleStatus()
        }

    private var isBleConnected = false
        set(value) {
            field = value

            updateBleStatus()
        }

    private var textCharForRead = ""
    private var textCharForWrite = ""

    private val bluetoothManager: BluetoothManager by lazy {
        getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
    }

    private val bluetoothAdapter: BluetoothAdapter by lazy {
        bluetoothManager.adapter
    }

    //region BLE advertise
    private val bleAdvertiser by lazy {
        bluetoothAdapter.bluetoothLeAdvertiser
    }

    private val advertiseSettings = AdvertiseSettings.Builder()
        .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
        .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
        .setConnectable(true)
        .build()

    private val advertiseData = AdvertiseData.Builder()
        .setIncludeDeviceName(false) // don't include name, because if name size > 8 bytes, ADVERTISE_FAILED_DATA_TOO_LARGE
        .addServiceUuid(ParcelUuid(UUID.fromString(SERVICE_UUID)))
        .build()

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            logMessage("Advertise start success\n$SERVICE_UUID")
        }

        override fun onStartFailure(errorCode: Int) {
            val desc = when (errorCode) {
                ADVERTISE_FAILED_DATA_TOO_LARGE -> "\nADVERTISE_FAILED_DATA_TOO_LARGE"
                ADVERTISE_FAILED_TOO_MANY_ADVERTISERS -> "\nADVERTISE_FAILED_TOO_MANY_ADVERTISERS"
                ADVERTISE_FAILED_ALREADY_STARTED -> "\nADVERTISE_FAILED_ALREADY_STARTED"
                ADVERTISE_FAILED_INTERNAL_ERROR -> "\nADVERTISE_FAILED_INTERNAL_ERROR"
                ADVERTISE_FAILED_FEATURE_UNSUPPORTED -> "\nADVERTISE_FAILED_FEATURE_UNSUPPORTED"
                else -> ""
            }
            logMessage("Advertise start failed: errorCode=$errorCode $desc")
            isBleAdvertising = false
        }
    }
    //endregion

    //region BLE GATT server
    private var gattServer: BluetoothGattServer? = null
    private val charForIndicate get() = gattServer?.getService(UUID.fromString(SERVICE_UUID))?.getCharacteristic(UUID.fromString(CHAR_FOR_INDICATE_UUID))
    private val subscribedDevices = mutableSetOf<BluetoothDevice>()

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            runOnUiThread {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    isBleConnected = true
                    logMessage("Central did connect")
                } else {
                    isBleConnected = false
                    logMessage("Central did disconnect")
                    subscribedDevices.remove(device)
                    updateBleStatus()
                }
            }
        }

        override fun onNotificationSent(device: BluetoothDevice, status: Int) {
            logMessage("onNotificationSent status=$status")
        }

        override fun onCharacteristicReadRequest(device: BluetoothDevice, requestId: Int, offset: Int, characteristic: BluetoothGattCharacteristic) {
            var log: String = "onCharacteristicRead offset=$offset"
            if (characteristic.uuid == UUID.fromString(CHAR_FOR_READ_UUID)) {
                runOnUiThread {
                    val strValue = textCharForRead
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, strValue.toByteArray(Charsets.UTF_8))
                    log += "\nresponse=success, value=\"$strValue\""
                    logMessage(log)
                }
            } else {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, 0, null)
                log += "\nresponse=failure, unknown UUID\n${characteristic.uuid}"
                logMessage(log)
            }
        }

        override fun onCharacteristicWriteRequest(device: BluetoothDevice, requestId: Int, characteristic: BluetoothGattCharacteristic, preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray?) {
            var log: String = "onCharacteristicWrite offset=$offset responseNeeded=$responseNeeded preparedWrite=$preparedWrite"
            if (characteristic.uuid == UUID.fromString(CHAR_FOR_WRITE_UUID)) {
                var strValue = value?.toString(Charsets.UTF_8) ?: ""
                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, strValue.toByteArray(Charsets.UTF_8))
                    log += "\nresponse=success, value=\"$strValue\""
                } else {
                    log += "\nresponse=notNeeded, value=\"$strValue\""
                }
                runOnUiThread {
                    textCharForWrite = strValue
                }
            } else {
                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, 0, null)
                    log += "\nresponse=failure, unknown UUID\n${characteristic.uuid}"
                } else {
                    log += "\nresponse=notNeeded, unknown UUID\n${characteristic.uuid}"
                }
            }
            logMessage(log)
        }

        override fun onDescriptorReadRequest(device: BluetoothDevice, requestId: Int, offset: Int, descriptor: BluetoothGattDescriptor) {
            var log = "onDescriptorReadRequest"
            if (descriptor.uuid == UUID.fromString(CCC_DESCRIPTOR_UUID)) {
                val returnValue = if (subscribedDevices.contains(device)) {
                    log += " CCCD response=ENABLE_NOTIFICATION"
                    BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                } else {
                    log += " CCCD response=DISABLE_NOTIFICATION"
                    BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
                }
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, returnValue)
            } else {
                log += " unknown uuid=${descriptor.uuid}"
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, 0, null)
            }
            logMessage(log)
        }

        override fun onDescriptorWriteRequest(device: BluetoothDevice, requestId: Int, descriptor: BluetoothGattDescriptor, preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray) {
            var strLog = "onDescriptorWriteRequest"
            if (descriptor.uuid == UUID.fromString(CCC_DESCRIPTOR_UUID)) {
                var status = BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED
                if (descriptor.characteristic.uuid == UUID.fromString(CHAR_FOR_INDICATE_UUID)) {
                    if (Arrays.equals(value, BluetoothGattDescriptor.ENABLE_INDICATION_VALUE)) {
                        subscribedDevices.add(device)
                        status = BluetoothGatt.GATT_SUCCESS
                        strLog += ", subscribed"
                    } else if (Arrays.equals(value, BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE)) {
                        subscribedDevices.remove(device)
                        status = BluetoothGatt.GATT_SUCCESS
                        strLog += ", unsubscribed"
                    }
                }
                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, status, 0, null)
                }
                updateBleStatus()
            } else {
                strLog += " unknown uuid=${descriptor.uuid}"
                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, 0, null)
                }
            }
            logMessage(strLog)
        }
    }
    //endregion

    private fun bleStartGattServer() {
        val gattServer = bluetoothManager.openGattServer(this, gattServerCallback)
        val service = BluetoothGattService(UUID.fromString(SERVICE_UUID), BluetoothGattService.SERVICE_TYPE_PRIMARY)
        var charForRead = BluetoothGattCharacteristic(UUID.fromString(CHAR_FOR_READ_UUID),
            BluetoothGattCharacteristic.PROPERTY_READ,
            BluetoothGattCharacteristic.PERMISSION_READ)
        var charForWrite = BluetoothGattCharacteristic(UUID.fromString(CHAR_FOR_WRITE_UUID),
            BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE)
        var charForIndicate = BluetoothGattCharacteristic(UUID.fromString(CHAR_FOR_INDICATE_UUID),
            BluetoothGattCharacteristic.PROPERTY_INDICATE,
            BluetoothGattCharacteristic.PERMISSION_READ)
        var charConfigDescriptor = BluetoothGattDescriptor(UUID.fromString(CCC_DESCRIPTOR_UUID),
            BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE)
        charForIndicate.addDescriptor(charConfigDescriptor)

        service.addCharacteristic(charForRead)
        service.addCharacteristic(charForWrite)
        service.addCharacteristic(charForIndicate)

        val result = gattServer.addService(service)
        this.gattServer = gattServer
        logMessage("addService " + when(result) {
            true -> "OK"
            false -> "fail"
        })
    }

    private fun bleStopGattServer() {
        gattServer?.close()
        gattServer = null
        logMessage("gattServer closed")
        runOnUiThread {
            isBleConnected = false
        }
    }

    private fun bleIndicate(text: String) {
        val data = text.toByteArray(Charsets.UTF_8)
        charForIndicate?.let {
            it.value = data
            for (device in subscribedDevices) {
                logMessage("sending indication \"$text\"")
                gattServer?.notifyCharacteristicChanged(device, it, true)
            }
        }
    }

    private fun bleStartAdvertising() {
        if (isBleAdvertising || !enableRanging) {
            // Do nothing
            return
        }

        isBleAdvertising = true
        bleStartGattServer()
        bleAdvertiser.startAdvertising(advertiseSettings, advertiseData, advertiseCallback)
    }

    private fun bleStopAdvertising() {
        if (!isBleAdvertising) {
            return
        }

        isBleAdvertising = false
        bleStopGattServer()
        bleAdvertiser.stopAdvertising(advertiseCallback)
    }

    //
    // Activity and UI handling
    //
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
    private val mBleStatusView: TextView by lazy {
        findViewById(R.id.ble_status)
    }

    private fun updateDevicesDisplay() {
        var deviceDisplayText: String = "Connected Devices: ${devices.size}\n"

        deviceDisplayText += devices.map { (_, device) ->
            "${device.deviceName}, location: {${device.x}; ${device.y}}, distance: ${device.distance}"
        }
        .joinToString("\n")

        mConnectedDevicesView.text = deviceDisplayText
    }

    private fun updateLocationDisplay(location: RealVector?) {
        mLocationView.text = "Location: $location\n"
    }

    private fun updateBleStatus() {
        val displayText: String =
            "BLE Advertising: $isBleAdvertising\n" +
            "BLE Connected: $isBleConnected\n" +
            "Subscribers: ${subscribedDevices.count()}"

        mBleStatusView.text = displayText
    }

    private fun createDeviceToLocationMap(): HashMap<String, Location> {
        val result = HashMap<String, Location>()
        for (i in 1..6) {
            mPreferences.getString("peer${i}", null)?.let { deviceName ->
                result[deviceName] = Location(
                    (mPreferences.getString("peer${i}x", null)?.toDouble() ?: 0.0) * 1000,
                    (mPreferences.getString("peer${i}y", null)?.toDouble() ?: 0.0) * 1000
                )
            }
        }

        return result
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        updateDevicesDisplay()
        updateLocationDisplay(null)
        updateBleStatus()

        findViewById<Button>(R.id.start).setOnClickListener {
            deviceName = mPreferences.getString("device_name", null) ?: "Device"
            enableRanging = mPreferences.getBoolean("enable_ranging", false)
            deviceToLocation = createDeviceToLocationMap()
            bleStartAdvertising()

            if (mPreferences.getBoolean("publish", false)) {
                mode = 0
                nanClient.publishService(SERVICE_NAME, this, null)
            }
            else if (mPreferences.getBoolean("subscribe", false)) {
                mode = 1
                nanClient.subscribeService(SERVICE_NAME, this, null)
            }
            else {
                logMessage("Please select a mode")
            }
        }

        findViewById<Button>(R.id.stop).setOnClickListener {
            bleStopAdvertising()
            nanClient.stopSession(mode, SERVICE_NAME, this)
        }
    }

}