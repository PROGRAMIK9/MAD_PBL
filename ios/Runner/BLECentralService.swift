import Foundation
import CoreBluetooth
import Flutter

@objc class BLECentralService: NSObject {
    private var central: CBCentralManager!
    private var eventSink: FlutterEventSink?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    func startDiscovery() {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            eventSink?("{\"type\": \"ble_status\", \"message\": \"scan_started\"}")
        } else {
            eventSink?("{\"type\": \"ble_status\", \"message\": \"adapter_not_ready\"}")
        }
    }

    func stopDiscovery() {
        central.stopScan()
        eventSink?("{\"type\": \"ble_status\", \"message\": \"scan_stopped\"}")
    }

    func attachSink(_ sink: @escaping FlutterEventSink) {
        eventSink = sink
    }

    func detachSink() {
        eventSink = nil
    }
}

extension BLECentralService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // No-op for now
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let id = peripheral.identifier.uuidString
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? String(id.suffix(6))
        let payload: [String: Any] = ["deviceId": id, "deviceName": name, "rssi": RSSI.intValue, "platformLabel": "ios", "transport": "ble"]
        if let sink = eventSink {
            sink(payload)
        }
    }
}

extension BLECentralService: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        attachSink(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        detachSink()
        return nil
    }
}
