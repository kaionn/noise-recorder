import AVFoundation
import Combine

@MainActor @Observable
final class AudioMeteringService {
    private(set) var currentDecibels: Double = -160
    private(set) var isRecording = false

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private let settings = AppSettings.shared

    // 閾値超過トラッキング
    private var exceedStartTime: Date?
    private var exceedMaxDb: Double = 0
    private var exceedDbSamples: [Double] = []

    var onThresholdExceeded: ((Date, Double, Double, Double) -> Void)?

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
        currentDecibels = -160
    }

    private func updateMetering() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()

        // AVAudioRecorder の averagePower は dBFS（-160〜0）
        // 簡易的に +160 してポジティブな値に変換
        let power = Double(recorder.averagePower(forChannel: 0))
        let normalizedDb = max(0, power + 160)

        currentDecibels = normalizedDb
        checkThreshold(db: normalizedDb)
    }

    private func checkThreshold(db: Double) {
        if db >= settings.threshold {
            if exceedStartTime == nil {
                exceedStartTime = Date()
                exceedMaxDb = db
                exceedDbSamples = [db]
            } else {
                exceedMaxDb = max(exceedMaxDb, db)
                exceedDbSamples.append(db)
            }
        } else {
            finalizeExceedEvent()
        }
    }

    private func finalizeExceedEvent() {
        guard let startTime = exceedStartTime else { return }

        let duration = Date().timeIntervalSince(startTime)
        // 0.5秒未満の超過は無視（ノイズ対策）
        guard duration >= 0.5 else {
            exceedStartTime = nil
            exceedDbSamples = []
            return
        }

        let avgDb = exceedDbSamples.reduce(0, +) / Double(exceedDbSamples.count)
        onThresholdExceeded?(startTime, exceedMaxDb, avgDb, duration)

        exceedStartTime = nil
        exceedMaxDb = 0
        exceedDbSamples = []
    }
}
