import Foundation

public struct MPStateData: Equatable {
    public var speed: Int = 0
    public var factoryCode: Int = 0
    public var lampStatus: Bool = false
    public var speedMode: Int = 0
    public var unit: Bool = false
    public var modifyMode: Int = 0
    public var lockStatus: Bool = false

    public var batteryVoltage: Int = 0
    public var batteryCurrent: Int = 0
    public var remainingCharge: Int = 0

    public var distanceSingle: Int = 0
    public var distanceAll: Int = 0

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
