import SwiftUI

/// Small transient banner for XP gains and level-ups. Slides in at the top.
struct CelebrationToast: View {
    let event: CelebrationCenter.Event

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppConstants.Colors.sunsetGold)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(AppConstants.Colors.sunsetGold.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch event {
        case .xpGained:        return "sparkles"
        case .levelUp:         return "star.circle.fill"
        case .streakMilestone: return "flame.fill"
        }
    }
    private var title: String {
        switch event {
        case .xpGained(let n):        return "+\(n) XP"
        case .levelUp(let l, _):      return String(localized: "Level \(l) reached!")
        case .streakMilestone(let d): return String(localized: "\(d)-day streak!")
        }
    }
    private var subtitle: String? {
        switch event {
        case .levelUp(_, let name): return name
        default: return nil
        }
    }
}

/// Full-screen moment for streak milestones. The emotional peak — and the
/// natural launchpad for the share card.
struct StreakMilestoneView: View {
    let days: Int
    let calmName: String
    let onShare: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "0A1428"), Color(hex: "1B2838"), Color(hex: "0D3B4F")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.orange.opacity(0.18 - Double(i) * 0.05), lineWidth: 2)
                            .frame(width: 150 + CGFloat(i) * 46)
                            .scaleEffect(appeared ? 1 : 0.7)
                            .opacity(appeared ? 1 : 0)
                    }
                    Image(systemName: "flame.fill")
                        .font(.system(size: 76, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.orange, AppConstants.Colors.sunsetGold],
                                                        startPoint: .top, endPoint: .bottom))
                        .shadow(color: .orange.opacity(0.55), radius: 22)
                        .scaleEffect(appeared ? 1 : 0.4)
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(String(localized: "\(days) days strong"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
                .opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onShare) {
                        Label("Share my streak", systemImage: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppConstants.Gradients.cta)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Button("Keep going", action: onDismiss)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.65)) {
                appeared = true
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
    }

    private var message: String {
        switch days {
        case 3:   return String(localized: "Three days in a row, \(calmName). This is how calm becomes a habit.")
        case 7:   return String(localized: "A full week, \(calmName). You showed up for yourself every single day.")
        case 14:  return String(localized: "Two weeks of anchoring. Your nervous system is learning.")
        case 30:  return String(localized: "Thirty days. This isn't luck anymore — it's who you are now.")
        case 60:  return String(localized: "Sixty days. Most people never get here. You did.")
        default:  return String(localized: "\(days) days of choosing calm. Extraordinary.")
        }
    }
}
