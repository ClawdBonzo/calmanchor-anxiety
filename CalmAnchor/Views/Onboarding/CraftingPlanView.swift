import SwiftUI

struct CraftingPlanView: View {
    let calmName: String
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress1: CGFloat = 0
    @State private var progress2: CGFloat = 0
    @State private var progress3: CGFloat = 0
    @State private var showComplete = false
    @State private var currentLabel = "Analyzing your triggers…"
    @State private var orbitAngle: Double = 0
    @State private var appeared = false

    private let labels = [
        "Analyzing your triggers…",
        "Building breathing exercises…",
        "Creating your 30-Day Peace Plan…"
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated loader / checkmark
            ZStack {
                // Orbit ring
                if !showComplete {
                    Circle()
                        .stroke(AppConstants.Colors.calmBlue.opacity(0.15), lineWidth: 2)
                        .frame(width: 130, height: 130)

                    Circle()
                        .fill(AppConstants.Colors.mintGreen)
                        .frame(width: 10, height: 10)
                        .offset(x: 65)
                        .rotationEffect(.degrees(orbitAngle))
                        .animation(
                            reduceMotion ? nil : .linear(duration: 2).repeatForever(autoreverses: false),
                            value: orbitAngle
                        )
                }

                if showComplete {
                    ZStack {
                        Circle()
                            .fill(AppConstants.Colors.mintGreen.opacity(0.18))
                            .frame(width: 110, height: 110)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(AppConstants.Colors.mintGreen)
                    }
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    ZStack {
                        Circle()
                            .fill(AppConstants.Colors.calmBlue.opacity(0.12))
                            .frame(width: 110, height: 110)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 44))
                            .foregroundStyle(AppConstants.Colors.calmBlue)
                            .symbolEffect(.pulse, isActive: !reduceMotion)
                    }
                }
            }
            .frame(height: 140)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.7)

            Spacer().frame(height: 28)

            // Title
            VStack(spacing: 8) {
                Text("Crafting your personalized\nPeace Plan\(calmName.isEmpty ? "" : " for \(calmName)")…")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .tracking(-0.2)

                Text(currentLabel)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.softLavender)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: currentLabel)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer().frame(height: 36)

            // Progress bars
            VStack(spacing: 18) {
                ProgressBarRow(label: "Trigger Analysis",    progress: progress1, icon: "brain.head.profile")
                ProgressBarRow(label: "Breathing Exercises", progress: progress2, icon: "wind")
                ProgressBarRow(label: "30-Day Peace Plan",   progress: progress3, icon: "calendar")
            }
            .padding(.horizontal, 36)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            if showComplete {
                Button(action: onNext) {
                    HStack(spacing: 10) {
                        Text("See Your Plan")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [AppConstants.Colors.mintGreen, AppConstants.Colors.sereneTeal],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppConstants.Colors.mintGreen.opacity(0.45), radius: 14, y: 5)
                }
                .padding(.horizontal, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 52)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) { appeared = true }
            if !reduceMotion { orbitAngle = 360 }
            startAnimation()
        }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.5)) { progress1 = 1.0 }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1200))
            withAnimation { currentLabel = labels[1] }
            withAnimation(.easeInOut(duration: 1.5)) { progress2 = 1.0 }

            try? await Task.sleep(for: .milliseconds(1300))
            withAnimation { currentLabel = labels[2] }
            withAnimation(.easeInOut(duration: 1.5)) { progress3 = 1.0 }

            try? await Task.sleep(for: .milliseconds(1700))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                showComplete = true
                currentLabel = "Your Peace Plan is ready!"
            }
        }
    }
}

struct ProgressBarRow: View {
    let label: String
    let progress: CGFloat
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppConstants.Colors.calmBlue)
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(progress >= 1 ? AppConstants.Colors.mintGreen : AppConstants.Colors.calmBlue)
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [AppConstants.Colors.calmBlue,
                                     progress >= 1 ? AppConstants.Colors.mintGreen : AppConstants.Colors.calmBlue],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}
