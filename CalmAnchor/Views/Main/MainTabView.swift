import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = MainTabView.initialTab
    @State private var showPanicMode = MainTabView.initialPanic

    // DEBUG-only: allow screenshot capture to jump to a specific tab / panic screen
    // via launch args -demoTab <0-4> and -demoPanic. No effect in Release.
    private static var initialTab: Int {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-demoTab"), i + 1 < args.count, let t = Int(args[i + 1]) {
            return t
        }
        #endif
        return 0
    }
    private static var initialPanic: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-demoPanic")
        #else
        return false
        #endif
    }

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
