import SwiftUI

struct NameInputView: View {
    @Binding var calmName: String
    let onNext: () -> Void
    @FocusState private var isFocused: Bool

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var fieldGlow = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated anchor icon — no logo repeat
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(AppConstants.Colors.sereneTeal.opacity(0.08 - Double(i) * 0.025))
                        .frame(width: 90 + CGFloat(i) * 28)
                        .scaleEffect(fieldGlow ? 1.04 : 1.0)
                }
                Text("✨")
                    .font(.system(size: 52))
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            .frame(height: 110)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: fieldGlow)
            .padding(.bottom, 28)

            // Text content
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
            .opacity(contentOpacity)
            .offset(y: contentOffset)

            Spacer().frame(height: 32)

            // Text field with glow border
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
                            isFocused
                                ? AppConstants.Colors.sereneTeal
                                : AppConstants.Colors.calmBlue.opacity(0.35),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .shadow(color: isFocused ? AppConstants.Colors.sereneTeal.opacity(0.3) : .clear,
                        radius: 12, y: 0)
                .padding(.horizontal, 32)
                .focused($isFocused)
                .onSubmit { if !calmName.trimmingCharacters(in: .whitespaces).isEmpty { onNext() } }
                .opacity(contentOpacity)
                .offset(y: contentOffset)
                .animation(.easeOut(duration: 0.2), value: isFocused)

            Spacer()

            // Continue button
            Button(action: onNext) {
                Text(calmName.trimmingCharacters(in: .whitespaces).isEmpty ? "Continue as Friend" : "Continue as \(calmName)")
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
            .opacity(contentOpacity)
        }
        .onAppear {
            fieldGlow = true
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.75).delay(0.25)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isFocused = true }
        }
    }
}
