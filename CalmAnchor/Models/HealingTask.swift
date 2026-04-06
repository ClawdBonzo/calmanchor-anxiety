import Foundation
import SwiftData

@Model
final class HealingTask {
    var id: UUID
    var title: String
    var taskDescription: String
    var category: String // breathing, journaling, grounding, movement, mindfulness
    var durationMinutes: Int
    var isCompleted: Bool
    var completedDate: Date?
    var dayNumber: Int // which day of the plan
    var sortOrder: Int

    init(
        title: String,
        taskDescription: String = "",
        category: String = "mindfulness",
        durationMinutes: Int = 5,
        isCompleted: Bool = false,
        dayNumber: Int = 1,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.category = category
        self.durationMinutes = durationMinutes
        self.isCompleted = isCompleted
        self.completedDate = nil
        self.dayNumber = dayNumber
        self.sortOrder = sortOrder
    }
}
