import SwiftUI

struct TriggerQuizView: View {
    @Binding var selectedTriggers: Set<String>
    let onNext: () -> Void

    @State private var appeared = false
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Header with onboarding image
            VStack(spacing: 14) {
                Image("Onboarding-2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "00C9B7").opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: Color(hex: "00C9B7").opacity(0.4), radius: 16, y: 4)
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1 : 0)

                Text("What triggers\nyour anxiety?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .tracking(-0.3)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                Text("Select all that apply — we'll personalize your plan")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.stormGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
            }
            .animation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.1), value: appeared)
            .padding(.bottom, 20)

            // Trigger grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(AppConstants.Triggers.allCases, id: \.label) { trigger in
                        TriggerChip(
                            label: trigger.label,
                            icon: trigger.icon,
                            isSelected: selectedTriggers.contains(trigger.label),
                            action: {
                                if selectedTriggers.contains(trigger.label) {
                                    selectedTriggers.remove(trigger.label)
                                } else {
                                    selectedTriggers.insert(trigger.label)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 8)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.25), value: appeared)

            // CTA
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text(selectedTriggers.isEmpty ? "Skip" : "Continue (\(selectedTriggers.count) selected)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    if !selectedTriggers.isEmpty {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
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
                .shadow(color: AppConstants.Colors.calmBlue.opacity(0.35), radius: 10, y: 4)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTriggers.count)
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)
            .padding(.bottom, 52)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.35), value: appeared)
        }
        .onAppear { appeared = true }
    }
}

struct TriggerChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(isSelected
                          ? AppConstants.Colors.calmBlue.opacity(0.55)
                          : .white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(isSelected ? Color(hex: "00C9B7") : .clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
