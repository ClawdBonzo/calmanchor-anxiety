import SwiftUI
import SwiftData
import Charts

/// All chart aggregates, computed ONCE per data/range change (never in `body`).
struct ProgressStats: Equatable {
    var avgMood: Double = 0
    var journalImprovedPct: Int? = nil
    var anxietyTrendingDown = false
    var panicCount = 0
    var avgBefore: Double = 0
    var avgAfter: Double = 0
    var avgDurationMin = 0

    static func compute(moods: [MoodEntry], journals: [JournalEntry], panic: [PanicEvent]) -> ProgressStats {
        var s = ProgressStats()
        if !moods.isEmpty {
            s.avgMood = Double(moods.reduce(0) { $0 + $1.moodLevel }) / Double(moods.count)
        }
        if !journals.isEmpty {
            let improved = journals.reduce(0) { $0 + ($1.moodAfter > $1.moodBefore ? 1 : 0) }
            s.journalImprovedPct = Int(Double(improved) / Double(journals.count) * 100)
        }
        // Compare the most recent 7 against the ones BEFORE them (no overlap —
        // the old suffix/prefix logic compared a set against itself for small n).
        if moods.count >= 8 {
            let recent = moods.suffix(7)
            let older = moods.dropLast(7)
            let r = Double(recent.reduce(0) { $0 + $1.anxietyLevel }) / Double(recent.count)
            let o = Double(older.reduce(0) { $0 + $1.anxietyLevel }) / Double(older.count)
            s.anxietyTrendingDown = r < o
        }
        let resolved = panic.filter(\.resolved)   // abandoned sessions aren't outcomes
        s.panicCount = resolved.count
        if !resolved.isEmpty {
            let n = Double(resolved.count)
            s.avgBefore = Double(resolved.reduce(0) { $0 + $1.intensityBefore }) / n
            s.avgAfter  = Double(resolved.reduce(0) { $0 + $1.intensityAfter }) / n
            s.avgDurationMin = Int((resolved.reduce(0.0) { $0 + $1.duration } / n) / 60)
        }
        return s
    }
}

enum ProgressTimeRange: String, CaseIterable {
    case week = "7 Days"
    case month = "30 Days"
    case all = "All Time"

    var cutoff: Date {
        switch self {
        case .week:  return Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        case .month: return Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        case .all:   return .distantPast
        }
    }
}

/// Outer shell: gate + range picker. The queries live in the inner content view
/// so they're only installed for premium users (free users never fetch three
/// tables to render a paywall) and rebuilt per range via `.id(timeRange)`.
struct ProgressChartsView: View {
    @EnvironmentObject private var revenueCat: RevenueCatService
    @State private var timeRange: ProgressTimeRange = .week
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if !revenueCat.isPremium {
                    PremiumGateView(
                        feature: "Progress Analytics",
                        icon: "chart.line.uptrend.xyaxis",
                        description: "See mood trends, anxiety patterns, journaling impact, and personalized insights."
                    ) { showPaywall = true }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            Picker("Time Range", selection: $timeRange) {
                                ForEach(ProgressTimeRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            ProgressChartsContent(range: timeRange)
                                .id(timeRange)   // rebuild queries for the new window
                            Spacer().frame(height: 80)
                        }
                        .padding(.horizontal, 20)
                    }
                    .background(Color(hex: "080E1C"))
                }
            }
            .navigationTitle("Progress")
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    calmName: "",
                    onContinue: { showPaywall = false },
                    onRestore: { showPaywall = false }
                )
                .environmentObject(revenueCat)
            }
        }
    }
}

/// Inner content: SQL-scoped queries + aggregates computed once (never in body).
struct ProgressChartsContent: View {
    let range: ProgressTimeRange
    @Query private var moods: [MoodEntry]
    @Query private var journals: [JournalEntry]
    @Query(sort: \PanicEvent.date) private var panicEvents: [PanicEvent]
    @State private var stats = ProgressStats()

