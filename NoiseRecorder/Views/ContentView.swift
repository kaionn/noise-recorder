import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("METER", systemImage: "waveform")
                }

            LogListView()
                .tabItem {
                    Label("LOG", systemImage: "list.bullet")
                }

            DashboardView()
                .tabItem {
                    Label("STATS", systemImage: "chart.bar")
                }

            ReportView()
                .tabItem {
                    Label("REPORT", systemImage: "doc.text")
                }

            SettingsView()
                .tabItem {
                    Label("SETTINGS", systemImage: "gear")
                }
        }
        .tint(AppColor.accent)
    }
}
