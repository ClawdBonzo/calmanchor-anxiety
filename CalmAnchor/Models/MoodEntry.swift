import Foundation
import SwiftData

@Model
final class MoodEntry {
    var id: UUID
    var date: Date
    var moodLevel: Int // 1-10
    var anxietyLevel: Int // 1-10
    var triggers: [String]
    var notes: String
    var timeOfDay: String // morning, afternoon, evening, night

    init(
        moodLevel: Int = 5,
        anxietyLevel: Int = 5,
        triggers: [String] = [],
        notes: String = "",
        timeOfDay: String = ""
    ) {
        self.id = UUID()
        self.date = Date()
        self.moodLevel = moodLevel
        self.anxietyLevel = anxietyLevel
        self.triggers = triggers
        self.notes = notes
        self.timeOfDay = timeOfDay.isEmpty ? MoodEntry.currentTimeOfDay() : timeOfDay
    }

    static func currentTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
}
