import Foundation
import SwiftData

/// The three canonical daily quest types, each tied to a real in-app action.
enum QuestType: String, CaseIterable {
    case logMood      // a MoodEntry is saved
    case healingTask  // a HealingTask is completed
    case calmSession  // a Panic SOS / breathing session ends

    var title: String {
        switch self {
        case .logMood:     return "Check in with your mood"
        case .healingTask: return "Complete a healing task"
        case .calmSession: return "Do a calming session"
        }
    }
    var detail: String {
        switch self {
        case .logMood:     return "Log how you're feeling today"
        case .healingTask: return "Finish one task in today's healing plan"
        case .calmSession: return "Complete a breathing or SOS session"
        }
    }
    var icon: String {
        switch self {
        case .logMood:     return "face.smiling"
        case .healingTask: return "leaf.fill"
        case .calmSession: return "wind"
        }
    }
    var xp: Int {
        switch self {
        case .logMood:     return 50
        case .healingTask: return 75
        case .calmSession: return 100
        }
    }
}

/// Generates and resets a small daily quest set, and funnels real in-app
/// events into quest completion + XP awards. Lazy/idempotent — safe to call
/// on every appear; resets at local midnight without any background timer.
enum QuestService {
    /// Ensure today's 3 quests exist; deactivate any from previous days.
    /// - Parameter isPremium: free users can't reach the healing plan, so their
    ///   daily set omits that quest — a visible goal that can never be completed
    ///   is worse than no goal at all.
    @MainActor
    @discardableResult
    static func refreshDailyQuests(in context: ModelContext, isPremium: Bool = true) -> [Quest] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: today) else { return [] }

        let active = (try? context.fetch(
            FetchDescriptor<Quest>(predicate: #Predicate { $0.isActive })
        )) ?? []

        var todays: [Quest] = []
        for q in active {
            if q.dueDate >= today && q.dueDate < tomorrow {
                todays.append(q)
            } else {
                q.isActive = false   // expire previous days' quests
            }
        }

        if !todays.isEmpty {
            try? context.save()
            return todays.sorted { $0.createdDate < $1.createdDate }
        }

        // Generate today's set (free users skip the premium-only healing task quest).
        let due = tomorrow.addingTimeInterval(-1)
        var created: [Quest] = []
        let types = QuestType.allCases.filter { isPremium || $0 != .healingTask }
        for type in types {
            let q = Quest(type: type.rawValue,
                          title: type.title,
                          questDescription: type.detail,
                          targetCount: 1,
                          xpReward: type.xp,
                          frequency: "daily",
                          dueDate: due)
            context.insert(q)
            created.append(q)
        }
        try? context.save()
        return created
    }

    /// Record a real event; completes the matching active quest and awards XP.
    /// Returns the XPAward if a quest *just* completed (for level-up feedback).
    @MainActor
    @discardableResult
    static func recordEvent(_ type: QuestType, in context: ModelContext) -> XPAward? {
        let today = Calendar.current.startOfDay(for: Date())
        let raw = type.rawValue
        let descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate { $0.isActive && !$0.isCompleted && $0.type == raw }
        )
        guard let quest = (try? context.fetch(descriptor))?
            .first(where: { $0.dueDate >= today }) else { return nil }

        quest.incrementProgress()
        guard quest.isCompleted else { try? context.save(); return nil }

        let award = XPService.award(quest.xpReward, source: "quest:\(raw)", in: context)
        try? context.save()
        return award
    }
}
