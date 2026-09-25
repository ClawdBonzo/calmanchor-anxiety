import SwiftUI
import SwiftData

struct GameCelebrationView: View {
    let celebration: CalmCelebration
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var statsArray: [GameStats]
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @ObservedObject private var game = CalmGame.shared

    @State private var appeared = false
    @State private var landed = false
    @State private var confetti = 0
    @State private var share: SharePayload?

    var body: some View {
        ZStack {
            CalmBrand.abyss.ignoresSafeArea()
            DawnBackground(warmth: 0.95, stars: 80)

            VStack(spacing: 20) {
                Spacer(minLength: 20)
                Kicker(text: kicker, color: CalmBrand.gold)
                    .opacity(appeared ? 1 : 0)

                ZStack {
                    Sunburst(rays: 14, color: CalmBrand.gold)
                        .frame(width: 320, height: 320)
                        .opacity(appeared ? 1 : 0)
                    art
                        .scaleEffect(landed ? 1 : (reduceMotion ? 1 : 1.9))
                        .opacity(landed ? 1 : 0)
                }
                .frame(minHeight: 200, maxHeight: 280)
                .layoutPriority(-1)

                VStack(spacing: 10) {
                    Text(title)
                        .font(.calmDisplay(32, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)
                    // Never truncate the message; on short screens the art
                    // and spacers give way instead.
                    Text(line)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 28)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                HStack(spacing: 8) {
                    if let xp = xpLabel { chip(xp, icon: "sparkles") }
                    if case .badge(_, let more) = celebration, more > 0 {
                        chip(String(format: String(localized: "+%lld more badges"), more), icon: "rosette")
                    }
                }
                .opacity(landed ? 1 : 0)

                Spacer()

                VStack(spacing: 12) {
                    Button { shareTapped() } label: {
                        Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(CalmPrimaryButtonStyle(colors: CalmBrand.accent))
                    Button(String(localized: "Keep going"), action: onDismiss)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(minHeight: 44)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
            }

            ConfettiBurst(trigger: confetti).ignoresSafeArea()
        }
        .environment(\.colorScheme, .dark)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
        .onAppear(perform: play)
        .sheet(item: $share) { payload in
            ActivityShareSheet(items: [payload.image, payload.text]) { completed in
                if completed { game.recordShare(in: modelContext); Haptics.success() }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: Content

    @ViewBuilder private var art: some View {
        switch celebration {
        case .badge(let b, _):
            BadgeMedallion(badge: b, unlocked: true, size: 160)
        case .rankUp(let level):
            let tier = CalmTier.forLevel(level)
            VStack(spacing: 6) {
                Image("BrandIcon").resizable().scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                Text(String(format: String(localized: "LEVEL %lld"), level))
                    .font(.system(size: 13, weight: .heavy, design: .rounded)).tracking(2)
                Text(tier.name.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded)).tracking(2)
                    .opacity(0.7)
            }
            .foregroundStyle(tier.ink)
            .frame(width: 150, height: 200)
            .background(tier.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1.5))
            .shadow(color: (tier.colors.last ?? .black).opacity(0.6), radius: 24, y: 10)
            .rotationEffect(.degrees(-4))
        case .streak:
            Image(systemName: "flame.fill")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [CalmBrand.gold, CalmBrand.coral], startPoint: .top, endPoint: .bottom))
                .shadow(color: CalmBrand.coral.opacity(0.6), radius: 28)
        }
    }

    private var kicker: String {
        switch celebration {
        case .badge(let b, _): return b.isSecret ? String(localized: "Secret badge found") : String(localized: "Badge unlocked")
        case .rankUp:          return String(localized: "New rank")
        case .streak:          return String(localized: "Calm streak")
        }
    }

    private var title: String {
        switch celebration {
        case .badge(let b, _):      return b.title
        case .rankUp(let level):    return CalmRanks.title(for: level)
        case .streak(let days):     return String(format: String(localized: "%lld days strong"), days)
        }
    }

    private var line: String {
        switch celebration {
        case .badge(let b, _):   return b.unlockedLine
        case .rankUp(let level): return CalmRanks.line(for: level)
        case .streak(let days):
            let name = profiles.first?.calmName ?? String(localized: "Friend")
            switch days {
            case 3:  return String(format: String(localized: "Three days in a row, %@. This is how calm becomes a habit."), name)
            case 7:  return String(format: String(localized: "A full week, %@. You showed up for yourself every single day."), name)
            case 14: return String(localized: "Two weeks of anchoring. Your nervous system is learning.")
            case 30: return String(localized: "Thirty days. This isn't luck anymore — it's who you are now.")
            case 60: return String(localized: "Sixty days. Most people never get here. You did.")
            default: return String(format: String(localized: "%lld days of choosing calm. Extraordinary."), days)
            }
        }
    }

    private var xpLabel: String? {
        switch celebration {
        case .badge(let b, _): return String(format: String(localized: "+%lld XP"), b.isSecret ? 50 : 25)
        default:               return nil
        }
    }

    private func chip(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .heavy))
            Text(text).font(.system(size: 13, weight: .heavy, design: .rounded)).monospacedDigit()
        }
        .foregroundStyle(CalmBrand.midnight)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(CalmBrand.accentGradient, in: Capsule())
    }

    // MARK: Motion + share

    private func play() {
        Haptics.success()
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : CalmMotion.pop) { appeared = true }
        withAnimation((reduceMotion ? .easeIn(duration: 0.2) : CalmMotion.slam).delay(reduceMotion ? 0 : 0.3)) {
            landed = true
        }
        if !reduceMotion {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(430))
                Haptics.drop()
                confetti += 1
            }
        }
    }

    private func shareTapped() {
        let stats = statsArray.first
        let streak = profiles.first?.currentStreak ?? 0
        let image: UIImage?
        let text: String
        switch celebration {
        case .badge(let b, _):
            image = ShareCardRenderer.render(BadgeShareCard(badge: b))
            text = String(format: String(localized: "I just unlocked %@ in CalmAnchor."), b.title)
        case .rankUp:
            image = ShareCardRenderer.render(RankShareCard(stats: stats, streak: streak,
                                                          badgesUnlocked: game.unlockedCount,
                                                          badgesTotal: game.totalCount))
            text = String(format: String(localized: "My calm rank: %@."), CalmRanks.title(for: stats?.currentLevel ?? 1))
        case .streak(let days):
            image = ShareCardRenderer.render(StreakShareCard(days: days))
            text = String(format: String(localized: "%lld days of calm in CalmAnchor."), days)
        }
        guard let image else { return }
        share = SharePayload(image: image, text: text + " " + CalmLinks.install(campaign: "share-text").absoluteString)
    }
}
