//
//  BluetoothLEView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 19/09/22.
//

import SwiftUI
import CoreBluetooth

struct BluetoothLEView: View {
    let bluetoothLEListener = BluetoothLEListener()
    @ObservedObject var bleManager: BluetoothLEManager

    init() {
        bleManager = BluetoothLEManager(bluetoothLEDelegate: bluetoothLEListener)
    }

    var body: some View {
        VStack {
            //TextField("Your Name", text: $bleManager.logText)
            HStack {
                Text(bleManager.bleStatus)
                Divider()
                    .frame(height: 20)
                Text("x: " + String(format: "%.1f", bleManager.x) + ", y: " + String(format: "%.1f", bleManager.y))
            }
        }
    }
}

struct BluetoothLEView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothLEView()
    }
}

protocol BluetoothLEDelegate {
    func didUpdateLocation(x: CGFloat, y: CGFloat)
}

class BluetoothLEListener: BluetoothLEDelegate {
    func didUpdateLocation(x: CGFloat, y: CGFloat) {
        return
    }
}

class BluetoothLEManager: NSObject, ObservableObject {
    let timeFormatter = DateFormatter()

    // BLE related properties
    let uuidService = CBUUID(string: "25AE1441-05D3-4C5B-8281-93D4E07420CF")
    let uuidCharForRead = CBUUID(string: "25AE1442-05D3-4C5B-8281-93D4E07420CF")
    let uuidCharForWrite = CBUUID(string: "25AE1443-05D3-4C5B-8281-93D4E07420CF")
    let uuidCharForIndicate = CBUUID(string: "25AE1444-05D3-4C5B-8281-93D4E07420CF")
    
    var bleCentral: CBCentralManager!
    var connectedPeripheral: CBPeripheral?

    let bluetoothLEDelegate: BluetoothLEDelegate
    
    @Published var logText = "Sample small text"
    @Published var bleStatus = "Unknown"
    @Published var x: CGFloat = 0.0
    @Published var y: CGFloat = 0.0

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
            appendLog("state = \(lifecycleState)")
        }
    }

    init(bluetoothLEDelegate: BluetoothLEDelegate) {
        // using DispatchQueue.main means we can update UI directly from delegate methods
        self.bluetoothLEDelegate = bluetoothLEDelegate
        super.init()
        bleCentral = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    func bleRestartLifecycle() {
        guard bleCentral.state == .poweredOn else {
            connectedPeripheral = nil
            lifecycleState = .bluetoothNotReady
            return
        }
        
        if let oldPeripheral = connectedPeripheral {
            bleCentral.cancelPeripheralConnection(oldPeripheral)
        }
        connectedPeripheral = nil
        bleScan()
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
            appendLog("ERROR: read failed, characteristic unavailable, uuid = \(uuid.uuidString)")
            return
        }
        connectedPeripheral?.readValue(for: characteristic)
    }

    func bleWriteCharacteristic(uuid: CBUUID, data: Data) {
        guard let characteristic = getCharacteristic(uuid: uuid) else {
            appendLog("ERROR: write failed, characteristic unavailable, uuid = \(uuid.uuidString)")
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
    
    func appendLog(_ message: String) {
        let logLine = "\(timeFormatter.string(from: Date())) \(message)"
        print("DEBUG: \(logLine)")
        logText.append("\n\(logLine)")
        bleStatus = bleGetStatusString()
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        appendLog("central didUpdateState: \(central.state.stringValue)")
        bleRestartLifecycle()
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        appendLog("didDiscover {name = \(peripheral.name ?? String("nil"))}")

        guard connectedPeripheral == nil else {
            appendLog("didDiscover ignored (connectedPeripheral already set)")
            return
        }

        bleCentral.stopScan()
        bleConnect(to: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        appendLog("didConnect")

        lifecycleState = .connectedDiscovering
        peripheral.delegate = self
        peripheral.discoverServices([uuidService])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if peripheral === connectedPeripheral {
            appendLog("didFailToConnect")
            connectedPeripheral = nil
            bleRestartLifecycle()
        } else {
            appendLog("didFailToConnect, unknown peripheral, ingoring")
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral === connectedPeripheral {
            appendLog("didDisconnect")
            connectedPeripheral = nil
            bleRestartLifecycle()
        } else {
            appendLog("didDisconnect, unknown peripheral, ingoring")
        }
    }
}

extension BluetoothLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == uuidService }) else {
            appendLog("ERROR: didDiscoverServices, service NOT found\nerror = \(String(describing: error)), disconnecting")
            bleCentral.cancelPeripheralConnection(peripheral)
            return
        }

        appendLog("didDiscoverServices, service found")
        peripheral.discoverCharacteristics([uuidCharForRead, uuidCharForWrite, uuidCharForIndicate], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        appendLog("didModifyServices")
        // usually this method is called when Android application is terminated
        if invalidatedServices.first(where: { $0.uuid == uuidService }) != nil {
            appendLog("disconnecting because peripheral removed the required service")
            bleCentral.cancelPeripheralConnection(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        appendLog("didDiscoverCharacteristics \(error == nil ? "OK" : "error: \(String(describing: error))")")

        if let charIndicate = service.characteristics?.first(where: { $0.uuid == uuidCharForIndicate }) {
            peripheral.setNotifyValue(true, for: charIndicate)
        } else {
            appendLog("WARN: characteristic for indication not found")
            lifecycleState = .connected
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            appendLog("didUpdateValue error: \(String(describing: error))")
            return
        }

        let data = characteristic.value ?? Data()
        let stringValue = String(data: data, encoding: .utf8) ?? ""
        let distancesArr = stringValue.components(separatedBy: ",")
        if (characteristic.uuid == uuidCharForRead || characteristic.uuid == uuidCharForIndicate) && distancesArr.count == 2 {
            x = CGFloat(Float(distancesArr[0]) ?? 0.0)
            y = CGFloat(Float(distancesArr[1]) ?? 0.0)
        }
        bluetoothLEDelegate.didUpdateLocation(x: x, y: y)
        appendLog("didUpdateValue '\(stringValue)'")
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        appendLog("didWrite \(error == nil ? "OK" : "error: \(String(describing: error))")")
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else {
            appendLog("didUpdateNotificationState error\n\(String(describing: error))")
            lifecycleState = .connected
            return
        }

        if characteristic.uuid == uuidCharForIndicate {
            let info = characteristic.isNotifying ? "Subscribed" : "Not subscribed"
            appendLog(info)
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
