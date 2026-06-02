import SwiftUI

/// Soft pre-prompt: we only trigger the real iOS permission request when the
/// user taps "Enable Reminders", so we never burn the one-shot system prompt
/// on undecided users.
struct NotificationOptInView: View {
    @Binding var notificationsEnabled: Bool
    @Binding var reminderTime: Date
    let onNext: () -> Void

    @State private var requesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Color(hex: "00C9B7"))
                .shadow(color: Color(hex: "00C9B7").opacity(0.4), radius: 16)
                .padding(.bottom, 28)

            Text("Stay anchored every day")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("A gentle daily nudge keeps your streak alive and your calm on track.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 10)

            VStack(spacing: 16) {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Daily reminder", systemImage: "bell.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .tint(Color(hex: "00C9B7"))

                DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                    Label("Remind me at", systemImage: "clock.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .tint(Color(hex: "00C9B7"))
                .disabled(!notificationsEnabled)
                .opacity(notificationsEnabled ? 1 : 0.4)
            }
            .padding(18)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 28)
            .padding(.top, 32)

            Spacer()

            Button(action: { Task { await primaryTapped() } }) {
                Text(notificationsEnabled ? "Enable Reminders" : "Continue")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppConstants.Gradients.cta)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(requesting)
            .padding(.horizontal, 28)

            Button("Maybe later") {
                notificationsEnabled = false
                onNext()
            }
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
    }

    private func primaryTapped() async {
        requesting = true
        if notificationsEnabled {
            let granted = await NotificationService.shared.requestAuthorization()
            notificationsEnabled = granted    // reflect the real OS decision
        }
        requesting = false
        onNext()
    }
}
