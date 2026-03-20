import Foundation
import SwiftData

@Model
final class NoiseEvent {
    var timestamp: Date
    var maxDecibels: Double
    var averageDecibels: Double
    var durationSeconds: Double

    init(timestamp: Date, maxDecibels: Double, averageDecibels: Double, durationSeconds: Double) {
        self.timestamp = timestamp
        self.maxDecibels = maxDecibels
        self.averageDecibels = averageDecibels
        self.durationSeconds = durationSeconds
    }
}
