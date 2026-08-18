import Foundation
import SwiftData

/// Builds a `WidgetSnapshot` from SwiftData and writes it to the App Group.
/// Call after any mutation that affects the widget (mood/journal/panic/streak)
/// and on app foreground. App target only — the widget never imports the models.
enum WidgetSync {
    @MainActor
    static func refresh(from context: ModelContext) {
        let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first
        let stats   = try? context.fetch(FetchDescriptor<GameStats>()).first

        // Predicate-scoped + fetchLimit: this runs on every save (including mid
        // panic session), so never materialize the whole mood table.
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        var todayDescriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay },
            sortBy: [SortDescriptor(\.date, order: .reverse)])
        todayDescriptor.fetchLimit = 1
        let todays = (try? context.fetch(todayDescriptor)) ?? []

        let snapshot = WidgetSnapshot(
            currentStreak: profile?.currentStreak ?? 0,
            longestStreak: profile?.longestStreak ?? 0,
            todayMoodLogged: !todays.isEmpty,
            todayMood: todays.first?.moodLevel ?? 0,
            level: stats?.currentLevel ?? 1,
            levelName: stats?.getLevelName() ?? "Anxious Beginner",
            lastUpdated: Date()
        )
        WidgetDataStore.write(snapshot)
    }
}
