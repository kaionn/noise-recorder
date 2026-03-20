import AVFoundation

struct ThresholdExceedEvent {
    let timestamp: Date
    let maxDecibels: Double
    let averageDecibels: Double
    let durationSeconds: Double
}

@MainActor @Observable
final class AudioMeteringService {
    private(set) var currentDecibels: Double?
    private(set) var isRecording = false

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private let settings = AppSettings.shared

    // 閾値超過トラッキング（running statistics）
    private var exceedStartTime: Date?
    private var exceedMaxDb: Double = 0
    private var exceedDbSum: Double = 0
    private var exceedDbCount: Int = 0

    var onThresholdExceeded: ((ThresholdExceedEvent) -> Void)?

    func startMetering() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            print("AVAudioSession setup failed: \(error)")
            return
        }

        let url = URL(fileURLWithPath: "/dev/null")
        let recorderSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true

            timer = Timer.scheduledTimer(withTimeInterval: settings.samplingInterval, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.updateMetering()
                }
            }
        } catch {
            print("AVAudioRecorder setup failed: \(error)")
        }
    }

    func stopMetering() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        finalizeExceedEvent()
        currentDecibels = nil
    }

    private func updateMetering() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()

        // AVAudioRecorder の averagePower は dBFS（-160〜0）
        // +120 して近似 SPL に変換（iPhone マイクの 0 dBFS ≒ SPL 120 dB）
        let power = Double(recorder.averagePower(forChannel: 0))
        let normalizedDb = max(0, power + 120)

        currentDecibels = normalizedDb
        checkThreshold(db: normalizedDb)
    }

    private func checkThreshold(db: Double) {
        if db >= settings.threshold {
            if exceedStartTime == nil {
                exceedStartTime = Date()
                exceedMaxDb = db
                exceedDbSum = db
                exceedDbCount = 1
            } else {
                exceedMaxDb = max(exceedMaxDb, db)
                exceedDbSum += db
                exceedDbCount += 1
            }
        } else {
            finalizeExceedEvent()
        }
    }

    private func finalizeExceedEvent() {
        guard let startTime = exceedStartTime, exceedDbCount > 0 else {
            resetExceedTracking()
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        guard duration >= 0.5 else {
            resetExceedTracking()
            return
        }

        let event = ThresholdExceedEvent(
            timestamp: startTime,
            maxDecibels: exceedMaxDb,
            averageDecibels: exceedDbSum / Double(exceedDbCount),
            durationSeconds: duration
        )
        onThresholdExceeded?(event)
        resetExceedTracking()
    }

    private func resetExceedTracking() {
        exceedStartTime = nil
        exceedMaxDb = 0
        exceedDbSum = 0
        exceedDbCount = 0
    }
}
