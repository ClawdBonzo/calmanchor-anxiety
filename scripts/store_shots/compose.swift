// CalmAnchor App Store screenshot compositor (CoreGraphics + CoreText, no AI).
//
//   swiftc -O -o /tmp/ca_compose scripts/store_shots/compose.swift
//   /tmp/ca_compose --raw <dir with 01.png…08.png> --assets <StoreAssets dir> \
//                   --locale en --out screenshots/v13/en --icon <AppIcon-1024.png>
//
// One continuous "night sea → dawn" panorama is drawn 8 frames wide and cut
// into 1320×2868 slides, so the breath wave, stars and glows flow across the
// set as it's swiped. Headline line 2 is filled with the gold→rose→coral
// accent. One headline size for the whole set per locale. Output is RGB PNG
// with no alpha, as App Store Connect requires.

import AppKit
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Args

var args: [String: String] = [:]
do {
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let k = it.next() { if k.hasPrefix("--"), let v = it.next() { args[String(k.dropFirst(2))] = v } }
}
guard let rawDir = args["raw"], let assetDir = args["assets"], let outDir = args["out"],
      let locale = args["locale"], let iconPath = args["icon"] else {
    FileHandle.standardError.write("usage: --raw --assets --locale --out --icon [--headlines]\n".data(using: .utf8)!)
    exit(2)
}
let headlinesPath = args["headlines"] ?? "scripts/store_shots/headlines.json"

// MARK: - Canvas + palette

let W: CGFloat = 1320, H: CGFloat = 2868, FRAMES = 8
let PW = W * CGFloat(FRAMES)

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
let abyss = rgb(0x050A14), midnight = rgb(0x080E1C), deepSea = rgb(0x0F1E30), harbor = rgb(0x16324F)
let mauve = rgb(0x6B5476), roseDawn = rgb(0xD99A8E), peach = rgb(0xF4C2A1)
let gold = rgb(0xF5D76E), roseLight = rgb(0xE8B49A), coral = rgb(0xE8A0A0)
let teal = rgb(0x00C9B7), mint = rgb(0xA8D5BA), lilac = rgb(0xB8A9C9), sky = rgb(0x5B9BD5)
let paper = rgb(0xF7F2EA), navyInk = rgb(0x0B1B33)

let space = CGColorSpace(name: CGColorSpace.sRGB)!

// MARK: - Deterministic RNG

struct Rng { var s: UInt64
    mutating func next() -> Double {
        s &+= 0x9E37_79B9_7F4A_7C15
        var z = s; z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9; z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Double((z ^ (z >> 31)) >> 11) / Double(1 << 53)
    }
}

// MARK: - Helpers

func loadImage(_ path: String) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func savePNG(_ img: CGImage, _ path: String) {
    let url = URL(fileURLWithPath: path)
    guard let dst = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(dst, img, nil)
    CGImageDestinationFinalize(dst)
}

func makeContext(_ w: Int, _ h: Int, alpha: Bool = true) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
              bitmapInfo: alpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)!
}

/// Top-left-origin drawing convenience.
extension CGContext {
    func flipY(_ h: CGFloat) { translateBy(x: 0, y: h); scaleBy(x: 1, y: -1) }
}

func linearGradient(_ colors: [CGColor], _ locs: [CGFloat]? = nil) -> CGGradient {
    CGGradient(colorsSpace: space, colors: colors as CFArray, locations: locs)!
}

func radialGlow(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ color: CGColor, _ a: CGFloat) {
    let g = linearGradient([color.copy(alpha: a)!, color.copy(alpha: 0)!])
    ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
}

// MARK: - Fonts

let isCJK = ["ja", "ko", "zh-Hans", "zh-Hant"].contains(locale)

func roundedFont(_ size: CGFloat, _ weight: NSFont.Weight) -> CTFont {
    if isCJK {
        let name = weight == .heavy || weight == .black ? "HiraginoSans-W8" : "HiraginoSans-W6"
        return CTFontCreateWithName(name as CFString, size, nil)
    }
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    let desc = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
    return (NSFont(descriptor: desc, size: size) ?? base) as CTFont
}
func textFont(_ size: CGFloat, _ weight: NSFont.Weight) -> CTFont {
    if isCJK { return CTFontCreateWithName("HiraginoSans-W6" as CFString, size, nil) }
    return NSFont.systemFont(ofSize: size, weight: weight) as CTFont
}

