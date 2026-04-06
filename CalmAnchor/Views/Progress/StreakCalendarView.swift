import SwiftUI
import SwiftData

struct StreakCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \JournalEntry.date) private var journals: [JournalEntry]
    @Query(sort: \MoodEntry.date) private var moods: [MoodEntry]
    @Query(sort: \HealingTask.sortOrder) private var allTasks: [HealingTask]
    @State private var selectedMonth = Date()

    private var profile: UserProfile? { profiles.first }
    private var activeDates: Set<DateComponents> {
        StreakService.activeDates(journals: journals, moods: moods)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak Summary
                    streakSummary

                    // Calendar
                    calendarView

                    // Today's Healing Plan
                    todayPlanSection

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Healing Streaks")
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
        .padding(16)
        .background(.white)
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

            let tasks = HealingPlanService.todaysTasks(from: modelContext)
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
        .background(.white)
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
    let label: String
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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
