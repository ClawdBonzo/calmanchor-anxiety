import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showPanicMode = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView(showPanicMode: $showPanicMode)
                    .tabItem {
                        Image("Tab-Dashboard")
                            .renderingMode(.template)
                        Text("Home")
                    }
                    .tag(0)

                JournalListView()
                    .tabItem {
                        Image("Tab-Journal")
                            .renderingMode(.template)
                        Text("Journal")
                    }
                    .tag(1)

                StreakCalendarView()
                    .tabItem {
                        Image("Tab-Streaks")
                            .renderingMode(.template)
                        Text("Streaks")
                    }
                    .tag(2)

                ProgressChartsView()
                    .tabItem {
                        Image("Tab-SOS")
                            .renderingMode(.template)
                        Text("Progress")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Image("Tab-Settings")
                            .renderingMode(.template)
                        Text("Settings")
                    }
                    .tag(4)
            }
            .tint(Color(hex: "00C9B7"))

            if showPanicMode {
                PanicSOSView(isPresented: $showPanicMode)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
    }
}
