import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var game = CalmGame.shared
    @Query private var statsArray: [GameStats]
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @State private var selected: CalmBadge?
    @State private var share: SharePayload?
    var showsClose = true

    private var sorted: [CalmBadge] {
        let all = CalmBadgeCatalog.all
        let done = all.filter { game.isUnlocked($0) }
            .sorted { (game.unlocked[$0.id] ?? .distantPast) > (game.unlocked[$1.id] ?? .distantPast) }
        let todo = all.filter { !game.isUnlocked($0) }
            .sorted { $0.progress(game.facts) > $1.progress(game.facts) }
        return done + todo
    }

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                DawnBackground(warmth: 0.45)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        AnchorPassCard(stats: statsArray.first,
                                       streak: profiles.first?.currentStreak ?? 0,
                                       badgesUnlocked: game.unlockedCount,
                                       badgesTotal: game.totalCount)
                            .onTapGesture { shareRank() }
                            .accessibilityHint(String(localized: "Double-tap to share your rank"))

                        if let next = game.nextBadge { NextBadgeCard(badge: next, facts: game.facts) }

                        HStack {
                            Text(String(localized: "Badges"))
                                .font(.calmDisplay(22))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(game.unlockedCount)/\(game.totalCount)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(CalmBrand.gold)
                                .monospacedDigit()
                        }

                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(sorted) { badge in
                                Button { selected = badge; Haptics.selection() } label: {
                                    BadgeTile(badge: badge,
                                              unlocked: game.isUnlocked(badge),
                                              progress: badge.progress(game.facts))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if game.unlockedCount >= 3 {
                            Link(destination: CalmLinks.writeReview) {
                                Text(String(localized: "Enjoying CalmAnchor? Leave a review on the App Store"))
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.55))
                                    .underline()
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(String(localized: "Achievements"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if showsClose {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .accessibilityLabel(String(localized: "Close"))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { shareRank() } label: { Image(systemName: "square.and.arrow.up") }
                        .accessibilityLabel(String(localized: "Share your rank"))
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            game.evaluate(in: modelContext)
            game.markBadgesSeen()
        }
        .sheet(item: $selected) { badge in
            BadgeDetailSheet(badge: badge, unlocked: game.isUnlocked(badge),
                             facts: game.facts, date: game.unlocked[badge.id])
                .presentationDetents([.medium])
                .presentationBackground(CalmBrand.deepSea)
        }
        .sheet(item: $share) { payload in
            ActivityShareSheet(items: [payload.image, payload.text]) { done in
                if done { game.recordShare(in: modelContext) }
            }
        }
    }

    private func shareRank() {
        let stats = statsArray.first
        guard let img = ShareCardRenderer.render(RankShareCard(
            stats: stats, streak: profiles.first?.currentStreak ?? 0,
            badgesUnlocked: game.unlockedCount, badgesTotal: game.totalCount)) else { return }
        let text = String(format: String(localized: "My calm rank: %@."), CalmRanks.title(for: stats?.currentLevel ?? 1))
        share = SharePayload(image: img, text: text + " " + CalmLinks.install(campaign: "share-text").absoluteString)
    }
}

// MARK: - Tile

struct BadgeTile: View {
    let badge: CalmBadge
    let unlocked: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            BadgeMedallion(badge: badge, unlocked: unlocked, progress: progress, size: 68)
            Text(unlocked || !badge.isSecret ? badge.title : "???")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(unlocked ? .white : .white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(height: 30, alignment: .top)
        }
        .opacity(unlocked ? 1 : 0.85)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Next badge

struct NextBadgeCard: View {
    let badge: CalmBadge
    let facts: CalmFacts
    var body: some View {
        HStack(spacing: 14) {
            BadgeMedallion(badge: badge, unlocked: false, progress: badge.progress(facts), size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Kicker(text: String(localized: "Next badge"), color: CalmBrand.teal)
                Text(badge.title).font(.calmDisplay(17)).foregroundStyle(.white)
                Text(badge.howToEarn)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            Text("\(min(facts[badge.metric], badge.target))/\(badge.target)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(CalmBrand.gold)
                .monospacedDigit()
        }
        .padding(16)
        .glassCard(glow: CalmBrand.teal, glowRadius: 8, cornerRadius: 20)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Detail

struct BadgeDetailSheet: View {
    let badge: CalmBadge
    let unlocked: Bool
    let facts: CalmFacts
    let date: Date?
    @Environment(\.modelContext) private var modelContext
    @State private var share: SharePayload?

    var body: some View {
        VStack(spacing: 16) {
            BadgeMedallion(badge: badge, unlocked: unlocked, progress: badge.progress(facts), size: 110)
                .padding(.top, 28)
            Text(unlocked || !badge.isSecret ? badge.title : String(localized: "Secret badge"))
                .font(.calmDisplay(24, weight: .black))
                .foregroundStyle(.white)
            Text(unlocked ? badge.unlockedLine
                 : (badge.isSecret ? String(localized: "It happens when it happens. Keep going.") : badge.howToEarn))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            if unlocked, let date {
                Text(String(format: String(localized: "Earned %@"), date.formatted(date: .abbreviated, time: .omitted)))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(CalmBrand.gold)
            } else if !badge.isSecret {
                VStack(spacing: 6) {
                    ProgressView(value: badge.progress(facts)).tint(CalmBrand.gold)
                    Text(String(format: String(localized: "%lld of %lld"), min(facts[badge.metric], badge.target), badge.target))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                    if badge.isPremium {
                        Label(String(localized: "Premium feature"), systemImage: "crown.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(CalmBrand.gold.opacity(0.8))
                    }
                }
                .padding(.horizontal, 48)
            }

            if unlocked {
                Button {
                    if let img = ShareCardRenderer.render(BadgeShareCard(badge: badge)) {
                        let text = String(format: String(localized: "I just unlocked %@ in CalmAnchor."), badge.title)
                        share = SharePayload(image: img, text: text + " " + CalmLinks.install(campaign: "share-text").absoluteString)
                    }
                } label: {
                    Label(String(localized: "Show it off"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(CalmPrimaryButtonStyle(colors: CalmBrand.accent))
                .padding(.horizontal, 32)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .environment(\.colorScheme, .dark)
        .sheet(item: $share) { payload in
            ActivityShareSheet(items: [payload.image, payload.text]) { done in
                if done { CalmGame.shared.recordShare(in: modelContext) }
            }
        }
    }
}
