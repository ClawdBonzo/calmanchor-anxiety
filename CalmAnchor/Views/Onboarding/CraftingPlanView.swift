import SwiftUI

struct CraftingPlanView: View {
    let calmName: String
    let onNext: () -> Void

    @State private var progress1: CGFloat = 0
    @State private var progress2: CGFloat = 0
    @State private var progress3: CGFloat = 0
    @State private var showComplete = false
    @State private var currentLabel = "Analyzing your triggers..."

    private let labels = [
        "Analyzing your triggers...",
        "Building breathing exercises...",
        "Creating your Peace Plan..."
    ]

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppConstants.Colors.calmBlue.opacity(0.15))
                        .frame(width: 120, height: 120)

                    if showComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(AppConstants.Colors.mintGreen)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(2)
                    }
                }

                Text("Crafting your personalized\nPeace Plan for \(calmName.isEmpty ? "you" : calmName)...")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(currentLabel)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.softLavender)
                    .contentTransition(.numericText())
            }

            VStack(spacing: 20) {
                ProgressBarRow(label: "Trigger Analysis", progress: progress1, icon: "brain.head.profile")
                ProgressBarRow(label: "Breathing Exercises", progress: progress2, icon: "wind")
                ProgressBarRow(label: "30-Day Peace Plan", progress: progress3, icon: "calendar")
            }
            .padding(.horizontal, 40)

            Spacer()

            if showComplete {
                Button(action: onNext) {
                    HStack(spacing: 12) {
                        Text("See Your Plan")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [AppConstants.Colors.mintGreen, AppConstants.Colors.sereneTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 60)
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Progress bar 1
        withAnimation(.easeInOut(duration: 1.5)) { progress1 = 1.0 }

        // Progress bar 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { currentLabel = labels[1] }
            withAnimation(.easeInOut(duration: 1.5)) { progress2 = 1.0 }
        }

        // Progress bar 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { currentLabel = labels[2] }
            withAnimation(.easeInOut(duration: 1.5)) { progress3 = 1.0 }
        }

        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(AppConstants.Colors.calmBlue)
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppConstants.Colors.calmBlue)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [AppConstants.Colors.calmBlue, AppConstants.Colors.mintGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
        }
    }
}
