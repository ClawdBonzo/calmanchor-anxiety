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
    @State private var showPaywall = false

    private let totalSteps = 7

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppConstants.Colors.deepNavy, Color(hex: "2A3F5F")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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

                CraftingPlanView(
                    calmName: calmName,
                    onNext: {
                        createProfile()
                        nextStep()
                    }
                )
                .tag(5)

                PaywallView(
                    calmName: calmName,
                    onContinue: { completeOnboarding() },
                    onRestore: { completeOnboarding() }
                )
                .tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentStep)
            .ignoresSafeArea()
        }
    }

    private func nextStep() {
        withAnimation {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    private func createProfile() {
        let profile = UserProfile(
            calmName: calmName.isEmpty ? "Friend" : calmName,
            triggers: Array(selectedTriggers),
            baselineMood: baselineMood,
            dailyMinutes: dailyMinutes
        )
        modelContext.insert(profile)
        HealingPlanService.generatePlan(for: profile, in: modelContext)
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