func line(_ s: String, _ font: CTFont, _ color: CGColor, kern: CGFloat = 0) -> CTLine {
    let a = NSAttributedString(string: s, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
        NSAttributedString.Key(kCTKernAttributeName as String): kern])
    return CTLineCreateWithAttributedString(a)
}
func width(_ l: CTLine) -> CGFloat { CGFloat(CTLineGetTypographicBounds(l, nil, nil, nil)) }

/// Greedy wrap (word-based for Latin, character-based for CJK) into ≤ maxLines.
func wrap(_ s: String, _ font: CTFont, _ maxW: CGFloat) -> [String] {
    let units: [String] = isCJK ? s.map(String.init) : s.split(separator: " ").map(String.init)
    let sep = isCJK ? "" : " "
    var lines: [String] = [], cur = ""
    for u in units {
        let t = cur.isEmpty ? u : cur + sep + u
        if width(line(t, font, paper)) <= maxW || cur.isEmpty { cur = t } else { lines.append(cur); cur = u }
    }
    if !cur.isEmpty { lines.append(cur) }
    // CJK: never start a line with closing punctuation.
    if isCJK, lines.count > 1 {
        for i in 1..<lines.count where "、。，．）」』！？".contains(lines[i].first ?? " ") {
            lines[i - 1].append(lines[i].removeFirst())
        }
    }
    return lines
}

/// Balance two lines so the sub reads as a tidy block.
func balanced(_ s: String, _ font: CTFont, _ maxW: CGFloat) -> [String] {
    var lo: CGFloat = maxW * 0.5, hi = maxW, best = wrap(s, font, maxW)
    guard best.count == 2 else { return best }
    for _ in 0..<14 {
        let mid = (lo + hi) / 2
        let w = wrap(s, font, mid)
        if w.count <= 2 { best = w; hi = mid } else { lo = mid }
    }
    return best
}

// MARK: - Copy

struct Frame: Decodable { let l1: String; let l2: String; let sub: String; let chips: [String]? }
let allCopy = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: headlinesPath))) as! [String: Any]
let frames: [Frame] = try! JSONDecoder().decode([Frame].self,
    from: JSONSerialization.data(withJSONObject: allCopy[locale] ?? allCopy["en"]!))

let margin: CGFloat = 80, textW: CGFloat = W - 2 * margin

// One headline size for the whole set: largest that fits every line.
var hSize: CGFloat = 132
while hSize > 64 {
    let f = roundedFont(hSize, .heavy)
    if frames.allSatisfy({ width(line($0.l1, f, paper)) <= textW && width(line($0.l2, f, paper)) <= textW }) { break }
    hSize -= 2
}
var sSize: CGFloat = 50
while sSize > 34 {
    let f = textFont(sSize, .semibold)
    if frames.allSatisfy({ wrap($0.sub, f, textW * 0.92).count <= 2 }) { break }
    sSize -= 2
}
let headFont = roundedFont(hSize, .heavy), subFont = textFont(sSize, .semibold)

// MARK: - Panorama background

