import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var showPanicMode: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journals: [JournalEntry]
    @State private var showQuickMood = false
    @State private var showJournal = false
    @State private var todayPrompt: String = AppConstants.journalPrompts.randomElement() ?? ""

    private var profile: UserProfile? { profiles.first }
    private var todaysMoods: [MoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return moods.filter { Calendar.current.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    greetingSection

                    // Panic Button
                    panicButton

                    // Today's Mood
                    todayMoodCard

                    // Daily Prompt
                    promptCard

                    // Streak Card
                    streakCard

                    // Today's Healing Tasks
                    healingTasksCard

                    // Quick Actions
                    quickActionsRow
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("CalmAnchor")
            .sheet(isPresented: $showQuickMood) {
                QuickMoodLogView()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showJournal) {
                JournalEntryView()
            }
        }
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("Hey, \(profile?.calmName ?? "Friend")")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            Spacer()

            // Streak badge
            if let streak = profile?.currentStreak, streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(streak)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(.top, 8)
    }

    private var panicButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                showPanicMode = true
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("SOS Panic Button")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Instant calm when you need it most")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .red.opacity(0.1), radius: 8, y: 4)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: showPanicMode)
    }

    private var todayMoodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Mood")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Button(action: { showQuickMood = true }) {
                    Label("Log Mood", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppConstants.Colors.calmBlue)
                }
            }

            if todaysMoods.isEmpty {
                HStack {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No mood logged yet today.\nTap + to check in with yourself.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 12) {
                    ForEach(todaysMoods.prefix(4)) { mood in
                        VStack(spacing: 4) {
                            Text(moodEmoji(mood.moodLevel))
                                .font(.system(size: 28))
                            Text(mood.timeOfDay.capitalized)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppConstants.Colors.sunsetGold)
                Text("Daily Reflection")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }

            Text(todayPrompt)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .italic()

            Button(action: { showJournal = true }) {
                Text("Write in Journal")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppConstants.Colors.calmBlue)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(AppConstants.Colors.sunsetGold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var streakCard: some View {
        HStack(spacing: 20) {
            StreakStatItem(value: "\(profile?.currentStreak ?? 0)", label: "Current\nStreak", icon: "flame.fill", color: .orange)
            StreakStatItem(value: "\(profile?.longestStreak ?? 0)", label: "Longest\nStreak", icon: "trophy.fill", color: AppConstants.Colors.sunsetGold)
            StreakStatItem(value: "\(profile?.totalSessions ?? 0)", label: "Total\nSessions", icon: "heart.fill", color: AppConstants.Colors.gentleCoral)
            StreakStatItem(value: "\(journals.count)", label: "Journal\nEntries", icon: "book.fill", color: AppConstants.Colors.calmBlue)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var healingTasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(AppConstants.Colors.mintGreen)
                Text("Today's Healing Plan")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
            }

            let tasks = HealingPlanService.todaysTasks(from: modelContext)
            if tasks.isEmpty {
                Text("No tasks for today - enjoy a rest day!")
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

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButton(title: "Breathe", icon: "wind", color: AppConstants.Colors.sereneTeal) {
                showPanicMode = true
            }
            QuickActionButton(title: "Journal", icon: "book.fill", color: AppConstants.Colors.calmBlue) {
                showJournal = true
            }
            QuickActionButton(title: "Mood", icon: "face.smiling", color: AppConstants.Colors.sunsetGold) {
                showQuickMood = true
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private func moodEmoji(_ level: Int) -> String {
        let emojis = ["😰", "😟", "😔", "😕", "😐", "🙂", "😊", "😌", "😄", "🌟"]
        return emojis[max(0, min(level - 1, 9))]
    }
}

struct StreakStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HealingTaskRow: View {
    @Bindable var task: HealingTask

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                task.isCompleted.toggle()
                if task.isCompleted { task.completedDate = Date() }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isCompleted ? AppConstants.Colors.mintGreen : .gray.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                Text("\(task.durationMinutes) min \u{2022} \(task.category.capitalized)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()

            Image(systemName: categoryIcon(task.category))
                .foregroundStyle(categoryColor(task.category))
        }
        .padding(.vertical, 4)
        .sensoryFeedback(.impact(weight: .light), trigger: task.isCompleted)
    }

    private func categoryIcon(_ cat: String) -> String {
        switch cat {
        case "breathing": return "wind"
        case "journaling": return "book.fill"
        case "grounding": return "hand.raised.fill"
        case "movement": return "figure.walk"
        default: return "brain.head.profile"
        }
    }

    private func categoryColor(_ cat: String) -> Color {
        switch cat {
        case "breathing": return AppConstants.Colors.sereneTeal
        case "journaling": return AppConstants.Colors.calmBlue
        case "grounding": return AppConstants.Colors.warmPeach
        case "movement": return AppConstants.Colors.sunsetGold
        default: return AppConstants.Colors.softLavender
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
