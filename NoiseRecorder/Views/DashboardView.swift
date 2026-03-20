import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \NoiseEvent.timestamp) private var allEvents: [NoiseEvent]
    private let settings = AppSettings.shared

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    HStack {
                        Text("Statistics")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal)

                    if allEvents.isEmpty {
                        Spacer().frame(height: 100)
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 48))
                                .foregroundStyle(.gray)
                            Text("No data yet")
                                .foregroundStyle(.gray)
                        }
                    } else {
                        hourlyChart
                        dailyChart
                        summaryRow
                    }
                }
                .padding(.top)
            }
        }
    }

    // 時間帯別の騒音レベル
    private var hourlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hourly Noise Level")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                if let peak = hourlyData.max(by: { $0.maxDb < $1.maxDb }) {
                    Text(String(format: "%.0f", peak.maxDb))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.warningOrange)
                    + Text(" dB")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
            }
            Text("LAST 24 HOURS")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.gray)
                .tracking(1)

            Chart(hourlyData, id: \.hour) { item in
                BarMark(
                    x: .value("Hour", item.hour),
                    y: .value("dB", item.maxDb)
                )
                .foregroundStyle(item.maxDb >= settings.threshold ? AppColor.dangerRed : AppColor.accent)
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour)h")
                                .font(.system(size: 10))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // 日別の超過回数
    private var dailyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Threshold Exceeded")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(dailyData.reduce(0) { $0 + $1.count }) Alerts")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.dangerRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColor.dangerRed.opacity(0.15))
                    .clipShape(Capsule())
            }
            Text("LAST 7 DAYS")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.gray)
                .tracking(1)

            Chart(dailyData, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(AppColor.warningOrange)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(.gray)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // サマリー行
    private var summaryRow: some View {
        HStack(spacing: 12) {
            SummaryCard(
                icon: "shield.checkered",
                label: "SAFE EXPOSURE",
                value: String(format: "%.1f hrs", safeHours),
                color: AppColor.safeGreen
            )
            SummaryCard(
                icon: "speaker.wave.3",
                label: "PEAK LEVEL",
                value: String(format: "%.1f dB", peakLevel),
                color: AppColor.dangerRed
            )
        }
        .padding(.horizontal)
    }

    private var safeHours: Double {
        let calendar = Calendar.current
        let todayEvents = allEvents.filter { calendar.isDateInToday($0.timestamp) }
        let totalExceeded = todayEvents.reduce(0.0) { $0 + $1.durationSeconds }
        return max(0, 24.0 - totalExceeded / 3600.0)
    }

    private var peakLevel: Double {
        allEvents.map(\.maxDecibels).max() ?? 0
    }

    // データ変換
    private struct HourlyItem {
        let hour: Int
        let maxDb: Double
    }

    private var hourlyData: [HourlyItem] {
        let calendar = Calendar.current
        let past24h = Date().addingTimeInterval(-86400)
        let recentEvents = allEvents.filter { $0.timestamp >= past24h }

        var hourMap: [Int: Double] = [:]
        for event in recentEvents {
            let hour = calendar.component(.hour, from: event.timestamp)
            hourMap[hour] = max(hourMap[hour] ?? 0, event.maxDecibels)
        }
        return (0..<24).map { HourlyItem(hour: $0, maxDb: hourMap[$0] ?? 0) }
    }

    private struct DailyItem {
        let date: Date
        let count: Int
    }

    private var dailyData: [DailyItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let count = allEvents.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }.count
            return DailyItem(date: date, count: count)
        }
    }
}

private struct SummaryCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.gray)
                .tracking(1)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