func drawPanorama(_ ctx: CGContext) {
    // Sky: night at the top, dawn at the horizon.
    let skyGrad = linearGradient([abyss, midnight, deepSea, harbor, rgb(0x3B3F66), mauve, roseDawn, peach],
                             [0, 0.2, 0.4, 0.58, 0.72, 0.84, 0.94, 1])
    ctx.drawLinearGradient(skyGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: H), options: [])

    // Horizon glows, a different warm note under each frame.
    let glows: [(CGFloat, CGFloat, CGColor, CGFloat)] = [
        (0.2, 1.0, coral, 0.45), (1.1, 0.95, gold, 0.35), (2.0, 1.0, roseDawn, 0.5), (3.0, 0.97, peach, 0.4),
        (4.0, 1.0, lilac, 0.35), (5.0, 0.96, coral, 0.45), (6.0, 1.0, gold, 0.4), (7.0, 0.95, teal, 0.28), (7.9, 1.0, roseDawn, 0.45)]
    for (x, y, c, a) in glows { radialGlow(ctx, CGPoint(x: x * W, y: y * H), W * 0.95, c, a) }
    // Cool blooms behind the headlines.
    for (x, c) in [(0.5, teal), (2.4, lilac), (4.5, sky), (6.5, teal)] as [(CGFloat, CGColor)] {
        radialGlow(ctx, CGPoint(x: x * W, y: H * 0.1), W * 0.85, c, 0.13)
    }

    // Stars in the top half.
    var r = Rng(s: 41)
    for _ in 0..<1300 {
        let x = r.next() * Double(PW), y = pow(r.next(), 1.6) * Double(H) * 0.55
        let rad = 0.8 + r.next() * 2.2
        let a = (0.12 + r.next() * 0.5) * (1 - y / (Double(H) * 0.55))
        ctx.setFillColor(CGColor(gray: 1, alpha: CGFloat(a)))
        ctx.fillEllipse(in: CGRect(x: x, y: y, width: rad * 2, height: rad * 2))
    }

    // Dotted ocean: rows of dots riding gentle waves, fading upward.
    let spacing: CGFloat = 24
    var row: CGFloat = 0
    var y = H * 0.66
    while y < H + spacing {
        let t = (y - H * 0.66) / (H * 0.34)            // 0 at the top of the sea → 1 at the bottom
        let amp = 10 + 26 * t
        var x: CGFloat = 0
        while x < PW {
            let yy = y + amp * sin(x / 260 + row * 0.7) + 0.5 * amp * sin(x / 97 + row)
            let a = 0.05 + 0.16 * t
            let rad: CGFloat = 2.6 + 1.6 * t
            ctx.setFillColor(CGColor(gray: 1, alpha: a))
            ctx.fillEllipse(in: CGRect(x: x - rad, y: yy - rad, width: rad * 2, height: rad * 2))
            x += spacing
        }
        y += spacing * (1.1 - 0.35 * t); row += 1
    }

    // The breath wave: a dashed line flowing across the whole set.
    let path = CGMutablePath()
    var first = true
    var x: CGFloat = 0
    while x <= PW {
        let t = x / W
        let yy = H * 0.232 + H * 0.022 * sin(t * .pi * 0.9 + 0.6) + H * 0.01 * sin(t * .pi * 2.3)
        if first { path.move(to: CGPoint(x: x, y: yy)); first = false } else { path.addLine(to: CGPoint(x: x, y: yy)) }
        x += 8
    }
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.3))
    ctx.setLineWidth(4); ctx.setLineCap(.round); ctx.setLineDash(phase: 0, lengths: [2, 18])
    ctx.strokePath()
    ctx.restoreGState()
}

// MARK: - Device frame

