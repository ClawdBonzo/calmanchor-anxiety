import SwiftUI
import UIKit

/// "Dawn over the harbor": the night sea (where panic happens) warming into
/// rose-gold dawn (where calm arrives). Every new surface draws from here so
/// the app, share cards and store art read as one family.
enum CalmBrand {
    // MARK: Night sea
    static let abyss    = Color(hex: "050A14")
    static let midnight = Color(hex: "080E1C")
    static let deepSea  = Color(hex: "0F1E30")
    static let harbor   = Color(hex: "16324F")
    static let tide     = Color(hex: "1E4B6B")

    // MARK: Dawn
    static let mauve     = Color(hex: "6B5476")
    static let roseDawn  = Color(hex: "D99A8E")
    static let peach     = Color(hex: "F4C2A1")
    static let roseGold  = Color(hex: "C09678")
    static let roseLight = Color(hex: "E8B49A")
    static let gold      = Color(hex: "F5D76E")
    static let coral     = Color(hex: "E8A0A0")

    // MARK: Sea glass
    static let teal     = Color(hex: "00C9B7")
    static let neonTeal = Color(hex: "00F0E0")
    static let mint     = Color(hex: "A8D5BA")
    static let lilac    = Color(hex: "B8A9C9")
    static let sky      = Color(hex: "5B9BD5")

    // MARK: Text
    static let paper  = Color(hex: "F7F2EA")
    static let mist   = Color(hex: "9DAEC6")

    /// Hero/poster gradient, top-leading → bottom-trailing.
    static let dawn: [Color] = [midnight, harbor, mauve, roseDawn, peach]
    /// Warm highlight used for XP, medallions and accent words.
    static let accent: [Color] = [gold, roseLight, coral]
    /// Primary action (the teal the app already uses for CTAs).
    static let action: [Color] = [neonTeal, teal]
    static let celebration: [Color] = [gold, roseLight, coral, teal, mint, lilac, paper]

    static var accentGradient: LinearGradient {
        LinearGradient(colors: accent, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var dawnGradient: LinearGradient {
        LinearGradient(colors: dawn, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Type

extension Font {
    static func calmDisplay(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    /// Rounded black with tabular digits so counters don't jitter.
    static func calmNumber(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded).monospacedDigit()
    }
}

/// Small uppercase eyebrow ("ANCHOR PASS · GOLD").
struct Kicker: View {
    let text: String
    var color: Color = CalmBrand.gold
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(2)
            .foregroundStyle(color)
    }
}

// MARK: - Haptics

@MainActor
enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    /// The "medallion lands" thud.
    static func drop() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1) }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7) }
}

// MARK: - Motion

enum CalmMotion {
    static let pop = Animation.spring(response: 0.55, dampingFraction: 0.62)
    static let slam = Animation.spring(response: 0.28, dampingFraction: 0.5)
    static let gentle = Animation.easeInOut(duration: 0.35)
}

// MARK: - Accent-gradient text

extension View {
    /// Fills text (or any shape) with the warm dawn accent gradient.
    func accentFill() -> some View {
        self.foregroundStyle(CalmBrand.accentGradient)
    }
}
