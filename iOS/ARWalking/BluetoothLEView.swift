//
//  BluetoothLEView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 19/09/22.
//

import SwiftUI
import CoreBluetooth

protocol BluetoothLEViewDelegate {
    func appendLog(_ message: String, status: String)
}

struct BluetoothLEView: View, BluetoothLEViewDelegate {
    
    let timeFormatter = DateFormatter()

    var bleManager: BluetoothLEManager!

    @State var logText = "Sample small text"
    @State var bleStatus = "Unknown"
    var x = "2.112"
    
    init() {
        bleManager = BluetoothLEManager(bluetoothLEViewDelegate: self)
    }
    
    var body: some View {
        VStack {
            Text("Status: " + bleStatus)
            Text("x: " + x + ", y: 0.0, z = 0.0")
        }
    }
    
    func appendLog(_ message: String, status: String) {
        let logLine = "\(timeFormatter.string(from: Date())) \(message)"
        print("DEBUG: \(logLine)")
        logText.append("\n\(logLine)")
        bleStatus = status
    }
}

struct BluetoothLEView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothLEView()
    }
}

class BluetoothLEManager: NSObject {
    // BLE related properties
    let uuidService = CBUUID(string: "25AE1441-05D3-4C5B-8281-93D4E07420CF")
    let uuidCharForRead = CBUUID(string: "25AE1442-05D3-4C5B-8281-93D4E07420CF")
    let uuidCharForWrite = CBUUID(string: "25AE1443-05D3-4C5B-8281-93D4E07420CF")
    let uuidCharForIndicate = CBUUID(string: "25AE1444-05D3-4C5B-8281-93D4E07420CF")
    
    var bleCentral: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var bluetoothLEViewDelegate: BluetoothLEViewDelegate

    enum BLELifecycleState: String {
        case bluetoothNotReady
        case disconnected
        case scanning
        case connecting
        case connectedDiscovering
        case connected
    }

    var lifecycleState = BLELifecycleState.bluetoothNotReady {
        didSet {
            guard lifecycleState != oldValue else { return }
            bluetoothLEViewDelegate.appendLog("state = \(lifecycleState)", status: bleGetStatusString())
//            if oldValue == .connected {
//                labelSubscription.text = "Not subscribed"
//            }
        }
    }