func drawDevice(_ ctx: CGContext, screen shot: CGImage, center cx: CGFloat, top: CGFloat, maxBottom: CGFloat) -> CGRect {
    var bodyW: CGFloat = 1000
    let aspect = CGFloat(shot.height) / CGFloat(shot.width)
    func bodyH(_ w: CGFloat) -> CGFloat { let band = w * 0.022, bezel = w * 0.024; return (w - 2 * (band + bezel)) * aspect + 2 * (band + bezel) }
    while top + bodyH(bodyW) > maxBottom && bodyW > 600 { bodyW -= 4 }
    let band = bodyW * 0.022, bezel = bodyW * 0.024
    let body = CGRect(x: cx - bodyW / 2, y: top, width: bodyW, height: bodyH(bodyW))
    let screen = body.insetBy(dx: band + bezel, dy: band + bezel)
    let s = screen.width / 440
    let bodyR = 62 * s + band + bezel, screenR = 62 * s

    // Shadow + dawn glow.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -60), blur: 140, color: CGColor(gray: 0, alpha: 0.6))
    ctx.addPath(CGPath(roundedRect: body, cornerWidth: bodyR, cornerHeight: bodyR, transform: nil))
    ctx.setFillColor(rgb(0x2B2F36)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 120, color: roseDawn.copy(alpha: 0.3)!)
    ctx.addPath(CGPath(roundedRect: body, cornerWidth: bodyR, cornerHeight: bodyR, transform: nil))
    ctx.setFillColor(rgb(0x2B2F36)); ctx.fillPath()
    ctx.restoreGState()

    // Titanium band.
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: body, cornerWidth: bodyR, cornerHeight: bodyR, transform: nil)); ctx.clip()
    ctx.drawLinearGradient(linearGradient([rgb(0x8C929C), rgb(0x4A4F58), rgb(0x2B2F36), rgb(0x5D636D), rgb(0x9AA0A9)],
                                          [0, 0.18, 0.5, 0.82, 1]),
                           start: CGPoint(x: body.minX, y: 0), end: CGPoint(x: body.maxX, y: 0), options: [])
    ctx.restoreGState()
    // Bezel.
    let bez = body.insetBy(dx: band, dy: band)
    ctx.addPath(CGPath(roundedRect: bez, cornerWidth: bodyR - band, cornerHeight: bodyR - band, transform: nil))
    ctx.setFillColor(rgb(0x050608)); ctx.fillPath()
    // Screen.
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: screen, cornerWidth: screenR, cornerHeight: screenR, transform: nil)); ctx.clip()
    ctx.saveGState()
    ctx.translateBy(x: screen.minX, y: screen.maxY); ctx.scaleBy(x: 1, y: -1)
    ctx.interpolationQuality = .high
    ctx.draw(shot, in: CGRect(x: 0, y: 0, width: screen.width, height: screen.height))
    ctx.restoreGState()
    // Glass sheen.
    ctx.drawLinearGradient(linearGradient([CGColor(gray: 1, alpha: 0.06), CGColor(gray: 1, alpha: 0)]),
                           start: CGPoint(x: screen.minX, y: screen.minY), end: CGPoint(x: screen.midX, y: screen.midY), options: [])
    ctx.restoreGState()
    ctx.addPath(CGPath(roundedRect: bez, cornerWidth: bodyR - band, cornerHeight: bodyR - band, transform: nil))
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.1)); ctx.setLineWidth(2); ctx.strokePath()
    return screen
}

// MARK: - Stickers

/// Draw an image centered at (cx, cy), rotated clockwise by `deg`, scaled to `w` wide.
func float(_ ctx: CGContext, _ img: CGImage, cx: CGFloat, cy: CGFloat, w: CGFloat, deg: CGFloat,
           card: Bool, shadow k: CGFloat = 1) {
    let h = w * CGFloat(img.height) / CGFloat(img.width)
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: deg * .pi / 180)
    let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
    if card {
        let r = w * 0.06
        let p = CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -40 * k), blur: 90 * k, color: CGColor(gray: 0, alpha: 0.55))
        ctx.addPath(p); ctx.setFillColor(midnight); ctx.fillPath()
        ctx.restoreGState()
        ctx.saveGState(); ctx.addPath(p); ctx.clip()
        ctx.saveGState(); ctx.translateBy(x: 0, y: rect.maxY); ctx.scaleBy(x: 1, y: -1)
        ctx.draw(img, in: CGRect(x: rect.minX, y: 0, width: w, height: h)); ctx.restoreGState()
        ctx.restoreGState()
        ctx.addPath(p); ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.28)); ctx.setLineWidth(3); ctx.strokePath()
    } else {
        ctx.setShadow(offset: CGSize(width: 0, height: -18 * k), blur: 36 * k, color: CGColor(gray: 0, alpha: 0.45))
        ctx.saveGState(); ctx.translateBy(x: 0, y: rect.maxY); ctx.scaleBy(x: 1, y: -1)
        ctx.draw(img, in: CGRect(x: rect.minX, y: 0, width: w, height: h)); ctx.restoreGState()
    }
    ctx.restoreGState()
}

