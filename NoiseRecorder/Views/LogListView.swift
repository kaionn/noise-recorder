import SwiftUI
import SwiftData

struct LogListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NoiseEvent.timestamp, order: .reverse) private var allEvents: [NoiseEvent]
    @State private var filterMode: FilterMode = .today

    enum FilterMode: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case custom = "Custom"
    }

    @State private var customDate = Date()

    private var filteredEvents: [NoiseEvent] {
        let calendar = Calendar.current
        switch filterMode {
        case .today:
            return allEvents.filter { calendar.isDateInToday($0.timestamp) }
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
            return allEvents.filter { $0.timestamp >= weekAgo }
        case .custom:
            return allEvents.filter { calendar.isDate($0.timestamp, inSameDayAs: customDate) }
        }
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 16) {
                // ヘッダー
                HStack {
                    Text("Noise Log")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal)

                // フィルタタブ
                HStack(spacing: 0) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        Button {
                            filterMode = mode
                        } label: {
                            Text(mode.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(filterMode == mode ? AppColor.accent : Color.clear)
                                .foregroundStyle(filterMode == mode ? .white : .gray)
                        }
                    }
                }
                .background(AppColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

                if filterMode == .custom {
                    DatePicker("Date", selection: $customDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                }

                // イベント数
                HStack {
                    Text("EVENT LOG — \(filteredEvents.count) CRITICAL")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.gray)
                        .tracking(1)
                    Spacer()
                    Text("SORT BY NEWEST")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppColor.accent)
                }
                .padding(.horizontal)

                if filteredEvents.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        Text("No events recorded")
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredEvents) { event in
                                EventCard(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

private struct EventCard: View {
    let event: NoiseEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(event.timestamp, format: .dateTime.month().day().hour().minute())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Label(formatDuration(event.durationSeconds), systemImage: "clock")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", event.maxDecibels))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.dangerRed)
                + Text(" dB")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColor.dangerRed)

                Text(String(format: "%.1f AVG", event.averageDecibels))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColor.warningOrange)
            }
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds < 60 { return String(format: "%.0fs", seconds) }
        let min = Int(seconds) / 60
        let sec = Int(seconds) % 60
        return String(format: "%d:%02d", min, sec)
    }
}
