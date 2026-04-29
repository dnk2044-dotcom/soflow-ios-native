// Operations.swift
// Direct ports of the four `*Operate.java` files in
// com/inuker/bluetooth/bledata/mpControlData/operate/
// Each one builds the hex-frame that is then AES-encrypted and written.
// Frame structure (from MPSpeedMaxOperate.java):
//   <header(str)> + "00" + <payload(4 hex chars BE)> + <checksum(2 hex chars)>

import Foundation

public enum MPOperations {

    /// Set top speed limit.
    /// Java: MPSpeedMaxOperate.parser → CHECK_BEGIN=1, CHECK_END=5
    /// → checksum sums bytes [1, 1+5) = 5 bytes (skip header byte 0)
    public static func speedMax(header: String, speed: Int) -> String {
        let payload = HexParser.addZeroForNumLeft(String(speed, radix: 16, uppercase: true), 4)
        let body = header + "00" + payload
        return body + HexParser.checksum(body, beginByte: 1, byteCount: 5)
    }

    /// Set speed-mode/gear.
    /// Java: MPSpeedSettingOperate.parser → CHECK_BEGIN=1, CHECK_END=4
    public static func speedSetting(header: String, mode: Int) -> String {
        let payload = HexParser.addZeroForNumLeft(String(mode, radix: 16, uppercase: true), 2)
        let body = header + "00" + "0" + String(mode)
        return body + HexParser.checksum(body, beginByte: 1, byteCount: 4)
    }

    /// Master on/off. Java: MPSwitchOperate.parser → CHECK_BEGIN=1, CHECK_END=4
    public static func switchOnOff(header: String, on: Bool) -> String {
        let body = header + "00" + (on ? "01" : "00")
        return body + HexParser.checksum(body, beginByte: 1, byteCount: 4)
    }

    /// Toggle metric/imperial display.
    /// Java: MPSwitchFlowMilesOperate.parser → CHECK_BEGIN=1, CHECK_END=4
    public static func switchFlowMiles(header: String, metric: Bool) -> String {
        let body = header + "00" + "0" + String(metric ? 0 : 1)
        return body + HexParser.checksum(body, beginByte: 1, byteCount: 4)
    }
}

// MARK: - Parsers (TODO)
//
// These need to be ported from .java files in
// com/inuker/bluetooth/bledata/mpControlData/parser/  :
//
//   MPStateParser.java         -> live ride state (speed, battery, mode)
//   MPBmsReturnsParser.java    -> battery management response
//   MPSwitchParser.java        -> ack of MPSwitchOperate
//   MPSwitchLongParser.java    -> long form
//   MPSwitchQueryReturnsParser.java -> query reply
//   MPSwitchSaveTreesParser.java    -> eco-mode reply
//   XHMPStateParser.java       -> XH variant (newer firmware?)
//
// Each parser takes the AES-decrypted hex string and uses
// HexParser.hex16to10Byte1 / Byte2 to slice fields out of fixed offsets.
// Expect each port to be ~30-80 lines of straight-line Swift.
public enum MPParsers {
    // Implement me — see comments above and read the corresponding .java
    // file in /tmp/dec_so/sources/com/inuker/bluetooth/bledata/mpControlData/parser/
}
