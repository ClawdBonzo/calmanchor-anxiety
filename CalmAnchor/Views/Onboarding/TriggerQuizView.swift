import SwiftUI

struct TriggerQuizView: View {
    @Binding var selectedTriggers: Set<String>
    let onNext: () -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppConstants.Colors.warmPeach)

                Text("What triggers\nyour anxiety?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Select all that apply - we'll personalize your plan")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.stormGray)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
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
                .padding(.horizontal, 24)
            }

            Button(action: onNext) {
                Text(selectedTriggers.isEmpty ? "Skip" : "Continue (\(selectedTriggers.count) selected)")
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

struct TriggerChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppConstants.Colors.calmBlue.opacity(0.6) : .white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppConstants.Colors.calmBlue : .clear, lineWidth: 1.5)
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
