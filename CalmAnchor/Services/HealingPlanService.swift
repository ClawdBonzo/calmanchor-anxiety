import Foundation
import SwiftData

struct HealingPlanService {
    // Plan cycles every 30 days. Completion is tracked per-cycle so a task
    // checked in month 1 shows fresh again in month 2.
    static let cycleLength = 30

    // (title, description, category, duration)
    private static let library: [(String, String, String, Int)] = [
        ("Morning Breathing", "Start your day with 4-7-8 breathing technique", "breathing", 3),
        ("Gratitude Check-in", "Write 3 things you're grateful for", "journaling", 5),
        ("Body Scan", "Progressive relaxation from head to toe", "mindfulness", 7),
        ("5-4-3-2-1 Grounding", "Engage all five senses to ground yourself", "grounding", 5),
        ("Gentle Stretching", "Release tension with mindful movement", "movement", 5),
        ("Evening Reflection", "Journal about your day and wins", "journaling", 5),
        ("Box Breathing", "4 counts in, hold, out, hold", "breathing", 3),
        ("Mindful Walk", "Walk slowly, noticing each step", "movement", 10),
        ("Thought Record", "Challenge anxious thoughts with evidence", "journaling", 7),
        ("Progressive Relaxation", "Tense and release each muscle group", "mindfulness", 8),
        ("Anchor Breathing", "Focus on breath as your anchor", "breathing", 5),
        ("Trigger Mapping", "Identify and plan for your triggers", "journaling", 10),
        ("Loving-Kindness", "Send compassion to yourself and others", "mindfulness", 7),
        ("Cold Exposure", "Splash cold water for vagus nerve activation", "grounding", 2),
        ("Visualization", "Picture your peaceful place in detail", "mindfulness", 5),
        ("Movement Break", "Shake out tension with full-body movement", "movement", 3),
        ("Affirmation Practice", "Repeat calming affirmations with intention", "mindfulness", 3),
        ("Worry Window", "Designate time to address worries, then let go", "journaling", 10),
        ("Nature Connection", "Spend time noticing natural elements", "grounding", 5),
        ("Self-Compassion Letter", "Write to yourself with kindness", "journaling", 8),
        ("Deep Belly Breathing", "Diaphragmatic breathing for calm", "breathing", 5),
        ("Mindful Eating", "Eat one meal with full attention", "mindfulness", 10),
        ("Anxiety Exposure", "Gently face a small fear with support", "grounding", 5),
        ("Sleep Wind-Down", "Create a calming bedtime routine", "mindfulness", 10),
        ("Celebration", "Acknowledge your healing journey progress", "journaling", 5),
        ("Free Movement", "Dance or move freely to release energy", "movement", 5),
        ("Breath Counting", "Count breaths to 10, then restart", "breathing", 5),
        ("Sensory Soothing", "Engage comforting textures, scents, sounds", "grounding", 5),
    ]

    /// Which task categories help most for each onboarding trigger. This is
    /// what makes "personalized to your triggers" true rather than a promise.
    private static let triggerAffinity: [String: [String]] = [
        "Work Stress":         ["breathing", "mindfulness"],
        "Social Situations":   ["grounding", "breathing"],
        "Health Worries":      ["mindfulness", "journaling"],
        "Financial Concerns":  ["journaling", "breathing"],
        "Relationship Issues": ["journaling", "mindfulness"],
        "Sleep Problems":      ["mindfulness", "breathing"],
        "Uncertainty":         ["grounding", "journaling"],
        "Perfectionism":       ["journaling", "mindfulness"],
        "Crowds / Spaces":     ["grounding", "breathing"],
        "Loneliness":          ["mindfulness", "movement"],
    ]

    static func generatePlan(for profile: UserProfile, in context: ModelContext) {
        let minutes = profile.dailyMinutes

        // Weight the library toward the user's triggers: preferred categories
        // are listed first, everything else follows, and we step through with a
        // stride coprime to the library size so no two days are identical.
        let preferred = Set(profile.triggers.flatMap { triggerAffinity[$0] ?? [] })
        let ordered = library.filter { preferred.contains($0.2) }
                    + library.filter { !preferred.contains($0.2) }
        let n = ordered.count
        let stride = coprimeStride(for: n)

        for day in 1...cycleLength {
            var dayMinutes = 0
            var sortOrder = 0
            var cursor = ((day - 1) * stride) % n
            var attempts = 0
            while dayMinutes < minutes && sortOrder < 5 && attempts < n {
                let plan = ordered[cursor]
                if dayMinutes + plan.3 <= minutes + 3 {
                    context.insert(HealingTask(title: plan.0,
                                               taskDescription: plan.1,
                                               category: plan.2,
                                               durationMinutes: plan.3,
                                               dayNumber: day,
                                               sortOrder: sortOrder))
                    dayMinutes += plan.3
                    sortOrder += 1
                }
                cursor = (cursor + 1) % n
                attempts += 1
            }
        }
        try? context.save()
    }

    /// Calendar-day-based plan day (starts at 1 on the signup day, advances at
    /// local midnight — not at the signup time of day).
    static func currentDayNumber(from startDate: Date, now: Date = Date()) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let today = cal.startOfDay(for: now)
        let elapsed = cal.dateComponents([.day], from: start, to: today).day ?? 0
        return max(1, elapsed + 1)
    }

    /// 1-based day within the current 30-day cycle.
    static func clampedDay(_ dayNumber: Int) -> Int {
        ((dayNumber - 1) % cycleLength) + 1
    }

    /// Start date of the cycle that contains `dayNumber`.
    static func cycleStart(from startDate: Date, dayNumber: Int) -> Date {
        let cal = Calendar.current
        let cycleIndex = (dayNumber - 1) / cycleLength
        let start = cal.startOfDay(for: startDate)
        return cal.date(byAdding: .day, value: cycleIndex * cycleLength, to: start) ?? start
    }

    static func todaysTasks(from context: ModelContext) -> [HealingTask] {
        let profile = fetchProfile(from: context)
        let startDate = profile?.createdAt ?? Date()
        let dayNumber = currentDayNumber(from: startDate)
        let day = clampedDay(dayNumber)

        let descriptor = FetchDescriptor<HealingTask>(
            predicate: #Predicate { $0.dayNumber == day },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let tasks = (try? context.fetch(descriptor)) ?? []

        // Per-cycle completion: a task completed in a PREVIOUS cycle is fresh
        // again now. Reset its flag lazily so month 2 doesn't show month 1's ticks.
        let thisCycle = cycleStart(from: startDate, dayNumber: dayNumber)
        var changed = false
        for t in tasks where t.isCompleted {
            if let done = t.completedDate, done < thisCycle {
                t.isCompleted = false
                t.completedDate = nil
                changed = true
            }
        }
        if changed { try? context.save() }
        return tasks
    }

    static func fetchProfile(from context: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt)])
        return try? context.fetch(descriptor).first
    }

    /// Smallest stride ≥ 2 that is coprime with `n`, so cycling by it visits
    /// every library entry before repeating (no identical days).
    private static func coprimeStride(for n: Int) -> Int {
        guard n > 2 else { return 1 }
        var s = 5
        while gcd(s, n) != 1 { s += 2 }
        return s
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }
}
