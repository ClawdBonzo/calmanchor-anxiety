import Foundation
import SwiftData

// MARK: - Facts

/// Everything badges measure, derived from the user's own data every time
/// (never a running ledger, so it can't drift and deleting data is honest).
enum CalmMetric: String, CaseIterable {
    case sessions, bigDrops, stormTamed, calmMinutes
    case longestStreak, moods, twiceADay, journals, gratitudes, planDays
    case level, triggers, shares
    case nightWatch, earlyLight, comeback, graceSaved
}

struct CalmFacts: Equatable {
    var values: [CalmMetric: Int] = [:]
    subscript(_ m: CalmMetric) -> Int { values[m] ?? 0 }

    @MainActor
    static func compute(in context: ModelContext) -> CalmFacts {
        let cal = Calendar.current
        let panics = ((try? context.fetch(FetchDescriptor<PanicEvent>())) ?? []).filter(\.resolved)
        let moods = (try? context.fetch(FetchDescriptor<MoodEntry>())) ?? []
        let journals = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
        let tasks = (try? context.fetch(FetchDescriptor<HealingTask>())) ?? []
        let profile = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first
        let stats = (try? context.fetch(FetchDescriptor<GameStats>()))?.first

        var f = CalmFacts()
        f.values[.sessions] = panics.count
        f.values[.bigDrops] = panics.filter { $0.intensityBefore - $0.intensityAfter >= 3 }.count
        f.values[.stormTamed] = panics.filter { $0.intensityBefore >= 8 && $0.intensityAfter <= 4 }.count
        f.values[.calmMinutes] = Int(panics.reduce(0) { $0 + $1.duration } / 60)
        f.values[.longestStreak] = max(profile?.longestStreak ?? 0, profile?.currentStreak ?? 0)
        f.values[.moods] = moods.count
        f.values[.journals] = journals.count
        f.values[.gratitudes] = journals.reduce(0) {
            $0 + $1.gratitudes.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        }
        f.values[.level] = stats?.currentLevel ?? 1
        f.values[.shares] = UserDefaults.standard.integer(forKey: CalmGame.sharesKey)

        // Days with both a morning and an evening/night check-in.
        let mornings = Set(moods.filter { $0.timeOfDay == "morning" }.map { cal.startOfDay(for: $0.date) })
        let evenings = Set(moods.filter { $0.timeOfDay == "evening" || $0.timeOfDay == "night" }
            .map { cal.startOfDay(for: $0.date) })
        f.values[.twiceADay] = mornings.intersection(evenings).count

        // Plan days where every task is done.
        let byDay = Dictionary(grouping: tasks, by: \.dayNumber)
        f.values[.planDays] = byDay.values.filter { !$0.isEmpty && $0.allSatisfy(\.isCompleted) }.count

        var triggerSet = Set<String>()
        moods.forEach { triggerSet.formUnion($0.triggers) }
        journals.forEach { triggerSet.formUnion($0.triggers) }
        panics.forEach { triggerSet.formUnion($0.triggers) }
        f.values[.triggers] = triggerSet.filter { !$0.isEmpty }.count

        // Secret moments.
        f.values[.nightWatch] = panics.contains { (0...4).contains(cal.component(.hour, from: $0.date)) } ? 1 : 0
        f.values[.earlyLight] = moods.contains { (4...6).contains(cal.component(.hour, from: $0.date)) } ? 1 : 0
        f.values[.graceSaved] = profile?.lastGraceUsedDate != nil ? 1 : 0

        var days = Set(moods.map { cal.startOfDay(for: $0.date) })
        journals.forEach { days.insert(cal.startOfDay(for: $0.date)) }
        panics.forEach { days.insert(cal.startOfDay(for: $0.date)) }
        let sorted = days.sorted()
        let returned = zip(sorted, sorted.dropFirst()).contains {
            (cal.dateComponents([.day], from: $0, to: $1).day ?? 0) >= 7
        }
        f.values[.comeback] = returned ? 1 : 0
        return f
    }
}

// MARK: - Badge definitions

