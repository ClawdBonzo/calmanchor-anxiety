import SwiftUI
import SwiftData

struct QuickMoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @State private var moodLevel: Int = 5
    @State private var anxietyLevel: Int = 5
    @State private var note = ""

    private let moodEmojis = ["😰", "😟", "😔", "😕", "😐", "🙂", "😊", "😌", "😄", "🌟"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Text(moodEmojis[moodLevel - 1])
                    .font(.system(size: 64))
                    .animation(.easeInOut(duration: 0.2), value: moodLevel)

                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Mood: \(moodLevel)/10")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Slider(value: Binding(
                            get: { Double(moodLevel) },
                            set: { moodLevel = Int($0) }
                        ), in: 1...10, step: 1)
                        .tint(AppConstants.Colors.calmBlue)
                    }

                    VStack(spacing: 8) {
                        Text("Anxiety: \(anxietyLevel)/10")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Slider(value: Binding(
                            get: { Double(anxietyLevel) },
                            set: { anxietyLevel = Int($0) }
                        ), in: 1...10, step: 1)
                        .tint(AppConstants.Colors.gentleCoral)
                    }
                }
                .padding(.horizontal, 20)

                TextField("Quick note (optional)...", text: $note)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 20)

                Button(action: saveMood) {
                    Text("Log Mood")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppConstants.Colors.calmBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Quick Mood Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveMood() {
        let entry = MoodEntry(
            moodLevel: moodLevel,
            anxietyLevel: anxietyLevel,
            notes: note
        )
        modelContext.insert(entry)

        if let profile = profiles.first {
            StreakService.updateStreak(for: profile)
        }

        dismiss()
    }
}
