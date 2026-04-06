import SwiftUI
import SwiftData
import Charts

struct ProgressChartsView: View {
    @Query(sort: \MoodEntry.date) private var moods: [MoodEntry]
    @Query(sort: \JournalEntry.date) private var journals: [JournalEntry]
    @Query(sort: \PanicEvent.date) private var panicEvents: [PanicEvent]
    @State private var timeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"
    }

    private var filteredMoods: [MoodEntry] {
        let cutoff = cutoffDate
        return moods.filter { $0.date >= cutoff }
    }

    private var filteredJournals: [JournalEntry] {
        let cutoff = cutoffDate
        return journals.filter { $0.date >= cutoff }
    }

    private var cutoffDate: Date {
        switch timeRange {
        case .week: return Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        case .month: return Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        case .all: return .distantPast
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range picker
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Mood trend chart
                    moodTrendChart

                    // Anxiety trend chart
                    anxietyTrendChart

                    // Journal mood impact
                    journalImpactChart

                    // Panic events summary
                    panicSummary

                    // Insights
                    insightsSection

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
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
        .background(.white)
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
        .background(.white)
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
        .background(.white)
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

            if panicEvents.isEmpty {
                Text("No panic events recorded. You're doing great!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                let avgBefore = Double(panicEvents.map(\.intensityBefore).reduce(0, +)) / Double(panicEvents.count)
                let avgAfter = Double(panicEvents.map(\.intensityAfter).reduce(0, +)) / Double(panicEvents.count)
                let avgDuration = panicEvents.map(\.duration).reduce(0, +) / Double(panicEvents.count)

                HStack(spacing: 16) {
                    PanicStat(label: "Events", value: "\(panicEvents.count)", icon: "number")
                    PanicStat(label: "Avg Before", value: String(format: "%.1f", avgBefore), icon: "arrow.up")
                    PanicStat(label: "Avg After", value: String(format: "%.1f", avgAfter), icon: "arrow.down")
                    PanicStat(label: "Avg Time", value: "\(Int(avgDuration / 60))m", icon: "clock")
                }
            }
        }
        .padding(16)
        .background(.white)
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
                    let avgMood = Double(moods.map(\.moodLevel).reduce(0, +)) / Double(moods.count)
                    InsightRow(text: "Your average mood is \(String(format: "%.1f", avgMood))/10")
                }

                if !journals.isEmpty {
                    let improved = journals.filter { $0.moodAfter > $0.moodBefore }.count
                    let pct = Int(Double(improved) / Double(journals.count) * 100)
                    InsightRow(text: "Journaling improved your mood \(pct)% of the time")
                }

                if moods.count >= 2 {
                    let recent = moods.suffix(7)
                    let older = moods.prefix(max(1, moods.count - 7))
                    let recentAvg = Double(recent.map(\.anxietyLevel).reduce(0, +)) / Double(recent.count)
                    let olderAvg = Double(older.map(\.anxietyLevel).reduce(0, +)) / Double(older.count)
                    if recentAvg < olderAvg {
                        InsightRow(text: "Your anxiety is trending downward - keep going!")
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
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
    let label: String
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
