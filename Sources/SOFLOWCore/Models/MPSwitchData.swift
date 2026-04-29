import Foundation

public struct MPSwitchData: Equatable {
    public var command: Int?
    public var operand: Int?
    public var success: Bool = false

    public init(command: Int? = nil, operand: Int? = nil, success: Bool = false) {
        self.command = command
        self.operand = operand
        self.success = success
    }
}

public struct MPSpeedMaxData: Equatable {
    public var speed: Int
    public init(speed: Int) { self.speed = speed }
}

public struct MPBmsData: Equatable {
    public var voltage: Int = 0
    public var current: Int = 0
    public var temperature: Int = 0
    public var capacity: Int = 0
    public var cycles: Int = 0
    public init() {}
}
