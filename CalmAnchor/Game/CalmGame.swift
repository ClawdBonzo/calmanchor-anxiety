import Foundation
import SwiftData
import SwiftUI

/// One full-screen "you did something great" moment.
enum CalmCelebration: Identifiable, Equatable {
    case badge(CalmBadge, alsoEarned: Int)
    case rankUp(level: Int)
    case streak(days: Int)

    var id: String {
        switch self {
        case .badge(let b, _):  return "badge-\(b.id)"
        case .rankUp(let l):    return "rank-\(l)"
        case .streak(let d):    return "streak-\(d)"
        }
    }
}

/// Badges, rank-ups and streak milestones in one queue, shown one at a time,
/// never during a Panic SOS session. Unlocks are recorded forever (never
/// revoked), and the review prompt is asked only after the queue clears on a
/// genuinely good moment.
@MainActor
final class CalmGame: ObservableObject {
    static let shared = CalmGame()

    static let sharesKey = "game.shares.v1"
    private let unlockedKey = "game.unlocked.v1"
    private let absorbedKey = "game.absorbed.v1"
    private let seenCountKey = "game.seenBadgeCount.v1"

    @Published private(set) var unlocked: [String: Date] = [:]
    @Published private(set) var facts = CalmFacts()
    @Published private(set) var current: CalmCelebration?
    /// Set when the last celebration in a batch that included a badge or a
    /// streak milestone is dismissed; the root view turns it into requestReview.
    @Published var wantsReview = false

    private var queue: [CalmCelebration] = []
    private var batchWasHappy = false
    private let defaults = UserDefaults.standard

    init() {
        if let raw = defaults.dictionary(forKey: unlockedKey) as? [String: Date] { unlocked = raw }
    }

    var unlockedCount: Int { unlocked.count }
    var totalCount: Int { CalmBadgeCatalog.all.count }
    var hasUnseenBadges: Bool { unlocked.count > defaults.integer(forKey: seenCountKey) }
    func markBadgesSeen() { defaults.set(unlocked.count, forKey: seenCountKey); objectWillChange.send() }

    func isUnlocked(_ b: CalmBadge) -> Bool { unlocked[b.id] != nil }

    /// The locked, non-secret badge closest to done — the "next up" hook.
    var nextBadge: CalmBadge? {
        CalmBadgeCatalog.all
            .filter { !$0.isSecret && !isUnlocked($0) }
            .max { $0.progress(facts) < $1.progress(facts) }
    }

    // MARK: Evaluate

    /// Recompute facts and queue anything newly earned. Safe to call often.
    func evaluate(in context: ModelContext) {
        facts = CalmFacts.compute(in: context)
        let earned = CalmBadgeCatalog.all.filter { $0.isEarned(facts) && unlocked[$0.id] == nil }

        // First run after updating: existing progress is absorbed quietly so a
        // long-time user isn't hit with a dozen celebrations at once.
        if !defaults.bool(forKey: absorbedKey) {
            defaults.set(true, forKey: absorbedKey)
            record(earned)
            return
        }
        guard !earned.isEmpty else { return }
        record(earned)

        // XP for each badge (rare ones pay more). Rank-ups enqueue themselves.
        for b in earned {
            XPService.award(b.isSecret ? 50 : 25, source: "badge:\(b.id)", in: context)
        }
        if let top = CalmBadgeCatalog.mostPrestigious(earned) {
            enqueue(.badge(top, alsoEarned: earned.count - 1))
        }
        // Level badges depend on the level we may have just reached.
        facts = CalmFacts.compute(in: context)
        let levelBadges = CalmBadgeCatalog.all.filter {
            $0.metric == .level && $0.isEarned(facts) && unlocked[$0.id] == nil
        }
        record(levelBadges)
    }

    private func record(_ badges: [CalmBadge]) {
        guard !badges.isEmpty else { return }
        let now = Date()
        for b in badges where unlocked[b.id] == nil { unlocked[b.id] = now }
        defaults.set(unlocked, forKey: unlockedKey)
    }

    // MARK: Queue

    func enqueue(_ c: CalmCelebration) {
        guard !Self.suppressed else { return }
        guard current?.id != c.id, !queue.contains(where: { $0.id == c.id }) else { return }
        // Streaks first, then badges, then rank-ups.
        queue.append(c)
        queue.sort { order($0) < order($1) }
        if current == nil { advance() }
    }

    func dismissCurrent() {
        if let c = current {
            switch c {
            case .badge, .streak: batchWasHappy = true
            case .rankUp: break
            }
        }
        advance()
        if current == nil {
            if batchWasHappy && unlocked.count >= 3 { wantsReview = true }
            batchWasHappy = false
        }
    }

    private func advance() {
        withAnimation(.easeOut(duration: 0.25)) {
            current = queue.isEmpty ? nil : queue.removeFirst()
        }
    }

    private func order(_ c: CalmCelebration) -> Int {
        switch c { case .streak: return 0; case .badge: return 1; case .rankUp: return 2 }
    }

    /// Record a completed share (drives the share badges).
    func recordShare(in context: ModelContext) {
        defaults.set(defaults.integer(forKey: Self.sharesKey) + 1, forKey: Self.sharesKey)
        evaluate(in: context)
    }

    /// Screenshot capture and UI tests stage celebrations explicitly.
    static var suppressed: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-CAScreenshotMode")
        #else
        return false
        #endif
    }

    #if DEBUG
    /// Showcase: present a specific celebration regardless of state.
    func debugShow(_ c: CalmCelebration) { current = c }
    func debugUnlock(_ ids: [String]) {
        let now = Date()
        for id in ids { unlocked[id] = now.addingTimeInterval(-Double.random(in: 0...1_000_000)) }
    }
    func debugRefreshFacts(in context: ModelContext) { facts = CalmFacts.compute(in: context) }
    /// Demo data: spread unlock dates over ~2 months, with 3 earned this week.
    func debugReseedUnlocks(in context: ModelContext) {
        facts = CalmFacts.compute(in: context)
        let earned = CalmBadgeCatalog.all.filter { $0.isEarned(facts) }
        let now = Date()
        unlocked = [:]
        for (i, b) in earned.enumerated() {
            let daysAgo = i < 3 ? Double(i + 1) : Double(9 + (i * 7) % 52)
            unlocked[b.id] = now.addingTimeInterval(-daysAgo * 86_400)
        }
        defaults.set(unlocked, forKey: unlockedKey)
        defaults.set(true, forKey: absorbedKey)
        defaults.set(unlocked.count, forKey: seenCountKey)
    }
    #endif
}
