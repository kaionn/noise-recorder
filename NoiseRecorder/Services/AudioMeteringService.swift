import AVFoundation

struct ThresholdExceedEvent {
    let timestamp: Date
    let maxDecibels: Double
    let averageDecibels: Double
    let durationSeconds: Double
}

enum MeteringPhase {
    case idle
    case calibrating
    case metering
}

@MainActor @Observable
final class AudioMeteringService {
    private(set) var currentDecibels: Double?
    private(set) var isRecording = false
    private(set) var phase: MeteringPhase = .idle
    private(set) var calibrationProgress: Double = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private let settings = AppSettings.shared

    // キャリブレーション
    private static let calibrationSampleCount = 30
    private static let ambientSPL: Double = 30.0
    private var calibrationSamples: [Double] = []

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

            if settings.noiseFloorDbfs != nil {
                phase = .metering
            } else {
                phase = .calibrating
                calibrationSamples = []
                calibrationProgress = 0
            }

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
        phase = .idle
        finalizeExceedEvent()
        currentDecibels = nil
        calibrationProgress = 0
    }

    /// UserDefaults をクリアし、次回 startMetering で再キャリブレーション
    func recalibrate() {
        settings.clearCalibration()
    }

    private func updateMetering() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()

        let power = Double(recorder.averagePower(forChannel: 0))

        switch phase {
        case .idle:
            break
        case .calibrating:
            calibrationSamples.append(power)
            calibrationProgress = Double(calibrationSamples.count) / Double(Self.calibrationSampleCount)

            if calibrationSamples.count >= Self.calibrationSampleCount {
                let noiseFloor = calibrationSamples.reduce(0, +) / Double(calibrationSamples.count)
                settings.noiseFloorDbfs = noiseFloor
                settings.calibrationDate = Date()
                phase = .metering
            }
        case .metering:
            let noiseFloor = settings.noiseFloorDbfs ?? -60.0
            let normalizedDb = max(0, (power - noiseFloor) + Self.ambientSPL)
            currentDecibels = normalizedDb
            checkThreshold(db: normalizedDb)
        }
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