struct CalmBadge: Identifiable, Hashable {
    let id: String
    let metric: CalmMetric
    let target: Int
    let title: String
    let howToEarn: String
    let unlockedLine: String
    let symbol: String
    var isSecret = false
    /// Earned through a Premium feature (journal, healing plan).
    var isPremium = false

    func progress(_ facts: CalmFacts) -> Double {
        min(1, Double(facts[metric]) / Double(max(target, 1)))
    }
    func isEarned(_ facts: CalmFacts) -> Bool { facts[metric] >= target }
}

enum CalmBadgeCatalog {
    private static func ladder(_ metric: CalmMetric, premium: Bool = false,
                               _ rungs: [(Int, String, String, String, String)]) -> [CalmBadge] {
        rungs.map { target, title, how, line, symbol in
            CalmBadge(id: "\(metric.rawValue).\(target)", metric: metric, target: target,
                      title: title, howToEarn: how, unlockedLine: line, symbol: symbol,
                      isPremium: premium)
        }
    }

    private static func secret(_ metric: CalmMetric, _ title: String, _ how: String,
                               _ line: String, _ symbol: String) -> CalmBadge {
        CalmBadge(id: "\(metric.rawValue).1", metric: metric, target: 1, title: title,
                  howToEarn: how, unlockedLine: line, symbol: symbol, isSecret: true)
    }

