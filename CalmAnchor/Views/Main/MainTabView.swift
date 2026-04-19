import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showPanicMode = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView(showPanicMode: $showPanicMode)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                JournalListView()
                    .tabItem {
                        Label("Journal", systemImage: "book.fill")
                    }
                    .tag(1)

                StreakCalendarView()
                    .tabItem {
                        Label("Streaks", systemImage: "flame.fill")
                    }
                    .tag(2)

                ProgressChartsView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(Color(hex: "00C9B7"))
            .sensoryFeedback(.selection, trigger: selectedTab)

            if showPanicMode {
                PanicSOSView(isPresented: $showPanicMode)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
    }
}
