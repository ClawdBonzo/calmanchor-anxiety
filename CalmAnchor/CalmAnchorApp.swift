import SwiftUI
import SwiftData

@main
struct CalmAnchorApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var revenueCat = RevenueCatService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            MoodEntry.self,
            JournalEntry.self,
            PanicEvent.self,
            HealingTask.self,
            GameStats.self,
            Quest.self,
            Badge.self,
            XPEvent.self
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
                .environmentObject(revenueCat)
                .onAppear {
                    revenueCat.configure()
                }
        }
    }
}

struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.opacity)
            }

            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

struct SplashScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            Image(colorScheme == .dark ? "Splash-Dark" : "Splash-Light")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: "0A1428"), Color(hex: "0D3B4F")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(-1)

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color(hex: "00C9B7").opacity(0.15 - Double(i) * 0.04), lineWidth: 2)
                            .frame(width: 160 + CGFloat(i) * 50)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)
                    }

                    Image("BrandIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: Color(hex: "00C9B7").opacity(0.4), radius: 20, y: 0)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 8) {
                    Text("CalmAnchor")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Your anchor in the storm")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "D4A574"))
                }
                .opacity(titleOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                logoScale = 1.0; logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                ringScale = 1.0; ringOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) { titleOpacity = 1.0 }
        }
    }
}
