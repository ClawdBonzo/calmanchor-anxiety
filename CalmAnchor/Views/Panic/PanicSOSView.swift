import SwiftUI
import SwiftData

struct PanicSOSView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentPhase: SOSPhase = .grounding
    @State private var breathCount = 0
    @State private var breathScale: CGFloat = 0.6
    @State private var breathLabel = "Breathe In"
    @State private var secondsElapsed: TimeInterval = 0
    @State private var intensityBefore: Int = 8
    @State private var intensityAfter: Int = 5
    @State private var currentAffirmation = AppConstants.affirmations.first ?? ""
    @State private var affirmationIndex = 0

    // Swift 6 / structured concurrency — Tasks replace Timer and DispatchQueue
    @State private var sessionTimerTask: Task<Void, Never>?
    @State private var breathingTask: Task<Void, Never>?

    // Entry flare
    @State private var entryFlare = false
    @State private var flareOpacity: Double = 1

    enum SOSPhase {
        case grounding, breathing, affirmations, complete
    }

    var body: some View {
        ZStack {
            // Background
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "080E1C"), Color(hex: "0D1A2E"), Color(hex: "091828")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Phase-reactive ambient glow
                Circle()
                    .fill(phaseGlowColor.opacity(0.08))
                    .frame(width: 400)
                    .blur(radius: 80)
                    .offset(y: -100)
                    .animation(.easeInOut(duration: 1.5), value: currentPhase)
                    .allowsHitTesting(false)
            }

            // Entry flare (skip when reduce motion is on)
            if !reduceMotion && flareOpacity > 0 {
                ZStack {
                    ForEach(0..<5) { i in
                        Circle()
                            .stroke(Color.red.opacity(max(0, 0.35 - Double(i) * 0.06)), lineWidth: 2)
                            .frame(width: 60 + CGFloat(i) * 50)
                            .scaleEffect(entryFlare ? 3.5 + CGFloat(i) * 0.4 : 1.0)
                            .opacity(entryFlare ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.2).delay(Double(i) * 0.12),
                                value: entryFlare
                            )
                    }
                }
                .opacity(flareOpacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }

            // Main content
            VStack(spacing: 0) {
                // Header: phase dots + dismiss
                HStack {
                    HStack(spacing: 6) {
                        ForEach(SOSPhase.allCases, id: \.rawValue) { phase in
                            Circle()
                                .fill(phase == currentPhase
                                      ? phaseGlowColor
                                      : .white.opacity(phaseIndex(phase) < phaseIndex(currentPhase) ? 0.35 : 0.12))
                                .frame(
                                    width: phase == currentPhase ? 10 : 7,
                                    height: phase == currentPhase ? 10 : 7
                                )
                                .animation(
                                    reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                                    value: currentPhase
                                )
                        }
                    }
                    .accessibilityLabel("Step \(phaseIndex(currentPhase) + 1) of 4")

                    Spacer()

                    Button(action: { completeSession() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: isPresented)
                    .accessibilityLabel("Close panic support")
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)

                switch currentPhase {
                case .grounding:    groundingView
                case .breathing:    breathingView
                case .affirmations: affirmationsView
                case .complete:     completeView
                }
            }
        }
        .onAppear {
            startSessionTimer()
            if !reduceMotion {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(50))
                    withAnimation { entryFlare = true }
                    try? await Task.sleep(for: .milliseconds(1400))
                    withAnimation(.easeOut(duration: 0.4)) { flareOpacity = 0 }
                }
            } else {
                flareOpacity = 0  // skip flare immediately
            }
        }
        .onDisappear { stopAllTasks() }
    }

    // MARK: - Grounding (5-4-3-2-1)

    private var groundingView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppConstants.Colors.electricTeal.opacity(0.1))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(AppConstants.Colors.electricTeal.opacity(0.05))
                    .frame(width: 145, height: 145)
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppConstants.Colors.electricTeal, AppConstants.Colors.sereneTeal],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: AppConstants.Colors.electricTeal.opacity(0.5), radius: 16, y: 4)
                    .symbolEffect(.breathe, isActive: !reduceMotion)
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("5-4-3-2-1 Grounding")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Anchor yourself in the present")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }

            VStack(alignment: .leading, spacing: 14) {
                GroundingRow(count: 5, sense: "things you can SEE",   icon: "eye.fill")
                GroundingRow(count: 4, sense: "things you can TOUCH", icon: "hand.point.up.fill")
                GroundingRow(count: 3, sense: "things you can HEAR",  icon: "ear.fill")
                GroundingRow(count: 2, sense: "things you can SMELL", icon: "nose.fill")
                GroundingRow(count: 1, sense: "thing you can TASTE",  icon: "mouth.fill")
            }
            .padding(.horizontal, 28)

            Spacer()

            ctaButton(label: "I'm grounded. Next: Breathing", color: AppConstants.Colors.electricTeal) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { currentPhase = .breathing }
                startBreathing()
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: currentPhase)
        }
    }

    // MARK: - Breathing (box breathing 4-4-4)

    private var breathingView: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(breathLabel)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: breathLabel)
                .accessibilityLabel("Breathing instruction: \(breathLabel)")

            // Breathing orb
            ZStack {
                if !reduceMotion {
                    ForEach(0..<4) { i in
                        Circle()
                            .fill(AppConstants.Colors.calmBlue.opacity(0.06 - Double(i) * 0.01))
                            .frame(width: 180 + CGFloat(i) * 40)
                            .scaleEffect(breathScale)
                            .animation(.easeInOut(duration: 4), value: breathScale)
                    }
                }
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppConstants.Colors.electricTeal.opacity(0.6),
                                AppConstants.Colors.calmBlue.opacity(0.3),
                                AppConstants.Colors.roseGold.opacity(0.1)
                            ],
                            center: .center, startRadius: 10, endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(reduceMotion ? 1.0 : breathScale)
                    .shadow(color: AppConstants.Colors.electricTeal.opacity(0.4), radius: 20, y: 4)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 4), value: breathScale)

                Image(systemName: "wind")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .scaleEffect(reduceMotion ? 1.0 : breathScale)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 4), value: breathScale)
            }
            .accessibilityHidden(true)

            Text("Breath \(breathCount) of 6")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))

            Spacer()

            if breathCount >= 6 {
                ctaButton(label: "Continue to Affirmations", color: AppConstants.Colors.calmBlue) {
                    breathingTask?.cancel()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { currentPhase = .affirmations }
                }
                .sensoryFeedback(.success, trigger: breathCount)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 50)
        }
    }

    // MARK: - Affirmations

    private var affirmationsView: some View {
        VStack(spacing: 36) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppConstants.Colors.sunsetGold.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppConstants.Colors.sunsetGold, AppConstants.Colors.roseGoldBright],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppConstants.Colors.sunsetGold.opacity(0.5), radius: 16, y: 4)
                    .symbolEffect(.variableColor, isActive: !reduceMotion)
            }
            .accessibilityHidden(true)

            Text(currentAffirmation)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .contentTransition(.opacity)
                .accessibilityLabel("Affirmation: \(currentAffirmation)")

            Button(action: nextAffirmation) {
                HStack(spacing: 6) {
                    Text("Next Affirmation")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                }
                .foregroundStyle(.white.opacity(0.55))
            }
            .sensoryFeedback(.selection, trigger: affirmationIndex)
            .accessibilityLabel("Show next affirmation")

            Spacer()

            ctaButton(label: "I Feel Calmer Now", color: AppConstants.Colors.mintGreen) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { currentPhase = .complete }
            }
            .sensoryFeedback(.success, trigger: currentPhase)
        }
    }

    // MARK: - Complete (Anchor Bloom)

    private var completeView: some View {
        AnchorBloomCompleteView(
            intensityAfter: $intensityAfter,
            reduceMotion: reduceMotion,
            onClose: { completeSession() }
        )
    }

    // MARK: - Shared CTA button

    private func ctaButton(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(color: color.opacity(0.45), radius: 12, y: 4)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 50)
    }

    // MARK: - Phase helpers

    private var phaseGlowColor: Color {
        switch currentPhase {
        case .grounding:    return AppConstants.Colors.electricTeal
        case .breathing:    return AppConstants.Colors.calmBlue
        case .affirmations: return AppConstants.Colors.sunsetGold
        case .complete:     return AppConstants.Colors.mintGreen
        }
    }

    private func phaseIndex(_ phase: SOSPhase) -> Int {
        switch phase {
        case .grounding: return 0; case .breathing: return 1
        case .affirmations: return 2; case .complete: return 3
        }
    }

    // MARK: - Structured-concurrency timer (replaces Timer + DispatchQueue)

    private func startSessionTimer() {
        sessionTimerTask?.cancel()
        sessionTimerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                secondsElapsed += 1
            }
        }
    }

    private func startBreathing() {
        breathCount = 0
        breathScale = 0.6
        breathingTask?.cancel()
        breathingTask = Task { @MainActor in
            await runBreathCycle()
        }
    }

    @MainActor
    private func runBreathCycle() async {
        while breathCount < 6 {
            guard !Task.isCancelled else { return }

            breathLabel = "Breathe In..."
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 4)) { breathScale = 1.0 }
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }

            breathLabel = "Hold..."
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }

            breathLabel = "Breathe Out..."
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 4)) { breathScale = 0.6 }
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }

            breathCount += 1
        }
        breathLabel = "Well done!"
    }

    private func stopAllTasks() {
        sessionTimerTask?.cancel(); sessionTimerTask = nil
        breathingTask?.cancel(); breathingTask = nil
    }

    // Keep for API compatibility with breathing view's "Continue" button
    private func stopBreathTimer() { breathingTask?.cancel(); breathingTask = nil }

    private func nextAffirmation() {
        affirmationIndex = (affirmationIndex + 1) % AppConstants.affirmations.count
        withAnimation(.easeInOut(duration: 0.4)) {
            currentAffirmation = AppConstants.affirmations[affirmationIndex]
        }
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
        stopAllTasks()
        withAnimation(.easeInOut(duration: 0.35)) { isPresented = false }
    }
}

