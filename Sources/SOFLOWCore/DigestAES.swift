// DigestAES.swift
// Port of com/inuker/bluetooth/bledata/digest/DigestAES.java
// Java used "AES/ECB/NoPadding". Apple's CommonCrypto supports the same.

import Foundation
import CommonCrypto

public enum DigestAES {

    /// AES-ECB-NoPadding encrypt. Length of `plain` must be a multiple of 16.
    /// Returns uppercase hex string (matches Java bytesToHexString output).
    public static func encrypt(_ plain: Data, key: Data) throws -> String {
        let cipherBytes = try crypt(input: plain, key: key, op: kCCEncrypt)
        return HexParser.bytesToHexString(cipherBytes)
    }

    /// AES-ECB-NoPadding decrypt. Returns uppercase hex of the plaintext.
    public static func decrypt(_ cipher: Data, key: Data) throws -> String {
        let plainBytes = try crypt(input: cipher, key: key, op: kCCDecrypt)
        return HexParser.bytesToHexString(plainBytes)
    }

    private static func crypt(input: Data, key: Data, op: Int) throws -> Data {
        var outLen = 0
        var output = Data(count: input.count + kCCBlockSizeAES128)
        let status = output.withUnsafeMutableBytes { outBytes in
            input.withUnsafeBytes { inBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(op),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode), // NoPadding == do not set kCCOptionPKCS7Padding
                        keyBytes.baseAddress, key.count,
                        nil,
                        inBytes.baseAddress, input.count,
                        outBytes.baseAddress, output.count,
                        &outLen
                    )
                }
            }
        }
        if status != kCCSuccess {
            throw NSError(domain: "DigestAES", code: Int(status))
        }
        output.removeSubrange(outLen..<output.count)
        return output
    }
}

public enum AESError: Error {
    case badInputLength
    case ccError(Int32)
}
