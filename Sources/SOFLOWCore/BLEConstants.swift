// BLEConstants.swift
// Mirrors com/inuker/bluetooth/bledata/data/constant/DataConstant.java
// Source extracted from /tmp/dec_so/sources/com/inuker/bluetooth/bledata/data/constant/DataConstant.java

import Foundation
import CoreBluetooth

/// Three scooter-firmware vendors are supported, picked at runtime.
/// SO ONE-PLUS defaults to .walkiz (set in SplashActivity.onCreate).
public enum ScooterFactory: Int {
    case kingMeter = 0   // KING-METER display vendor
    case nordic    = 1   // Nordic UART Service (NUS)
    case walkiz    = 2   // SOFLOW custom "Walkiz" service

    public var serviceUUID: CBUUID {
        switch self {
        case .kingMeter: return CBUUID(string: "43480001-F001-4B49-4E47-204D45544552")
        case .nordic:    return CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
        case .walkiz:    return CBUUID(string: "00008000-0000-1000-8000-57616C6B697A")
        }
    }

    public var writeCharUUID: CBUUID {
        switch self {
        case .kingMeter: return CBUUID(string: "43480002-F001-4B49-4E47-204D45544552")
        case .nordic:    return CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
        case .walkiz:    return CBUUID(string: "00008001-0000-1000-8000-57616C6B697A")
        }
    }

    public var notifyCharUUID: CBUUID {
        switch self {
        case .kingMeter: return CBUUID(string: "43480003-F001-4B49-4E47-204D45544552")
        case .nordic:    return CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
        case .walkiz:    return CBUUID(string: "00008002-0000-1000-8000-57616C6B697A")
        }
    }
}

public enum BLEUUIDs {
    /// Standard CCCD descriptor — used to enable notifications.
    public static let cccd = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")

    /// Shield/encryption service (used for AES key handshake).
    public static let shieldService = CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d1910")
    public static let shieldTx      = CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d1913")

    /// FOTA (firmware update) service — short 16-bit UUIDs from index.js
    public static let fotaService    = CBUUID(string: "2600")
    public static let fotaCtrlChar   = CBUUID(string: "7000")
    public static let fotaDataChar   = CBUUID(string: "7001")

    /// Advertised name prefix used by SOFLOW scooters.
    public static let nameFilterPrefix = "HIBOY"
}

public enum FOTAControlOp: UInt8 {
    case signature        = 0
    case digest           = 1
    case startRequest     = 2
    case startResponse    = 3
    case newSector        = 4
    case integrityCheckRequest  = 5
    case integrityCheckResponse = 6
}

public enum SOFLOWNet {
    /// Backend URL extracted from inuker NetConstant.java
    /// NOTE: plain HTTP, not HTTPS. iOS App Transport Security will block this
    /// unless you add an NSAppTransportSecurity exception in Info.plist.
    public static let baseURL = URL(string: "http://47.52.238.166:8080/")!

    /// AES key used for the network-layer "reciprocal" digest.
    /// Source: inuker/bluetooth/bledata/network/digest/DigestKey.java
    public static let networkAESKey = "cnplgolf"
}
