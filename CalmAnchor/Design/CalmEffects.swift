import SwiftUI

// MARK: - Deterministic RNG (so star fields and confetti are stable per seed)

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

// MARK: - Night sea → dawn background

/// A starlit night sky over a warm dawn horizon. Drawn once with Canvas (no
/// per-frame work); the only motion is an optional slow horizon breathe.
struct DawnBackground: View {
    /// 0 = full night (Dashboard), 1 = strong dawn (celebrations, recap).
    var warmth: Double = 0.35
    var stars: Int = 110
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: CalmBrand.abyss, location: 0),
                    .init(color: CalmBrand.midnight, location: 0.28),
                    .init(color: CalmBrand.deepSea, location: 0.55),
                    .init(color: CalmBrand.harbor.opacity(0.9), location: 0.82),
                    .init(color: CalmBrand.mauve.opacity(0.35 + 0.5 * warmth), location: 1)
                ],
                startPoint: .top, endPoint: .bottom)

            // Dawn glow rising from the horizon.
            RadialGradient(colors: [CalmBrand.roseDawn.opacity(0.55 * warmth), .clear],
                           center: .bottom, startRadius: 0, endRadius: 520)
                .scaleEffect(breathe ? 1.06 : 1.0, anchor: .bottom)
            RadialGradient(colors: [CalmBrand.peach.opacity(0.35 * warmth), .clear],
                           center: UnitPoint(x: 0.85, y: 1.02), startRadius: 0, endRadius: 360)
            // Cool sea-glass bloom behind the header.
            RadialGradient(colors: [CalmBrand.teal.opacity(0.10), .clear],
                           center: UnitPoint(x: 0.2, y: 0.08), startRadius: 0, endRadius: 320)

            StarField(count: stars, seed: 41)
                .opacity(0.9 - 0.4 * warmth)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}

struct StarField: View {
    let count: Int
    let seed: UInt64
    var body: some View {
        Canvas { ctx, size in
            var rng = SplitMix64(seed: seed)
            for _ in 0..<count {
                let x = rng.unit() * size.width
                let y = pow(rng.unit(), 1.6) * size.height * 0.6
                let r = 0.5 + rng.unit() * 1.5
                let fade = 1 - (y / (size.height * 0.6))
                let a = (0.15 + rng.unit() * 0.55) * fade
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                         with: .color(.white.opacity(a)))
            }
        }
    }
}

// MARK: - Confetti

/// Seeded, physically-plausible confetti drawn in a Canvas. Increment
/// `trigger` to fire a burst. Off under Reduce Motion; hidden from VoiceOver.
struct ConfettiBurst: View {
    var trigger: Int
    var count = 110
    var duration: Double = 2.8
    var colors: [Color] = CalmBrand.celebration
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?

    private struct Piece {
        let vx, vy, size, delay, spin, flip: Double
        let color: Color
        let shape: Int
    }

    var body: some View {
        GeometryReader { geo in
            if let start, !reduceMotion {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSince(start)
                    Canvas { ctx, size in
                        guard t < duration + 0.3 else { return }
                        let origin = CGPoint(x: size.width / 2, y: size.height * 0.42)
                        for p in pieces(seed: UInt64(trigger) &* 7919 &+ 17) {
                            let lt = max(0, t - p.delay)
                            guard lt > 0 else { continue }
                            let drag = 1.9, g = 620.0
                            let k = (1 - exp(-drag * lt)) / drag
                            let x = origin.x + p.vx * k
                            let y = origin.y + p.vy * k + 0.5 * g * lt * lt * 0.55
                            let fadeStart = duration * 0.65
                            let alpha = lt < fadeStart ? 1 : max(0, 1 - (lt - fadeStart) / (duration - fadeStart))
                            var c = ctx
                            c.opacity = alpha
                            c.translateBy(x: x, y: y)
                            c.rotate(by: .radians(p.spin * lt))
                            c.scaleBy(x: max(0.15, abs(cos(p.flip * lt))), y: 1)
                            let s = p.size
                            let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                            switch p.shape {
                            case 0: c.fill(Path(roundedRect: CGRect(x: -s / 2, y: -s / 5, width: s, height: s / 2.5),
                                                  cornerRadius: 1), with: .color(p.color))
                            case 1: c.fill(Path(ellipseIn: rect.insetBy(dx: s * 0.2, dy: s * 0.2)), with: .color(p.color))
                            default: c.fill(sparkle(in: rect), with: .color(p.color))
                            }
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, _ in start = Date() }
        .onAppear { if trigger > 0 { start = Date() } }
    }

    private func pieces(seed: UInt64) -> [Piece] {
        var rng = SplitMix64(seed: seed)
        return (0..<count).map { _ in
            let angle = -Double.pi * (0.08 + rng.unit() * 0.84)
            let speed = 380 + rng.unit() * 540
            return Piece(vx: cos(angle) * speed, vy: sin(angle) * speed,
                         size: 6 + rng.unit() * 6, delay: rng.unit() * 0.12,
                         spin: (rng.unit() - 0.5) * 10, flip: 3 + rng.unit() * 6,
                         color: colors[Int(rng.unit() * Double(colors.count)) % colors.count],
                         shape: Int(rng.unit() * 3) % 3)
        }
    }

    private func sparkle(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), R = r.width / 2, q = R * 0.28
        p.move(to: CGPoint(x: c.x, y: c.y - R))
        p.addQuadCurve(to: CGPoint(x: c.x + R, y: c.y), control: CGPoint(x: c.x + q, y: c.y - q))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + R), control: CGPoint(x: c.x + q, y: c.y + q))
        p.addQuadCurve(to: CGPoint(x: c.x - R, y: c.y), control: CGPoint(x: c.x - q, y: c.y + q))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - R), control: CGPoint(x: c.x - q, y: c.y - q))
        return p
    }
}

// MARK: - Sunburst

/// Soft dawn rays turning slowly behind celebration art.
struct Sunburst: View {
    var rays = 14
    var color: Color = CalmBrand.gold
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false

    var body: some View {
        ZStack {
            ForEach(0..<rays, id: \.self) { i in
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.22), .clear],
                                         startPoint: .bottom, endPoint: .top))
                    .frame(width: 16, height: 260)
                    .offset(y: -130)
                    .rotationEffect(.degrees(Double(i) / Double(rays) * 360))
            }
        }
        .rotationEffect(.degrees(spin ? 360 : 0))
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

// MARK: - Count-up number

/// Animates an integer from 0 → value once on appear (or instantly under Reduce Motion).
struct CountUpText: View {
    let value: Int
    var font: Font = .calmNumber(40)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0

    var body: some View {
        Text("\(shown)")
            .font(font)
            .contentTransition(.numericText(value: Double(shown)))
            .onAppear {
                if reduceMotion { shown = value; return }
                withAnimation(.easeOut(duration: 1.1)) { shown = value }
            }
            .onChange(of: value) { _, v in withAnimation(.easeOut(duration: 0.6)) { shown = v } }
            .accessibilityLabel("\(value)")
    }
}
