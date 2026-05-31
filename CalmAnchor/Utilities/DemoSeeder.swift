//
//  DemoSeeder.swift
//  CalmAnchor
//
//  DEBUG-ONLY utility for seeding aspirational demo data used to capture
//  App Store screenshots. This file compiles to nothing in Release builds.
//
//  Usage: add launch arguments in the Xcode scheme (or `xcrun simctl launch`)
//    -seedDemoData   wipes the store and inserts ~30 days of realistic data
//    -demoPremium    forces RevenueCatService.isPremium = true so premium
//                    screens (Journal, Progress, Streaks) render for capture
//
//  Neither argument is present in normal runs, so real users are unaffected.
//

#if DEBUG
import Foundation
import SwiftData

enum DemoSeeder {

    static var shouldSeed: Bool {
        ProcessInfo.processInfo.arguments.contains("-seedDemoData")
    }

    static var forcePremium: Bool {
        ProcessInfo.processInfo.arguments.contains("-demoPremium")
    }

    private static let triggerVocab = ["Work", "Health", "Sleep", "Social", "Finances", "Relationships"]
    private static let copingVocab  = ["Box Breathing", "5-4-3-2-1 Grounding", "Body Scan", "Mindful Walk", "Affirmations"]

    /// Wipes all existing data and inserts a polished, aspirational dataset.
    @MainActor
    static func seed(into context: ModelContext) {
        wipe(context)

        let cal = Calendar.current
        let now = Date()

        // MARK: Profile — established user with a healthy streak
        let profile = UserProfile(
            calmName: "Riley",
            triggers: ["Work", "Sleep", "Social"],
            baselineMood: 4,
            dailyMinutes: 15,
            currentStreak: 12,
            longestStreak: 21,
            totalSessions: 86,
            isPremium: true
        )
        profile.lastActiveDate = now
        context.insert(profile)

        // MARK: Mood entries — 30 days, gentle upward trend (mood↑, anxiety↓)
        for dayOffset in stride(from: 29, through: 0, by: -1) {
            guard let base = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            // 1–2 entries per day at varied times
            let entriesToday = (dayOffset % 3 == 0) ? 2 : 1
            for e in 0..<entriesToday {
                let progress = Double(29 - dayOffset) / 29.0           // 0 → 1 over time
                let mood = Int((4.0 + progress * 4.0).rounded()) + (e == 0 ? 0 : 1)   // ~4 → ~8
                let anxiety = Int((8.0 - progress * 4.5).rounded())                    // ~8 → ~3
                let hour = e == 0 ? 8 : 20
                let date = cal.date(bySettingHour: hour, minute: 15, second: 0, of: base) ?? base
                let entry = MoodEntry(
                    moodLevel: min(max(mood, 1), 10),
                    anxietyLevel: min(max(anxiety, 1), 10),
                    triggers: [triggerVocab[(dayOffset + e) % triggerVocab.count]],
                    notes: "",
                    timeOfDay: hour < 12 ? "morning" : "evening"
                )
                entry.date = date
                context.insert(entry)
            }
        }

        // MARK: Journal entries — 14 over the last 3 weeks
        let gratitudeSets = [
            ["A quiet morning", "My support system", "Small wins today"],
            ["Sunlight on my walk", "A good night's sleep", "Feeling more like myself"],
            ["Coffee with a friend", "Finishing a hard task", "My breath as an anchor"],
            ["A calm commute", "Time to rest", "Progress, not perfection"]
        ]
        let affirmations = [
            "I am safe in this moment.",
            "This feeling will pass, and I will be okay.",
            "I am stronger than my anxiety.",
            "I give myself permission to rest."
        ]
        let freeWrites = [
            "Felt the tightness in my chest before the meeting, but box breathing pulled me back. Proud of how I handled it.",
            "A harder day. Named the worry, sat with it, and it loosened its grip by evening.",
            "Noticed I slept better after the wind-down routine. Mornings feel less heavy now.",
            "Grounded myself with 5-4-3-2-1 when the spiral started. It actually worked."
        ]
        for i in 0..<14 {
            guard let date = cal.date(byAdding: .day, value: -(i * 2), to: now) else { continue }
            let progress = Double(13 - i) / 13.0
            let entry = JournalEntry(
                moodBefore: min(max(Int((4.0 + progress * 3.0).rounded()), 1), 10),
                moodAfter: min(max(Int((6.0 + progress * 3.0).rounded()), 1), 10),
                anxietyLevel: min(max(Int((7.0 - progress * 3.5).rounded()), 1), 10),
                triggers: [triggerVocab[i % triggerVocab.count]],
                gratitudes: gratitudeSets[i % gratitudeSets.count],
                affirmation: affirmations[i % affirmations.count],
                freeWrite: freeWrites[i % freeWrites.count],
                copingUsed: [copingVocab[i % copingVocab.count]]
            )
            entry.date = cal.date(bySettingHour: 21, minute: 30, second: 0, of: date) ?? date
            context.insert(entry)
        }

        // MARK: Panic events — a few, all resolved with big intensity drops
        for i in 0..<5 {
            guard let date = cal.date(byAdding: .day, value: -(i * 5 + 1), to: now) else { continue }
            let event = PanicEvent(
                intensityBefore: 9 - i % 2,
                intensityAfter: 3,
                duration: TimeInterval(180 + i * 45),
                techniquesUsed: ["Box Breathing", "5-4-3-2-1 Grounding"],
                triggers: [triggerVocab[i % triggerVocab.count]],
                notes: "Used the Panic SOS flow. Came down within a few minutes.",
                resolved: true
            )
            event.date = date
            context.insert(event)
        }

        // MARK: Healing plan — reuse the real generator, then complete days 1–12
        HealingPlanService.generatePlan(for: profile, in: context)
        let descriptor = FetchDescriptor<HealingTask>(sortBy: [SortDescriptor(\.dayNumber), SortDescriptor(\.sortOrder)])
        if let tasks = try? context.fetch(descriptor) {
            for task in tasks where task.dayNumber <= 12 {
                task.isCompleted = true
                if let d = cal.date(byAdding: .day, value: -(13 - task.dayNumber), to: now) {
                    task.completedDate = d
                }
            }
        }

        // MARK: Game stats — mid-journey level
        let stats = GameStats()
        stats.currentLevel = 6
        stats.totalXP = 3600
        stats.totalXPEarned = 3600
        stats.lastXPUpdate = now
        context.insert(stats)

        try? context.save()
    }

    @MainActor
    private static func wipe(_ context: ModelContext) {
        try? context.delete(model: MoodEntry.self)
        try? context.delete(model: JournalEntry.self)
        try? context.delete(model: PanicEvent.self)
        try? context.delete(model: HealingTask.self)
        try? context.delete(model: UserProfile.self)
        try? context.delete(model: GameStats.self)
        try? context.save()
    }
}
#endif
