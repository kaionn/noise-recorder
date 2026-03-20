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
        let events = filteredEvents

        VStack(spacing: 16) {
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

            HStack {
                Text("EVENT LOG — \(events.count) CRITICAL")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.gray)
                    .tracking(1)
                Spacer()
                Text("SORT BY NEWEST")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppColor.accent)
            }
            .padding(.horizontal)

            if events.isEmpty {
                Spacer()
                EmptyStateView(icon: "waveform.slash", message: "No events recorded")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(events) { event in
                            EventCard(event: event)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .appBackground()
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

                Label(event.durationSeconds.formattedDuration(), systemImage: "clock")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(event.maxDecibels.formattedDb)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.dangerRed)
                + Text(" dB")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColor.dangerRed)

                Text("\(event.averageDecibels.formattedDb) AVG")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColor.warningOrange)
            }
        }
        .cardStyle()
    }
}
