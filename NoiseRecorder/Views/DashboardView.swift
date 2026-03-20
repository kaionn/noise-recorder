import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \NoiseEvent.timestamp) private var allEvents: [NoiseEvent]
    private let settings = AppSettings.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Statistics")
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal)

                if allEvents.isEmpty {
                    Spacer().frame(height: 100)
                    EmptyStateView(icon: "chart.bar", message: "No data yet")
                } else {
                    let hourly = computeHourlyData()
                    let daily = computeDailyData()

                    hourlyChart(data: hourly)
                    dailyChart(data: daily)
                    summaryRow
                }
            }
            .padding(.top)
        }
        .appBackground()
    }

    private func hourlyChart(data: [HourlyItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hourly Noise Level")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                if let peak = data.max(by: { $0.maxDb < $1.maxDb }), peak.maxDb > 0 {
                    Text(peak.maxDb.formattedDb)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.warningOrange)
                    + Text(" dB")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
            }
            SectionLabel(text: "LAST 24 HOURS")

            Chart(data, id: \.hour) { item in
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
            .chartYAxisStyle()
            .frame(height: 160)
        }
        .cardStyle()
        .padding(.horizontal)
    }

    private func dailyChart(data: [DailyItem]) -> some View {
        let totalAlerts = data.reduce(0) { $0 + $1.count }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Threshold Exceeded")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(totalAlerts) Alerts")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.dangerRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColor.dangerRed.opacity(0.15))
                    .clipShape(Capsule())
            }
            SectionLabel(text: "LAST 7 DAYS")

            Chart(data, id: \.date) { item in
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
            .chartYAxisStyle()
            .frame(height: 140)
        }
        .cardStyle()
        .padding(.horizontal)
    }

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
                value: peakLevel.formattedDbWithUnit,
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

    // MARK: - Data computation

    private struct HourlyItem {
        let hour: Int
        let maxDb: Double
    }

    private func computeHourlyData() -> [HourlyItem] {
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

    private func computeDailyData() -> [DailyItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 一度のパスで日別カウントを集計
        var countMap: [Int: Int] = [:]
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        for event in allEvents where event.timestamp >= sevenDaysAgo {
            let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: event.timestamp)).day ?? 0
            countMap[days, default: 0] += 1
        }

        return (-6...0).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            return DailyItem(date: date, count: countMap[offset] ?? 0)
        }
    }
}

// MARK: - Chart Y-axis shared style

private extension View {
    func chartYAxisStyle() -> some View {
        self.chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(.gray)
            }
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
            SectionLabel(text: label)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
