import SwiftUI
import SwiftData

struct JournalEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @State private var moodBefore: Int = 5
    @State private var moodAfter: Int = 5
    @State private var anxietyLevel: Int = 5
    @State private var selectedTriggers: Set<String> = []
    @State private var gratitude1 = ""
    @State private var gratitude2 = ""
    @State private var gratitude3 = ""
    @State private var affirmation = AppConstants.affirmations.randomElement() ?? ""
    @State private var freeWrite = ""
    @State private var selectedCoping: Set<String> = []
    @State private var currentPage = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                moodPage.tag(0)
                triggersPage.tag(1)
                gratitudePage.tag(2)
                freeWritePage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .navigationTitle("Daily Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if currentPage == 3 {
                        Button("Save") { saveJournal() }
                            .bold()
                    }
                }
            }
        }
    }

    private var moodPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                JournalSectionHeader(icon: "face.smiling", title: "How are you feeling?")

                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Mood Before Journaling: \(moodBefore)/10")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Slider(value: Binding(get: { Double(moodBefore) }, set: { moodBefore = Int($0) }),
                               in: 1...10, step: 1)
                        .tint(AppConstants.Colors.calmBlue)
                    }

                    VStack(spacing: 8) {
                        Text("Anxiety Level: \(anxietyLevel)/10")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Slider(value: Binding(get: { Double(anxietyLevel) }, set: { anxietyLevel = Int($0) }),
                               in: 1...10, step: 1)
                        .tint(AppConstants.Colors.gentleCoral)
                    }
                }

                // Coping techniques used
                VStack(alignment: .leading, spacing: 10) {
                    Text("Coping techniques used today:")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    FlowLayout(spacing: 8) {
                        ForEach(AppConstants.CopingTechniques.allCases, id: \.label) { technique in
                            Button(action: {
                                if selectedCoping.contains(technique.label) {
                                    selectedCoping.remove(technique.label)
                                } else {
                                    selectedCoping.insert(technique.label)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: technique.icon)
                                        .font(.system(size: 12))
                                    Text(technique.label)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedCoping.contains(technique.label) ?
                                    AppConstants.Colors.calmBlue.opacity(0.2) : Color(.systemGray6))
                                .foregroundStyle(selectedCoping.contains(technique.label) ?
                                    AppConstants.Colors.calmBlue : .primary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private var triggersPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                JournalSectionHeader(icon: "exclamationmark.triangle", title: "What triggered you today?")

                FlowLayout(spacing: 8) {
                    ForEach(AppConstants.Triggers.allCases, id: \.label) { trigger in
                        Button(action: {
                            if selectedTriggers.contains(trigger.label) {
                                selectedTriggers.remove(trigger.label)
                            } else {
                                selectedTriggers.insert(trigger.label)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: trigger.icon)
                                    .font(.system(size: 12))
                                Text(trigger.label)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedTriggers.contains(trigger.label) ?
                                AppConstants.Colors.warmPeach.opacity(0.3) : Color(.systemGray6))
                            .foregroundStyle(selectedTriggers.contains(trigger.label) ?
                                AppConstants.Colors.warmPeach : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private var gratitudePage: some View {
        ScrollView {
            VStack(spacing: 20) {
                JournalSectionHeader(icon: "heart.fill", title: "Gratitude & Affirmation")

                VStack(spacing: 14) {
                    Text("Three things I'm grateful for:")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    GratitudeField(number: 1, text: $gratitude1)
                    GratitudeField(number: 2, text: $gratitude2)
                    GratitudeField(number: 3, text: $gratitude3)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's Affirmation")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    Text("\"\(affirmation)\"")
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .italic()
                        .foregroundStyle(AppConstants.Colors.calmBlue)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(AppConstants.Colors.calmBlue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Shuffle Affirmation") {
                        withAnimation { affirmation = AppConstants.affirmations.randomElement() ?? affirmation }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppConstants.Colors.calmBlue)
                }
            }
            .padding(20)
        }
    }

    private var freeWritePage: some View {
        VStack(spacing: 16) {
            JournalSectionHeader(icon: "pencil.line", title: "Free Write")

            Text(AppConstants.journalPrompts.randomElement() ?? "")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .italic()
                .padding(.horizontal, 20)

            TextEditor(text: $freeWrite)
                .font(.system(size: 16, design: .rounded))
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                Text("Mood After Journaling: \(moodAfter)/10")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Slider(value: Binding(get: { Double(moodAfter) }, set: { moodAfter = Int($0) }),
                       in: 1...10, step: 1)
                .tint(AppConstants.Colors.mintGreen)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }

    private func saveJournal() {
        let gratitudes = [gratitude1, gratitude2, gratitude3].filter { !$0.isEmpty }
        let entry = JournalEntry(
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            anxietyLevel: anxietyLevel,
            triggers: Array(selectedTriggers),
            gratitudes: gratitudes,
            affirmation: affirmation,
            freeWrite: freeWrite,
            copingUsed: Array(selectedCoping)
        )
        modelContext.insert(entry)

        if let profile = profiles.first {
            StreakService.updateStreak(for: profile)
        }

        dismiss()
    }
}

struct JournalSectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(AppConstants.Colors.calmBlue)
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GratitudeField: View {
    let number: Int
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Text("\(number).")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppConstants.Colors.calmBlue)
                .frame(width: 24)
            TextField("I'm grateful for...", text: $text)
                .font(.system(size: 15, design: .rounded))
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
