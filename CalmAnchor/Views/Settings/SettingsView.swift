import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject private var revenueCat: RevenueCatService
    @Query private var profiles: [UserProfile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showResetAlert = false
    @State private var showResourceLibrary = false
    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    private var profile: UserProfile? { profiles.first }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { profile?.notificationsEnabled ?? false },
            set: { newValue in
                guard let p = profile else { return }
                Task { @MainActor in
                    if newValue {
                        let granted = await NotificationService.shared.requestAuthorization()
                        p.notificationsEnabled = granted
                        await NotificationService.shared.syncAll(
                            profile: p,
                            hasActivityToday: NotificationService.shared.hasActivityToday(p))
                    } else {
                        p.notificationsEnabled = false
                        NotificationService.shared.cancelAll()
                    }
                }
            }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { profile?.reminderTime ?? UserProfile.defaultReminderTime },
            set: { newValue in
                guard let p = profile else { return }
                p.reminderTime = newValue
                Task { @MainActor in
                    await NotificationService.shared.syncAll(
                        profile: p,
                        hasActivityToday: NotificationService.shared.hasActivityToday(p))
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 14) {
                        Image("BrandIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color(hex: "00C9B7").opacity(0.3), radius: 6, y: 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile?.calmName ?? "Friend")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text("Member since \(profile?.createdAt ?? Date(), format: .dateTime.month(.abbreviated).year())")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Healing Settings
                Section("Healing Plan") {
                    HStack {
                        Label("Daily Minutes", systemImage: "clock.fill")
                        Spacer()
                        Text("\(profile?.dailyMinutes ?? 10) min")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Triggers", systemImage: "exclamationmark.triangle.fill")
                        Spacer()
                        Text("\(profile?.triggers.count ?? 0) selected")
                            .foregroundStyle(.secondary)
                    }
                }

                // Reminders
                Section("Reminders") {
                    Toggle(isOn: notificationsBinding) {
                        Label("Daily Reminders", systemImage: "bell.fill")
                    }
                    if profile?.notificationsEnabled == true {
                        DatePicker(selection: reminderTimeBinding, displayedComponents: .hourAndMinute) {
                            Label("Reminder Time", systemImage: "clock.badge")
                        }
                    }
                }

                // Subscription
                Section("Subscription") {
                    HStack {
                        Label("Plan", systemImage: "star.fill")
                        Spacer()
                        Text(revenueCat.isPremium ? "Premium" : "Free")
                            .foregroundStyle(.secondary)
                    }

                    if !revenueCat.isPremium {
                        Button(action: { showPaywall = true }) {
                            Label("Upgrade to Premium", systemImage: "crown.fill")
                                .foregroundStyle(AppConstants.Colors.sunsetGold)
                        }
                    }

                    Button(action: { Task { await restorePurchases() } }) {
                        HStack {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                            if isRestoring {
                                Spacer()
                                ProgressView().scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isRestoring)

                    if revenueCat.isPremium {
                        Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                            Label("Manage Subscription", systemImage: "creditcard")
                        }
                    }

                    if let msg = restoreMessage {
                        Text(msg)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                // Resources
                Section {
                    Button(action: { showResourceLibrary = true }) {
                        Label("Coping Techniques Library", systemImage: "book.fill")
                    }

                    // The most important tap in the app — make it actually dial.
                    Link(destination: URL(string: "tel:988")!) {
                        Label("Crisis Hotline: 988", systemImage: "phone.fill")
                            .foregroundStyle(.red)
                    }
                    .accessibilityHint("Calls the 988 Suicide and Crisis Lifeline")
                } header: {
                    Text("Resources")
                } footer: {
                    Text("CalmAnchor offers self-help and wellness tools and is not a substitute for professional medical advice, diagnosis, or treatment. If you're in crisis, call or text 988 (US) or your local emergency number.")
                }

                // Data
                Section("Data & Privacy") {
                    Label("Your entries are stored locally on device", systemImage: "lock.shield.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    Button(role: .destructive, action: { showResetAlert = true }) {
                        Label("Reset All Data", systemImage: "trash.fill")
                    }
                }

                // About
                Section("About") {
                    Button(action: { requestReview() }) {
                        Label("Rate CalmAnchor", systemImage: "star.bubble.fill")
                    }

                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text(Self.appVersionString)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://gwlabs.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: URL(string: "https://gwlabs.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showResourceLibrary) {
                ResourceLibraryView()
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetData() }
            } message: {
                Text("This will delete all your journal entries, mood logs, and progress. This cannot be undone.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    calmName: profile?.calmName ?? "Friend",
                    onContinue: { showPaywall = false },
                    onRestore: { showPaywall = false }
                )
                .environmentObject(revenueCat)
            }
        }
    }

    private func restorePurchases() async {
        isRestoring = true
        restoreMessage = nil
        do {
            let success = try await revenueCat.restorePurchases()
            isRestoring = false
            restoreMessage = success ? "Premium restored!" : "No active subscription found."
        } catch {
            isRestoring = false
            restoreMessage = error.localizedDescription
        }
    }

    /// "Reset All Data" means ALL of it — including gamification, so a fresh
    /// onboarding doesn't inherit the previous level/XP/quests.
    private func resetData() {
        try? modelContext.delete(model: MoodEntry.self)
        try? modelContext.delete(model: JournalEntry.self)
        try? modelContext.delete(model: PanicEvent.self)
        try? modelContext.delete(model: HealingTask.self)
        try? modelContext.delete(model: UserProfile.self)
        try? modelContext.delete(model: GameStats.self)
        try? modelContext.delete(model: Quest.self)
        try? modelContext.delete(model: XPEvent.self)
        try? modelContext.delete(model: Badge.self)
        try? modelContext.save()
        NotificationService.shared.cancelEverything()
        WidgetSync.refresh(from: modelContext)
        hasCompletedOnboarding = false
    }

    private static var appVersionString: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return b.isEmpty ? v : "\(v) (\(b))"
    }
}