func symbolImage(_ name: String, _ pt: CGFloat, _ color: NSColor) -> CGImage? {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: pt, weight: .heavy)) else { return nil }
    let sz = base.size
    let img = NSImage(size: sz, flipped: false) { r in
        base.draw(in: r); color.set(); r.fill(using: .sourceAtop); return true
    }
    return img.cgImage(forProposedRect: nil, context: nil, hints: nil)
}

/// Paper pill with a tinted icon disc and a label (top-left origin coordinates).
func chip(_ ctx: CGContext, _ text: String, icon: String, tint: CGColor, left: CGFloat, cy: CGFloat, deg: CGFloat) {
    let f = roundedFont(40, .bold)
    let l = line(text, f, navyInk)
    let h: CGFloat = 104, disc: CGFloat = 64
    let w = 20 + disc + 18 + width(l) + 34
    ctx.saveGState()
    ctx.translateBy(x: left + w / 2, y: cy)
    ctx.rotate(by: deg * .pi / 180)
    let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 50, color: CGColor(gray: 0, alpha: 0.45))
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: h / 2, cornerHeight: h / 2, transform: nil))
    ctx.setFillColor(paper); ctx.fillPath()
    ctx.restoreGState()
    let dr = CGRect(x: rect.minX + 20, y: -disc / 2, width: disc, height: disc)
    ctx.setFillColor(tint); ctx.fillEllipse(in: dr)
    if let sym = symbolImage(icon, 30, .white) {
        let sw = CGFloat(sym.width) * 0.9, sh = CGFloat(sym.height) * 0.9
        ctx.saveGState(); ctx.translateBy(x: dr.midX, y: dr.midY); ctx.scaleBy(x: 1, y: -1)
        ctx.draw(sym, in: CGRect(x: -sw / 2, y: -sh / 2, width: sw, height: sh)); ctx.restoreGState()
    }
    ctx.saveGState()
    ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    ctx.textPosition = CGPoint(x: dr.maxX + 18, y: 14)
    CTLineDraw(l, ctx)
    ctx.restoreGState()
    ctx.restoreGState()
}

func confetti(_ ctx: CGContext, around c: CGPoint, spreadW: CGFloat, spreadH: CGFloat, avoid: CGRect, seed: UInt64) {
    var r = Rng(s: seed)
    let cols = [gold, roseLight, coral, teal, mint, lilac, paper]
    var placed = 0
    while placed < 90 {
        let x = c.x + (r.next() - 0.5) * spreadW, y = c.y + (r.next() - 0.5) * spreadH
        let p = CGPoint(x: x, y: y)
        if avoid.contains(p) { _ = r.next(); continue }
        ctx.saveGState()
        ctx.translateBy(x: x, y: y); ctx.rotate(by: r.next() * .pi)
        ctx.setFillColor(cols[Int(r.next() * Double(cols.count)) % cols.count])
        let s = 12 + r.next() * 14
        if r.next() < 0.5 { ctx.fill(CGRect(x: -s / 2, y: -s / 5, width: s, height: s / 2.4)) }
        else { ctx.fillEllipse(in: CGRect(x: -s / 3, y: -s / 3, width: s / 1.5, height: s / 1.5)) }
        ctx.restoreGState()
        placed += 1
    }
}

// MARK: - Text drawing (top-left coords)

func drawLine(_ ctx: CGContext, _ l: CTLine, centerX: CGFloat, baseline: CGFloat) {
    ctx.saveGState()
    ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    ctx.textPosition = CGPoint(x: centerX - width(l) / 2, y: baseline)
    CTLineDraw(l, ctx)
    ctx.restoreGState()
}

