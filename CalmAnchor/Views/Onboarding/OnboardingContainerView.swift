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

            // Page content
            TabView(selection: $currentStep) {
                SplashOnboardingView(onNext: nextStep)
                    .tag(0)

                NameInputView(calmName: $calmName, onNext: nextStep)
                    .tag(1)

                TriggerQuizView(selectedTriggers: $selectedTriggers, onNext: nextStep)
                    .tag(2)

                MoodBaselineView(baselineMood: $baselineMood, onNext: nextStep)
                    .tag(3)

                DailyMinutesView(dailyMinutes: $dailyMinutes, onNext: nextStep)
                    .tag(4)

                NotificationOptInView(
                    notificationsEnabled: $notificationsEnabled,
                    reminderTime: $reminderTime,
                    onNext: nextStep
                )
                .tag(5)

                CraftingPlanView(
                    calmName: calmName,
                    onNext: {
                        createProfile()
                        nextStep()
                    }
                )
                .tag(6)

                PaywallView(
                    calmName: calmName,
                    onContinue: { completeOnboarding() },
                    onRestore:  { completeOnboarding() }
                )
                .tag(7)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .scrollDismissesKeyboard(.immediately)
            .ignoresSafeArea()

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

    private func createProfile() {
        let profile = UserProfile(
            calmName: calmName.trimmingCharacters(in: .whitespaces).isEmpty ? "Friend" : calmName,
            triggers: Array(selectedTriggers),
            baselineMood: baselineMood,
            dailyMinutes: dailyMinutes
        )
        profile.notificationsEnabled = notificationsEnabled
        profile.reminderTime = reminderTime
        modelContext.insert(profile)
        HealingPlanService.generatePlan(for: profile, in: modelContext)

        Task { await NotificationService.shared.syncAll(profile: profile, hasActivityToday: false) }
    }

    private func completeOnboarding() {
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
