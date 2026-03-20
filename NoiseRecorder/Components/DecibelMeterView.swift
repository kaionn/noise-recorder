import SwiftUI

struct GaugeView: View {
    let decibels: Double?
    let threshold: Double
    let minDb: Double?
    let avgDb: Double?
    let maxDb: Double?

    private var normalizedLevel: Double {
        guard let db = decibels else { return 0 }
        return min(max(db / 120.0, 0), 1.0)
    }

    private var thresholdNormalized: Double {
        min(threshold / 120.0, 1.0)
    }

    var body: some View {
        VStack(spacing: 20) {
            // 半円ゲージ
            ZStack {
                // 背景アーク
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(360))
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 240, height: 120)

                // グラデーションアーク
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(180 + 180 * normalizedLevel))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [AppColor.safeGreen, .yellow, AppColor.warningOrange, AppColor.dangerRed]),
                            center: .bottom,
                            startAngle: .degrees(180),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 240, height: 120)
                    .animation(.linear(duration: 0.15), value: normalizedLevel)

                // 閾値マーカー
                ThresholdMarker(angle: 180 + 180 * thresholdNormalized, radius: 120)

                // 数値表示
                VStack(spacing: 2) {
                    Text(decibels.map { String(format: "%.1f", $0) } ?? "--")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("DECIBELS")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.gray)
                        .tracking(2)
                }
                .offset(y: 20)
            }
            .frame(height: 160)

            // MIN / AVG / MAX
            HStack(spacing: 0) {
                StatColumn(label: "MIN", value: minDb, color: .gray)
                StatColumn(label: "AVG", value: avgDb, color: AppColor.accent)
                    .background(AppColor.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                StatColumn(label: "MAX", value: maxDb, color: .gray)
            }
            .padding(.horizontal, 30)
        }
    }
}

private struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

private struct ThresholdMarker: View {
    let angle: Double
    let radius: CGFloat

    var body: some View {
        Circle()
            .fill(AppColor.dangerRed)
            .frame(width: 8, height: 8)
            .offset(
                x: radius * CGFloat(cos(angle * .pi / 180)),
                y: radius * CGFloat(sin(angle * .pi / 180))
            )
    }
}

private struct StatColumn: View {
    let label: String
    let value: Double?
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.gray)
                .tracking(1)
            Text(value.map { String(format: "%.1f", $0) } ?? "--")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text("dB")
                .font(.system(size: 11))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
