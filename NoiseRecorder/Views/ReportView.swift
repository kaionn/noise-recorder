import SwiftUI
import SwiftData

struct ReportView: View {
    @Query(sort: \NoiseEvent.timestamp, order: .reverse) private var allEvents: [NoiseEvent]
    @State private var recorderName = ""
    @State private var address = ""
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var endDate = Date()
    @State private var showShareSheet = false
    @State private var pdfData: Data?

    private var filteredEvents: [NoiseEvent] {
        allEvents.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    var body: some View {
        let events = filteredEvents

        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Export Report")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal)

                // 記録者情報
                SectionCard(title: "RECORDER INFORMATION") {
                    VStack(spacing: 12) {
                        FormField(placeholder: "Name", text: $recorderName)
                        FormField(placeholder: "Address", text: $address)
                    }
                }

                // 期間選択
                SectionCard(title: "REPORTING PERIOD") {
                    VStack(spacing: 12) {
                        DateRow(label: "Start Date", date: $startDate)
                        DateRow(label: "End Date", date: $endDate)
                    }
                }

                // プレビュー
                SectionCard(title: "REPORT PREVIEW") {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total Events:")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text("\(events.count)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppColor.accent)
                        }

                        Divider().overlay(Color.gray.opacity(0.3))

                        ForEach(events.prefix(5)) { event in
                            HStack {
                                Text(event.timestamp, format: .dateTime.month().day().year())
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(event.maxDecibels.formattedDbWithUnit)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColor.dangerRed)
                            }
                            .padding(.vertical, 2)
                        }

                        if events.count > 5 {
                            Text("+ \(events.count - 5) more events")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                    }
                }

                // PDF出力ボタン
                Button {
                    generateAndShare()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                        Text("Export PDF Report")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(events.isEmpty ? Color.gray : AppColor.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(events.isEmpty)
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .appBackground()
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
    }

    private func generateAndShare() {
        let events = filteredEvents
        let info = PDFReportGenerator.ReportInfo(
            recorderName: recorderName,
            address: address,
            startDate: startDate,
            endDate: endDate,
            events: events
        )
        pdfData = PDFReportGenerator.generate(info: info)
        showShareSheet = true
    }
}

// MARK: - Private Components

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: title)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .padding(.horizontal)
    }
}

private struct FormField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(12)
            .background(AppColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct DateRow: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.white)
            Spacer()
            DatePicker("", selection: $date, displayedComponents: .date).labelsHidden()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
