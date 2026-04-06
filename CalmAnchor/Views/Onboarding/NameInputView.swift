import SwiftUI

struct NameInputView: View {
    @Binding var calmName: String
    let onNext: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.moon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppConstants.Colors.softLavender)
                    .symbolEffect(.pulse)

                Text("What should we call\nyour calmest self?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("This is the version of you we're building toward")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.stormGray)
                    .multilineTextAlignment(.center)
            }

            TextField("", text: $calmName, prompt: Text("Your name...").foregroundStyle(.white.opacity(0.4)))
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppConstants.Colors.calmBlue.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 40)
                .focused($isFocused)
                .onSubmit { onNext() }

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
        .onAppear { isFocused = true }
    }
}
