import Foundation
import SwiftUI

/// Central place to surface "you did something great" moments. Services post
/// here (level-ups, streak milestones); the Dashboard renders whatever's queued.
/// Keeps XP/streak logic decoupled from presentation.
@MainActor
final class CelebrationCenter: ObservableObject {
    static let shared = CelebrationCenter()

    enum Event: Equatable, Identifiable {
        case xpGained(Int)
        case levelUp(level: Int, name: String)
        case streakMilestone(days: Int)

        var id: String {
            switch self {
            case .xpGained(let n):              return "xp-\(n)-\(UUID().uuidString)"
            case .levelUp(let l, _):            return "level-\(l)"
            case .streakMilestone(let d):       return "streak-\(d)"
            }
        }
    }

    /// Transient banner (XP gain / level up). Auto-clears.
    @Published var toast: Event?
    /// Full-screen moment (streak milestone). Dismissed by the user.
    @Published var celebration: Event?

    private var toastTask: Task<Void, Never>?

    func post(_ award: XPAward) {
        if award.didLevelUp {
            show(toast: .levelUp(level: award.newLevel, name: award.levelName))
        } else if award.xpGained > 0 {
            show(toast: .xpGained(award.xpGained))
        }
    }

    func postStreakMilestone(_ days: Int) {
        // Only celebrate real milestones, and only once per milestone per install.
        let milestones: Set<Int> = [3, 7, 14, 30, 60, 100]
        guard milestones.contains(days) else { return }
        let key = "celebrated.streak.\(days)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        celebration = .streakMilestone(days: days)
    }

    private func show(toast event: Event) {
        toastTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { toast = event }
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { self?.toast = nil }
        }
    }
}
