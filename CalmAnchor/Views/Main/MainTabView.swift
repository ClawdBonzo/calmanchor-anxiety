import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showPanicMode = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView(showPanicMode: $showPanicMode)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)

                JournalListView()
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("Journal")
                    }
                    .tag(1)

                StreakCalendarView()
                    .tabItem {
                        Image(systemName: "flame.fill")
                        Text("Streaks")
                    }
                    .tag(2)

                ProgressChartsView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progress")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(4)
            }
            .tint(AppConstants.Colors.calmBlue)

            if showPanicMode {
                PanicSOSView(isPresented: $showPanicMode)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
    }
}
