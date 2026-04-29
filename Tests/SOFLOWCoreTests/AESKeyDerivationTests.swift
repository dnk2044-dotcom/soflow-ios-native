import XCTest
@testable import SOFLOWCore

final class AESKeyDerivationTests: XCTestCase {

    func testKeyHex() {
        XCTAssertEqual(
            AESKeyDerivation.masterKey.hexUppercase(),
            "30572F52364B3F473050415811632D2B"
        )
        XCTAssertEqual(AESKeyDerivation.masterKey.count, 16)
    }

    func testTV1_zeroBlock() throws {
        let cipher = try DigestAES.encrypt(
            Data(repeating: 0, count: 16),
            key: AESKeyDerivation.masterKey
        )
        XCTAssertEqual(cipher, "F3F06525120E9D152FF1A05872EBBAA1")
    }

    func testTV3_battery_lock_setting_style() throws {
        let cipher = try AESKeyDerivation.encryptParser("D706D50000010A", padLength: 32)
        XCTAssertEqual(cipher, "8777154CD1667F2D6A78EA4B50DF2B2B")
    }

    func testRoundTrip() throws {
        let plainHex = "D706D50000010A000000000000000000"
        let plain = Data(hexString: plainHex)!
        let cipher = try DigestAES.encrypt(plain, key: AESKeyDerivation.masterKey)
        let back = try AESKeyDerivation.decryptToHex(cipher)
        XCTAssertEqual(back, plainHex)
    }

    func testPadRightWithZeros() {
        XCTAssertEqual(AESKeyDerivation.padRightWithZeros("AB", to: 8), "AB000000")
        XCTAssertEqual(AESKeyDerivation.padRightWithZeros("ABCDEFGH", to: 8), "ABCDEFGH")
    }
}

extension Data {
    fileprivate func hexUppercase() -> String {
        return self.map { String(format: "%02X", $0) }.joined()
    }
}
