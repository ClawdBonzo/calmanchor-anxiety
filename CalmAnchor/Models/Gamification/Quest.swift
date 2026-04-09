import Foundation
import SwiftData

@Model
final class Quest {
    @Attribute(.unique) var id: UUID
    var type: String
    var title: String
    var questDescription: String
    var targetCount: Int
    var currentProgress: Int = 0
    var xpReward: Int
    var dueDate: Date
    var frequency: String
    var isCompleted: Bool = false
    var completedDate: Date?
    var isActive: Bool = true
    var createdDate: Date = Date()

    init(type: String, title: String, questDescription: String, targetCount: Int,
         xpReward: Int, frequency: String, dueDate: Date) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.questDescription = questDescription
        self.targetCount = targetCount
        self.xpReward = xpReward
        self.frequency = frequency
        self.dueDate = dueDate
    }

    var progressPercentage: Double {
        targetCount > 0 ? min(Double(currentProgress) / Double(targetCount), 1.0) : 0
    }

    var isExpired: Bool {
        Date() > dueDate && !isCompleted
    }

    func incrementProgress() {
        guard currentProgress < targetCount else { return }
        currentProgress += 1
        if currentProgress >= targetCount {
            isCompleted = true
            completedDate = Date()
        }
    }
}
