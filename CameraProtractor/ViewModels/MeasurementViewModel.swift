import Foundation

@MainActor
final class MeasurementViewModel: ObservableObject {
    @Published var baselineAngle: Double?
    @Published var history: [MeasurementRecord] = []
    @Published var captureMessage: String?

    let cameraService: CameraService
    let motionService: MotionService

    private let historyStore: HistoryStore

    var currentAngle: Double {
        motionService.reading.rollDegrees
    }

    var pitchAngle: Double {
        motionService.reading.pitchDegrees
    }

    var relativeAngle: Double? {
        guard let baselineAngle else { return nil }
        return MotionService.shortestAngleDelta(from: baselineAngle, to: currentAngle)
    }

    var isLevel: Bool {
        abs(currentAngle) <= 1.0
    }

    init(historyStore: HistoryStore = HistoryStore()) {
        cameraService = CameraService()
        motionService = MotionService()
        self.historyStore = historyStore
        history = historyStore.load()
    }

    func start() {
        cameraService.requestAccessAndStart()
        motionService.start()
    }

    func stop() {
        cameraService.stop()
        motionService.stop()
    }

    func lockBaseline() {
        baselineAngle = currentAngle
        captureMessage = "Baseline locked at \(Self.formatAngle(currentAngle))"
    }

    func resetBaseline() {
        baselineAngle = nil
        captureMessage = "Baseline reset"
    }

    func captureMeasurement() {
        captureMessage = "Capturing measurement..."
        let absolute = currentAngle
        let baseline = baselineAngle
        let relative = relativeAngle

        cameraService.capturePhoto { [weak self] result in
            guard let self else { return }

            let filename: String?
            switch result {
            case let .success(photoFilename):
                filename = photoFilename
                self.captureMessage = "Measurement saved"
            case let .failure(error):
                filename = nil
                self.captureMessage = "Measurement saved without photo: \(error.localizedDescription)"
            }

            self.saveRecord(
                absoluteAngle: absolute,
                baselineAngle: baseline,
                relativeAngle: relative,
                photoFilename: filename
            )
        }
    }

    func clearHistory() {
        history.removeAll()
        historyStore.save(history)
        captureMessage = "History cleared"
    }

    private func saveRecord(
        absoluteAngle: Double,
        baselineAngle: Double?,
        relativeAngle: Double?,
        photoFilename: String?
    ) {
        let record = MeasurementRecord(
            absoluteAngle: absoluteAngle,
            baselineAngle: baselineAngle,
            relativeAngle: relativeAngle,
            photoFilename: photoFilename
        )
        history.insert(record, at: 0)
        history = Array(history.prefix(30))
        historyStore.save(history)
    }

    static func formatAngle(_ value: Double) -> String {
        String(format: "%.1f°", value)
    }
}
