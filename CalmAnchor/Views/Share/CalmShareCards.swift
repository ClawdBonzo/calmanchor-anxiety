import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

// MARK: - Links

enum CalmLinks {
    /// Campaign-tagged install link, so App Store Connect can attribute the
    /// installs each card type brings in.
    static func install(campaign: String) -> URL {
        URL(string: "https://apps.apple.com/app/apple-store/id6761788508?pt=117201882&ct=\(campaign)&mt=8")!
    }
    static let writeReview = URL(string: "https://apps.apple.com/app/id6761788508?action=write-review")!
}

// MARK: - QR

struct QRCodeView: View {
    let url: URL
    var size: CGFloat = 52

    var body: some View {
        if let img = Self.image(for: url) {
            Image(uiImage: img).interpolation(.none).resizable().frame(width: size, height: size)
        }
    }

    static func image(for url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let out = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cg = CIContext().createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Card chrome

/// A 360×640 pt story poster (rendered at 3× = 1080×1920).
struct SharePoster<Content: View>: View {
    var colors: [Color] = CalmBrand.dawn
    let campaign: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [CalmBrand.gold.opacity(0.35), .clear],
                           center: UnitPoint(x: 0.5, y: 1.0), startRadius: 0, endRadius: 320)
            StarField(count: 70, seed: 7).opacity(0.8)
            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                ShareFooter(campaign: campaign)
            }
            .padding(.horizontal, 22)
            .padding(.top, 46)
            .padding(.bottom, 26)
        }
        .frame(width: 360, height: 640)
        .environment(\.colorScheme, .dark)
    }
}

struct ShareFooter: View {
    let campaign: String
    var body: some View {
        HStack(spacing: 10) {
            Image("BrandIcon").resizable().scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text("CalmAnchor").font(.system(size: 14, weight: .heavy, design: .rounded))
                Text(String(localized: "Panic attack help · Free on the App Store"))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white)
            Spacer()
            QRCodeView(url: CalmLinks.install(campaign: campaign), size: 46)
                .padding(4)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Card kinds

struct BadgeShareCard: View {
    let badge: CalmBadge
    var body: some View {
        SharePoster(campaign: "share-badge") {
            VStack(spacing: 18) {
                Spacer()
                Kicker(text: String(localized: "Badge unlocked"))
                ZStack {
                    Sunburst(rays: 14, color: CalmBrand.gold)
                        .frame(width: 280, height: 280)
                    BadgeMedallion(badge: badge, unlocked: true, size: 150)
                }
                .frame(height: 230)
                Text(badge.title)
                    .font(.calmDisplay(34, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(badge.unlockedLine)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                Spacer()
                Text(String(localized: "What's your calm rank?"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(CalmBrand.gold)
                    .padding(.bottom, 14)
            }
        }
    }
}

struct RankShareCard: View {
    let stats: GameStats?
    let streak: Int
    let badgesUnlocked: Int
    let badgesTotal: Int
    var body: some View {
        SharePoster(campaign: "share-rank") {
            VStack(spacing: 22) {
                Spacer()
                Kicker(text: String(localized: "My calm rank"))
                AnchorPassCard(stats: stats, streak: streak, badgesUnlocked: badgesUnlocked,
                               badgesTotal: badgesTotal)
                    .rotationEffect(.degrees(-3))
                    .padding(.horizontal, 6)
                HStack(spacing: 12) {
                    PosterStat(value: "\(stats?.currentLevel ?? 1)", label: String(localized: "level"))
                    PosterStat(value: "\(streak)", label: String(localized: "day streak"))
                    PosterStat(value: "\(badgesUnlocked)", label: String(localized: "badges"))
                }
                Spacer()
                Text(String(localized: "Calm is a skill. I'm practicing."))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(CalmBrand.gold)
                    .padding(.bottom, 14)
            }
        }
    }
}

struct StreakShareCard: View {
    let days: Int
    var body: some View {
        SharePoster(campaign: "share-streak") {
            VStack(spacing: 14) {
                Spacer()
                Kicker(text: String(localized: "Calm streak"))
                ZStack {
                    Sunburst(rays: 16, color: CalmBrand.peach).frame(width: 300, height: 300)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 110, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [CalmBrand.gold, CalmBrand.coral],
                                                        startPoint: .top, endPoint: .bottom))
                        .shadow(color: CalmBrand.coral.opacity(0.6), radius: 24)
                }
                .frame(height: 220)
                Text("\(days)")
                    .font(.calmNumber(120))
                    .foregroundStyle(CalmBrand.accentGradient)
                Text(String(localized: "days of choosing calm"))
                    .font(.calmDisplay(22))
                    .foregroundStyle(.white)
                Spacer()
                Text(String(localized: "One breath at a time."))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(CalmBrand.gold)
                    .padding(.bottom, 14)
            }
        }
    }
}

struct PosterStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.calmNumber(30)).foregroundStyle(.white)
            Text(label).font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Rendering + sharing

enum ShareCardRenderer {
    @MainActor
    static func render<V: View>(_ view: V) -> UIImage? {
        let renderer = ImageRenderer(content: view.environment(\.dynamicTypeSize, .large))
        renderer.proposedSize = ProposedViewSize(width: 360, height: 640)
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// System share sheet that tells us whether the user actually shared.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (Bool) -> Void = { _ in }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, completed, _, _ in onComplete(completed) }
        return vc
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

/// Identifiable wrapper so a rendered card can drive `.sheet(item:)`.
struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
    let text: String
}