    init(bluetoothLEViewDelegate: BluetoothLEViewDelegate) {
        // using DispatchQueue.main means we can update UI directly from delegate methods
        self.bluetoothLEViewDelegate = bluetoothLEViewDelegate
        super.init()
        bleCentral = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    func bleRestartLifecycle() {
        guard bleCentral.state == .poweredOn else {
            connectedPeripheral = nil
            lifecycleState = .bluetoothNotReady
            return
        }

        //if userWantsToScanAndConnect {
        if true {
            if let oldPeripheral = connectedPeripheral {
                bleCentral.cancelPeripheralConnection(oldPeripheral)
            }
            connectedPeripheral = nil
            bleScan()
        } else {
            bleDisconnect()
        }
    }

    func bleScan() {
        lifecycleState = .scanning
        bleCentral.scanForPeripherals(withServices: [uuidService], options: nil)
    }

    func bleConnect(to peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        lifecycleState = .connecting
        bleCentral.connect(peripheral, options: nil)
    }

    func bleDisconnect() {
        if bleCentral.isScanning {
            bleCentral.stopScan()
        }
        if let peripheral = connectedPeripheral {
            bleCentral.cancelPeripheralConnection(peripheral)
        }
        lifecycleState = .disconnected
    }

    func bleReadCharacteristic(uuid: CBUUID) {
        guard let characteristic = getCharacteristic(uuid: uuid) else {
            bluetoothLEViewDelegate.appendLog("ERROR: read failed, characteristic unavailable, uuid = \(uuid.uuidString)", status: bleGetStatusString())
            return
        }
        connectedPeripheral?.readValue(for: characteristic)
    }

    func bleWriteCharacteristic(uuid: CBUUID, data: Data) {
        guard let characteristic = getCharacteristic(uuid: uuid) else {
            bluetoothLEViewDelegate.appendLog("ERROR: write failed, characteristic unavailable, uuid = \(uuid.uuidString)", status: bleGetStatusString())
            return
        }
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }

    func getCharacteristic(uuid: CBUUID) -> CBCharacteristic? {
        guard let service = connectedPeripheral?.services?.first(where: { $0.uuid == uuidService }) else {
            return nil
        }
        return service.characteristics?.first { $0.uuid == uuid }
    }

    private func bleGetStatusString() -> String {
        guard let bleCentral = bleCentral else { return "not initialized" }
        switch bleCentral.state {
        case .unauthorized:
            return bleCentral.state.stringValue + " (allow in Settings)"
        case .poweredOff:
            return "Bluetooth OFF"
        case .poweredOn:
            return "ON, \(lifecycleState)"
        default:
            return bleCentral.state.stringValue
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothLEViewDelegate.appendLog("central didUpdateState: \(central.state.stringValue)", status: bleGetStatusString())
        bleRestartLifecycle()
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        bluetoothLEViewDelegate.appendLog("didDiscover {name = \(peripheral.name ?? String("nil"))}", status: bleGetStatusString())

        guard connectedPeripheral == nil else {
            bluetoothLEViewDelegate.appendLog("didDiscover ignored (connectedPeripheral already set)", status: bleGetStatusString())
            return
        }

        bleCentral.stopScan()
        bleConnect(to: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        bluetoothLEViewDelegate.appendLog("didConnect", status: bleGetStatusString())

        lifecycleState = .connectedDiscovering
        peripheral.delegate = self
        peripheral.discoverServices([uuidService])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if peripheral === connectedPeripheral {
            bluetoothLEViewDelegate.appendLog("didFailToConnect", status: bleGetStatusString())
            connectedPeripheral = nil
            bleRestartLifecycle()
        } else {
            bluetoothLEViewDelegate.appendLog("didFailToConnect, unknown peripheral, ingoring", status: bleGetStatusString())
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral === connectedPeripheral {
            bluetoothLEViewDelegate.appendLog("didDisconnect", status: bleGetStatusString())
            connectedPeripheral = nil
            bleRestartLifecycle()
        } else {
            bluetoothLEViewDelegate.appendLog("didDisconnect, unknown peripheral, ingoring", status: bleGetStatusString())
        }
    }
}

extension BluetoothLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == uuidService }) else {
            bluetoothLEViewDelegate.appendLog("ERROR: didDiscoverServices, service NOT found\nerror = \(String(describing: error)), disconnecting", status: bleGetStatusString())
            bleCentral.cancelPeripheralConnection(peripheral)
            return
        }

        bluetoothLEViewDelegate.appendLog("didDiscoverServices, service found", status: bleGetStatusString())
        peripheral.discoverCharacteristics([uuidCharForRead, uuidCharForWrite, uuidCharForIndicate], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        bluetoothLEViewDelegate.appendLog("didModifyServices", status: bleGetStatusString())
        // usually this method is called when Android application is terminated
        if invalidatedServices.first(where: { $0.uuid == uuidService }) != nil {
            bluetoothLEViewDelegate.appendLog("disconnecting because peripheral removed the required service", status: bleGetStatusString())
            bleCentral.cancelPeripheralConnection(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        bluetoothLEViewDelegate.appendLog("didDiscoverCharacteristics \(error == nil ? "OK" : "error: \(String(describing: error))")", status: bleGetStatusString())

        if let charIndicate = service.characteristics?.first(where: { $0.uuid == uuidCharForIndicate }) {
            peripheral.setNotifyValue(true, for: charIndicate)
        } else {
            bluetoothLEViewDelegate.appendLog("WARN: characteristic for indication not found", status: bleGetStatusString())
            lifecycleState = .connected
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            bluetoothLEViewDelegate.appendLog("didUpdateValue error: \(String(describing: error))", status: bleGetStatusString())
            return
        }

        let data = characteristic.value ?? Data()
        let stringValue = String(data: data, encoding: .utf8) ?? ""
        if characteristic.uuid == uuidCharForRead {
//            textFieldDataForRead.text = stringValue
        } else if characteristic.uuid == uuidCharForIndicate {
//            textFieldDataForIndicate.text = stringValue
        }
        bluetoothLEViewDelegate.appendLog("didUpdateValue '\(stringValue)'", status: bleGetStatusString())
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        bluetoothLEViewDelegate.appendLog("didWrite \(error == nil ? "OK" : "error: \(String(describing: error))")", status: bleGetStatusString())
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else {
            bluetoothLEViewDelegate.appendLog("didUpdateNotificationState error\n\(String(describing: error))", status: bleGetStatusString())
            lifecycleState = .connected
            return
        }

        if characteristic.uuid == uuidCharForIndicate {
            let info = characteristic.isNotifying ? "Subscribed" : "Not subscribed"
//            labelSubscription.text = info
            bluetoothLEViewDelegate.appendLog(info, status: bleGetStatusString())
        }
        lifecycleState = .connected
    }
}

// MARK: - Other extensions
extension CBManagerState {
    var stringValue: String {
        switch self {
        case .unknown: return "unknown"
        case .resetting: return "resetting"
        case .unsupported: return "unsupported"
        case .unauthorized: return "unauthorized"
        case .poweredOff: return "poweredOff"
        case .poweredOn: return "poweredOn"
        @unknown default: return "\(rawValue)"
        }
    }
}
