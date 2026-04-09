import SwiftUI

struct MoodBaselineView: View {
    @Binding var baselineMood: Int
    let onNext: () -> Void

    @State private var appeared = false
    @State private var emojiScale: CGFloat = 0.6
    @State private var glowPulse = false

    private let moodEmojis = ["😰","😟","😔","😕","😐","🙂","😊","😌","😄","🌟"]

    private var moodColor: Color {
        switch baselineMood {
        case 1...3: return AppConstants.Colors.gentleCoral
        case 4...6: return AppConstants.Colors.calmBlue
        default:    return AppConstants.Colors.mintGreen
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Emoji with glow ring
            ZStack {
                Circle()
                    .fill(moodColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .scaleEffect(glowPulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: glowPulse)

                Text(moodEmojis[baselineMood - 1])
                    .font(.system(size: 72))
                    .scaleEffect(emojiScale)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: baselineMood)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : -20)
            .padding(.bottom, 28)

            // Text
            VStack(spacing: 10) {
                Text("How are you feeling\nright now?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .tracking(-0.3)

                Text("We'll use this as your starting point")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.stormGray)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)

            Spacer().frame(height: 36)

            // Slider
            VStack(spacing: 14) {
                HStack {
                    Text("Anxious")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppConstants.Colors.gentleCoral)
                    Spacer()
                    Text("Level \(baselineMood) of 10")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .contentTransition(.numericText())
                    Spacer()
                    Text("Peaceful")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppConstants.Colors.mintGreen)
                }
                .padding(.horizontal, 4)

                CustomSlider(value: $baselineMood, range: 1...10)
                    .frame(height: 44)
            }
            .padding(.horizontal, 36)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [AppConstants.Colors.calmBlue, AppConstants.Colors.sereneTeal],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppConstants.Colors.calmBlue.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            glowPulse = true
            withAnimation(.spring(response: 0.7, dampingFraction: 0.68).delay(0.1)) {
                appeared = true
                emojiScale = 1.0
            }
        }
    }
}

struct CustomSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let steps = CGFloat(range.upperBound - range.lowerBound)
            let stepWidth = totalWidth / steps
            let thumbX = CGFloat(value - range.lowerBound) * stepWidth

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.12))
                    .frame(height: 8)

                // Filled track
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [AppConstants.Colors.gentleCoral,
                                     AppConstants.Colors.calmBlue,
                                     AppConstants.Colors.mintGreen],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(thumbX + 16, 16), height: 8)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 30, height: 30)
                    .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
                    .overlay(
                        Circle()
                            .fill(AppConstants.Colors.calmBlue.opacity(0.3))
                            .frame(width: 12, height: 12)
                    )
                    .offset(x: thumbX - 15)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                let newValue = Int(round(g.location.x / stepWidth)) + range.lowerBound
                                value = min(max(newValue, range.lowerBound), range.upperBound)
                            }
                    )
            }
            .frame(height: geometry.size.height)
        }
        .sensoryFeedback(.selection, trigger: value)
    }
}
