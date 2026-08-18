import SwiftUI
import SwiftData

struct StreakCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var revenueCat: RevenueCatService
    @Query private var profiles: [UserProfile]
    @Query(sort: \JournalEntry.date) private var journals: [JournalEntry]
    @Query(sort: \MoodEntry.date) private var moods: [MoodEntry]
    @Query(sort: \PanicEvent.date) private var panicEvents: [PanicEvent]
    @State private var selectedMonth = Date()
    @State private var showPaywall = false
    @State private var todaysTasks: [HealingTask] = []

    private var profile: UserProfile? { profiles.first }
    private var activeDates: Set<DateComponents> {
        StreakService.activeDates(journals: journals, moods: moods, panicEvents: panicEvents)
    }

    var body: some View {
        NavigationStack {
            // Streaks + calendar are free: the streak is the retention hook, and a
            // user who can't see it has no reason to keep it. Only the healing
            // plan (the paid content) is gated below.
            ScrollView {
                VStack(spacing: 24) {
                    streakSummary
                    calendarView
                    if revenueCat.isPremium {
                        todayPlanSection
                    } else {
                        PremiumGateView(
                            feature: "Personalized Healing Plan",
                            icon: "leaf.fill",
                            description: "Unlock your 30-day plan tailored to your triggers."
                        ) { showPaywall = true }
                    }
                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(hex: "080E1C"))
            .onAppear { todaysTasks = HealingPlanService.todaysTasks(from: modelContext) }
            .navigationTitle("Healing Streaks")
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

    private var streakSummary: some View {
        HStack(spacing: 16) {
            StreakBadge(value: profile?.currentStreak ?? 0, label: "Current", icon: "flame.fill", color: .orange)
            StreakBadge(value: profile?.longestStreak ?? 0, label: "Best", icon: "trophy.fill", color: AppConstants.Colors.sunsetGold)
            StreakBadge(value: profile?.totalSessions ?? 0, label: "Total", icon: "heart.fill", color: AppConstants.Colors.gentleCoral)
        }
    }

    private var calendarView: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Text(selectedMonth, format: .dateTime.month(.wide).year())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                }
            }

            // Day headers
            let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
            HStack {
                ForEach(dayNames, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = calendarDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        let isActive = activeDates.contains(comps)
                        let isToday = Calendar.current.isDateInToday(date)

                        ZStack {
                            if isActive {
                                Circle()
                                    .fill(AppConstants.Colors.mintGreen.opacity(0.3))
                                    .frame(width: 36, height: 36)
                            }
                            if isToday {
                                Circle()
                                    .stroke(AppConstants.Colors.calmBlue, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 15, weight: isActive ? .bold : .regular, design: .rounded))
                                .foregroundStyle(isActive ? AppConstants.Colors.mintGreen : .primary)
                        }
                        .frame(height: 40)
                    } else {
                        Text("")
                            .frame(height: 40)
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedMonth)
        .padding(16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var todayPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(AppConstants.Colors.mintGreen)
                Text("Today's Healing Plan")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }

            let tasks = todaysTasks
            if tasks.isEmpty {
                Text("Rest day - no tasks scheduled.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tasks) { task in
                    HealingTaskRow(task: task)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func changeMonth(_ offset: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonth) {
            withAnimation { selectedMonth = newMonth }
        }
    }


    private func calendarDays() -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: selectedMonth)!
        let firstDay = interval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        var current = firstDay
        while current < interval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

struct StreakBadge: View {
    let value: Int
    let label: LocalizedStringKey
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
            }
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
