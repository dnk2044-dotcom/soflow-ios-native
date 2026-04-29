// HexParser.swift
// Port of com/inuker/bluetooth/bledata/mpControlData/util/HexParser.java
// All scooter command frames are built/parsed as hex strings on the
// Android side; we keep that convention to make the protocol bytes match
// the Android wire format exactly.

import Foundation

public enum HexParser {

    /// One-byte slice as decimal string. Java `hex16To10Byte1` equivalent.
    public static func hex16to10Byte1(_ s: String, at i: Int) -> String? {
        guard i + 2 <= s.count else { return nil }
        return Int(substring(s, i, i+2), radix: 16).map(String.init)
    }

    /// Two-byte big-endian slice as decimal string. Java `hex16To10Byte2`.
    public static func hex16to10Byte2(_ s: String, at i: Int) -> String? {
        guard i + 4 <= s.count else { return nil }
        return Int(substring(s, i, i+4), radix: 16).map(String.init)
    }

    /// Faithful port of `HexParser.toCheck(HexParser.add16(split1Byte(str, begin, byteCount)))`.
    /// In the Java code the chain is:
    ///   1. `split1Byte` slices bytes [begin, begin+byteCount) from the string
    ///   2. `add16` sums them as hex bytes
    ///   3. `toCheck` returns the LAST TWO hex chars of that sum
    /// — i.e. the low byte. So `checksum(frame, beginByte, byteCount)` returns
    /// a 2-char uppercase hex string suitable for appending to the frame.
    public static func checksum(_ frame: String, beginByte: Int, byteCount: Int) -> String {
        var sum: UInt = 0
        // skip beginByte * 2 hex chars (= beginByte raw bytes)
        let chars = Array(frame)
        let from = beginByte * 2
        let to   = (beginByte + byteCount) * 2
        guard to <= chars.count else { return "00" }
        var i = from
        while i < to {
            if let b = UInt(String(chars[i..<min(i+2, to)]), radix: 16) {
                sum &+= b
            }
            i += 2
        }
        // Java's toCheck returns the last 2 hex chars of the sum string,
        // which for sums up to 0xFFFF is equivalent to (sum & 0xFF) as a
        // 2-digit hex string. For very large sums Java would just take the
        // ASCII tail — we replicate the byte-level low byte semantically.
        let hex = String(format: "%X", sum)
        if hex.count >= 2 {
            return String(hex.suffix(2)).uppercased()
        }
        return String(format: "%02X", sum & 0xFF)
    }

    /// Convenience for older call sites that summed the whole body —
    /// use `checksum(_:beginByte:byteCount:)` instead for the protocol-correct
    /// algorithm. This one is kept for backwards compatibility with the
    /// previous starter code; it sums the whole frame which is NOT what
    /// the Android side does. Mark the use of this with a TODO.
    public static func toCheck(_ frameWithoutChecksum: String) -> String {
        var sum: UInt = 0
        var idx = frameWithoutChecksum.startIndex
        while idx < frameWithoutChecksum.endIndex {
            let next = frameWithoutChecksum.index(idx, offsetBy: 2,
                                                  limitedBy: frameWithoutChecksum.endIndex)
                ?? frameWithoutChecksum.endIndex
            if let b = UInt(frameWithoutChecksum[idx..<next], radix: 16) {
                sum &+= b
            }
            idx = next
        }
        return String(format: "%02X", sum & 0xFF)
    }

    /// Left-pad a hex string with zeros to a target length.
    /// Java reference: DigestAES.addZeroForNumLeft.
    public static func addZeroForNumLeft(_ hex: String, _ length: Int) -> String {
        if hex.count >= length { return hex }
        return String(repeating: "0", count: length - hex.count) + hex
    }

    public static func bytesToHexString(_ data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined()
    }

    public static func hexToBytes(_ hex: String) -> Data {
        var s = hex
        if s.count % 2 == 1 { s = "0" + s }
        var out = Data(capacity: s.count / 2)
        var idx = s.startIndex
        while idx < s.endIndex {
            let next = s.index(idx, offsetBy: 2)
            if let b = UInt8(s[idx..<next], radix: 16) {
                out.append(b)
            }
            idx = next
        }
        return out
    }

    private static func substring(_ s: String, _ from: Int, _ to: Int) -> String {
        let lo = s.index(s.startIndex, offsetBy: from)
        let hi = s.index(s.startIndex, offsetBy: to)
        return String(s[lo..<hi])
    }
}