    init(range: ProgressTimeRange) {
        self.range = range
        let cutoff = range.cutoff
        _moods = Query(filter: #Predicate<MoodEntry> { $0.date >= cutoff }, sort: \.date)
        _journals = Query(filter: #Predicate<JournalEntry> { $0.date >= cutoff }, sort: \.date)
    }

    // Already SQL-scoped by the query; kept as the names the chart code uses.
    private var filteredMoods: [MoodEntry] { moods }
    private var filteredJournals: [JournalEntry] { journals }

    var body: some View {
        VStack(spacing: 24) {
            moodTrendChart
            anxietyTrendChart
            journalImpactChart
            panicSummary
            insightsSection
        }
        // Recompute aggregates only when the underlying data changes.
        .task(id: moods.count &+ journals.count &* 31 &+ panicEvents.count &* 997) {
            stats = ProgressStats.compute(moods: moods, journals: journals, panic: panicEvents)
        }
    }

    private var moodTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundStyle(AppConstants.Colors.calmBlue)
                Text("Mood Trend")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }

            if filteredMoods.isEmpty {
                chartPlaceholder("Log moods to see trends")
            } else {
                Chart(filteredMoods) { mood in
                    LineMark(
                        x: .value("Date", mood.date, unit: .day),
                        y: .value("Mood", mood.moodLevel)
                    )
                    .foregroundStyle(AppConstants.Colors.calmBlue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", mood.date, unit: .day),
                        y: .value("Mood", mood.moodLevel)
                    )
                    .foregroundStyle(AppConstants.Colors.calmBlue)
                }
                .chartYScale(domain: 1...10)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [1, 5, 10])
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var anxietyTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(AppConstants.Colors.gentleCoral)
                Text("Anxiety Levels")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }

            if filteredMoods.isEmpty {
                chartPlaceholder("Log moods to track anxiety")
            } else {
                Chart(filteredMoods) { mood in
                    AreaMark(
                        x: .value("Date", mood.date, unit: .day),
                        y: .value("Anxiety", mood.anxietyLevel)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppConstants.Colors.gentleCoral.opacity(0.3), AppConstants.Colors.gentleCoral.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", mood.date, unit: .day),
                        y: .value("Anxiety", mood.anxietyLevel)
                    )
                    .foregroundStyle(AppConstants.Colors.gentleCoral)
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 1...10)
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var journalImpactChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.heart.fill")
                    .foregroundStyle(AppConstants.Colors.mintGreen)
                Text("Journaling Impact")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }

            if filteredJournals.isEmpty {
                chartPlaceholder("Journal entries will show mood changes")
            } else {
                Chart(filteredJournals) { journal in
                    BarMark(
                        x: .value("Date", journal.date, unit: .day),
                        yStart: .value("Before", journal.moodBefore),
                        yEnd: .value("After", journal.moodAfter)
                    )
                    .foregroundStyle(journal.moodAfter >= journal.moodBefore ?
                        AppConstants.Colors.mintGreen : AppConstants.Colors.gentleCoral)
                }
                .chartYScale(domain: 1...10)
                .frame(height: 180)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(AppConstants.Colors.mintGreen).frame(width: 8, height: 8)
                        Text("Mood improved").font(.system(size: 12))
                    }
                    HStack(spacing: 4) {
                        Circle().fill(AppConstants.Colors.gentleCoral).frame(width: 8, height: 8)
                        Text("Mood declined").font(.system(size: 12))
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var panicSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(.red)
                Text("Panic Events")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }

            if stats.panicCount == 0 {
                Text("No panic events recorded. You're doing great!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 16) {
                    PanicStat(label: "Events", value: "\(stats.panicCount)", icon: "number")
                    PanicStat(label: "Avg Before", value: String(format: "%.1f", stats.avgBefore), icon: "arrow.up")
                    PanicStat(label: "Avg After", value: String(format: "%.1f", stats.avgAfter), icon: "arrow.down")
                    PanicStat(label: "Avg Time", value: "\(stats.avgDurationMin)m", icon: "clock")
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppConstants.Colors.sunsetGold)
                Text("Insights")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 8) {
                if !moods.isEmpty {
                    InsightRow(text: "Your average mood is \(String(format: "%.1f", stats.avgMood))/10")
                }
                if let pct = stats.journalImprovedPct {
                    InsightRow(text: "Journaling improved your mood \(pct)% of the time")
                }
                if stats.anxietyTrendingDown {
                    InsightRow(text: "Your anxiety is trending downward - keep going!")
                }
                if moods.isEmpty && stats.journalImprovedPct == nil {
                    InsightRow(text: "Log a few moods and your insights will appear here.")
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func chartPlaceholder(_ text: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 32))
                    .foregroundStyle(.tertiary)
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 32)
            Spacer()
        }
    }
}

struct PanicStat: View {
    let label: LocalizedStringKey
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InsightRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundStyle(AppConstants.Colors.sunsetGold)
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
