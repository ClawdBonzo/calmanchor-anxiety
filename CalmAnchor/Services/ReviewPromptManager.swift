import Foundation
import StoreKit
import SwiftUI

/// Requests App Store reviews only after genuinely positive moments, with
/// frequency caps and spacing so we never nag. Apple ultimately decides
/// whether the sheet appears; these guards ensure we never *ask* at a bad time.
@MainActor
enum ReviewPromptManager {
    private static let lastAskedKey  = "review.lastAskedDate"
    private static let countKey      = "review.askCount"
    private static let firstAskKey   = "review.firstAskDate"
    private static let milestonesKey = "review.firedMilestones"

    private static let minDaysBetween = 20
    private static let maxPerYear     = 3
    private static let milestones     = [7, 30]

    /// Call after a Panic SOS session — only fires if anxiety actually dropped.
    static func requestAfterCalmSession(intensityBefore: Int,
                                        intensityAfter: Int,
                                        using request: RequestReviewAction) {
        guard intensityAfter < intensityBefore else { return }   // never after a bad moment
        guard canAsk() else { return }
        fire(using: request)
    }

    /// Call after a streak advance — fires once per milestone (7, 30…).
    static func requestForStreakMilestone(_ streak: Int,
                                          using request: RequestReviewAction) {
        guard milestones.contains(streak) else { return }
        var fired = Set(UserDefaults.standard.array(forKey: milestonesKey) as? [Int] ?? [])
        guard !fired.contains(streak) else { return }
        guard canAsk() else { return }
        fired.insert(streak)
        UserDefaults.standard.set(Array(fired), forKey: milestonesKey)
        fire(using: request)
    }

    // MARK: - Guards

    private static func canAsk() -> Bool {
        let d = UserDefaults.standard
        let now = Date()

        if let first = d.object(forKey: firstAskKey) as? Date {
            if now.timeIntervalSince(first) < 365 * 86_400 {
                if d.integer(forKey: countKey) >= maxPerYear { return false }
            } else {
                d.set(0, forKey: countKey)        // rolling year elapsed → reset window
                d.set(now, forKey: firstAskKey)
            }
        }
        if let last = d.object(forKey: lastAskedKey) as? Date,
           now.timeIntervalSince(last) < Double(minDaysBetween) * 86_400 {
            return false
        }
        return true
    }

    private static func fire(using request: RequestReviewAction) {
        let d = UserDefaults.standard
        let now = Date()
        if d.object(forKey: firstAskKey) == nil { d.set(now, forKey: firstAskKey) }
        d.set(now, forKey: lastAskedKey)
        d.set(d.integer(forKey: countKey) + 1, forKey: countKey)
        request()
    }
}
