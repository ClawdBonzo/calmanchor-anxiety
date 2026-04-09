import Foundation
import SwiftData

@Model
final class Badge {
    @Attribute(.unique) var id: UUID
    var badgeType: String
    var title: String
    var badgeDescription: String
    var icon: String
    var unlockedDate: Date?
    var isUnlocked: Bool = false
    var category: String
    var unlockCriteria: String
    var rarity: String

    init(badgeType: String, title: String, badgeDescription: String, icon: String,
         category: String, unlockCriteria: String, rarity: String) {
        self.id = UUID()
        self.badgeType = badgeType
        self.title = title
        self.badgeDescription = badgeDescription
        self.icon = icon
        self.category = category
        self.unlockCriteria = unlockCriteria
        self.rarity = rarity
    }
}
