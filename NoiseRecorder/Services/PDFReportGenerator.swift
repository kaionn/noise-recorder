import UIKit
import PDFKit

struct PDFReportGenerator {
    struct ReportInfo {
        var recorderName: String = ""
        var address: String = ""
        var startDate: Date
        var endDate: Date
        var events: [NoiseEvent]
    }

    static func generate(info: ReportInfo) -> Data {
        let pageWidth: CGFloat = 595.2  // A4
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20)
            ]
            let title = "騒音記録レポート"
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttr)
            y += 35

            let headerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"

            let headerLines = [
                "記録者: \(info.recorderName.isEmpty ? "（未設定）" : info.recorderName)",
                "住所: \(info.address.isEmpty ? "（未設定）" : info.address)",
                "記録期間: \(dateFormatter.string(from: info.startDate)) 〜 \(dateFormatter.string(from: info.endDate))",
                "超過イベント数: \(info.events.count)件",
                ""
            ]
            for line in headerLines {
                line.draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttr)
                y += 20
            }

            let tableHeaderAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10)
            ]
            let tableAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10)
            ]

            let columns: [(String, CGFloat)] = [
                ("日時", 0),
                ("最大 dB", contentWidth * 0.4),
                ("平均 dB", contentWidth * 0.55),
                ("持続時間", contentWidth * 0.7)
            ]

            let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: 20)
            UIColor.systemGray5.setFill()
            UIRectFill(headerRect)

            for (text, offset) in columns {
                text.draw(at: CGPoint(x: margin + offset + 5, y: y + 3), withAttributes: tableHeaderAttr)
            }
            y += 22

            for event in info.events {
                if y > pageHeight - margin - 30 {
                    context.beginPage()
                    y = margin
                }

                let row = [
                    dateFormatter.string(from: event.timestamp),
                    event.maxDecibels.formattedDb,
                    event.averageDecibels.formattedDb,
                    event.durationSeconds.formattedDuration(style: .japanese)
                ]

                for (i, text) in row.enumerated() {
                    text.draw(at: CGPoint(x: margin + columns[i].1 + 5, y: y), withAttributes: tableAttr)
                }
                y += 18

                let linePath = UIBezierPath()
                linePath.move(to: CGPoint(x: margin, y: y))
                linePath.addLine(to: CGPoint(x: margin + contentWidth, y: y))
                UIColor.systemGray4.setStroke()
                linePath.lineWidth = 0.5
                linePath.stroke()
                y += 2
            }

            y = pageHeight - margin
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.gray
            ]
            let now = dateFormatter.string(from: Date())
            "出力日時: \(now) | 騒音証拠レコーダー".draw(at: CGPoint(x: margin, y: y), withAttributes: footerAttr)
        }

        return data
    }
}
