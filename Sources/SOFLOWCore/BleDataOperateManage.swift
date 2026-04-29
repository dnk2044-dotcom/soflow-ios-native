// BleDataOperateManage.swift
// Port of com/inuker/bluetooth/bledata/mpControlData/operate/BleDataOperateManage.java
//
// This is the main "send a command to the scooter" facade. Each method
// builds an unencrypted parser string, right-pads it to a block boundary,
// AES-ECB encrypts it with the hardcoded master key, and returns the raw
// bytes ready to be written to the BLE write characteristic.
//
// Original Java method shape (one example):
//
//     public static byte[] battery_lock_setting(MPSwitchData d) {
//         String parser = MPSwitchOperate.parser(BATTERY_LOCK_SETTING, d);
//         parser = DigestAES.encrypt(
//                    DigestAES.hexToByteArray(DigestAES.addZeroForNum(parser, 32)),
//                    DigestKey.bKey);
//         return HexUtil.hexStringToBytes(parser);
//     }
//
// All command headers below are byte-identical to the Android constants.

import Foundation

public enum BleDataOperateManage {

    // MARK: - Command headers (D7xx) — verbatim from Java
    public static let SPEED_MAX               = "D707A9"
    public static let LOCK_MODE               = "D706A0"
    public static let BRIGHTNESS_SETTING      = "D706A1"
    public static let LAMP_SETTING            = "D706A2"
    public static let SPEED_MODE              = "D706A3"
    public static let CRUISE_SETTING          = "D706A4"
    public static let BOOST_SETTING           = "D706A5"
    public static let CONNECTION_STATUS_LIGHT = "D706A6"
    public static let UNIT                    = "D706A7"
    public static let TURNING_LIGHTS          = "D706A8"
    public static let QUERY                   = "D706D9"
    public static let RESET                   = "D706D7"
    public static let SAVED_TREES             = "D706D8"
    public static let DARK_MODE               = "D706D6"
    public static let BATTERY_LOCK_SETTING    = "D706D5"
    public static let FLOWMILES               = "D706B5"
    public static let ECO                     = "D706F1"
    public static let OTA                     = "D707F1"
    public static let OTAPACKAGE_SIZE         = "D707F2"

    // MARK: - Helpers

    /// Build, pad to 32 hex chars, AES-encrypt, return bytes.
    private static func encrypt32(_ parserHex: String) -> Data {
        do {
            let cipherHex = try AESKeyDerivation.encryptParser(parserHex, padLength: 32)
            return HexParser.hexToBytes(cipherHex)
        } catch {
            return Data()
        }
    }

    /// Build, pad to 64 hex chars (= two AES blocks), encrypt, return bytes.
    /// Used by `change_BleName`.
    private static func encrypt64(_ parserHex: String) -> Data {
        do {
            let cipherHex = try AESKeyDerivation.encryptParser(parserHex, padLength: 64)
            return HexParser.hexToBytes(cipherHex)
        } catch {
            return Data()
        }
    }

    // MARK: - Public command builders

    /// Top-speed limit. Plain (no AES) per Android — kept here for symmetry.
    public static func setSpeedMax(_ kmh: Int) -> Data {
        let frame = MPOperations.speedMax(header: SPEED_MAX, speed: kmh)
        return HexParser.hexToBytes(frame)
    }

    public static func batteryLockSetting(success: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: BATTERY_LOCK_SETTING, on: success)
        return encrypt32(parser)
    }

    public static func boostSetting(on: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: BOOST_SETTING, on: on)
        return encrypt32(parser)
    }

    public static func cruiseSetting(on: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: CRUISE_SETTING, on: on)
        return encrypt32(parser)
    }

    public static func darkMode(on: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: DARK_MODE, on: on)
        return encrypt32(parser)
    }

    public static func eco(level: Int) -> Data {
        let parser = MPOperations.speedSetting(header: ECO, mode: level)
        return encrypt32(parser)
    }

    public static func flowMiles(metric: Bool) -> Data {
        let parser = MPOperations.switchFlowMiles(header: FLOWMILES, metric: metric)
        return encrypt32(parser)
    }

    public static func unit(metric: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: UNIT, on: metric)
        return encrypt32(parser)
    }

    public static func turningLights(on: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: TURNING_LIGHTS, on: on)
        return encrypt32(parser)
    }

    public static func connectionLight(on: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: CONNECTION_STATUS_LIGHT, on: on)
        return encrypt32(parser)
    }

    public static func brightness(level: Int) -> Data {
        let parser = MPOperations.speedSetting(header: BRIGHTNESS_SETTING, mode: level)
        return encrypt32(parser)
    }

    public static func lampSetting(on: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: LAMP_SETTING, on: on)
        return encrypt32(parser)
    }

    public static func speedMode(level: Int) -> Data {
        let parser = MPOperations.speedSetting(header: SPEED_MODE, mode: level)
        return encrypt32(parser)
    }

    public static func lockMode(on: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: LOCK_MODE, on: on)
        return encrypt32(parser)
    }

    public static func query() -> Data {
        let parser = MPOperations.switchOnOff(header: QUERY, on: false)
        return encrypt32(parser)
    }

    public static func reset() -> Data {
        let parser = MPOperations.switchOnOff(header: RESET, on: true)
        return encrypt32(parser)
    }

    public static func savedTrees(on: Bool) -> Data {
        let parser = MPOperations.switchOnOff(header: SAVED_TREES, on: on)
        return encrypt32(parser)
    }

    /// Change the BLE advertised name. Up to 26 ASCII chars (52 hex chars
    /// + 12 chars reserved for header+checksum padding == 64 hex chars).
    public static func changeBleName(_ name: String) -> Data {
        let utf8Hex = name.utf8.map { String(format: "%02X", $0) }.joined()
        return encrypt64(utf8Hex)
    }
}
