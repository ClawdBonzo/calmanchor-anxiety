import ActivityKit
import Foundation

/// Live Activity state for the Panic SOS breathing session.
/// Shared between the app target (start/update/end) and the widget extension
/// (Dynamic Island + lock-screen UI).
struct PanicBreathingAttributes: ActivityAttributes {
    let totalCycles: Int          // 6 box-breathing cycles
    let startedAt: Date

    public struct ContentState: Codable, Hashable {
        public enum BreathPhase: String, Codable, Hashable {
            case grounding, inhale, hold, exhale, affirmations, complete

            public var instruction: String {
                switch self {
                case .grounding:    return "Grounding"
                case .inhale:       return "Breathe In"
                case .hold:         return "Hold"
                case .exhale:       return "Breathe Out"
                case .affirmations: return "Affirmations"
                case .complete:     return "You did it"
                }
            }
        }

        public var phase: BreathPhase
        public var cycle: Int
        public var phaseEndsAt: Date   // drives a self-animating countdown in the UI

        public init(phase: BreathPhase, cycle: Int, phaseEndsAt: Date) {
            self.phase = phase
            self.cycle = cycle
            self.phaseEndsAt = phaseEndsAt
        }
    }
}
