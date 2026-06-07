import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MeasurementViewModel()

    var body: some View {
        ZStack {
            CameraPreviewView(session: viewModel.cameraService.session)
                .ignoresSafeArea()

            ProtractorOverlayView(
                currentAngle: viewModel.currentAngle,
                baselineAngle: viewModel.baselineAngle,
                relativeAngle: viewModel.relativeAngle,
                isLevel: viewModel.isLevel
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                topPanel
                Spacer()
                bottomControls
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 20)
        }
        .background(Color.black)
        .task {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var topPanel: some View {
        VStack(spacing: 10) {
            switch viewModel.cameraService.authorizationState {
            case .authorized, .unknown:
                EmptyView()
            case .denied:
                Text("Camera permission is needed for live measurement.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .background(.black.opacity(0.68), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(alignment: .top) {
                angleReadout
                Spacer()
                HistoryView(history: viewModel.history, clearAction: viewModel.clearHistory)
            }
        }
    }

    private var angleReadout: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(MeasurementViewModel.formatAngle(viewModel.currentAngle))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            if let relative = viewModel.relativeAngle {
                Text("Relative \(MeasurementViewModel.formatAngle(relative))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.mint)
            } else {
                Text("No baseline locked")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.78))
            }

            Text("Pitch \(MeasurementViewModel.formatAngle(viewModel.pitchAngle))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.68))
        }
        .padding(14)
        .background(.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 8))
    }

    private var bottomControls: some View {
        VStack(spacing: 10) {
            if let message = viewModel.captureMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 10) {
                Button(action: viewModel.lockBaseline) {
                    Label("Baseline", systemImage: "pin.fill")
                }
                .buttonStyle(ControlButtonStyle(tint: .mint))

                Button(action: viewModel.resetBaseline) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(ControlButtonStyle(tint: .orange))

                Button(action: viewModel.captureMeasurement) {
                    Label("Capture", systemImage: "camera.fill")
                }
                .buttonStyle(ControlButtonStyle(tint: .white))
            }
        }
    }
}

private struct ControlButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .foregroundStyle(tint == .white ? .black : .white)
            .padding(.horizontal, 13)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(tint.opacity(configuration.isPressed ? 0.72 : 0.95), in: RoundedRectangle(cornerRadius: 8))
    }
}
