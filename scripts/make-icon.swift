import AppKit

// Renders the cup.and.saucer SF Symbol onto a coffee-colored rounded-rect and
// writes PNGs at every size an app icon needs. Output dir is argv[1].
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func render(_ px: Int) -> Data {
    let size = CGFloat(px)
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext

    // Rounded-rect "squircle-ish" background inset a touch from the canvas,
    // matching the modern macOS icon grid (~82% of the canvas).
    let inset = size * 0.09
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = rect.width * 0.2237
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Warm coffee gradient background.
    let top = NSColor(calibratedRed: 0.52, green: 0.37, blue: 0.26, alpha: 1)    // #856044-ish
    let bottom = NSColor(calibratedRed: 0.29, green: 0.20, blue: 0.14, alpha: 1) // #4A3324-ish
    ctx.saveGState()
    path.addClip()
    let gradient = NSGradient(starting: top, ending: bottom)!
    gradient.draw(in: rect, angle: -90)
    ctx.restoreGState()

    // Cream-colored cup symbol, centered, ~58% of the rect.
    let symPt = rect.width * 0.58
    let cfg = NSImage.SymbolConfiguration(pointSize: symPt, weight: .regular)
        .applying(.init(paletteColors: [NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.90, alpha: 1)]))
    if let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        let s = symbol.size
        let origin = NSPoint(x: rect.midX - s.width / 2, y: rect.midY - s.height / 2)
        symbol.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
    }

    image.unlockFocus()

    // Re-rasterize at exact pixel dimensions (lockFocus uses backing scale).
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for px in [16, 32, 64, 128, 256, 512, 1024] {
    let data = render(px)
    let url = URL(fileURLWithPath: "\(outDir)/icon_\(px).png")
    try! data.write(to: url)
    print("wrote \(url.lastPathComponent) (\(data.count) bytes)")
}
