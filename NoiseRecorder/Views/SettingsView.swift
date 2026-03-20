import SwiftUI

struct SettingsView: View {
    private let settings = AppSettings.shared
    @State private var threshold: Double = AppSettings.shared.threshold

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    HStack {
                        Text("Settings")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal)

                    // 閾値セクション
                    VStack(spacing: 20) {
                        Text("NOISE THRESHOLD")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.gray)
                            .tracking(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // 大きな数値表示
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(threshold))")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColor.accent)
                            Text("dB")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.gray)
                        }

                        Text("ACTIVE THRESHOLD")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.gray)
                            .tracking(1)

                        // スライダー
                        VStack(spacing: 8) {
                            Slider(value: $threshold, in: 30...100, step: 1) {
                                Text("Threshold")
                            } onEditingChanged: { editing in
                                if !editing { settings.threshold = threshold }
                            }
                            .tint(AppColor.accent)

                            HStack {
                                Text("30 dB")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("65 dB")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("100 dB")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                            }
                        }

                        // リファレンスガイド
                        VStack(spacing: 0) {
                            ThresholdReference(
                                db: 40,
                                title: "40 dB Library level (night)",
                                subtitle: "MINIMAL NOISE",
                                current: threshold
                            )
                            Divider().overlay(Color.gray.opacity(0.2))
                            ThresholdReference(
                                db: 50,
                                title: "50 dB Normal conversation (day)",
                                subtitle: "AMBIENT HUMAN",
                                current: threshold
                            )
                            Divider().overlay(Color.gray.opacity(0.2))
                            ThresholdReference(
                                db: 60,
                                title: "60 dB Vacuum cleaner (loud)",
                                subtitle: "MECHANICAL NOISE",
                                current: threshold
                            )
                        }
                    }
                    .padding(16)
                    .background(AppColor.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // About セクション
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ABOUT")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.gray)
                            .tracking(1)

                        HStack {
                            Text("Version Info")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("Version 1.0.0")
                                .foregroundStyle(.gray)
                        }

                        Divider().overlay(Color.gray.opacity(0.2))

                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.gray)
                            Text("Relative dB values are approximate and intended for reference only. Accuracy depends on device hardware.")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(16)
                    .background(AppColor.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.top)
            }
        }
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
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.gray)
                    .tracking(1)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
