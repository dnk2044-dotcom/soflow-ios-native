// BLEManager.swift
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

    public var deviceAESKey: Data = AESKeyDerivation.masterKey

    private var central: CBCentralManager!
    private var writeChar: CBCharacteristic?
    private var notifyChar: CBCharacteristic?

    public override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    public func setFactory(_ f: ScooterFactory) { self.factory = f }

    public func startScan() {
        guard central.state == .poweredOn else { return }
        discovered.removeAll()
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

    public func writeEncrypted(frameHex: String, padLength: Int = 32) throws {
        guard let writeChar, let connected else {
            throw NSError(domain: "BLEManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Not connected"])
        }
        let cipherHex = try AESKeyDerivation.encryptParser(frameHex, padLength: padLength)
        let cipher = HexParser.hexToBytes(cipherHex)
        connected.writeValue(cipher, for: writeChar, type: .withoutResponse)
    }

    public func writeRaw(_ data: Data) {
        guard let writeChar, let connected else { return }
        connected.writeValue(data, for: writeChar, type: .withoutResponse)
    }

    public func send(_ commandBuilder: () -> Data) {
        writeRaw(commandBuilder())
    }
}

extension BLEManager: CBCentralManagerDelegate {
    nonisolated public func centralManagerDidUpdateState(_ c: CBCentralManager) {
        Task { @MainActor in self.state = c.state }
    }

    nonisolated public func centralManager(_ c: CBCentralManager,
                                           didDiscover peripheral: CBPeripheral,
                                           advertisementData: [String: Any],
                                           rssi RSSI: NSNumber) {
        Task { @MainActor in
            if !self.discovered.contains(where: { $0.identifier == peripheral.identifier }) {
                self.discovered.append(peripheral)
            }
        }
    }

    nonisolated public func centralManager(_ c: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.connected = peripheral
            peripheral.discoverServices([self.factory.serviceUUID, BLEUUIDs.shieldService])
        }
    }

    nonisolated public func centralManager(_ c: CBCentralManager,
                                           didDisconnectPeripheral peripheral: CBPeripheral,
                                           error: Error?) {
        Task { @MainActor in
            if self.connected?.identifier == peripheral.identifier {
                self.connected = nil
                self.writeChar = nil
                self.notifyChar = nil
            }
        }
    }
}

extension BLEManager: CBPeripheralDelegate {
    nonisolated public func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            for svc in p.services ?? [] where svc.uuid == self.factory.serviceUUID {
                p.discoverCharacteristics([self.factory.writeCharUUID, self.factory.notifyCharUUID], for: svc)
            }
        }
    }

    nonisolated public func peripheral(_ p: CBPeripheral,
                                       didDiscoverCharacteristicsFor service: CBService,
                                       error: Error?) {
        Task { @MainActor in
            for ch in service.characteristics ?? [] {
                if ch.uuid == self.factory.writeCharUUID  { self.writeChar  = ch }
                if ch.uuid == self.factory.notifyCharUUID {
                    self.notifyChar = ch
                    p.setNotifyValue(true, for: ch)
                }
            }
        }
    }

    nonisolated public func peripheral(_ p: CBPeripheral,
                                       didUpdateValueFor characteristic: CBCharacteristic,
                                       error: Error?) {
        let raw = characteristic.value ?? Data()
        let uuid = characteristic.uuid
        Task { @MainActor in
            guard uuid == self.factory.notifyCharUUID else { return }
            self.lastNotify = raw
            let item = BeaconItem(type: 0, len: raw.count, bytes: raw)
            if let st = MPStateParser.parse(item) {
                self.lastState = st
                return
            }
            _ = MPSwitchParser.parse(item)
        }
    }
}
