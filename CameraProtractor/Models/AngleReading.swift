import Foundation

struct AngleReading: Equatable {
    let rollDegrees: Double
    let pitchDegrees: Double
    let yawDegrees: Double
    let rotationRateDegreesPerSecond: Double
    let timestamp: Date

    static let zero = AngleReading(
        rollDegrees: 0,
        pitchDegrees: 0,
        yawDegrees: 0,
        rotationRateDegreesPerSecond: 0,
        timestamp: .now
    )
}
