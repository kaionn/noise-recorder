import Foundation
import SwiftUI

@MainActor @Observable
final class AppSettings {
    static let shared = AppSettings()

    var threshold: Double {
        didSet { UserDefaults.standard.set(threshold, forKey: "threshold") }
    }

    var samplingInterval: Double {
        didSet { UserDefaults.standard.set(samplingInterval, forKey: "samplingInterval") }
    }

    private init() {
        let savedThreshold = UserDefaults.standard.double(forKey: "threshold")
        self.threshold = savedThreshold > 0 ? savedThreshold : 50.0

        let savedInterval = UserDefaults.standard.double(forKey: "samplingInterval")
        self.samplingInterval = savedInterval > 0 ? savedInterval : 0.1
    }
}

// デザインカラー定数
enum AppColor {
    static let background = Color(red: 14/255, green: 14/255, blue: 16/255)
    static let cardBackground = Color(red: 24/255, green: 24/255, blue: 28/255)
    static let accent = Color(red: 0, green: 122/255, blue: 255/255)
    static let safeGreen = Color(red: 76/255, green: 217/255, blue: 100/255)
    static let warningOrange = Color.orange
    static let dangerRed = Color(red: 255/255, green: 59/255, blue: 48/255)
}
