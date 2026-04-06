import SwiftUI
import SwiftData

@main
struct CalmAnchorApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            MoodEntry.self,
            JournalEntry.self,
            PanicEvent.self,
            HealingTask.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .modelContainer(sharedModelContainer)
        }
    }
}

struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
                .transition(.opacity)
        } else {
            OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .transition(.opacity)
        }
    }
}