/// Line 2 of the headline, filled with the accent gradient through a text mask.
func drawAccentLine(_ ctx: CGContext, _ s: String, centerX: CGFloat, baseline: CGFloat) {
    let l = line(s, headFont, paper, kern: -hSize * 0.012)
    let w = width(l)
    var asc: CGFloat = 0, desc: CGFloat = 0
    _ = CTLineGetTypographicBounds(l, &asc, &desc, nil)
    let bw = Int(ceil(w + 20)), bh = Int(ceil(asc + desc + 20))
    let mctx = makeContext(bw, bh)
    mctx.textPosition = CGPoint(x: 10, y: desc + 10)
    CTLineDraw(l, mctx)
    guard let mask = mctx.makeImage() else { return }
    let rect = CGRect(x: centerX - w / 2 - 10, y: baseline - asc - 10, width: CGFloat(bw), height: CGFloat(bh))
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 30, color: CGColor(gray: 0, alpha: 0.35))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.maxY); ctx.scaleBy(x: 1, y: -1)
    ctx.clip(to: CGRect(x: 0, y: 0, width: rect.width, height: rect.height), mask: mask)
    ctx.drawLinearGradient(linearGradient([gold, roseLight, coral]), start: CGPoint(x: 0, y: rect.height),
                           end: CGPoint(x: rect.width, y: 0), options: [])
    ctx.restoreGState()
    ctx.endTransparencyLayer()
    ctx.restoreGState()
}

// MARK: - Compose

let fm = FileManager.default
try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)
func asset(_ n: String) -> CGImage? { loadImage("\(assetDir)/\(n)") }
let icon = loadImage(iconPath)

let pano = makeContext(Int(PW), Int(H), alpha: false)
pano.flipY(H)
drawPanorama(pano)
guard let panoImg = pano.makeImage() else { exit(1) }

