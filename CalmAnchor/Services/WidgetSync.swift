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

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let moods = (try? context.fetch(
            FetchDescriptor<MoodEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        )) ?? []
        let todays = moods.filter { Calendar.current.startOfDay(for: $0.date) == startOfDay }

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
