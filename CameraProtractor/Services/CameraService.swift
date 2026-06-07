import AVFoundation
import UIKit

final class CameraService: NSObject, ObservableObject {
    enum AuthorizationState: Equatable {
        case unknown
        case authorized
        case denied
    }

    @Published private(set) var authorizationState: AuthorizationState = .unknown
    @Published private(set) var isSessionRunning = false
    @Published private(set) var lastCaptureError: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera-protractor.camera-session")
    private let photoOutput = AVCapturePhotoOutput()
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    private var isConfigured = false

    override init() {
        super.init()
        authorizationState = Self.currentAuthorizationState
    }

    func requestAccessAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorizationState = .authorized
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.authorizationState = granted ? .authorized : .denied
                    if granted {
                        self?.configureAndStart()
                    }
                }
            }
        case .denied, .restricted:
            authorizationState = .denied
        @unknown default:
            authorizationState = .denied
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                Task { @MainActor in
                    self.isSessionRunning = false
                }
            }
        }
    }

    func capturePhoto(completion: @escaping (Result<String, Error>) -> Void) {
        lastCaptureError = nil

        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.isConfigured else {
                Task { @MainActor in
                    completion(.failure(CameraError.sessionNotConfigured))
                }
                return
            }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off

            let delegate = PhotoCaptureDelegate { [weak self] result in
                Task { @MainActor in
                    if case let .failure(error) = result {
                        self?.lastCaptureError = error.localizedDescription
                    }
                    completion(result)
                    self?.photoCaptureDelegate = nil
                }
            }

            self.photoCaptureDelegate = delegate
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.isConfigured {
                do {
                    try self.configureSession()
                    self.isConfigured = true
                } catch {
                    Task { @MainActor in
                        self.lastCaptureError = error.localizedDescription
                    }
                    return
                }
            }

            if !self.session.isRunning {
                self.session.startRunning()
                Task { @MainActor in
                    self.isSessionRunning = true
                }
            }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.cameraUnavailable
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(photoOutput)
    }

    private static var currentAuthorizationState: AuthorizationState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .unknown
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<String, Error>) -> Void

    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            completion(.failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            completion(.failure(CameraError.noPhotoData))
            return
        }

        do {
            let filename = "measurement-\(UUID().uuidString).jpg"
            let url = try FileManager.default.measurementPhotosDirectory()
                .appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            completion(.success(filename))
        } catch {
            completion(.failure(error))
        }
    }
}

enum CameraError: LocalizedError {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case sessionNotConfigured
    case noPhotoData

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "The back camera is unavailable."
        case .cannotAddInput:
            return "The camera input could not be added."
        case .cannotAddOutput:
            return "The photo output could not be added."
        case .sessionNotConfigured:
            return "The camera session is not ready yet."
        case .noPhotoData:
            return "The captured photo did not contain image data."
        }
    }
}
