import SwiftUI

struct DailyMinutesView: View {
    @Binding var dailyMinutes: Int
    let onNext: () -> Void

    @State private var appeared = false
    private let options = [5, 10, 15, 20, 30]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppConstants.Colors.sunsetGold.opacity(0.15))
                        .frame(width: 96, height: 96)
                    Circle()
                        .fill(AppConstants.Colors.sunsetGold.opacity(0.08))
                        .frame(width: 130, height: 130)
                    Image(systemName: "clock.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(AppConstants.Colors.sunsetGold)
                        .symbolEffect(.pulse)
                }
                .frame(height: 120)

                Text("How many minutes\nper day for healing?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .tracking(-0.3)

                Text("Even 5 minutes daily can transform your anxiety")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.stormGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            .scaleEffect(appeared ? 1.0 : 0.85)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.65, dampingFraction: 0.7).delay(0.1), value: appeared)

            Spacer().frame(height: 28)

            // Options
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { minutes in
                    Button(action: { dailyMinutes = minutes }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(dailyMinutes == minutes
                                          ? AppConstants.Colors.mintGreen
                                          : .white.opacity(0.12))
                                    .frame(width: 26, height: 26)
                                if dailyMinutes == minutes {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: dailyMinutes)

                            Text("\(minutes) minutes")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)

                            Spacer()

                            Text(minuteLabel(minutes))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(dailyMinutes == minutes
                                                 ? AppConstants.Colors.mintGreen
                                                 : AppConstants.Colors.stormGray)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(dailyMinutes == minutes
                                      ? AppConstants.Colors.calmBlue.opacity(0.2)
                                      : .white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(dailyMinutes == minutes
                                        ? AppConstants.Colors.calmBlue.opacity(0.6)
                                        : .clear, lineWidth: 1.5)
                        )
                        .scaleEffect(dailyMinutes == minutes ? 1.01 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: dailyMinutes)
                    }
                    .sensoryFeedback(.selection, trigger: dailyMinutes)
                }
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.25), value: appeared)

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
            .animation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.35), value: appeared)
        }
        .onAppear { appeared = true }
    }

    private func minuteLabel(_ m: Int) -> String {
        switch m {
        case 5:  return "Quick & gentle"
        case 10: return "Recommended"
        case 15: return "Balanced"
        case 20: return "Deep work"
        case 30: return "Full immersion"
        default: return ""
        }
    }
}
