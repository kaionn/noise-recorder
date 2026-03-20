import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var meteringService = AudioMeteringService()
    private let settings = AppSettings.shared

    // Running statistics（O(1) per sample）
    @State private var minDb: Double = 0
    @State private var maxDb: Double = 0
    @State private var dbSum: Double = 0
    @State private var dbCount: Int = 0

    private var avgDb: Double {
        dbCount > 0 ? dbSum / Double(dbCount) : 0
    }

    var body: some View {
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
                    SectionLabel(text: "SAFETY THRESHOLD")
                    Text("\(Int(settings.threshold)) dB")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.accent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    SectionLabel(text: "STATUS")
                    Text(statusText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            GaugeView(
                decibels: meteringService.currentDecibels,
                threshold: settings.threshold,
                minDb: minDb,
                avgDb: avgDb,
                maxDb: maxDb
            )

            Spacer()

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
        .appBackground()
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
        dbCount += 1
        dbSum += db
        if dbCount == 1 {
            minDb = db
            maxDb = db
        } else {
            minDb = min(minDb, db)
            maxDb = max(maxDb, db)
        }
    }

    private func resetStats() {
        minDb = 0
        maxDb = 0
        dbSum = 0
        dbCount = 0
    }

    private func startRecording() {
        resetStats()
        meteringService.onThresholdExceeded = { event in
            let noiseEvent = NoiseEvent(
                timestamp: event.timestamp,
                maxDecibels: event.maxDecibels,
                averageDecibels: event.averageDecibels,
                durationSeconds: event.durationSeconds
            )
            modelContext.insert(noiseEvent)
            try? modelContext.save()
        }
        meteringService.startMetering()
    }
}
