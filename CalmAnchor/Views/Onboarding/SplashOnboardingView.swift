import SwiftUI

struct SplashOnboardingView: View {
    let onNext: () -> Void
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButton = false
    @State private var breatheScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Breathing circle animation
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(
                            AppConstants.Colors.calmBlue
                                .opacity(0.15 - Double(i) * 0.04)
                        )
                        .frame(width: 200 + CGFloat(i) * 40)
                        .scaleEffect(breatheScale)
                }

                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppConstants.Colors.mintGreen)
                    .scaleEffect(breatheScale)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    breatheScale = 1.15
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
                    .foregroundStyle(AppConstants.Colors.softLavender)
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
                        colors: [AppConstants.Colors.calmBlue, AppConstants.Colors.sereneTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppConstants.Colors.calmBlue.opacity(0.4), radius: 12, y: 6)
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
