import Foundation
import SwiftUI

@MainActor @Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let threshold = "threshold"
        static let samplingInterval = "samplingInterval"
    }

    var threshold: Double {
        didSet { UserDefaults.standard.set(threshold, forKey: Keys.threshold) }
    }

    var samplingInterval: Double {
        didSet { UserDefaults.standard.set(samplingInterval, forKey: Keys.samplingInterval) }
    }

    private init() {
        let savedThreshold = UserDefaults.standard.double(forKey: Keys.threshold)
        self.threshold = savedThreshold > 0 ? savedThreshold : 50.0

        let savedInterval = UserDefaults.standard.double(forKey: Keys.samplingInterval)
        self.samplingInterval = savedInterval > 0 ? savedInterval : 0.1
    }
}

// MARK: - デザイン定数

enum AppColor {
    static let background = Color(red: 14/255, green: 14/255, blue: 16/255)
    static let cardBackground = Color(red: 24/255, green: 24/255, blue: 28/255)
    static let accent = Color(red: 0, green: 122/255, blue: 255/255)
    static let safeGreen = Color(red: 76/255, green: 217/255, blue: 100/255)
    static let warningOrange = Color.orange
    static let dangerRed = Color(red: 255/255, green: 59/255, blue: 48/255)
}

// MARK: - 共通フォーマッター

extension Double {
    var formattedDb: String { String(format: "%.1f", self) }
    var formattedDbWithUnit: String { String(format: "%.1f dB", self) }

    func formattedDuration(style: DurationFormatStyle = .short) -> String {
        if self < 60 {
            switch style {
            case .short: return String(format: "%.0fs", self)
            case .japanese: return String(format: "%.0f秒", self)
            }
        }
        let min = Int(self) / 60
        let sec = Int(self) % 60
        switch style {
        case .short: return String(format: "%d:%02d", min, sec)
        case .japanese: return "\(min)分\(sec)秒"
        }
    }
}

enum DurationFormatStyle {
    case short
    case japanese
}

// MARK: - 共通 View Modifier

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            content
        }
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 14) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }

    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}

// MARK: - 共通 UI コンポーネント

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.gray)
            .tracking(1)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            Text(message)
                .foregroundStyle(.gray)
        }
    }
}
