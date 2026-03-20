import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var meteringService = AudioMeteringService()
    @State private var minDb: Double = 0
    @State private var maxDb: Double = 0
    @State private var avgDb: Double = 0
    @State private var dbSamples: [Double] = []
    private let settings = AppSettings.shared

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 16) {
                // ヘッダー
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .foregroundStyle(AppColor.accent)
                        Text("NOISE RECORDER")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1)
                    }
                    Spacer()
                    Image(systemName: "gearshape")
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal)

                // 閾値表示
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SAFETY THRESHOLD")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.gray)
                            .tracking(1)
                        Text("\(Int(settings.threshold)) dB")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColor.accent)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("STATUS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.gray)
                            .tracking(1)
                        Text(statusText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(statusColor)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // メーター
                GaugeView(
                    decibels: meteringService.currentDecibels,
                    threshold: settings.threshold,
                    minDb: minDb,
                    avgDb: avgDb,
                    maxDb: maxDb
                )

                Spacer()

                // 記録ボタン
                Button {
                    if meteringService.isRecording {
                        meteringService.stopMetering()
                        resetStats()
                    } else {
                        startRecording()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: meteringService.isRecording ? "stop.fill" : "mic.fill")
                        Text(meteringService.isRecording ? "Stop Recording" : "Start Recording")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(meteringService.isRecording ? AppColor.dangerRed : AppColor.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 8)
            }
        }
        .onChange(of: meteringService.currentDecibels) {
            updateStats(meteringService.currentDecibels)
        }
    }

    private var statusText: String {
        if !meteringService.isRecording { return "Standby" }
        if meteringService.currentDecibels >= settings.threshold { return "ALERT" }
        return "Safe"
    }

    private var statusColor: Color {
        if !meteringService.isRecording { return .gray }
        if meteringService.currentDecibels >= settings.threshold { return AppColor.dangerRed }
        return AppColor.safeGreen
    }

    private func updateStats(_ db: Double) {
        guard meteringService.isRecording else { return }
        dbSamples.append(db)
        minDb = dbSamples.min() ?? 0
        maxDb = dbSamples.max() ?? 0
        avgDb = dbSamples.reduce(0, +) / Double(dbSamples.count)
    }

    private func resetStats() {
        minDb = 0
        maxDb = 0
        avgDb = 0
        dbSamples = []
    }

    private func startRecording() {
        resetStats()
        meteringService.onThresholdExceeded = { timestamp, maxDb, avgDb, duration in
            let event = NoiseEvent(
                timestamp: timestamp,
                maxDecibels: maxDb,
                averageDecibels: avgDb,
                durationSeconds: duration
            )
            modelContext.insert(event)
            try? modelContext.save()
        }
        meteringService.startMetering()
    }
}
