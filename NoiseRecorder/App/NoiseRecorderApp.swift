import SwiftUI
import SwiftData

@main
struct NoiseRecorderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: NoiseEvent.self)
    }
}
