import Foundation

extension FileManager {
    func measurementPhotosDirectory() throws -> URL {
        let directory = try url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Measurement Photos", isDirectory: true)

        if !fileExists(atPath: directory.path) {
            try createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }

    func measurementHistoryFileURL() throws -> URL {
        try url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("measurement-history.json")
    }
}
