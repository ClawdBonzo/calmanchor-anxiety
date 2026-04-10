import SwiftUI

struct SplashOnboardingView: View {
    let onNext: () -> Void

    @State private var heroScale: CGFloat = 0.88
    @State private var heroOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 24
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 28
    @State private var breatheScale: CGFloat = 1.0
    @State private var beginTap = false
    @State private var particle1Offset: CGSize = .zero
    @State private var particle2Offset: CGSize = .zero
    @State private var particle3Offset: CGSize = .zero

    var body: some View {
        ZStack {
            // Ambient floating particles
            ambientParticles

            VStack(spacing: 0) {
                Spacer()

                // Hero image with breathing glow rings
                ZStack {
                    // Outer glow rings
                    ForEach(0..<4) { i in
                        Circle()
                            .fill(Color(hex: "00C9B7").opacity(0.06 - Double(i) * 0.012))
                            .frame(width: 260 + CGFloat(i) * 38)
                            .scaleEffect(breatheScale + CGFloat(i) * 0.01)
                    }

                    // Hero image
                    Image("Onboarding-1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 220, height: 220)
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "00C9B7").opacity(0.45), radius: 24, y: 8)
                        .scaleEffect(breatheScale)
                }
                .scaleEffect(heroScale)
                .opacity(heroOpacity)
                .padding(.bottom, 36)

                // Title stack
                VStack(spacing: 12) {
                    Text("CalmAnchor")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(-0.5)

                    Text("Your anchor in the storm")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "D4A574"))

                    Text("Anxiety recovery, one breath at a time.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)

                Spacer()

                // CTA button
                Button(action: { beginTap.toggle(); onNext() }) {
                    HStack(spacing: 10) {
                        Text("Begin Your Calm Journey")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "00C9B7"), Color(hex: "0D3B4F")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color(hex: "00C9B7").opacity(0.5), radius: 16, y: 6)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: beginTap)
                .opacity(buttonOpacity)
                .offset(y: buttonOffset)
                .padding(.horizontal, 28)
                .padding(.bottom, 54)
            }
        }
        .onAppear { runEntrance() }
    }

    // MARK: - Ambient Particles

    private var ambientParticles: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "00C9B7").opacity(0.07))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .offset(particle1Offset)
                .position(x: 60, y: 180)

            Circle()
                .fill(Color(hex: "D4A574").opacity(0.06))
                .frame(width: 80, height: 80)
                .blur(radius: 16)
                .offset(particle2Offset)
                .position(x: 340, y: 300)

            Circle()
                .fill(Color(hex: "5B9BD5").opacity(0.07))
                .frame(width: 100, height: 100)
                .blur(radius: 18)
                .offset(particle3Offset)
                .position(x: 200, y: 650)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Animation Sequence

    private func runEntrance() {
        // Breathing loop
        withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
            breatheScale = 1.06
        }

        // Particle drift
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            particle1Offset = CGSize(width: 18, height: -24)
        }
        withAnimation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true).delay(1)) {
            particle2Offset = CGSize(width: -20, height: 16)
        }
        withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true).delay(0.5)) {
            particle3Offset = CGSize(width: 14, height: -18)
        }

        // Entrance sequence
        withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.1)) {
            heroScale = 1.0
            heroOpacity = 1.0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.45)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.8)) {
            subtitleOpacity = 1.0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(1.0)) {
            buttonOpacity = 1.0
            buttonOffset = 0
        }
    }
}
