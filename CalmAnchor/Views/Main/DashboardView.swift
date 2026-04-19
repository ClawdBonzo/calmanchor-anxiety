import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var showPanicMode: Bool
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var revenueCat: RevenueCatService
    @Query private var profiles: [UserProfile]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journals: [JournalEntry]
    @Query private var gameStatsArray: [GameStats]

    @State private var showQuickMood = false
    @State private var showJournal = false
    @State private var showCalmCard = false
    @State private var showPaywall = false
    @State private var todayPrompt: String = AppConstants.journalPrompts.randomElement() ?? ""
    @State private var panicPulse = false
    @State private var streakGlow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var profile: UserProfile? { profiles.first }
    private var gameStats: GameStats? { gameStatsArray.first }

    private var todaysMoods: [MoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return moods.filter { Calendar.current.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AnchorBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        greetingSection
                            .padding(.top, 12)
                        panicButton
                        if revenueCat.isPremium { stayedCalmCard }
                        todayMoodCard
                        if revenueCat.isPremium { promptCard }
                        if revenueCat.isPremium { streakCard }
                        if revenueCat.isPremium { healingTasksCard }
                        quickActionsRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showQuickMood) {
                QuickMoodLogView()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showJournal) {
                JournalEntryView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    calmName: profile?.calmName ?? "Friend",
                    onContinue: { showPaywall = false },
                    onRestore: { showPaywall = false }
                )
                .environmentObject(revenueCat)
            }
            .fullScreenCover(isPresented: $showCalmCard) {
                ViralShareCardView(
                    calmName: profile?.calmName ?? "Friend",
                    streakDays: profile?.currentStreak ?? 0
                )
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                panicPulse = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                streakGlow = true
            }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greetingText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                Text("Hey, \(profile?.calmName ?? "Friend")")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // Level badge (if GameStats loaded)
                if let stats = gameStats {
                    HStack(spacing: 5) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppConstants.Colors.sunsetGold)
                        Text("Lv \(stats.currentLevel)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppConstants.Colors.sunsetGold.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppConstants.Colors.sunsetGold.opacity(0.25), lineWidth: 1))
                }

                // Streak badge
                if let streak = profile?.currentStreak, streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.orange)
                        Text("\(streak)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.orange.opacity(0.14))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.orange.opacity(0.3), lineWidth: 1))
                    .shadow(color: .orange.opacity(streakGlow ? 0.35 : 0.1), radius: 8, y: 2)
                }
            }
        }
    }

    // MARK: - Panic Button

    private var panicButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) { showPanicMode = true }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    // Pulsing ripple rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.red.opacity(0.22 - Double(i) * 0.06), lineWidth: 1.5)
                            .frame(width: 52 + CGFloat(i) * 18)
                            .scaleEffect(panicPulse ? 1.6 + CGFloat(i) * 0.15 : 1.0)
                            .opacity(panicPulse ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.4)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.45),
                                value: panicPulse
                            )
                    }
                    // Core button
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.red.opacity(0.25), Color.red.opacity(0.05)],
                                center: .center, startRadius: 0, endRadius: 28
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(
                            LinearGradient(colors: [.red, Color(hex: "C9456A")],
                                           startPoint: .top, endPoint: .bottom)
                        )
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 3) {
                    Text("SOS Panic Button")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Instant calm when you need it most")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassCard(glow: .red, glowRadius: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: showPanicMode)
        .accessibilityLabel("SOS Panic Button — open breathing and grounding support")
    }

    // MARK: - "I Stayed Calm Today" Viral Card

    private var stayedCalmCard: some View {
        Button(action: { showCalmCard = true }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppConstants.Colors.electricTeal.opacity(0.3), AppConstants.Colors.roseGold.opacity(0.1)],
                                center: .center, startRadius: 0, endRadius: 26
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: "anchor")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppConstants.Colors.electricTeal, AppConstants.Colors.roseGoldBright],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("I Stayed Calm Today")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Share your anchor with others")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppConstants.Colors.electricTeal.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                LinearGradient(
                    colors: [AppConstants.Colors.electricTeal.opacity(0.1), AppConstants.Colors.roseGold.opacity(0.06)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppConstants.Colors.electricTeal.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: AppConstants.Colors.electricTeal.opacity(0.12), radius: 10, y: 3)
        }
        .sensoryFeedback(.selection, trigger: showCalmCard)
        .accessibilityLabel("I Stayed Calm Today — share your progress")
    }

    // MARK: - Today's Mood Card

    private var todayMoodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "face.smiling.inverse")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppConstants.Colors.electricTeal)
                    Text("Today's Mood")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button(action: { showQuickMood = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Log")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(AppConstants.Colors.electricTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppConstants.Colors.electricTeal.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            if todaysMoods.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("No mood logged yet.\nTap Log to check in.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 12) {
                    ForEach(todaysMoods.prefix(4)) { mood in
                        VStack(spacing: 5) {
                            Text(moodEmoji(mood.moodLevel))
                                .font(.system(size: 28))
                            Text(mood.timeOfDay.capitalized)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Daily Prompt

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppConstants.Colors.sunsetGold)
                Text("Daily Reflection")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(todayPrompt)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .italic()
                .lineSpacing(3)

            Button(action: { showJournal = true }) {
                Text("Write in Journal")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppConstants.Colors.sunsetGold.opacity(0.75))
                    .clipShape(Capsule())
                    .shadow(color: AppConstants.Colors.sunsetGold.opacity(0.3), radius: 6, y: 2)
            }
        }
        .padding(16)
        .background(AppConstants.Colors.sunsetGold.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppConstants.Colors.sunsetGold.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 0) {
            PremiumStatItem(
                value: "\(profile?.currentStreak ?? 0)",
                label: "Streak",
                icon: "flame.fill",
                color: .orange
            )
            divider
            PremiumStatItem(
                value: "\(profile?.longestStreak ?? 0)",
                label: "Best",
                icon: "trophy.fill",
                color: AppConstants.Colors.sunsetGold
            )
            divider
            PremiumStatItem(
                value: "\(profile?.totalSessions ?? 0)",
                label: "Sessions",
                icon: "heart.fill",
                color: AppConstants.Colors.gentleCoral
            )
            divider
            PremiumStatItem(
                value: "\(journals.count)",
                label: "Journals",
                icon: "book.fill",
                color: AppConstants.Colors.calmBlue
            )
        }
        .padding(.vertical, 16)
        .glassCard(glow: AppConstants.Colors.electricTeal, glowRadius: 8)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(width: 1, height: 36)
    }

    // MARK: - Healing Tasks

    private var healingTasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppConstants.Colors.mintGreen)
                Text("Today's Healing Plan")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }

            let tasks = HealingPlanService.todaysTasks(from: modelContext)
            if tasks.isEmpty {
                Text("No tasks today — enjoy a rest day!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            } else {
                ForEach(tasks) { task in
                    HealingTaskRow(task: task)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 10) {
            PremiumQuickAction(title: "Breathe", icon: "wind", color: AppConstants.Colors.electricTeal) {
                showPanicMode = true
            }
            PremiumQuickAction(title: "Journal", icon: "book.fill", color: AppConstants.Colors.calmBlue) {
                if revenueCat.isPremium { showJournal = true } else { showPaywall = true }
            }
            PremiumQuickAction(title: "Mood", icon: "face.smiling", color: AppConstants.Colors.sunsetGold) {
                showQuickMood = true
            }
        }
    }

    // MARK: - Helpers

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

// MARK: - Premium Stat Item

struct PremiumStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.5), radius: 4, y: 1)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Premium Quick Action Button

struct PremiumQuickAction: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.6), radius: 5, y: 1)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard(glow: color, glowRadius: 6)
        }
    }
}

// MARK: - Healing Task Row (updated for dark theme)

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
                    .foregroundStyle(task.isCompleted ? AppConstants.Colors.mintGreen : .white.opacity(0.25))
                    .shadow(color: task.isCompleted ? AppConstants.Colors.mintGreen.opacity(0.4) : .clear, radius: 4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .white.opacity(0.35) : .white.opacity(0.88))
                Text("\(task.durationMinutes) min · \(task.category.capitalized)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer()

            Image(systemName: categoryIcon(task.category))
                .font(.system(size: 14))
                .foregroundStyle(categoryColor(task.category).opacity(0.8))
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
        case "breathing": return AppConstants.Colors.electricTeal
        case "journaling": return AppConstants.Colors.calmBlue
        case "grounding": return AppConstants.Colors.warmPeach
        case "movement": return AppConstants.Colors.sunsetGold
        default: return AppConstants.Colors.softLavender
        }
    }
}

// MARK: - Legacy structs kept for compile compatibility

struct StreakStatItem: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionButton: View {
    let title: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 22)).foregroundStyle(color)
                Text(title).font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
