import SwiftUI

struct MoodBaselineView: View {
    @Binding var baselineMood: Int
    let onNext: () -> Void

    private let moodEmojis = ["😰", "😟", "😔", "😕", "😐", "🙂", "😊", "😌", "😄", "🌟"]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text(moodEmojis[baselineMood - 1])
                    .font(.system(size: 80))
                    .contentTransition(.numericText())

                Text("How are you feeling\nright now?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("This helps us understand your starting point")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.stormGray)
            }

            VStack(spacing: 16) {
                HStack {
                    Text("Anxious")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppConstants.Colors.gentleCoral)
                    Spacer()
                    Text("Peaceful")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppConstants.Colors.mintGreen)
                }
                .padding(.horizontal, 8)

                CustomSlider(value: $baselineMood, range: 1...10)
                    .frame(height: 44)

                Text("Level \(baselineMood) of 10")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 40)

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
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
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
                    .fill(.white.opacity(0.15))
                    .frame(height: 8)

                // Filled track
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [AppConstants.Colors.gentleCoral, AppConstants.Colors.calmBlue, AppConstants.Colors.mintGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: thumbX + 16, height: 8)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .offset(x: thumbX - 16)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let newValue = Int(round(gesture.location.x / stepWidth)) + range.lowerBound
                                value = min(max(newValue, range.lowerBound), range.upperBound)
                            }
                    )
            }
            .frame(height: geometry.size.height)
        }
        .sensoryFeedback(.selection, trigger: value)
    }
}
