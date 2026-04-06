import SwiftUI

struct ResourceLibraryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: ResourceCategory = .all

    enum ResourceCategory: String, CaseIterable {
        case all = "All"
        case breathing = "Breathing"
        case grounding = "Grounding"
        case mindfulness = "Mindfulness"
        case cbt = "CBT Tools"
        case crisis = "Crisis"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ResourceCategory.allCases, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ?
                                            AppConstants.Colors.calmBlue : Color(.systemGray6))
                                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Resource cards
                    LazyVStack(spacing: 14) {
                        ForEach(filteredResources) { resource in
                            ResourceCardView(resource: resource)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 80)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Resources")
            .searchable(text: $searchText, prompt: "Search techniques...")
        }
    }

    private var filteredResources: [CalmResource] {
        var resources = CalmResource.library
        if selectedCategory != .all {
            resources = resources.filter { $0.category == selectedCategory.rawValue }
        }
        if !searchText.isEmpty {
            resources = resources.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        return resources
    }
}

struct CalmResource: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let icon: String
    let steps: [String]
    let duration: String

    static let library: [CalmResource] = [
        CalmResource(
            title: "4-7-8 Breathing",
            description: "A natural tranquilizer for the nervous system",
            category: "Breathing",
            icon: "wind",
            steps: [
                "Exhale completely through your mouth",
                "Close your mouth and inhale through your nose for 4 seconds",
                "Hold your breath for 7 seconds",
                "Exhale completely through your mouth for 8 seconds",
                "Repeat 3-4 times"
            ],
            duration: "3 min"
        ),
        CalmResource(
            title: "Box Breathing",
            description: "Used by Navy SEALs to stay calm under pressure",
            category: "Breathing",
            icon: "square",
            steps: [
                "Inhale slowly for 4 seconds",
                "Hold your breath for 4 seconds",
                "Exhale slowly for 4 seconds",
                "Hold again for 4 seconds",
                "Repeat 4-6 times"
            ],
            duration: "4 min"
        ),
        CalmResource(
            title: "5-4-3-2-1 Grounding",
            description: "Anchor yourself in the present moment using your senses",
            category: "Grounding",
            icon: "hand.raised.fill",
            steps: [
                "Name 5 things you can SEE",
                "Name 4 things you can TOUCH",
                "Name 3 things you can HEAR",
                "Name 2 things you can SMELL",
                "Name 1 thing you can TASTE"
            ],
            duration: "5 min"
        ),
        CalmResource(
            title: "Body Scan Meditation",
            description: "Systematically relax each part of your body",
            category: "Mindfulness",
            icon: "figure.stand",
            steps: [
                "Lie down or sit comfortably",
                "Start at the top of your head",
                "Slowly move attention down through each body part",
                "Notice tension without judgment",
                "Breathe into areas of tension and release"
            ],
            duration: "10 min"
        ),
        CalmResource(
            title: "Thought Record",
            description: "Challenge anxious thoughts with evidence",
            category: "CBT Tools",
            icon: "doc.text.fill",
            steps: [
                "Write down the anxious thought",
                "Rate your belief in it (0-100%)",
                "List evidence FOR the thought",
                "List evidence AGAINST the thought",
                "Create a balanced alternative thought",
                "Re-rate your belief"
            ],
            duration: "10 min"
        ),
        CalmResource(
            title: "Progressive Muscle Relaxation",
            description: "Tense and release muscle groups to relieve physical tension",
            category: "Mindfulness",
            icon: "figure.flexibility",
            steps: [
                "Start with your feet - tense for 5 seconds",
                "Release and notice the difference",
                "Move to calves, thighs, abdomen",
                "Continue through chest, arms, hands",
                "Finish with shoulders, neck, face",
                "Rest and notice full-body relaxation"
            ],
            duration: "15 min"
        ),
        CalmResource(
            title: "Cold Water Technique",
            description: "Activate the dive reflex to calm your nervous system",
            category: "Grounding",
            icon: "drop.fill",
            steps: [
                "Fill a bowl with cold water and ice",
                "Take a deep breath",
                "Submerge your face for 15-30 seconds",
                "Alternatively, hold ice cubes in your hands",
                "Notice the shift in your body's response"
            ],
            duration: "2 min"
        ),
        CalmResource(
            title: "Cognitive Defusion",
            description: "Create distance between you and anxious thoughts",
            category: "CBT Tools",
            icon: "brain.head.profile",
            steps: [
                "Notice the anxious thought",
                "Prefix it with 'I notice I'm having the thought that...'",
                "Say it in a silly voice internally",
                "Visualize the thought as a cloud passing by",
                "Thank your mind for trying to protect you"
            ],
            duration: "5 min"
        ),
        CalmResource(
            title: "Crisis Resources",
            description: "Important contacts when you need immediate help",
            category: "Crisis",
            icon: "phone.fill",
            steps: [
                "988 Suicide & Crisis Lifeline: Call or text 988",
                "Crisis Text Line: Text HOME to 741741",
                "NAMI Helpline: 1-800-950-NAMI",
                "SAMHSA Helpline: 1-800-662-4357",
                "Emergency: 911"
            ],
            duration: "Immediate"
        )
    ]
}

struct ResourceCardView: View {
    let resource: CalmResource
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppConstants.Colors.calmBlue.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: resource.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(AppConstants.Colors.calmBlue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(resource.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(resource.description)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(isExpanded ? nil : 1)
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text(resource.duration)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(AppConstants.Colors.sereneTeal)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(resource.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(AppConstants.Colors.calmBlue)
                                .clipShape(Circle())

                            Text(step)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 58)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
