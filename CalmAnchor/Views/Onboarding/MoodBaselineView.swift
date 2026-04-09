import SwiftUI

struct MoodBaselineView: View {
    @Binding var baselineMood: Int
    let onNext: () -> Void

    @State private var appeared = false
    @State private var imageScale: CGFloat = 0.8

    private let moodEmojis = ["😰","😟","😔","😕","😐","🙂","😊","😌","😄","🌟"]

    private var trackColor: Color {
        switch baselineMood {
        case 1...3: return AppConstants.Colors.gentleCoral
        case 4...6: return AppConstants.Colors.calmBlue
        default:    return AppConstants.Colors.mintGreen
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero image with mood emoji overlay
            ZStack(alignment: .bottomTrailing) {
                Image("Onboarding-3")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(trackColor.opacity(0.6), lineWidth: 2.5))
                    .shadow(color: trackColor.opacity(0.4), radius: 16, y: 4)
                    .animation(.easeInOut(duration: 0.4), value: trackColor)

                // Mood emoji badge
                Text(moodEmojis[baselineMood - 1])
                    .font(.system(size: 32))
                    .padding(4)
                    .background(Circle().fill(Color(hex: "0D2840")))
                    .overlay(Circle().stroke(trackColor.opacity(0.4), lineWidth: 1.5))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: baselineMood)
            }
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.7, dampingFraction: 0.68).delay(0.1), value: appeared)
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
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2), value: appeared)

            Spacer().frame(height: 36)

            // Slider section
            VStack(spacing: 14) {
                HStack {
                    Text("Anxious")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppConstants.Colors.gentleCoral)
                    Spacer()
                    Text("Level \(baselineMood) of 10")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
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
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3), value: appeared)

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
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4), value: appeared)
        }
        .onAppear { appeared = true }
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
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.12))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [AppConstants.Colors.gentleCoral,
                                     AppConstants.Colors.calmBlue,
                                     AppConstants.Colors.mintGreen],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(thumbX + 15, 15), height: 8)

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
