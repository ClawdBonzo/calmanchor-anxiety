import Foundation
import SwiftData

struct HealingPlanService {
    static func generatePlan(for profile: UserProfile, in context: ModelContext) {
        let _ = profile.triggers
        let minutes = profile.dailyMinutes

        let plans: [(String, String, String, Int)] = [
            // (title, description, category, duration)
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

        // Build a 30-day plan cycling through tasks, ~minutes/day per day
        for day in 1...30 {
            var dayMinutes = 0
            var sortOrder = 0
            let taskIndex = (day - 1) * 2 // rotate through tasks

            while dayMinutes < minutes && sortOrder < 5 {
                let idx = (taskIndex + sortOrder) % plans.count
                let plan = plans[idx]

                if dayMinutes + plan.3 <= minutes + 3 { // small overflow OK
                    let task = HealingTask(
                        title: plan.0,
                        taskDescription: plan.1,
                        category: plan.2,
                        durationMinutes: plan.3,
                        dayNumber: day,
                        sortOrder: sortOrder
                    )
                    context.insert(task)
                    dayMinutes += plan.3
                }
                sortOrder += 1
            }
        }

        try? context.save()
    }

    static func todaysTasks(from context: ModelContext) -> [HealingTask] {
        let profile = fetchProfile(from: context)
        let startDate = profile?.createdAt ?? Date()
        let dayNumber = max(1, Calendar.current.dateComponents([.day], from: startDate, to: Date()).day! + 1)
        let clampedDay = ((dayNumber - 1) % 30) + 1

        let descriptor = FetchDescriptor<HealingTask>(
            predicate: #Predicate { $0.dayNumber == clampedDay },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    static func fetchProfile(from context: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try? context.fetch(descriptor).first
    }
}
