import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var meteringService = AudioMeteringService()
    private let settings = AppSettings.shared

    // Running statistics（O(1) per sample）
    @State private var minDb: Double?
    @State private var maxDb: Double?
    @State private var dbSum: Double = 0
    @State private var dbCount: Int = 0

    // 前回セッションの統計値
    @State private var lastMinDb: Double?
    @State private var lastAvgDb: Double?
    @State private var lastMaxDb: Double?

    private var avgDb: Double? {
        dbCount > 0 ? dbSum / Double(dbCount) : nil
    }

    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .foregroundStyle(AppColor.accent)
                Text("NOISE RECORDER")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1)
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

            if meteringService.phase == .calibrating {
                VStack(spacing: 20) {
                    ProgressView(value: meteringService.calibrationProgress)
                        .progressViewStyle(.linear)
                        .tint(AppColor.accent)
                        .frame(width: 200)
                    Text("Calibrating microphone…")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray)
                    Text("Keep the environment quiet")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray.opacity(0.7))
                }
            } else {
                GaugeView(
                    decibels: meteringService.currentDecibels,
                    threshold: settings.threshold,
                    minDb: meteringService.isRecording ? minDb : lastMinDb,
                    avgDb: meteringService.isRecording ? avgDb : lastAvgDb,
                    maxDb: meteringService.isRecording ? maxDb : lastMaxDb,
                    isLastSession: !meteringService.isRecording && lastMinDb != nil
                )
            }

            Spacer()

            Button {
                if meteringService.isRecording {
                    saveLastSession()
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
        if let db = meteringService.currentDecibels, db >= settings.threshold { return "ALERT" }
        return "Safe"
    }

    private var statusColor: Color {
        if !meteringService.isRecording { return .gray }
        if let db = meteringService.currentDecibels, db >= settings.threshold { return AppColor.dangerRed }
        return AppColor.safeGreen
    }

    private func updateStats(_ db: Double?) {
        guard meteringService.isRecording, let db else { return }
        dbCount += 1
        dbSum += db
        if let currentMin = minDb {
            minDb = min(currentMin, db)
        } else {
            minDb = db
        }
        if let currentMax = maxDb {
            maxDb = max(currentMax, db)
        } else {
            maxDb = db
        }
    }

    private func saveLastSession() {
        lastMinDb = minDb
        lastAvgDb = avgDb
        lastMaxDb = maxDb
    }

    private func resetStats() {
        minDb = nil
        maxDb = nil
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
