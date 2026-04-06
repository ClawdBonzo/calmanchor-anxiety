import SwiftUI

enum AppConstants {
    static let appName = "CalmAnchor"
    static let maxMoodLevel = 10
    static let minMoodLevel = 1

    enum Colors {
        static let calmBlue = Color(hex: "5B9BD5")
        static let deepNavy = Color(hex: "1B2838")
        static let softLavender = Color(hex: "B8A9C9")
        static let warmPeach = Color(hex: "F4C2A1")
        static let mintGreen = Color(hex: "A8D5BA")
        static let gentleCoral = Color(hex: "E8A0A0")
        static let sunsetGold = Color(hex: "F5D76E")
        static let cloudWhite = Color(hex: "F7F9FC")
        static let stormGray = Color(hex: "6B7B8D")
        static let sereneTeal = Color(hex: "6BBFAB")
    }

    enum Triggers: CaseIterable {
        case work, social, health, financial, relationships, sleep, uncertainty, perfectionism, crowds, loneliness

        var label: String {
            switch self {
            case .work: return "Work Stress"
            case .social: return "Social Situations"
            case .health: return "Health Worries"
            case .financial: return "Financial Concerns"
            case .relationships: return "Relationship Issues"
            case .sleep: return "Sleep Problems"
            case .uncertainty: return "Uncertainty"
            case .perfectionism: return "Perfectionism"
            case .crowds: return "Crowds / Spaces"
            case .loneliness: return "Loneliness"
            }
        }

        var icon: String {
            switch self {
            case .work: return "briefcase.fill"
            case .social: return "person.3.fill"
            case .health: return "heart.fill"
            case .financial: return "dollarsign.circle.fill"
            case .relationships: return "heart.circle.fill"
            case .sleep: return "moon.fill"
            case .uncertainty: return "questionmark.circle.fill"
            case .perfectionism: return "star.fill"
            case .crowds: return "person.2.wave.2.fill"
            case .loneliness: return "person.fill.questionmark"
            }
        }
    }

    enum CopingTechniques: CaseIterable {
        case breathing, grounding, journaling, movement, meditation, tapping, coldWater, progressive, visualization

        var label: String {
            switch self {
            case .breathing: return "Deep Breathing"
            case .grounding: return "5-4-3-2-1 Grounding"
            case .journaling: return "Journaling"
            case .movement: return "Physical Movement"
            case .meditation: return "Meditation"
            case .tapping: return "EFT Tapping"
            case .coldWater: return "Cold Water"
            case .progressive: return "Muscle Relaxation"
            case .visualization: return "Visualization"
            }
        }

        var icon: String {
            switch self {
            case .breathing: return "wind"
            case .grounding: return "hand.raised.fill"
            case .journaling: return "book.fill"
            case .movement: return "figure.walk"
            case .meditation: return "brain.head.profile"
            case .tapping: return "hand.tap.fill"
            case .coldWater: return "drop.fill"
            case .progressive: return "figure.flexibility"
            case .visualization: return "eye.fill"
            }
        }
    }

    static let affirmations = [
        "I am safe in this moment.",
        "This feeling is temporary and will pass.",
        "I have survived every difficult moment so far.",
        "I am stronger than my anxiety.",
        "I choose peace over worry.",
        "My breath is my anchor.",
        "I release what I cannot control.",
        "I am worthy of calm and peace.",
        "Each breath brings me closer to calm.",
        "I trust myself to handle what comes.",
        "I am not my anxious thoughts.",
        "This moment is all I need to focus on.",
        "I give myself permission to feel and heal.",
        "My courage is greater than my fear.",
        "I am building resilience with every breath.",
        "Peace flows through me like a gentle stream.",
        "I am anchored in the present moment.",
        "My anxiety does not define me.",
        "I welcome calm into my body and mind.",
        "I am learning to befriend my nervous system."
    ]

    static let journalPrompts = [
        "What made you feel safe today?",
        "Describe a moment of calm you experienced recently.",
        "What are three things you're grateful for right now?",
        "Write about a fear that turned out okay.",
        "What would you tell a friend feeling anxious?",
        "Describe your ideal peaceful place.",
        "What coping skill helped you most this week?",
        "Write a letter of compassion to yourself.",
        "What boundary would help your peace of mind?",
        "List five things you can see, hear, and feel right now.",
        "What progress have you noticed in your healing?",
        "Describe a time you felt truly at peace.",
        "What small win can you celebrate today?",
        "How has your relationship with anxiety changed?",
        "What does 'calm' look like in your daily life?"
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
