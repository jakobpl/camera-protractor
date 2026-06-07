import SwiftUI

struct HistoryView: View {
    let history: [MeasurementRecord]
    let clearAction: () -> Void

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel("Measurement history")
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                List {
                    if history.isEmpty {
                        Text("No measurements yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(history) { record in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(record.createdAt, format: .dateTime.month().day().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Text("Angle")
                                    Spacer()
                                    Text(MeasurementViewModel.formatAngle(record.absoluteAngle))
                                        .monospacedDigit()
                                }

                                if let relative = record.relativeAngle {
                                    HStack {
                                        Text("Relative")
                                        Spacer()
                                        Text(MeasurementViewModel.formatAngle(relative))
                                            .monospacedDigit()
                                    }
                                    .foregroundStyle(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle("History")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            isPresented = false
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive, action: clearAction)
                            .disabled(history.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
