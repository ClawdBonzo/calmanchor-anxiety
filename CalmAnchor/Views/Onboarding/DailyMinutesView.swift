import SwiftUI

struct DailyMinutesView: View {
    @Binding var dailyMinutes: Int
    let onNext: () -> Void

    private let options = [5, 10, 15, 20, 30]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppConstants.Colors.sunsetGold)
                    .symbolEffect(.pulse)

                Text("How many minutes\nper day for healing?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Even 5 minutes daily can transform your anxiety")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.stormGray)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { minutes in
                    Button(action: { dailyMinutes = minutes }) {
                        HStack {
                            Image(systemName: dailyMinutes == minutes ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(
                                    dailyMinutes == minutes ? AppConstants.Colors.mintGreen : .white.opacity(0.4)
                                )
                                .font(.system(size: 22))

                            Text("\(minutes) minutes")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)

                            Spacer()

                            Text(minuteLabel(minutes))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppConstants.Colors.stormGray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(dailyMinutes == minutes ? AppConstants.Colors.calmBlue.opacity(0.2) : .white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(dailyMinutes == minutes ? AppConstants.Colors.calmBlue.opacity(0.5) : .clear, lineWidth: 1.5)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: dailyMinutes)
                }
            }
            .padding(.horizontal, 32)

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

    private func minuteLabel(_ m: Int) -> String {
        switch m {
        case 5: return "Quick & gentle"
        case 10: return "Recommended"
        case 15: return "Balanced"
        case 20: return "Deep work"
        case 30: return "Full immersion"
        default: return ""
        }
    }
}
