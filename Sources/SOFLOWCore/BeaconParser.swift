// BeaconParser.swift
// Direct port of com.inuker.bluetooth.library.beacon.BeaconParser
// — a sequential byte-cursor used by every BLE notify-frame parser in
// the Android codebase. Java's ByteBuffer with LITTLE_ENDIAN order, but
// the public read methods (readByte/readShort) actually return BIG-endian
// composed values (see readShort: (b1<<8)+b2). We mirror that exactly.

import Foundation

public struct BeaconItem {
    public var type: Int
    public var len: Int
    public var bytes: Data
    public init(type: Int, len: Int, bytes: Data) {
        self.type = type
        self.len = len
        self.bytes = bytes
    }
}

public final class BeaconParser {
    public let bytes: Data
    private var cursor: Int = 0

    public init(_ data: Data) {
        self.bytes = data
    }

    public convenience init(_ item: BeaconItem) {
        self.init(item.bytes)
    }

    // Mirrors readByte(): returns unsigned 0..255
    @discardableResult
    public func readByte() -> Int {
        guard cursor < bytes.count else { return 0 }
        let v = Int(bytes[cursor])
        cursor += 1
        return v & 0xFF
    }

    // Mirrors readShort(): big-endian compose of next two bytes
    @discardableResult
    public func readShort() -> Int {
        let hi = readByte()
        let lo = readByte()
        return (hi << 8) + lo
    }

    // Java overloaded "readShort(int hi, int lo)" — pure helper, no cursor move
    public func readShort(_ hi: Int, _ lo: Int) -> Int {
        return (hi << 8) + lo
    }

    @discardableResult
    public func readShort3() -> Int {
        return (readByte() << 16) + (readByte() << 8) + readByte()
    }

    @discardableResult
    public func readShort4() -> Int {
        return (readByte() << 24) + (readByte() << 16) + (readByte() << 8) + readByte()
    }

    public func getBit(_ value: Int, _ pos: Int) -> Bool {
        return (value & (1 << pos)) != 0
    }

    /// Mirror of Java getBits(byte, fromInclusive, toExclusive) — BUT note the
    /// Java implementation uses `(255 >> (8 - i2))` which ignores the lower bound.
    /// We replicate the bug for fidelity with Android behaviour.
    public func getBits(_ b: Int, _ from: Int, _ to: Int) -> Int {
        return (b >> from) & (255 >> (8 - to))
    }

    public func getInt2(_ data: Data, at offset: Int) -> Int {
        return (Int(data[offset]) << 8) | Int(data[offset + 1])
    }

    public func getInt3(_ data: Data, at offset: Int) -> Int {
        return (Int(data[offset]) << 16) |
               (Int(data[offset + 1]) << 8) |
               Int(data[offset + 2])
    }

    public func setPosition(_ pos: Int) { cursor = pos }
    public var position: Int { cursor }
    public var remaining: Int { bytes.count - cursor }
}
