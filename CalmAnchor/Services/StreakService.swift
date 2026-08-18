import Foundation
import SwiftData

struct StreakService {
    /// One missed day is forgiven at most once every 30 days. A single slip
    /// erasing a long streak is the classic churn trigger; a grace day keeps
    /// people in the habit without making streaks meaningless.
    static let graceCooldownDays = 30

    @MainActor
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
            } else if daysBetween == 2, canUseGrace(profile, today: today) {
                // Missed exactly one day — spend the grace day, keep the streak going.
                profile.lastGraceUsedDate = today
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

        // Celebrate real milestones (3/7/14/30/60/100), once each.
        CelebrationCenter.shared.postStreakMilestone(profile.currentStreak)

        // Just logged today → there's no streak to lose tonight.
        NotificationService.shared.cancelStreakRisk()
    }

    private static func canUseGrace(_ profile: UserProfile, today: Date) -> Bool {
        guard profile.currentStreak >= 3 else { return false }   // nothing worth saving yet
        guard let last = profile.lastGraceUsedDate else { return true }
        let since = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0
        return since >= graceCooldownDays
    }

    static func activeDates(journals: [JournalEntry],
                            moods: [MoodEntry],
                            panicEvents: [PanicEvent] = []) -> Set<DateComponents> {
        let calendar = Calendar.current
        var dates = Set<DateComponents>()
        for journal in journals {
            dates.insert(calendar.dateComponents([.year, .month, .day], from: journal.date))
        }
        for mood in moods {
            dates.insert(calendar.dateComponents([.year, .month, .day], from: mood.date))
        }
        // A completed panic session is real activity — show it on the calendar.
        for event in panicEvents where event.resolved {
            dates.insert(calendar.dateComponents([.year, .month, .day], from: event.date))
        }
        return dates
    }
}
