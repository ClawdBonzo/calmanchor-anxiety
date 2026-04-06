import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var date: Date
    var moodBefore: Int
    var moodAfter: Int
    var anxietyLevel: Int
    var triggers: [String]
    var gratitudes: [String]
    var affirmation: String
    var freeWrite: String
    var copingUsed: [String]

    init(
        moodBefore: Int = 5,
        moodAfter: Int = 5,
        anxietyLevel: Int = 5,
        triggers: [String] = [],
        gratitudes: [String] = [],
        affirmation: String = "",
        freeWrite: String = "",
        copingUsed: [String] = []
    ) {
        self.id = UUID()
        self.date = Date()
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.anxietyLevel = anxietyLevel
        self.triggers = triggers
        self.gratitudes = gratitudes
        self.affirmation = affirmation
        self.freeWrite = freeWrite
        self.copingUsed = copingUsed
    }
}
