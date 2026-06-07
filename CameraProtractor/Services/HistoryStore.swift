import Foundation

final class HistoryStore {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> [MeasurementRecord] {
        do {
            let url = try fileManager.measurementHistoryFileURL()
            guard fileManager.fileExists(atPath: url.path) else { return [] }
            let data = try Data(contentsOf: url)
            return try decoder.decode([MeasurementRecord].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ records: [MeasurementRecord]) {
        do {
            let url = try fileManager.measurementHistoryFileURL()
            let data = try encoder.encode(records)
            try data.write(to: url, options: .atomic)
        } catch {
            assertionFailure("Could not save measurement history: \(error)")
        }
    }
}
