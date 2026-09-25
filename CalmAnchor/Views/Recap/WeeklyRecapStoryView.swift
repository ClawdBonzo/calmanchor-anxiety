import SwiftUI
import SwiftData

// MARK: - Data

/// A plain snapshot of the last 7 days, taken when the story opens.
struct WeeklyRecap {
    var sessions = 0
    var calmMinutes = 0
    var avgBefore = 0.0
    var avgAfter = 0.0
    var checkIns = 0
    var dailyMood: [Double?] = Array(repeating: nil, count: 7)   // oldest → today
    var dayLabels: [String] = []
    var streak = 0
    var newBadges: [CalmBadge] = []
    var journals = 0

    var drop: Double { max(0, avgBefore - avgAfter) }

    @MainActor
    static func build(in context: ModelContext) -> WeeklyRecap {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -6, to: today) else { return WeeklyRecap() }
        let panics = ((try? context.fetch(FetchDescriptor<PanicEvent>(
            predicate: #Predicate { $0.date >= start }))) ?? []).filter(\.resolved)
        let moods = (try? context.fetch(FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.date >= start }))) ?? []
        let journals = (try? context.fetchCount(FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.date >= start }))) ?? 0

        var r = WeeklyRecap()
        r.sessions = panics.count
        r.calmMinutes = Int(panics.reduce(0) { $0 + $1.duration } / 60)
        if !panics.isEmpty {
            r.avgBefore = Double(panics.map(\.intensityBefore).reduce(0, +)) / Double(panics.count)
            r.avgAfter = Double(panics.map(\.intensityAfter).reduce(0, +)) / Double(panics.count)
        }
        r.checkIns = moods.count
        let fmt = DateFormatter(); fmt.setLocalizedDateFormatFromTemplate("EEEEE")
        for i in 0..<7 {
            guard let d = cal.date(byAdding: .day, value: i, to: start) else { continue }
            r.dayLabels.append(fmt.string(from: d))
            let day = moods.filter { cal.isDate($0.date, inSameDayAs: d) }
            if !day.isEmpty { r.dailyMood[i] = Double(day.map(\.moodLevel).reduce(0, +)) / Double(day.count) }
        }
        r.streak = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first?.currentStreak ?? 0
        r.newBadges = CalmBadgeCatalog.all.filter { (CalmGame.shared.unlocked[$0.id] ?? .distantPast) >= start }
        r.journals = journals
        return r
    }

    /// Worth a story once there's something real to replay.
    @MainActor
    static func isAvailable(in context: ModelContext) -> Bool {
        let r = build(in: context)
        return r.sessions + r.checkIns + r.journals >= 3
    }
}

// MARK: - Story

