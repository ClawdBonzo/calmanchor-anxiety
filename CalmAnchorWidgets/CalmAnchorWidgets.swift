import WidgetKit
import SwiftUI

struct DailyPromptEntry: TimelineEntry {
    let date: Date
    let prompt: String
    let affirmation: String
    let snapshot: WidgetSnapshot
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
        DailyPromptEntry(date: Date(),
                         prompt: prompts[0],
                         affirmation: affirmations[0],
                         snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyPromptEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyPromptEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh at next local midnight (so "today" resets) with a 6h fallback.
        let cal = Calendar.current
        let nextMidnight = cal.nextDate(after: Date(),
                                        matching: DateComponents(hour: 0),
                                        matchingPolicy: .nextTime)
            ?? Date().addingTimeInterval(6 * 3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func makeEntry() -> DailyPromptEntry {
        let cal = Calendar.current
        let day = cal.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return DailyPromptEntry(
            date: Date(),
            prompt: prompts[day % prompts.count],
            affirmation: affirmations[day % affirmations.count],
            snapshot: WidgetDataStore.read()
        )
    }
}

struct CalmAnchorWidgetEntryView: View {
    var entry: DailyPromptEntry
    @Environment(\.widgetFamily) var family

    private let teal = Color(red: 0, green: 0.788, blue: 0.718)
    private let gold = Color(red: 0.961, green: 0.843, blue: 0.431)

    var body: some View {
        switch family {
        case .systemSmall:  smallWidget
        case .systemLarge:  largeWidget
        default:            mediumWidget
        }
    }

    private var streakChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill").foregroundStyle(.orange)
            Text(entry.snapshot.currentStreak > 0
                 ? "\(entry.snapshot.currentStreak)-day streak"
                 : "Start your streak")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
    }

    private var levelChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.circle.fill").foregroundStyle(gold)
            Text("Lv \(entry.snapshot.level)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            streakChip
            Spacer()
            Text(entry.affirmation)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .lineLimit(3)
            Spacer()
        }
        .padding(12)
        // Small widget has no room for a separate SOS button, so the whole
        // tile is the panic entry point — the highest-value action.
        .widgetURL(URL(string: "calmanchor://panic"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                streakChip
                Text(entry.prompt)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                Spacer()
                Text(entry.affirmation)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(.secondary).italic().lineLimit(2)
            }
            Spacer()
            Link(destination: URL(string: "calmanchor://panic")!) {
                VStack(spacing: 2) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 32)).foregroundStyle(.red.opacity(0.85))
                    Text("SOS").font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(14)
        .widgetURL(URL(string: "calmanchor://logmood"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                streakChip
                Spacer()
                levelChip
            }
            Divider()
            Text(entry.prompt)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(2)
            Text(entry.affirmation)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(.secondary).italic().lineLimit(3)
            Spacer()
            HStack {
                Label(entry.snapshot.todayMoodLogged ? "Mood logged today" : "Log today's mood",
                      systemImage: entry.snapshot.todayMoodLogged ? "checkmark.circle.fill" : "face.smiling")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(entry.snapshot.todayMoodLogged ? teal : .primary)
                Spacer()
                Link(destination: URL(string: "calmanchor://panic")!) {
                    Text("SOS")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(.red.opacity(0.85), in: Capsule())
                }
            }
        }
        .padding(16)
        .widgetURL(URL(string: "calmanchor://logmood"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct CalmAnchorWidgets: Widget {
    let kind = "CalmAnchorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyPromptProvider()) { entry in
            CalmAnchorWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Calm")
        .description("Your streak, today's mood, and a daily affirmation.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Lock Screen SOS widget
// For a panic app the distance from "I'm having an attack" to the breathing
// orb IS the product. This puts SOS one tap from the Lock Screen — no unlock,
// no app hunt, no splash.

struct SOSEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

struct SOSProvider: TimelineProvider {
    func placeholder(in context: Context) -> SOSEntry { SOSEntry(date: Date(), streak: 0) }
    func getSnapshot(in context: Context, completion: @escaping (SOSEntry) -> Void) {
        completion(SOSEntry(date: Date(), streak: WidgetDataStore.read().currentStreak))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SOSEntry>) -> Void) {
        let entry = SOSEntry(date: Date(), streak: WidgetDataStore.read().currentStreak)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(6 * 3600))))
    }
}

struct SOSAccessoryView: View {
    var entry: SOSEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "wind").font(.system(size: 18, weight: .bold))
                    Text("SOS").font(.system(size: 10, weight: .heavy, design: .rounded))
                }
            }
            .widgetURL(URL(string: "calmanchor://panic"))
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "wind").font(.system(size: 20, weight: .bold))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Panic SOS").font(.system(size: 14, weight: .bold, design: .rounded))
                    Text(entry.streak > 0 ? "Breathe · \(entry.streak)-day streak" : "Tap to breathe")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .widgetURL(URL(string: "calmanchor://panic"))
        default:
            Image(systemName: "wind").widgetURL(URL(string: "calmanchor://panic"))
        }
    }
}

struct CalmAnchorSOSWidget: Widget {
    let kind = "CalmAnchorSOSWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SOSProvider()) { entry in
            SOSAccessoryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Panic SOS")
        .description("One tap to guided breathing — right from your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct CalmAnchorWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalmAnchorWidgets()
        CalmAnchorSOSWidget()
        PanicBreathingLiveActivity()
    }
}
