import Foundation

struct MeasurementRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let absoluteAngle: Double
    let baselineAngle: Double?
    let relativeAngle: Double?
    let photoFilename: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        absoluteAngle: Double,
        baselineAngle: Double?,
        relativeAngle: Double?,
        photoFilename: String?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.absoluteAngle = absoluteAngle
        self.baselineAngle = baselineAngle
        self.relativeAngle = relativeAngle
        self.photoFilename = photoFilename
    }
}
