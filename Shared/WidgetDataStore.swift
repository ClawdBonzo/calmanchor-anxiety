import Foundation
import WidgetKit

/// Lightweight read-only projection of app state shared with the widget via an
/// App Group. The app is the sole writer; the widget reads.
struct WidgetSnapshot: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var todayMoodLogged: Bool
    var todayMood: Int        // 1...10, 0 = none
    var level: Int
    var levelName: String
    var lastUpdated: Date

    static let empty = WidgetSnapshot(
        currentStreak: 0, longestStreak: 0,
        todayMoodLogged: false, todayMood: 0,
        level: 1, levelName: "Anxious Beginner",
        lastUpdated: .distantPast
    )
}

enum WidgetDataStore {
    static let appGroupID = "group.com.clawdbonzo.CalmAnchor"
    private static let snapshotKey = "widget.snapshot.v1"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// App side: persist the latest snapshot and refresh widget timelines.
    static func write(_ snapshot: WidgetSnapshot) {
        guard let defaults,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Widget (or app) side: read the last snapshot, or `.empty`.
    static func read() -> WidgetSnapshot {
        guard let defaults,
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}
