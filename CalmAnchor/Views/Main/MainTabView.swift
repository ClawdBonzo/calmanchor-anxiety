import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = MainTabView.initialTab
    @State private var showPanicMode = MainTabView.initialPanic
    @State private var showWidgetMood = false
    @State private var dayKey = Calendar.current.startOfDay(for: Date())

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
                    // Re-init at midnight / on foreground so date-scoped queries roll over.
                    .id(dayKey)
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
        .sheet(isPresented: $showWidgetMood) {
            QuickMoodLogView()
                .presentationDetents([.medium])
        }
        .task { repairMissingProfileIfNeeded() }
        .onChange(of: scenePhase) { _, phase in
            // Bump the day key on foreground so date-scoped views re-init.
            if phase == .active { dayKey = Calendar.current.startOfDay(for: Date()) }
        }
        .onOpenURL { url in
            switch url.host {
            case "panic":
                showPanicMode = true
            case "logmood":
                selectedTab = 0
                showWidgetMood = true
            default:
                break
            }
        }
    }

    /// Self-heal for installs affected by the 1.0 onboarding bug (swiping past
    /// the crafting step skipped profile creation), and de-dupe accidental
    /// duplicate profiles. Idempotent; runs once per app entry.
    private func repairMissingProfileIfNeeded() {
        let profiles = (try? modelContext.fetch(
            FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        if profiles.isEmpty {
            let p = UserProfile()
            modelContext.insert(p)
            HealingPlanService.generatePlan(for: p, in: modelContext)
            try? modelContext.save()
        } else if profiles.count > 1 {
            // Keep the oldest (the one streak/settings writes most likely targeted).
            for extra in profiles.dropFirst() { modelContext.delete(extra) }
            try? modelContext.save()
        }
    }
}
