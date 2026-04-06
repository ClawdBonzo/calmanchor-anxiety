import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var showNewEntry = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(entries) { entry in
                            JournalRowView(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showNewEntry = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showNewEntry) {
                JournalEntryView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppConstants.Colors.calmBlue.opacity(0.4))
            Text("Your journal awaits")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("Start writing to track your healing journey")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { showNewEntry = true }) {
                Label("Write First Entry", systemImage: "pencil")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(AppConstants.Colors.calmBlue)
                    .clipShape(Capsule())
            }
        }
        .padding(40)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}

struct JournalRowView: View {
    let entry: JournalEntry
    private let moodEmojis = ["😰", "😟", "😔", "😕", "😐", "🙂", "😊", "😌", "😄", "🌟"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Text(moodEmojis[max(0, min(entry.moodBefore - 1, 9))])
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(moodEmojis[max(0, min(entry.moodAfter - 1, 9))])
                }
            }

            if !entry.freeWrite.isEmpty {
                Text(entry.freeWrite)
                    .font(.system(size: 14, design: .rounded))
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }

            if !entry.gratitudes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppConstants.Colors.gentleCoral)
                    Text(entry.gratitudes.joined(separator: " \u{2022} "))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if !entry.triggers.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.triggers.prefix(3), id: \.self) { trigger in
                        Text(trigger)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppConstants.Colors.warmPeach.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
