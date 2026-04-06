import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showResetAlert = false
    @State private var showResourceLibrary = false

    private var profile: UserProfile? { profiles.first }

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

                // Resources
                Section("Resources") {
                    Button(action: { showResourceLibrary = true }) {
                        Label("Coping Techniques Library", systemImage: "book.fill")
                    }

                    Label("Crisis Hotline: 988", systemImage: "phone.fill")
                        .foregroundStyle(.red)
                }

                // Subscription
                Section("Subscription") {
                    HStack {
                        Label("Plan", systemImage: "star.fill")
                        Spacer()
                        Text(profile?.isPremium == true ? "Premium" : "Free")
                            .foregroundStyle(.secondary)
                    }

                    Button(action: { /* RevenueCat restore */ }) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }

                // Data
                Section("Data & Privacy") {
                    Label("All data stored locally on device", systemImage: "lock.shield.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    Button(role: .destructive, action: { showResetAlert = true }) {
                        Label("Reset All Data", systemImage: "trash.fill")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: URL(string: "https://example.com/terms")!) {
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
        }
    }

    private func resetData() {
        try? modelContext.delete(model: MoodEntry.self)
        try? modelContext.delete(model: JournalEntry.self)
        try? modelContext.delete(model: PanicEvent.self)
        try? modelContext.delete(model: HealingTask.self)
        try? modelContext.delete(model: UserProfile.self)
        hasCompletedOnboarding = false
    }
}
