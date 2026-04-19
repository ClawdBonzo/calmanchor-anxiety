import SwiftUI

struct NameInputView: View {
    @Binding var calmName: String
    let onNext: () -> Void
    @FocusState private var isFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon — SF Symbol, guaranteed to render
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color(hex: "00C9B7").opacity(0.10 - Double(i) * 0.03))
                        .frame(width: 100 + CGFloat(i) * 30)
                        .scaleEffect(pulseScale + CGFloat(i) * 0.01)
                }
                Circle()
                    .fill(Color(hex: "00C9B7").opacity(0.18))
                    .frame(width: 88)
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(Color(hex: "00C9B7"))
            }
            .frame(height: 130)
            .scaleEffect(appeared ? 1.0 : 0.6)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.65, dampingFraction: 0.65).delay(0.1), value: appeared)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 3.5).repeatForever(autoreverses: true),
                value: pulseScale
            )
            .padding(.bottom, 32)

            // Heading
            VStack(spacing: 10) {
                Text("What should we call\nyour calmest self?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .tracking(-0.3)

                Text("This is the version of you we're building toward")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.stormGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2), value: appeared)

            Spacer().frame(height: 36)

            // Text field
            TextField("", text: $calmName,
                      prompt: Text("Your name…").foregroundStyle(.white.opacity(0.3)))
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 18)
                .padding(.horizontal, 24)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isFocused ? Color(hex: "00C9B7") : AppConstants.Colors.calmBlue.opacity(0.4),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .shadow(color: isFocused ? Color(hex: "00C9B7").opacity(0.3) : .clear, radius: 14)
                .padding(.horizontal, 28)
                .focused($isFocused)
                .onSubmit { onNext() }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3), value: appeared)
                .animation(.easeOut(duration: 0.2), value: isFocused)

            Spacer()

            // CTA
            Button(action: { isFocused = false; onNext() }) {
                HStack(spacing: 8) {
                    Text(calmName.trimmingCharacters(in: .whitespaces).isEmpty
                         ? "Continue as Friend"
                         : "Continue as \(calmName)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
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
                .shadow(color: AppConstants.Colors.calmBlue.opacity(0.45), radius: 12, y: 5)
            }
            .sensoryFeedback(.selection, trigger: calmName)
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4), value: appeared)
        }
        .onTapGesture { isFocused = false }
        .onAppear {
            appeared = true
            if !reduceMotion { pulseScale = 1.05 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                isFocused = true
            }
        }
        .onDisappear { isFocused = false }
    }
}
