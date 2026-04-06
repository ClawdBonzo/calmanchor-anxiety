import SwiftUI
import SwiftData

struct PanicSOSView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var currentPhase: SOSPhase = .grounding
    @State private var breathCount = 0
    @State private var isBreathing = false
    @State private var breathScale: CGFloat = 0.6
    @State private var breathLabel = "Breathe In"
    @State private var secondsElapsed: TimeInterval = 0
    @State private var intensityBefore: Int = 8
    @State private var intensityAfter: Int = 5
    @State private var currentAffirmation = AppConstants.affirmations.first ?? ""
    @State private var affirmationIndex = 0
    @State private var timer: Timer?
    @State private var breathTimer: Timer?

    enum SOSPhase {
        case grounding, breathing, affirmations, complete
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { completeSession() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(20)
                }

                switch currentPhase {
                case .grounding:
                    groundingView
                case .breathing:
                    breathingView
                case .affirmations:
                    affirmationsView
                case .complete:
                    completeView
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimers() }
    }

    // MARK: - Grounding (5-4-3-2-1)
    private var groundingView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppConstants.Colors.sereneTeal)
                .symbolEffect(.breathe)

            Text("5-4-3-2-1 Grounding")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 18) {
                GroundingRow(count: 5, sense: "things you can SEE", icon: "eye.fill")
                GroundingRow(count: 4, sense: "things you can TOUCH", icon: "hand.point.up.fill")
                GroundingRow(count: 3, sense: "things you can HEAR", icon: "ear.fill")
                GroundingRow(count: 2, sense: "things you can SMELL", icon: "nose.fill")
                GroundingRow(count: 1, sense: "thing you can TASTE", icon: "mouth.fill")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                withAnimation { currentPhase = .breathing }
                startBreathing()
            }) {
                Text("I'm grounded. Next: Breathing")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppConstants.Colors.sereneTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Breathing
    private var breathingView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(breathLabel)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .contentTransition(.numericText())

            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(AppConstants.Colors.calmBlue.opacity(0.12 - Double(i) * 0.03))
                        .frame(width: 200 + CGFloat(i) * 50)
                        .scaleEffect(breathScale)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppConstants.Colors.calmBlue, AppConstants.Colors.sereneTeal.opacity(0.5)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(breathScale)

                Text("🫁")
                    .font(.system(size: 48))
                    .scaleEffect(breathScale)
            }

            Text("Breath \(breathCount) of 6")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            if breathCount >= 6 {
                Button(action: {
                    stopBreathTimer()
                    withAnimation { currentPhase = .affirmations }
                }) {
                    Text("Continue to Affirmations")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppConstants.Colors.calmBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 50)
        }
    }

    // MARK: - Affirmations
    private var affirmationsView: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(AppConstants.Colors.sunsetGold)
                .symbolEffect(.variableColor)

            Text(currentAffirmation)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .contentTransition(.opacity)

            Button(action: nextAffirmation) {
                Label("Next Affirmation", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button(action: { withAnimation { currentPhase = .complete } }) {
                Text("I Feel Calmer Now")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppConstants.Colors.mintGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Complete
    private var completeView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(AppConstants.Colors.mintGreen)
                .symbolEffect(.bounce)

            Text("You did it!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("You navigated through the storm.\nEvery time you use these tools, you grow stronger.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 14) {
                Text("How intense is your anxiety now?")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))

                Slider(value: Binding(get: { Double(intensityAfter) }, set: { intensityAfter = Int($0) }),
                       in: 1...10, step: 1)
                .tint(AppConstants.Colors.mintGreen)
                .padding(.horizontal, 40)

                Text("\(intensityAfter)/10")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.mintGreen)
            }

            Spacer()

            Button(action: { completeSession() }) {
                Text("Close & Return")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppConstants.Colors.calmBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Helpers
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            secondsElapsed += 1
        }
    }

    private func startBreathing() {
        breathCount = 0
        runBreathCycle()
    }

    private func runBreathCycle() {
        guard breathCount < 6 else { return }

        // Inhale 4s
        breathLabel = "Breathe In..."
        withAnimation(.easeInOut(duration: 4)) { breathScale = 1.0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            // Hold 4s
            breathLabel = "Hold..."

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                // Exhale 4s
                breathLabel = "Breathe Out..."
                withAnimation(.easeInOut(duration: 4)) { breathScale = 0.6 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    breathCount += 1
                    if breathCount < 6 {
                        runBreathCycle()
                    } else {
                        breathLabel = "Well done!"
                    }
                }
            }
        }
    }

    private func stopBreathTimer() {
        breathTimer?.invalidate()
        breathTimer = nil
    }

    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        stopBreathTimer()
    }

    private func nextAffirmation() {
        affirmationIndex = (affirmationIndex + 1) % AppConstants.affirmations.count
        withAnimation { currentAffirmation = AppConstants.affirmations[affirmationIndex] }
    }

    private func completeSession() {
        let event = PanicEvent(
            intensityBefore: intensityBefore,
            intensityAfter: intensityAfter,
            duration: secondsElapsed,
            techniquesUsed: ["5-4-3-2-1 Grounding", "Box Breathing", "Affirmations"],
            resolved: true
        )
        modelContext.insert(event)
        stopTimers()
        withAnimation { isPresented = false }
    }
}

struct GroundingRow: View {
    let count: Int
    let sense: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppConstants.Colors.sereneTeal.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text("\(count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.sereneTeal)
            }

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.white.opacity(0.6))
                Text(sense)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}
