import SwiftUI

// MARK: - Shared ambient background used across all screens
// Midnight navy base + slowly drifting teal/rose-gold blobs + anchor particle glows

struct AnchorBackground: View {
    @State private var blob1 = false
    @State private var blob2 = false
    @State private var blob3 = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "080E1C"),
                    Color(hex: "0D1F35"),
                    Color(hex: "091828")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Teal blob — top center
            Ellipse()
                .fill(AppConstants.Colors.electricTeal.opacity(0.09))
                .frame(width: 380, height: 220)
                .blur(radius: 70)
                .offset(x: blob1 ? 20 : -20, y: blob1 ? -180 : -140)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: blob1)

            // Rose-gold blob — bottom right
            Ellipse()
                .fill(AppConstants.Colors.roseGold.opacity(0.07))
                .frame(width: 320, height: 200)
                .blur(radius: 65)
                .offset(x: blob2 ? 80 : 40, y: blob2 ? 260 : 200)
                .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true).delay(1.5), value: blob2)

            // Mid teal blob — left
            Ellipse()
                .fill(AppConstants.Colors.electricTeal.opacity(0.05))
                .frame(width: 260, height: 160)
                .blur(radius: 55)
                .offset(x: blob3 ? -100 : -60, y: blob3 ? 40 : 80)
                .animation(.easeInOut(duration: 13).repeatForever(autoreverses: true).delay(3), value: blob3)

            // Anchor glow particle — subtle, top
            Circle()
                .fill(AppConstants.Colors.electricTeal.opacity(0.04))
                .frame(width: 120, height: 120)
                .blur(radius: 30)
                .scaleEffect(glowPulse ? 1.3 : 1.0)
                .offset(x: 60, y: -80)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: glowPulse)

            // Rose-gold accent particle — bottom left
            Circle()
                .fill(AppConstants.Colors.roseGold.opacity(0.05))
                .frame(width: 90, height: 90)
                .blur(radius: 25)
                .scaleEffect(glowPulse ? 1.2 : 0.9)
                .offset(x: -80, y: 160)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true).delay(2), value: glowPulse)
        }
        .ignoresSafeArea()
        .onAppear {
            blob1 = true
            blob2 = true
            blob3 = true
            glowPulse = true
        }
    }
}

// MARK: - View modifier for consistent dark card styling

struct GlassCard: ViewModifier {
    var glow: Color = .clear
    var glowRadius: CGFloat = 0
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.09), lineWidth: 1)
            )
            .shadow(color: glow.opacity(glowRadius > 0 ? 0.25 : 0), radius: glowRadius, y: 3)
    }
}

extension View {
    func glassCard(glow: Color = .clear, glowRadius: CGFloat = 0, cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCard(glow: glow, glowRadius: glowRadius, cornerRadius: cornerRadius))
    }
}
