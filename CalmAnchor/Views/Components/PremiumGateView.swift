import SwiftUI

struct PremiumGateView: View {
    let feature: String
    let icon: String
    let description: String
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppConstants.Colors.sunsetGold.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AppConstants.Colors.sunsetGold)
            }

            VStack(spacing: 8) {
                Text(feature)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onUpgrade) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Unlock with Premium")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color(hex: "080E1C"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppConstants.Colors.sunsetGold)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppConstants.Colors.sunsetGold.opacity(0.4), radius: 12, y: 4)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "080E1C"))
    }
}
