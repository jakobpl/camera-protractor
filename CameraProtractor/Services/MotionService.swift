import CoreMotion
import Foundation

@MainActor
final class MotionService: ObservableObject {
    @Published private(set) var reading = AngleReading.zero
    @Published private(set) var isAvailable = CMMotionManager().isDeviceMotionAvailable

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private let smoothingFactor = 0.18
    private var smoothedRoll: Double?
    private var smoothedPitch: Double?
    private var smoothedYaw: Double?

    init() {
        queue.name = "camera-protractor.motion"
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
    }

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            isAvailable = false
            return
        }

        isAvailable = true

        motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }

            let rawRoll = Self.radiansToDegrees(motion.attitude.roll)
            let rawPitch = Self.radiansToDegrees(motion.attitude.pitch)
            let rawYaw = Self.radiansToDegrees(motion.attitude.yaw)
            let rotationRate = Self.radiansToDegrees(
                sqrt(
                    pow(motion.rotationRate.x, 2)
                    + pow(motion.rotationRate.y, 2)
                    + pow(motion.rotationRate.z, 2)
                )
            )

            let roll = self.filtered(rawRoll, previous: &self.smoothedRoll)
            let pitch = self.filtered(rawPitch, previous: &self.smoothedPitch)
            let yaw = self.filtered(rawYaw, previous: &self.smoothedYaw)

            Task { @MainActor in
                self.reading = AngleReading(
                    rollDegrees: roll,
                    pitchDegrees: pitch,
                    yawDegrees: yaw,
                    rotationRateDegreesPerSecond: rotationRate,
                    timestamp: .now
                )
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    private func filtered(_ newValue: Double, previous: inout Double?) -> Double {
        guard let oldValue = previous else {
            previous = newValue
            return newValue
        }

        let delta = Self.shortestAngleDelta(from: oldValue, to: newValue)
        let smoothed = Self.normalizedDegrees(oldValue + (smoothingFactor * delta))
        previous = smoothed
        return smoothed
    }

    static func shortestAngleDelta(from start: Double, to end: Double) -> Double {
        var delta = end - start
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        return delta
    }

    static func normalizedDegrees(_ degrees: Double) -> Double {
        var normalized = degrees
        while normalized > 180 { normalized -= 360 }
        while normalized < -180 { normalized += 360 }
        return normalized
    }

    private static func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }
}