struct WeeklyRecapStoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var recap = WeeklyRecap()
    @State private var page = 0
    @State private var progress = 0.0
    @State private var paused = false
    @State private var share: SharePayload?

    private enum Page { case intro, sessions, drop, mood, badges, summary }
    private var pages: [Page] {
        var p: [Page] = [.intro]
        if recap.sessions > 0 { p += [.sessions, .drop] }
        if recap.checkIns > 0 { p.append(.mood) }
        if !recap.newBadges.isEmpty { p.append(.badges) }
        p.append(.summary)
        return p
    }
    private let pageDuration = 5.5

    var body: some View {
        ZStack {
            background(for: pages[min(page, pages.count - 1)])
                .animation(.easeInOut(duration: 0.6), value: page)
                .ignoresSafeArea()
            StarField(count: 60, seed: UInt64(page + 3)).opacity(0.6).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content(for: pages[min(page, pages.count - 1)])
                    .id(page)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .scale(scale: 0.92).combined(with: .opacity)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 24)

            // Tap zones: left third back, rest forward.
            HStack(spacing: 0) {
                Color.clear.contentShape(Rectangle()).frame(maxWidth: .infinity)
                    .onTapGesture { go(-1) }
                Color.clear.contentShape(Rectangle()).frame(maxWidth: .infinity)
                    .onTapGesture { go(1) }
                Color.clear.contentShape(Rectangle()).frame(maxWidth: .infinity)
                    .onTapGesture { go(1) }
            }
            .padding(.top, 90)
            .padding(.bottom, pages[min(page, pages.count - 1)] == .summary ? 180 : 0)
            .accessibilityHidden(true)
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            recap = WeeklyRecap.build(in: modelContext)
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-CARecapPage"), i + 1 < args.count, let n = Int(args[i + 1]) {
                page = min(n, pages.count - 1); progress = 0.45
            }
            #endif
        }
        .task(id: page) { await tick() }
        .sheet(item: $share) { p in
            ActivityShareSheet(items: [p.image, p.text]) { done in
                if done { CalmGame.shared.recordShare(in: modelContext) }
            }
        }
        .accessibilityAction(named: String(localized: "Next")) { go(1) }
        .accessibilityAction(named: String(localized: "Previous")) { go(-1) }
    }

    // MARK: Chrome

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(pages.indices, id: \.self) { i in
                    GeometryReader { g in
                        Capsule().fill(.white.opacity(0.25))
                            .overlay(alignment: .leading) {
                                Capsule().fill(.white)
                                    .frame(width: g.size.width * (i < page ? 1 : (i == page ? progress : 0)))
                            }
                    }
                    .frame(height: 3)
                }
            }
            HStack {
                Label(String(localized: "Your week in calm"), systemImage: "sparkles")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white).frame(width: 44, height: 44)
                }
                .accessibilityLabel(String(localized: "Close"))
            }
        }
        .padding(.top, 8)
    }

    private func background(for p: Page) -> LinearGradient {
        let c: [Color]
        switch p {
        case .intro, .summary: c = CalmBrand.dawn
        case .sessions:        c = [CalmBrand.midnight, Color(hex: "0B3D5C"), CalmBrand.teal.opacity(0.8)]
        case .drop:            c = [CalmBrand.abyss, CalmBrand.harbor, CalmBrand.sky.opacity(0.7)]
        case .mood:            c = [CalmBrand.midnight, Color(hex: "3A2F5C"), CalmBrand.lilac.opacity(0.8)]
        case .badges:          c = [CalmBrand.abyss, Color(hex: "4A2F3F"), CalmBrand.roseGold]
        }
        return LinearGradient(colors: c, startPoint: .top, endPoint: .bottom)
    }

    // MARK: Pages

    @ViewBuilder private func content(for p: Page) -> some View {
        switch p {
        case .intro:
            VStack(spacing: 18) {
                Spacer()
                Image("BrandIcon").resizable().scaledToFit().frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: CalmBrand.gold.opacity(0.5), radius: 24)
                Text(String(localized: "Your week\nin calm"))
                    .font(.calmDisplay(46, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LinearGradient(colors: [.white, CalmBrand.gold], startPoint: .top, endPoint: .bottom))
                Text(String(localized: "Seven days. Let's look at what you did."))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer(); Spacer()
            }
        case .sessions:
            bigStat(value: recap.sessions,
                    title: recap.sessions == 1 ? String(localized: "calm session") : String(localized: "calm sessions"),
                    line: String(format: String(localized: "%lld minutes of breathing through it."), recap.calmMinutes),
                    icon: "lifepreserver.fill")
        case .drop:
            VStack(spacing: 20) {
                Spacer()
                Kicker(text: String(localized: "Average intensity"), color: .white.opacity(0.8))
                HStack(alignment: .firstTextBaseline, spacing: 18) {
                    VStack { Text(String(format: "%.1f", recap.avgBefore)).font(.calmNumber(64)); Text(String(localized: "before")).font(.system(size: 14, weight: .bold, design: .rounded)).opacity(0.7) }
                    Image(systemName: "arrow.right").font(.system(size: 30, weight: .heavy)).foregroundStyle(CalmBrand.gold)
                    VStack { Text(String(format: "%.1f", recap.avgAfter)).font(.calmNumber(64)).foregroundStyle(CalmBrand.mint); Text(String(localized: "after")).font(.system(size: 14, weight: .bold, design: .rounded)).opacity(0.7) }
                }
                .foregroundStyle(.white)
                Text(dropLine)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                Spacer(); Spacer()
            }
        case .mood:
            VStack(spacing: 22) {
                Spacer()
                Kicker(text: String(localized: "Your mood this week"), color: .white.opacity(0.8))
                MoodBars(values: recap.dailyMood, labels: recap.dayLabels, animate: !reduceMotion)
                    .frame(height: 200)
                Text(String(format: String(localized: "%lld check-ins. You kept noticing."), recap.checkIns))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer(); Spacer()
            }
        case .badges:
            VStack(spacing: 22) {
                Spacer()
                Kicker(text: String(localized: "New this week"), color: CalmBrand.gold)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 16)], spacing: 18) {
                    ForEach(recap.newBadges.prefix(6)) { b in
                        VStack(spacing: 8) {
                            BadgeMedallion(badge: b, unlocked: true, size: 72)
                            Text(b.title).font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white).multilineTextAlignment(.center)
                        }
                    }
                }
                Text(recap.newBadges.count == 1 ? String(localized: "One new badge. Well earned.")
                     : String(format: String(localized: "%lld new badges. Well earned."), recap.newBadges.count))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer(); Spacer()
            }
        case .summary:
            VStack(spacing: 18) {
                Spacer()
                Text(String(localized: "That was your week."))
                    .font(.calmDisplay(34, weight: .black)).foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    PosterStat(value: "\(recap.sessions)", label: String(localized: "sessions"))
                    PosterStat(value: "\(recap.checkIns)", label: String(localized: "check-ins"))
                    PosterStat(value: "\(recap.streak)", label: String(localized: "day streak"))
                    PosterStat(value: "\(recap.newBadges.count)", label: String(localized: "new badges"))
                }
                Spacer()
                Button { shareSummary() } label: {
                    Label(String(localized: "Share my week"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(CalmPrimaryButtonStyle(colors: CalmBrand.accent))
                Button(String(localized: "Play again")) { withAnimation { page = 0; progress = 0 } }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(minHeight: 44)
                    .padding(.bottom, 20)
            }
        }
    }

    private var dropLine: String {
        let d = recap.drop
        if d >= 3 { return String(localized: "Big drops. Your tools are working.") }
        if d >= 1 { return String(localized: "Every session brought it down.") }
        return String(localized: "You stayed with it. That counts.")
    }

    private func bigStat(value: Int, title: String, line: String, icon: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: icon).font(.system(size: 44, weight: .bold)).foregroundStyle(CalmBrand.gold)
            CountUpText(value: value, font: .calmNumber(120)).foregroundStyle(.white)
            Text(title).font(.calmDisplay(26)).foregroundStyle(.white)
            Text(line).font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center)
            Spacer(); Spacer()
        }
    }

    // MARK: Playback

    private func go(_ delta: Int) {
        let next = page + delta
        guard next >= 0 else { progress = 0; return }
        guard next < pages.count else { return }
        Haptics.selection()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) { page = next; progress = 0 }
    }

    private func tick() async {
        if CalmGame.suppressed { return }   // screenshot capture holds the page still
        progress = 0
        while !Task.isCancelled && progress < 1 {
            try? await Task.sleep(for: .milliseconds(50))
            guard scenePhase == .active, share == nil else { continue }
            progress = min(1, progress + 0.05 / pageDuration)
        }
        if progress >= 1, page < pages.count - 1 { go(1) }
    }

    private func shareSummary() {
        guard let img = ShareCardRenderer.render(RecapShareCard(recap: recap)) else { return }
        let text = String(format: String(localized: "My week in calm: %lld sessions, %lld check-ins."), recap.sessions, recap.checkIns)
        share = SharePayload(image: img, text: text + " " + CalmLinks.install(campaign: "share-recap").absoluteString)
    }
}

