import SwiftUI

struct TriggerQuizView: View {
    @Binding var selectedTriggers: Set<String>
    let onNext: () -> Void

    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = -16
    @State private var gridOpacity: Double = 0
    @State private var gridOffset: CGFloat = 20

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            // Header
            VStack(spacing: 10) {
                ZStack {
                    ForEach(0..<2) { i in
                        Circle()
                            .fill(AppConstants.Colors.gentleCoral.opacity(0.08 - Double(i) * 0.03))
                            .frame(width: 64 + CGFloat(i) * 22)
                    }
                    Text("⚡")
                        .font(.system(size: 36))
                }
                .frame(height: 80)

                Text("What triggers\nyour anxiety?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .tracking(-0.3)

                Text("Select all that apply — we'll personalize your plan")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.stormGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(headerOpacity)
            .offset(y: headerOffset)
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
            .opacity(gridOpacity)
            .offset(y: gridOffset)

            // Continue button
            Button(action: onNext) {
                HStack(spacing: 6) {
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
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.75).delay(0.1)) {
                headerOpacity = 1; headerOffset = 0
            }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.75).delay(0.25)) {
                gridOpacity = 1; gridOffset = 0
            }
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
                    .stroke(isSelected ? AppConstants.Colors.sereneTeal : .clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
