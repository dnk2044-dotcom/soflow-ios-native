// BLEManager.swift
// CoreBluetooth replacement for the Android `com.inuker.bluetooth` library.
// This is a starting skeleton — connect/disconnect/scan/read/write/notify
// works; protocol parsers must still be ported from
// /tmp/dec_so/sources/com/inuker/bluetooth/bledata/mpControlData/parser/*.java
// Each MP*Operate.java becomes a Swift function that builds a frame, AES-encrypts it,
// and writes via `write(_:on:)`. Each MP*Parser.java becomes a Swift function that
// AES-decrypts notify bytes and decodes the structured response.

import Foundation
import CoreBluetooth

@MainActor
public final class BLEManager: NSObject, ObservableObject {
    @Published public private(set) var state: CBManagerState = .unknown
    @Published public private(set) var discovered: [CBPeripheral] = []
    @Published public private(set) var connected: CBPeripheral?
    @Published public private(set) var lastNotify: Data?
    @Published public private(set) var lastState: MPStateData?
    @Published public private(set) var factory: ScooterFactory = .walkiz

    /// AES-128 master key — see analysis/AES-KEY-DERIVATION-REPORT.md.
    /// Hardcoded in the Android APK as DigestKey.bKey. Used for all
    /// AES-ECB-NoPadding encrypted commands.
    public var deviceAESKey: Data = AESKeyDerivation.masterKey

    private var central: CBCentralManager!
    private var writeChar: CBCharacteristic?
    private var notifyChar: CBCharacteristic?

    public override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Public API

    public func setFactory(_ f: ScooterFactory) { self.factory = f }

    public func startScan() {
        guard central.state == .poweredOn else { return }
        discovered.removeAll()
        // Scan all services — the SOFLOW BLE name doesn't always include a service in the advertisement
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    public func stopScan() { central.stopScan() }

    public func connect(_ peripheral: CBPeripheral) {
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    public func disconnect() {
        guard let p = connected else { return }
        central.cancelPeripheralConnection(p)
    }

    /// Encrypt frame with the master AES key and write it to the scooter.
    public func writeEncrypted(frameHex: String, padLength: Int = 32) throws {
        guard let writeChar, let connected else {
            throw NSError(domain: "BLEManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"])
        }
        let cipherHex = try AESKeyDerivation.encryptParser(frameHex, padLength: padLength)
        let cipher = HexParser.hexToBytes(cipherHex)
        connected.writeValue(cipher, for: writeChar, type: .withoutResponse)
    }

    /// Send a pre-built command (already encrypted) to the scooter.
    public func writeRaw(_ data: Data) {
        guard let writeChar, let connected else { return }
        connected.writeValue(data, for: writeChar, type: .withoutResponse)
    }

    /// High-level convenience: send any of the BleDataOperateManage builders.
    public func send(_ commandBuilder: () -> Data) {
        writeRaw(commandBuilder())
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ c: CBCentralManager) { state = c.state }

    public func centralManager(_ c: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String: Any],
                               rssi RSSI: NSNumber) {
        guard !discovered.contains(where: { $0.identifier == peripheral.identifier }) else { return }
        // Optional name filter — uncomment to restrict to SOFLOW scooters only.
        // if peripheral.name?.hasPrefix(BLEUUIDs.nameFilterPrefix) != true { return }
        discovered.append(peripheral)
    }

    public func centralManager(_ c: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connected = peripheral
        peripheral.discoverServices([factory.serviceUUID, BLEUUIDs.shieldService])
    }

    public func centralManager(_ c: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if connected?.identifier == peripheral.identifier {
            connected = nil; writeChar = nil; notifyChar = nil
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    public func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        for svc in p.services ?? [] where svc.uuid == factory.serviceUUID {
            p.discoverCharacteristics([factory.writeCharUUID, factory.notifyCharUUID], for: svc)
        }
    }

    public func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor service: CBServic