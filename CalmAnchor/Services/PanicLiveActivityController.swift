import Foundation
@preconcurrency import ActivityKit

/// App-side manager for the Panic breathing Live Activity. Every method no-ops
/// safely when Live Activities are unavailable or disabled, so the in-app
/// breathing experience is unchanged when there's no activity.
@MainActor
final class PanicLiveActivityController {
    private var activity: Activity<PanicBreathingAttributes>?

    func start(totalCycles: Int = 6) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = PanicBreathingAttributes(totalCycles: totalCycles, startedAt: .now)
        let initial = PanicBreathingAttributes.ContentState(phase: .grounding, cycle: 0, phaseEndsAt: .now)
        activity = try? Activity.request(
            attributes: attributes,
            content: .init(state: initial, staleDate: nil),
            pushType: nil
        )
    }

    func update(phase: PanicBreathingAttributes.ContentState.BreathPhase,
                cycle: Int, secondsInPhase: TimeInterval) async {
        guard let activity else { return }
        let state = PanicBreathingAttributes.ContentState(
            phase: phase, cycle: cycle,
            phaseEndsAt: Date().addingTimeInterval(secondsInPhase)
        )
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    func end() async {
        guard let activity else { return }
        let final = PanicBreathingAttributes.ContentState(phase: .complete, cycle: 6, phaseEndsAt: .now)
        await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .after(.now + 3))
        self.activity = nil
    }

    /// If the app was force-quit or crashed mid-session, a stale Live Activity
    /// can linger on the Lock Screen / Dynamic Island. Clear any on foreground.
    static func endOrphans() async {
        for stale in Activity<PanicBreathingAttributes>.activities {
            let final = PanicBreathingAttributes.ContentState(phase: .complete, cycle: 6, phaseEndsAt: .now)
            await stale.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
        }
    }
}
