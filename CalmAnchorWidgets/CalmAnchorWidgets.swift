import WidgetKit
import SwiftUI

struct DailyPromptEntry: TimelineEntry {
    let date: Date
    let prompt: String
    let affirmation: String
    let streakCount: Int
}

struct DailyPromptProvider: TimelineProvider {
    private let prompts = [
        "What made you feel safe today?",
        "Describe a moment of calm you experienced recently.",
        "What are three things you're grateful for right now?",
        "Write about a fear that turned out okay.",
        "What would you tell a friend feeling anxious?",
        "Describe your ideal peaceful place.",
        "What coping skill helped you most this week?",
        "Write a letter of compassion to yourself.",
        "What boundary would help your peace of mind?",
        "What small win can you celebrate today?",
    ]

    private let affirmations = [
        "I am safe in this moment.",
        "This feeling is temporary and will pass.",
        "I am stronger than my anxiety.",
        "I choose peace over worry.",
        "My breath is my anchor.",
        "I release what I cannot control.",
        "Each breath brings me closer to calm.",
    ]

    func placeholder(in context: Context) -> DailyPromptEntry {
        DailyPromptEntry(
            date: Date(),
            prompt: "What made you feel safe today?",
            affirmation: "I am safe in this moment.",
            streakCount: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyPromptEntry) -> Void) {
        let entry = DailyPromptEntry(
            date: Date(),
            prompt: prompts.randomElement() ?? prompts[0],
            affirmation: affirmations.randomElement() ?? affirmations[0],
            streakCount: 3
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyPromptEntry>) -> Void) {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let promptIndex = dayOfYear % prompts.count
        let affirmationIndex = dayOfYear % affirmations.count

        let entry = DailyPromptEntry(
            date: Date(),
            prompt: prompts[promptIndex],
            affirmation: affirmations[affirmationIndex],
            streakCount: 0
        )

        let nextUpdate = calendar.date(byAdding: .hour, value: 6, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct CalmAnchorWidgetEntryView: View {
    var entry: DailyPromptEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
                Text("CalmAnchor")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.affirmation)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(3)

            Spacer()
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                    Text("CalmAnchor")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Text(entry.prompt)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(2)

                Spacer()

                Text(entry.affirmation)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(2)
            }

            Spacer()

            VStack {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red.opacity(0.8))
                Text("SOS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct CalmAnchorWidgets: Widget {
    let kind = "CalmAnchorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyPromptProvider()) { entry in
            CalmAnchorWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Calm")
        .description("Your daily journal prompt and affirmation.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
