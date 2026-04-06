import Foundation
import SwiftData

@Model
final class PanicEvent {
    var id: UUID
    var date: Date
    var intensityBefore: Int // 1-10
    var intensityAfter: Int // 1-10
    var duration: TimeInterval // seconds
    var techniquesUsed: [String]
    var triggers: [String]
    var notes: String
    var resolved: Bool

    init(
        intensityBefore: Int = 8,
        intensityAfter: Int = 5,
        duration: TimeInterval = 0,
        techniquesUsed: [String] = [],
        triggers: [String] = [],
        notes: String = "",
        resolved: Bool = false
    ) {
        self.id = UUID()
        self.date = Date()
        self.intensityBefore = intensityBefore
        self.intensityAfter = intensityAfter
        self.duration = duration
        self.techniquesUsed = techniquesUsed
        self.triggers = triggers
        self.notes = notes
        self.resolved = resolved
    }
}
