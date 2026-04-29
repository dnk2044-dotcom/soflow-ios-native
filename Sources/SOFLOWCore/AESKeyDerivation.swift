// AESKeyDerivation.swift
//
// SOFLOW BLE encryption key derivation, reverse-engineered from the
// Modify BLE Name 1.0 and SO ONE-PLUS 1.0.6 Android APKs.
//
// SOURCE OF TRUTH:
//   /tmp/jadx_modify/sources/com/inuker/bluetooth/bledata/digest/DigestKey.java
//
//       public static final byte[] bKey = {48, 87, 47, 82, 54, 75, 63, 71,
//                                          48, 80, 65, 88, 17, 99, 45, 43};
//
// USAGE PATTERN (from BleDataOperateManage.java in the Modify BLE Name app):
//
//       parser = DigestAES.encrypt(
//                  DigestAES.hexToByteArray(DigestAES.addZeroForNum(parser, 32)),
//                  DigestKey.bKey);
//
// → take the parser's hex string, right-pad with '0' chars to 32 hex chars
//   (= one 16-byte AES block), encrypt with AES-ECB-NoPadding using bKey.
//
// FOR LONGER COMMANDS (DT mode, change_BleName):
// → pad to 64 or 128 hex chars; encrypt as multiple ECB blocks.
//
// THIS IS THE KEY. NO PER-DEVICE DERIVATION IS PERFORMED.
// The `MPInfo.carsecret` field that the SO ONE-PLUS server returns is
// stored in DataConstant.key but never actually fed back into AES; the
// `password_DEVICE()` / `password_TOKEN()` helpers reference it but are
// dead code in both APKs we analyzed.
//
// VERIFIED TEST VECTORS (Python pycryptodome cross-check, see
// analysis/verify_aes/test_aes.py):
//
//   plain:  00000000000000000000000000000000
//   cipher: F3F06525120E9D152FF1A05872EBBAA1
//
//   plain:  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
//   cipher: A34F6025B3980B44D2A3A2BDF213670E
//
//   plain:  D706D50000010A000000000000000000
//   cipher: 8777154CD1667F2D6A78EA4B50DF2B2B
//
// LIMITATION: this key is a single-app secret shared by ALL SOFLOW devices
// the apps target. If the firmware on a specific scooter expects a different
// per-device key (e.g. a newer firmware that rotates the master key), this
// approach will fail and a real BLE-pairing sniff will be needed. Empirically
// — across the four APK variants we have (Modify BLE Name, SO ONE-PLUS,
// SO2 ZERO-Air Max, SO4-SOX-Tier) — all use the same hardcoded bKey, so
// this is unlikely.

import Foundation

public enum AESKeyDerivation {

    /// The hardcoded SOFLOW BLE master AES-128 key.
    /// Hex: `30572F52364B3F473050415811632D2B`
    public static let masterKey: Data = Data([
        0x30, 0x57, 0x2F, 0x52, 0x36, 0x4B, 0x3F, 0x47,
        0x30, 0x50, 0x41, 0x58, 0x11, 0x63, 0x2D, 0x2B
    ])

    /// Encrypt a parser-built hex command string the way the Java code does:
    /// 1. Right-pad the hex string to `padLength` chars with '0'
    /// 2. Hex-decode to bytes (must be a multiple of 16)
    /// 3. AES-ECB-NoPadding encrypt with `masterKey`
    /// 4. Return uppercase hex of the ciphertext (matches Java output)
    ///
    /// `padLength` matches the Java call sites:
    ///   - 32  → standard one-block command (16 bytes)
    ///   - 64  → BLE-name change (32 bytes / 2 blocks)
    ///   - 128 → DT factory commands (64 bytes / 4 blocks)
    public static func encryptParser(_ parserHex: String, padLength: Int = 32) throws -> String {
        guard padLength % 32 == 0 else {
            throw AESKeyDerivationError.badPadLength(padLength)
        }
        let padded = padRightWithZeros(parserHex, to: padLength)
        let plain = Data(hexString: padded) ?? Data()
        guard plain.count % 16 == 0, plain.count > 0 else {
            throw AESKeyDerivationError.badInputLength(plain.count)
        }
        return try DigestAES.encrypt(plain, key: masterKey)
    }

    /// Decrypt an incoming hex-encoded ciphertext. The result is the original
    /// padded plaintext as uppercase hex — the caller may need to strip
    /// trailing '0' chars to get back to the parser string.
    public static func decryptToHex(_ cipherHex: String) throws -> String {
        let ct = Data(hexString: cipherHex) ?? Data()
        guard ct.count % 16 == 0, ct.count > 0 else {
            throw AESKeyDerivationError.badInputLength(ct.count)
        }
        return try DigestAES.decrypt(ct, key: masterKey)
    }

    /// Mirror of Java DigestAES.addZeroForNum — right-pads with '0' chars.
    public static func padRightWithZeros(_ s: String, to length: Int) -> String {
        if s.count >= length { return s }
        return s + String(repeating: "0", count: length - s.count)
    }
}

public enum AESKeyDerivationError: Error, CustomStringConvertible {
    case badPadLength(Int)
    case badInputLength(Int)

    public var description: String {
        switch self {
        case .badPadLength(let n):
            return "padLength must be a multiple of 32 hex chars (one AES block); got \(n)"
        case .badInputLength(let n):
            return "input must be non-empty multiple of 16 bytes for AES-ECB; got \(n)"
        }
    }
}

// MARK: - Hex helpers

extension Data {
    init?(hexString: String) {
        let s = hexString.count % 2 == 1 ? "0" + hexString : hexString
        var bytes = [UInt8]()
        bytes.reserveCapacity(s.count / 2)
        var i = s.startIndex
        while i < s.endIndex {
            let next = s.index(i, offsetBy: 2)
            guard let byte = UInt8(s[i..<next], radix: 16) else { return nil }
            bytes.append(byte)
            i = next
        }
        self = Data(bytes)
    }
}
