import Foundation
import SwiftData

struct StreakService {
    static func updateStreak(for profile: UserProfile) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActive = profile.lastActiveDate {
            let lastDay = calendar.startOfDay(for: lastActive)

            if lastDay == today {
                return // already logged today
            }

            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 1 {
                profile.currentStreak += 1
            } else {
                profile.currentStreak = 1
            }
        } else {
            profile.currentStreak = 1
        }

        profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
        profile.lastActiveDate = today
        profile.totalSessions += 1
    }

    static func activeDates(journals: [JournalEntry], moods: [MoodEntry]) -> Set<DateComponents> {
        let calendar = Calendar.current
        var dates = Set<DateComponents>()

        for journal in journals {
            let comps = calendar.dateComponents([.year, .month, .day], from: journal.date)
            dates.insert(comps)
        }

        for mood in moods {
            let comps = calendar.dateComponents([.year, .month, .day], from: mood.date)
            dates.insert(comps)
        }

        return dates
    }
}
