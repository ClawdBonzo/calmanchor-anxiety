import SwiftUI

struct SplashOnboardingView: View {
    let onNext: () -> Void
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButton = false
    @State private var breatheScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Onboarding illustration
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color(hex: "00C9B7").opacity(0.1 - Double(i) * 0.03))
                        .frame(width: 240 + CGFloat(i) * 40)
                        .scaleEffect(breatheScale)
                }

                Image("Onboarding-1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color(hex: "00C9B7").opacity(0.3), radius: 16, y: 8)
                    .scaleEffect(breatheScale)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    breatheScale = 1.05
                }
            }

            VStack(spacing: 16) {
                Text("CalmAnchor")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(animateTitle ? 1 : 0)
                    .offset(y: animateTitle ? 0 : 20)

                Text("Your personal anxiety recovery companion")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "D4A574"))
                    .multilineTextAlignment(.center)
                    .opacity(animateSubtitle ? 1 : 0)
                    .offset(y: animateSubtitle ? 0 : 15)
            }

            Spacer()

            Button(action: onNext) {
                HStack(spacing: 12) {
                    Text("Start Your Calm Life")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "00C9B7"), Color(hex: "0D3B4F")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "00C9B7").opacity(0.4), radius: 12, y: 6)
            }
            .opacity(animateButton ? 1 : 0)
            .offset(y: animateButton ? 0 : 30)
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) { animateTitle = true }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) { animateSubtitle = true }
            withAnimation(.easeOut(duration: 0.8).delay(1.0)) { animateButton = true }
        }
    }
}
