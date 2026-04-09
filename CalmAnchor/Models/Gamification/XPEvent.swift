import Foundation
import SwiftData

@Model
final class XPEvent {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var source: String
    var xpAmount: Int
    var multiplier: Double = 1.0
    var details: String = ""

    init(source: String, xpAmount: Int, multiplier: Double = 1.0, details: String = "") {
        self.id = UUID()
        self.timestamp = Date()
        self.source = source
        self.xpAmount = xpAmount
        self.multiplier = multiplier
        self.details = details
    }

    var finalXP: Int { Int(Double(xpAmount) * multiplier) }
}