    static let all: [CalmBadge] = {
        var b: [CalmBadge] = []
        b += ladder(.sessions, [
            (1, String(localized: "First Anchor"), String(localized: "Finish your first Panic SOS session."),
             String(localized: "You faced it and stayed with it. That took courage."), "lifepreserver.fill"),
            (3, String(localized: "Steady Hands"), String(localized: "Finish 3 Panic SOS sessions."),
             String(localized: "Three storms weathered. Your hands are steadier than you think."), "hand.raised.fill"),
            (10, String(localized: "Wave Rider"), String(localized: "Finish 10 Panic SOS sessions."),
             String(localized: "Ten sessions. You know this water now."), "water.waves"),
            (25, String(localized: "Storm Veteran"), String(localized: "Finish 25 Panic SOS sessions."),
             String(localized: "Twenty-five times you chose to breathe through it."), "tropicalstorm"),
            (50, String(localized: "Lighthouse"), String(localized: "Finish 50 Panic SOS sessions."),
             String(localized: "Fifty sessions. You're a light for your own ships."), "lightbulb.fill"),
            (100, String(localized: "Unsinkable"), String(localized: "Finish 100 Panic SOS sessions."),
             String(localized: "A hundred sessions. Nothing keeps you under."), "sailboat.fill")
        ])
        b += ladder(.bigDrops, [
            (1, String(localized: "Wave Breaker"), String(localized: "Lower your intensity by 3 or more in one session."),
             String(localized: "You watched a wave rise and fall. Proof that it passes."), "chart.line.downtrend.xyaxis"),
            (5, String(localized: "Tide Turner"), String(localized: "Lower your intensity by 3 or more in 5 sessions."),
             String(localized: "Five times the tide turned your way."), "arrow.uturn.down.circle.fill"),
            (20, String(localized: "Calm Engineer"), String(localized: "Lower your intensity by 3 or more in 20 sessions."),
             String(localized: "Twenty big drops. You've built a method that works."), "gearshape.2.fill")
        ])
        b += ladder(.stormTamed, [
            (1, String(localized: "Storm Tamer"), String(localized: "Bring an 8 or higher down to 4 or lower."),
             String(localized: "From an 8 to a 4. That isn't small. That's huge."), "hurricane")
        ])
        b += ladder(.calmMinutes, [
            (10, String(localized: "Ten Calm Minutes"), String(localized: "Spend 10 minutes in Panic SOS sessions."),
             String(localized: "Ten minutes of practice on purpose. It adds up."), "hourglass"),
            (60, String(localized: "The Calm Hour"), String(localized: "Spend 60 minutes in Panic SOS sessions."),
             String(localized: "A full hour of breathing through it."), "timer"),
            (180, String(localized: "Deep Water"), String(localized: "Spend 3 hours in Panic SOS sessions."),
             String(localized: "Three hours of practice. Calm runs deep in you now."), "drop.fill")
        ])
        b += ladder(.longestStreak, [
            (3, String(localized: "Ripple"), String(localized: "Reach a 3-day streak."),
             String(localized: "Three days in a row. The ripple starts here."), "flame.fill"),
            (7, String(localized: "Full Week"), String(localized: "Reach a 7-day streak."),
             String(localized: "Seven days of showing up for yourself."), "7.circle.fill"),
            (14, String(localized: "Fortnight Anchor"), String(localized: "Reach a 14-day streak."),
             String(localized: "Two weeks. Your nervous system is learning."), "14.circle.fill"),
            (30, String(localized: "Moon Cycle"), String(localized: "Reach a 30-day streak."),
             String(localized: "A whole moon cycle of calm practice."), "moon.fill"),
            (60, String(localized: "Steady Current"), String(localized: "Reach a 60-day streak."),
             String(localized: "Sixty days. This is who you are now."), "wind"),
            (100, String(localized: "Hundred Tides"), String(localized: "Reach a 100-day streak."),
             String(localized: "A hundred tides in and out. Remarkable."), "trophy.fill"),
            (365, String(localized: "Year of Calm"), String(localized: "Reach a 365-day streak."),
             String(localized: "A full year. Take a bow."), "sun.max.fill")
        ])
        b += ladder(.moods, [
            (1, String(localized: "First Check-In"), String(localized: "Log your mood for the first time."),
             String(localized: "Naming a feeling is the first step to taming it."), "face.smiling"),
            (10, String(localized: "Self-Aware"), String(localized: "Log 10 mood check-ins."),
             String(localized: "Ten check-ins. You're learning your own weather."), "eye.fill"),
            (30, String(localized: "Mood Mapper"), String(localized: "Log 30 mood check-ins."),
             String(localized: "Thirty data points. Patterns are starting to show."), "map.fill"),
            (100, String(localized: "Inner Weather"), String(localized: "Log 100 mood check-ins."),
             String(localized: "A hundred check-ins. You read your skies like a pro."), "cloud.sun.fill"),
            (365, String(localized: "Year in Feelings"), String(localized: "Log 365 mood check-ins."),
             String(localized: "A year of feelings, honestly noticed."), "calendar")
        ])
        b += ladder(.twiceADay, [
            (1, String(localized: "Bookends"), String(localized: "Check in both morning and evening on the same day."),
             String(localized: "Morning and evening. You bookended your day."), "sun.horizon.fill"),
            (7, String(localized: "Sunrise to Sunset"), String(localized: "Check in morning and evening on 7 days."),
             String(localized: "Seven full days, start to finish."), "sunset.fill")
        ])
        b += ladder(.journals, premium: true, [
            (1, String(localized: "First Page"), String(localized: "Write your first journal entry."),
             String(localized: "The first page is always the hardest."), "book.fill"),
            (10, String(localized: "Storyteller"), String(localized: "Write 10 journal entries."),
             String(localized: "Ten entries. Your story is taking shape."), "text.book.closed.fill"),
            (30, String(localized: "Chronicler"), String(localized: "Write 30 journal entries."),
             String(localized: "Thirty entries of honest reflection."), "books.vertical.fill"),
            (100, String(localized: "Author of Calm"), String(localized: "Write 100 journal entries."),
             String(localized: "A hundred entries. That's a whole book about you."), "pencil.line")
        ])
        b += ladder(.gratitudes, premium: true, [
            (3, String(localized: "Thank You"), String(localized: "Write 3 gratitudes."),
             String(localized: "Three good things, noticed on purpose."), "heart.fill"),
            (30, String(localized: "Grateful Heart"), String(localized: "Write 30 gratitudes."),
             String(localized: "Thirty reasons to be glad. You found every one."), "heart.circle.fill"),
            (100, String(localized: "Abundance"), String(localized: "Write 100 gratitudes."),
             String(localized: "A hundred gratitudes. Your cup runneth over."), "gift.fill"),
            (300, String(localized: "Overflowing"), String(localized: "Write 300 gratitudes."),
             String(localized: "Three hundred. Gratitude is a habit now."), "sparkles")
        ])
        b += ladder(.planDays, premium: true, [
            (1, String(localized: "Day One Done"), String(localized: "Complete every task on one day of your plan."),
             String(localized: "Day one of your plan, fully done."), "leaf.fill"),
            (7, String(localized: "First Week Bloom"), String(localized: "Complete 7 days of your plan."),
             String(localized: "A week of your plan, complete. Something's growing."), "camera.macro"),
            (15, String(localized: "Halfway Harbor"), String(localized: "Complete 15 days of your plan."),
             String(localized: "Halfway there. Look how far you've come."), "flag.fill"),
            (30, String(localized: "Plan Complete"), String(localized: "Complete all 30 days of your plan."),
             String(localized: "Thirty days, start to finish. You did the whole thing."), "checkmark.seal.fill")
        ])
        b += ladder(.level, [
            (5, String(localized: "Rising Tide"), String(localized: "Reach level 5."),
             String(localized: "Level 5. The tide is rising in your favor."), "arrow.up.circle.fill"),
            (10, String(localized: "Double Digits"), String(localized: "Reach level 10."),
             String(localized: "Level 10. Double digits of calm."), "10.circle.fill"),
            (15, String(localized: "Rose Gold"), String(localized: "Reach level 15."),
             String(localized: "Rose Gold. Rare air up here."), "rosette"),
            (20, String(localized: "Zen Anchor"), String(localized: "Reach level 20."),
             String(localized: "The top rank. Truly anchored."), "crown.fill")
        ])
        b += ladder(.triggers, [
            (3, String(localized: "Pattern Spotter"), String(localized: "Log 3 different triggers."),
             String(localized: "Knowing your triggers takes away their surprise."), "magnifyingglass")
        ])
        b += ladder(.shares, [
            (1, String(localized: "Anchor Friend"), String(localized: "Share a CalmAnchor card."),
             String(localized: "Sharing calm makes more of it."), "square.and.arrow.up.fill"),
            (5, String(localized: "Calm Ambassador"), String(localized: "Share 5 CalmAnchor cards."),
             String(localized: "Five shares. Someone out there needed that."), "person.2.fill")
        ])
        b.append(secret(.nightWatch, String(localized: "Night Watch"),
                        String(localized: "Finish a Panic SOS session between midnight and 5 a.m."),
                        String(localized: "You got through the small hours. Be gentle with yourself today."),
                        "moon.stars.fill"))
        b.append(secret(.earlyLight, String(localized: "Early Light"),
                        String(localized: "Check in before 7 a.m."),
                        String(localized: "Up with the sun and already checking in."), "sun.haze.fill"))
        b.append(secret(.comeback, String(localized: "Welcome Back"),
                        String(localized: "Come back after a week away."),
                        String(localized: "Welcome back. Returning is the bravest part."),
                        "arrow.uturn.backward.circle.fill"))
        b.append(secret(.graceSaved, String(localized: "Saved by Grace"),
                        String(localized: "Let a grace day save your streak."),
                        String(localized: "One missed day didn't undo your progress. Grace works."),
                        "shield.fill"))
        return b
    }()

    static func badge(id: String) -> CalmBadge? { all.first { $0.id == id } }

    /// Which unlock to feature when several land at once.
    static let prestige: [CalmMetric] = [
        .stormTamed, .sessions, .longestStreak, .planDays, .bigDrops, .level, .nightWatch,
        .comeback, .graceSaved, .journals, .calmMinutes, .moods, .gratitudes, .twiceADay,
        .earlyLight, .triggers, .shares
    ]

    static func mostPrestigious(_ badges: [CalmBadge]) -> CalmBadge? {
        badges.min { a, b in
            let ia = prestige.firstIndex(of: a.metric) ?? 99, ib = prestige.firstIndex(of: b.metric) ?? 99
            return ia != ib ? ia < ib : a.target > b.target
        }
    }
}