for (i, fr) in frames.enumerated() {
    let n = i + 1
    let ctx = makeContext(Int(W), Int(H), alpha: false)
    ctx.flipY(H)
    // Slice of the panorama.
    ctx.saveGState()
    ctx.translateBy(x: -CGFloat(i) * W, y: H); ctx.scaleBy(x: 1, y: -1)
    ctx.draw(panoImg, in: CGRect(x: 0, y: 0, width: PW, height: H))
    ctx.restoreGState()

    // Headline.
    let headlineTop: CGFloat = 170
    let lh = hSize * 1.02
    let l1 = line(fr.l1, headFont, paper, kern: -hSize * 0.012)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 30, color: CGColor(gray: 0, alpha: 0.35))
    drawLine(ctx, l1, centerX: W / 2, baseline: headlineTop + hSize * 0.92)
    ctx.restoreGState()
    drawAccentLine(ctx, fr.l2, centerX: W / 2, baseline: headlineTop + hSize * 0.92 + lh)

    // Sub.
    let subTop = headlineTop + 2 * lh + 30
    let subLines = balanced(fr.sub, subFont, textW * 0.92)
    for (k, s) in subLines.enumerated() {
        drawLine(ctx, line(s, subFont, rgb(0xDCE6F5, 0.88)), centerX: W / 2,
                 baseline: subTop + sSize * 0.95 + CGFloat(k) * sSize * 1.18)
    }
    let deviceTop = subTop + 2 * sSize * 1.18 + 70

    // Device — horizontal offset gives each frame room for its stickers.
    let offsets: [CGFloat] = [50, -40, 40, 0, -50, 50, 60, -40]
    guard let shot = loadImage("\(rawDir)/\(String(format: "%02d", n)).png") else {
        print("missing raw \(n)"); continue
    }
    let scr = drawDevice(ctx, screen: shot, center: W / 2 + offsets[i], top: deviceTop, maxBottom: H - 70)

    // Stickers per frame.
    switch n {
    case 1:
        if let w = asset("widget-lock.png") { float(ctx, w, cx: 330, cy: H - 560, w: 560, deg: -7, card: false, shadow: 1.3) }
    case 2:
        if let isl = asset("island.png") { float(ctx, isl, cx: W - 380, cy: scr.minY + 170, w: 640, deg: 5, card: false, shadow: 1.3) }
        chip(ctx, "8 → 3", icon: "arrow.down.right", tint: teal, left: 50, cy: scr.minY + 1080, deg: -4)
    case 3:
        confetti(ctx, around: CGPoint(x: W / 2, y: scr.minY + 420), spreadW: W * 1.05, spreadH: 700,
                 avoid: scr.insetBy(dx: 40, dy: 40), seed: 7)
        if let c = asset("card-streak.png") { float(ctx, c, cx: W - 250, cy: H - 700, w: 420, deg: 8, card: true, shadow: 1.3) }
    case 4:
        if let b = asset("badge-stormTamed.1.png") { float(ctx, b, cx: 170, cy: scr.minY + 1130, w: 330, deg: -10, card: false) }
        if let b = asset("badge-longestStreak.14.png") { float(ctx, b, cx: W - 170, cy: scr.minY + 520, w: 310, deg: 9, card: false) }
        if let b = asset("badge-nightWatch.1.png") { float(ctx, b, cx: W - 185, cy: H - 420, w: 310, deg: 6, card: false) }
    case 5:
        if let b = asset("badge-bigDrops.5.png") { float(ctx, b, cx: W - 180, cy: scr.minY + 300, w: 320, deg: 8, card: false) }
        if let c = asset("card-recap.png") { float(ctx, c, cx: 250, cy: H - 640, w: 400, deg: -7, card: true, shadow: 1.3) }
    case 6:
        if let p = asset("pass.png") { float(ctx, p, cx: W - 330, cy: H - 520, w: 640, deg: 6, card: false, shadow: 1.4) }
    case 7:
        if let c = asset("card-recap.png") { float(ctx, c, cx: 260, cy: H - 620, w: 420, deg: -7, card: true, shadow: 1.3) }
        if let b = asset("badge-moods.30.png") { float(ctx, b, cx: W - 170, cy: scr.minY + 360, w: 300, deg: 9, card: false) }
    case 8:
        let chips = fr.chips ?? []
        let specs: [(String, CGColor, CGFloat, CGFloat)] = [
            ("person.crop.circle.badge.xmark", coral, 44, -3), ("nosign", mauve, 74, 2), ("lock.iphone", teal, 44, -3)]
        for (k, t) in chips.prefix(3).enumerated() {
            chip(ctx, t, icon: specs[k].0, tint: specs[k].1, left: specs[k].2, cy: scr.minY + 820 + CGFloat(k) * 140, deg: specs[k].3)
        }
        if let ic = icon {
            ctx.saveGState()
            ctx.translateBy(x: W - 175, y: scr.minY + 170); ctx.rotate(by: 8 * .pi / 180)
            let r = CGRect(x: -100, y: -100, width: 200, height: 200)
            ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: CGColor(gray: 0, alpha: 0.5))
            let p = CGPath(roundedRect: r, cornerWidth: 45, cornerHeight: 45, transform: nil)
            ctx.addPath(p); ctx.setFillColor(midnight); ctx.fillPath()
            ctx.addPath(p); ctx.clip()
            ctx.translateBy(x: 0, y: r.maxY); ctx.scaleBy(x: 1, y: -1)
            ctx.draw(ic, in: CGRect(x: r.minX, y: 0, width: 200, height: 200))
            ctx.restoreGState()
        }
    default: break
    }

    if let img = ctx.makeImage() {
        savePNG(img, "\(outDir)/\(String(format: "%02d", n)).png")
        print("wrote \(n)")
    }
}

// Contact sheet for review.
let thumbs = (1...FRAMES).compactMap { loadImage("\(outDir)/\(String(format: "%02d", $0)).png") }
if !thumbs.isEmpty {
    let th: CGFloat = 640, tw = th * W / H, gap: CGFloat = 28, pad: CGFloat = 48
    let sw = pad * 2 + CGFloat(thumbs.count) * tw + CGFloat(thumbs.count - 1) * gap
    let sc = makeContext(Int(sw), Int(th + pad * 2), alpha: false)
    sc.setFillColor(rgb(0x1C1C1E)); sc.fill(CGRect(x: 0, y: 0, width: sw, height: th + pad * 2))
    for (k, t) in thumbs.enumerated() {
        let r = CGRect(x: pad + CGFloat(k) * (tw + gap), y: pad, width: tw, height: th)
        sc.saveGState()
        sc.addPath(CGPath(roundedRect: r, cornerWidth: 26, cornerHeight: 26, transform: nil)); sc.clip()
        sc.draw(t, in: r); sc.restoreGState()
    }
    if let s = sc.makeImage() { savePNG(s, "\(outDir)/contact.png") }
}
print("done: headline \(hSize)pt, sub \(sSize)pt")