// MARK: - SOSPhase CaseIterable + RawRepresentable

extension PanicSOSView.SOSPhase: CaseIterable, RawRepresentable {
    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .grounding; case 1: self = .breathing
        case 2: self = .affirmations; case 3: self = .complete
        default: return nil
        }
    }
    var rawValue: Int {
        switch self {
        case .grounding: return 0; case .breathing: return 1
        case .affirmations: return 2; case .complete: return 3
        }
    }
    static var allCases: [PanicSOSView.SOSPhase] {
        [.grounding, .breathing, .affirmations, .complete]
    }
}

// MARK: - Anchor Bloom Complete View

struct AnchorBloomCompleteView: View {
    @Binding var intensityAfter: Int
    let reduceMotion: Bool
    let onClose: () -> Void

    @State private var bloomScale: CGFloat = 0.2
    @State private var bloomOpacity: Double = 0
    @State private var ringScales: [CGFloat] = [1, 1, 1, 1, 1]
    @State private var ringOpacities: [Double] = [1, 1, 1, 1, 1]
    @State private var textAppeared = false
    @State private var closeTap = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Anchor bloom
            ZStack {
                if !reduceMotion {
                    ForEach(0..<5) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppConstants.Colors.sunsetGold.opacity(max(0, 0.5 - Double(i) * 0.08)),
                                        AppConstants.Colors.roseGold.opacity(max(0, 0.3 - Double(i) * 0.05))
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: 70 + CGFloat(i) * 40)
                            .scaleEffect(ringScales[i])
                            .opacity(ringOpacities[i])
                    }
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppConstants.Colors.sunsetGold.opacity(0.3),
                                AppConstants.Colors.roseGold.opacity(0.1),
                                Color.clear
                            ],
                            center: .center, startRadius: 0, endRadius: 55
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(bloomScale)
                    .opacity(bloomOpacity)

                Image(systemName: "anchor")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppConstants.Colors.sunsetGold, AppConstants.Colors.roseGoldBright],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppConstants.Colors.sunsetGold.opacity(0.6), radius: 20, y: 4)
                    .scaleEffect(bloomScale)
                    .opacity(bloomOpacity)
            }
            .accessibilityLabel("Golden anchor — you made it through")
            .onAppear { triggerBloom() }

            VStack(spacing: 10) {
                Text("You did it!")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("You navigated through the storm.\nEvery time you use these tools, you grow stronger.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(3)
            }
            .opacity(textAppeared ? 1 : 0)
            .offset(y: textAppeared ? 0 : 14)
            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.75).delay(0.5), value: textAppeared)

            VStack(spacing: 12) {
                Text("How intense is your anxiety now?")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))

                Slider(
                    value: Binding(get: { Double(intensityAfter) }, set: { intensityAfter = Int($0) }),
                    in: 1...10, step: 1
                )
                .tint(AppConstants.Colors.mintGreen)
                .sensoryFeedback(.selection, trigger: intensityAfter)
                .padding(.horizontal, 36)
                .accessibilityLabel("Anxiety level after session")
                .accessibilityValue("\(intensityAfter) out of 10")

                Text("\(intensityAfter)/10")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.mintGreen)
            }
            .opacity(textAppeared ? 1 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.75).delay(0.65), value: textAppeared)

            Spacer()

            Button(action: { closeTap.toggle(); onClose() }) {
                Text("Close & Return")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppConstants.Colors.calmBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: AppConstants.Colors.calmBlue.opacity(0.45), radius: 12, y: 4)
            }
            .sensoryFeedback(.success, trigger: closeTap)
            .padding(.horizontal, 28)
            .padding(.bottom, 50)
            .opacity(textAppeared ? 1 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.75).delay(0.8), value: textAppeared)
        }
    }

    private func triggerBloom() {
        if reduceMotion {
            // Instantly show final state — no animation
            bloomScale = 1.0; bloomOpacity = 1.0; textAppeared = true
            return
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) {
            bloomScale = 1.0; bloomOpacity = 1.0
        }
        for i in 0..<5 {
            withAnimation(.easeOut(duration: 1.8).delay(Double(i) * 0.14)) {
                ringScales[i] = 2.2 + CGFloat(i) * 0.25
                ringOpacities[i] = 0
            }
        }
        // Replace DispatchQueue with structured concurrency
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            textAppeared = true
        }
    }
}

// MARK: - Grounding Row

struct GroundingRow: View {
    let count: Int
    let sense: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppConstants.Colors.electricTeal.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text("\(count)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.electricTeal)
            }
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                Text(sense)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notice \(count) \(sense)")
    }
}
