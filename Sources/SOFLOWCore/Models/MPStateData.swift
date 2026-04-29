// MPStateData.swift
// Port of com.inuker.bluetooth.bledata.mpControlData.model.MPStateData
// Holds the live-ride state of a SOFLOW scooter — speed, battery, faults,
// distance counters, lights, mode flags. Populated by MPStateParser from
// every notify-frame the scooter emits while connected.

import Foundation

public struct MPStateData: Equatable {
    public var speed: Int = 0
    public var factoryCode: Int = 0
    public var lampStatus: Bool = false
    public var speedMode: Int = 0          // 0..3 ECO / DRIVE / SPORT
    public var unit: Bool = false          // false=km/h, true=mph
    public var modifyMode: Int = 0
    public var lockStatus: Bool = false

    public var batteryVoltage: Int = 0     // raw 16-bit
    public var batteryCurrent: Int = 0     // raw 16-bit
    public var remainingCharge: Int = 0    // %

    public var distanceSingle: Int = 0     // current trip
    public var distanceAll: Int = 0        // total odometer

    public var communicationLeft: Int = 0
    public var communicationRight: Int = 0
    public var displayLeft: Int = 0
    public var displayRight: Int = 0
    public var cpuLeft: Int = 0
    public var cpuRight: Int = 0

    public var faultBrake: Bool = false
    public var faultController: Bool = false
    public var faultMotor: Bool = false
    public var faultCommunication: Bool = false
    public var stealingAlert: Bool = false
    public var transferFault: Bool = false
    public var systemStatus: Bool = false

    public var singleRideTime: Int = 0
    public var darkMode: Int = 0
    public var faults: [Bool] = []

    public init() {}
}