// MARK: - Pieces

struct MoodBars: View {
    let values: [Double?]
    let labels: [String]
    var animate = true
    @State private var grown = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(values.indices, id: \.self) { i in
                VStack(spacing: 6) {
                    GeometryReader { g in
                        VStack {
                            Spacer(minLength: 0)
                            Capsule()
                                .fill(values[i] == nil ? AnyShapeStyle(Color.white.opacity(0.15))
                                                       : AnyShapeStyle(CalmBrand.accentGradient))
                                .frame(height: max(8, g.size.height * (grown ? CGFloat((values[i] ?? 1) / 10) : 0.05)))
                        }
                    }
                    Text(i < labels.count ? labels[i] : "")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .onAppear {
            if animate { withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) { grown = true } }
            else { grown = true }
        }
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Mood by day"))
    }
}

struct RecapShareCard: View {
    let recap: WeeklyRecap
    var body: some View {
        SharePoster(campaign: "share-recap") {
            VStack(spacing: 18) {
                Spacer()
                Kicker(text: String(localized: "My week in calm"))
                MoodBars(values: recap.dailyMood, labels: recap.dayLabels, animate: false)
                    .frame(height: 150)
                    .padding(.horizontal, 8)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    PosterStat(value: "\(recap.sessions)", label: String(localized: "sessions"))
                    PosterStat(value: "\(recap.checkIns)", label: String(localized: "check-ins"))
                    PosterStat(value: "\(recap.streak)", label: String(localized: "day streak"))
                    PosterStat(value: "\(recap.newBadges.count)", label: String(localized: "new badges"))
                }
                Spacer()
                Text(String(localized: "One breath at a time."))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(CalmBrand.gold)
                    .padding(.bottom, 14)
            }
        }
    }
}
