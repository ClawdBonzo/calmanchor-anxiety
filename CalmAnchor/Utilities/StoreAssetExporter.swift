#if DEBUG
import SwiftUI
import SwiftData

/// DEBUG-only: renders the floating "stickers" the App Store compositor lays
/// over each frame (medallions, share cards, the Anchor Pass, widget and
/// Dynamic Island mocks) from the real SwiftUI views, into
/// Documents/StoreAssets/. Writes done.txt last so the capture script knows
/// the set is complete. Launch with -CAShowcase export.
@MainActor
enum StoreAssetExporter {
    static func run(context: ModelContext) {
        let fm = FileManager.default
        let dir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("StoreAssets")
        try? fm.removeItem(at: dir)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let game = CalmGame.shared
        game.debugRefreshFacts(in: context)
        let stats = (try? context.fetch(FetchDescriptor<GameStats>()))?.first
        let profile = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first

        func save<V: View>(_ name: String, _ view: V, opaque: Bool = false) {
            let r = ImageRenderer(content: view
                .environment(\.colorScheme, .dark)
                .environment(\.dynamicTypeSize, .large))
            r.scale = 3
            r.isOpaque = opaque
            if let data = r.uiImage?.pngData() { try? data.write(to: dir.appendingPathComponent(name)) }
        }

        // Badge medallions (transparent).
        for id in ["stormTamed.1", "longestStreak.14", "bigDrops.5", "sessions.3", "moods.30", "nightWatch.1"] {
            if let b = CalmBadgeCatalog.badge(id: id) {
                save("badge-\(id).png", BadgeMedallion(badge: b, unlocked: true, size: 150).padding(30))
            }
        }

        // Share cards (opaque story posters).
        if let b = CalmBadgeCatalog.badge(id: "stormTamed.1") {
            save("card-badge.png", BadgeShareCard(badge: b), opaque: true)
        }
        save("card-rank.png", RankShareCard(stats: stats, streak: profile?.currentStreak ?? 12,
                                            badgesUnlocked: game.unlockedCount, badgesTotal: game.totalCount), opaque: true)
        save("card-streak.png", StreakShareCard(days: 21), opaque: true)
        save("card-recap.png", RecapShareCard(recap: WeeklyRecap.build(in: context)), opaque: true)

        // Anchor Pass on its own.
        save("pass.png", AnchorPassCard(stats: stats, streak: profile?.currentStreak ?? 12,
                                        badgesUnlocked: game.unlockedCount, badgesTotal: game.totalCount)
            .frame(width: 360).padding(24))

        // Lock Screen Panic SOS widget + Dynamic Island breathing pill.
        save("widget-lock.png", LockWidgetMock().padding(24))
        save("island.png", IslandMock().padding(24))

        try? "ok".write(to: dir.appendingPathComponent("done.txt"), atomically: true, encoding: .utf8)
    }
}

private struct LockWidgetMock: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("9:41")
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(.white.opacity(0.18))
                    VStack(spacing: 1) {
                        Image(systemName: "wind").font(.system(size: 22, weight: .bold))
                        Text("SOS").font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(.white)
                }
                .frame(width: 66, height: 66)
                // Mirrors SOSAccessoryView (.accessoryRectangular) in the widget.
                HStack(spacing: 8) {
                    Image(systemName: "wind").font(.system(size: 20, weight: .bold))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Panic SOS").font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("Breathe · 12-day streak").font(.system(size: 11, weight: .medium, design: .rounded))
                            .opacity(0.75)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 66)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(22)
        .background(
            LinearGradient(colors: [CalmBrand.harbor, CalmBrand.mauve], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

private struct IslandMock: View {
    var body: some View {
        HStack(spacing: 12) {
            // Mirrors the expanded Dynamic Island in PanicBreathingLiveActivity.
            Image(systemName: "wind").font(.system(size: 22, weight: .bold)).foregroundStyle(CalmBrand.teal)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(String(localized: "Hold")).font(.system(size: 17, weight: .heavy, design: .rounded))
                Text(String(localized: "Breath 3 of 6")).font(.system(size: 12, weight: .semibold, design: .rounded)).opacity(0.7)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 16)
            Text("0:03").font(.system(size: 24, weight: .bold, design: .rounded)).monospacedDigit()
                .foregroundStyle(CalmBrand.teal)
        }
        .padding(.horizontal, 18)
        .frame(width: 330, height: 76)
        .background(.black, in: Capsule())
    }
}
#endif
