import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var calmName = ""
    @State private var selectedTriggers: Set<String> = []
    @State private var baselineMood: Int = 5
    @State private var dailyMinutes: Int = 10
    @State private var notificationsEnabled = true
    @State private var reminderTime = UserProfile.defaultReminderTime

    private let totalSteps = 8

    var body: some View {
        ZStack(alignment: .top) {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0A1428"), Color(hex: "1B2838"), Color(hex: "0D3B4F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Page content. A switch (not a TabView) because navigation is
            // driven solely by each page's CTA: swiping between steps is
            // deliberately impossible (skipping the profile-creation step
            // shipped as a bug that produced profile-less installs), and a
            // paged TabView's gesture recognizer swallows the vertical drags
            // that each page's fitsOrScrolls() ScrollView needs on short
            // viewports (iPad compatibility windows).
            Group {
                switch currentStep {
                case 0:
                    SplashOnboardingView(onNext: nextStep)
                        .fitsOrScrolls()
                case 1:
                    NameInputView(calmName: $calmName, onNext: nextStep)
                        .fitsOrScrolls()
                case 2:
                    TriggerQuizView(selectedTriggers: $selectedTriggers, onNext: nextStep)
                case 3:
                    MoodBaselineView(baselineMood: $baselineMood, onNext: nextStep)
                        .fitsOrScrolls()
                case 4:
                    DailyMinutesView(dailyMinutes: $dailyMinutes, onNext: nextStep)
                        .fitsOrScrolls()
                case 5:
                    NotificationOptInView(
                        notificationsEnabled: $notificationsEnabled,
                        reminderTime: $reminderTime,
                        onNext: nextStep
                    )
                    .fitsOrScrolls()
                case 6:
                    CraftingPlanView(
                        calmName: calmName,
                        onNext: {
                            createProfile()
                            nextStep()
                        }
                    )
                    .fitsOrScrolls()
                default:
                    PaywallView(
                        calmName: calmName,
                        onContinue: { completeOnboarding() },
                        onRestore:  { completeOnboarding() }
                    )
                }
            }
            .scrollDismissesKeyboard(.immediately)

            // Progress dots — visible only on the input steps
            if currentStep >= 1 && currentStep <= 6 {
                StepProgressDots(current: currentStep - 1, total: 6)
                    .padding(.top, 56)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    private func nextStep() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    /// Idempotent upsert. Safe to call more than once (swipe back-and-forth) and
    /// from both the crafting screen and completeOnboarding(), so a user can
    /// never reach the main app without a profile + healing plan.
    private func createProfile() {
        let name = calmName.trimmingCharacters(in: .whitespaces).isEmpty ? "Friend" : calmName
        let existing = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first
        let profile: UserProfile
        if let existing {
            profile = existing
            profile.calmName = name
            profile.triggers = Array(selectedTriggers)
            profile.baselineMood = baselineMood
            profile.dailyMinutes = dailyMinutes
        } else {
            profile = UserProfile(calmName: name,
                                  triggers: Array(selectedTriggers),
                                  baselineMood: baselineMood,
                                  dailyMinutes: dailyMinutes)
            modelContext.insert(profile)
        }
        profile.notificationsEnabled = notificationsEnabled
        profile.reminderTime = reminderTime

        // Only generate the plan once; regenerate only if none exists yet.
        let taskCount = (try? modelContext.fetchCount(FetchDescriptor<HealingTask>())) ?? 0
        if taskCount == 0 {
            HealingPlanService.generatePlan(for: profile, in: modelContext)
        }
        try? modelContext.save()

        Task { await NotificationService.shared.syncAll(profile: profile, hasActivityToday: false) }
    }

    private func completeOnboarding() {
        createProfile()          // guarantees a profile even if the user swiped past step 6
        hasCompletedOnboarding = true
    }
}

// MARK: - Step Progress Dots

struct StepProgressDots: View {
    let current: Int   // 0-based
    let total: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current
                          ? Color(hex: "00C9B7")
                          : Color.white.opacity(i < current ? 0.45 : 0.18))
                    .frame(width: i == current ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
            }
        }
    }
}
