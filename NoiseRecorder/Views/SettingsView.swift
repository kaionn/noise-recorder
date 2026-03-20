import SwiftUI

struct SettingsView: View {
    private let settings = AppSettings.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Settings")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal)

                // 閾値セクション
                VStack(spacing: 20) {
                    SectionLabel(text: "NOISE THRESHOLD")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(settings.threshold))")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColor.accent)
                        Text("dB")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.gray)
                    }

                    SectionLabel(text: "ACTIVE THRESHOLD")

                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { settings.threshold },
                            set: { settings.threshold = $0 }
                        ), in: 30...100, step: 1)
                        .tint(AppColor.accent)

                        HStack {
                            Text("30 dB").font(.system(size: 10)).foregroundStyle(.gray)
                            Spacer()
                            Text("65 dB").font(.system(size: 10)).foregroundStyle(.gray)
                            Spacer()
                            Text("100 dB").font(.system(size: 10)).foregroundStyle(.gray)
                        }
                    }

                    VStack(spacing: 0) {
                        ThresholdReference(db: 40, title: "40 dB Library level (night)", subtitle: "MINIMAL NOISE", current: settings.threshold)
                        Divider().overlay(Color.gray.opacity(0.2))
                        ThresholdReference(db: 50, title: "50 dB Normal conversation (day)", subtitle: "AMBIENT HUMAN", current: settings.threshold)
                        Divider().overlay(Color.gray.opacity(0.2))
                        ThresholdReference(db: 60, title: "60 dB Vacuum cleaner (loud)", subtitle: "MECHANICAL NOISE", current: settings.threshold)
                    }
                }
                .cardStyle()
                .padding(.horizontal)

                // About セクション
                VStack(alignment: .leading, spacing: 16) {
                    SectionLabel(text: "ABOUT")

                    HStack {
                        Text("Version Info").foregroundStyle(.white)
                        Spacer()
                        Text("Version \(appVersion)").foregroundStyle(.gray)
                    }

                    Divider().overlay(Color.gray.opacity(0.2))

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle").foregroundStyle(.gray)
                        Text("Relative dB values are approximate and intended for reference only. Accuracy depends on device hardware.")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                    }
                }
                .cardStyle()
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .appBackground()
    }
}

private struct ThresholdReference: View {
    let db: Int
    let title: String
    let subtitle: String
    let current: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: current >= Double(db) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(current >= Double(db) ? AppColor.safeGreen : .gray)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                SectionLabel(text: subtitle)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
