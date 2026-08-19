import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let scale: CGFloat = 2

// Bitmap context helper: draw in points, rasterize at `scale`x for crispness.
func canvas(_ wPt: CGFloat, _ hPt: CGFloat, _ draw: () -> Void) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                              pixelsWide: Int(wPt * scale), pixelsHigh: Int(hPt * scale),
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                              isPlanar: false, colorSpaceName: .deviceRGB,
                              bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: wPt, height: hPt)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

func write(_ data: Data, _ name: String) {
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    print("wrote \(name) (\(data.count) bytes)")
}

func cupSymbol(filled: Bool, color: NSColor, pointSize: CGFloat) -> NSImage? {
    let cfg = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        .applying(.init(paletteColors: [color]))
    return NSImage(systemSymbolName: filled ? "cup.and.saucer.fill" : "cup.and.saucer",
                   accessibilityDescription: nil)?.withSymbolConfiguration(cfg)
}

// --- Menu-bar cup states (dark/light x active/inactive) ---
func cupTile(bg: NSColor, cup: NSColor, filled: Bool) -> Data {
    let w: CGFloat = 60, h: CGFloat = 40
    return canvas(w, h) {
        bg.setFill()
        NSRect(x: 0, y: 0, width: w, height: h).fill()
        if let sym = cupSymbol(filled: filled, color: cup, pointSize: 20) {
            let s = sym.size
            sym.draw(at: NSPoint(x: (w - s.width) / 2, y: (h - s.height) / 2),
                     from: .zero, operation: .sourceOver, fraction: 1)
        }
    }
}

let darkBar = NSColor(calibratedWhite: 0.15, alpha: 1)
let lightBar = NSColor(calibratedWhite: 0.93, alpha: 1)
write(cupTile(bg: darkBar,  cup: .white, filled: true),  "cup1.png") // dark, active
write(cupTile(bg: darkBar,  cup: .white, filled: false), "cup2.png") // dark, inactive
write(cupTile(bg: lightBar, cup: .black, filled: true),  "cup3.png") // light, active
write(cupTile(bg: lightBar, cup: .black, filled: false), "cup4.png") // light, inactive

// --- Dropdown menu render ---
enum Row {
    case check(String, on: Bool, indent: Bool)
    case plain(String)
    case header(String)
    case sep
}
let rows: [Row] = [
    .check("Active", on: true, indent: false),
    .sep,
    .header("Keep Awake"),
    .check("Prevent display sleep", on: true, indent: true),
    .check("Prevent system idle sleep", on: true, indent: true),
    .check("Prevent disk idle sleep", on: true, indent: true),
    .check("Prevent system sleep (on AC power)", on: true, indent: true),
    .sep,
    .plain("Start at login"),
    .sep,
    .plain("About Caffeinate"),
    .plain("Quit Caffeinate"),
]

let font = NSFont.systemFont(ofSize: 13)
let checkFont = NSFont.systemFont(ofSize: 12, weight: .bold)
let textColor = NSColor(calibratedWhite: 0.10, alpha: 1)
let grayColor = NSColor(calibratedWhite: 0.55, alpha: 1)
let margin: CGFloat = 10          // outer margin for the soft shadow
let leftPad: CGFloat = 10
let gutter: CGFloat = 18          // checkmark column
let indentW: CGFloat = 16
let rightPad: CGFloat = 22
let rowH: CGFloat = 22
let sepH: CGFloat = 11
let vPad: CGFloat = 5             // inner top/bottom padding

func textX(indent: Bool) -> CGFloat { leftPad + gutter + (indent ? indentW : 0) }

// Width from the widest row.
var maxRight: CGFloat = 0
for row in rows {
    switch row {
    case .check(let t, _, let indent):
        let w = (t as NSString).size(withAttributes: [.font: font]).width
        maxRight = max(maxRight, textX(indent: indent) + w)
    case .plain(let t):
        let w = (t as NSString).size(withAttributes: [.font: font]).width
        maxRight = max(maxRight, textX(indent: false) + w)
    case .header(let t):
        let w = (t as NSString).size(withAttributes: [.font: font]).width
        maxRight = max(maxRight, leftPad + 6 + w)
    case .sep: break
    }
}
let menuW = maxRight + rightPad
var menuH = vPad * 2
for row in rows { if case .sep = row { menuH += sepH } else { menuH += rowH } }

let W = menuW + margin * 2
let H = menuH + margin * 2

let menuData = canvas(W, H) {
    let ctx = NSGraphicsContext.current!.cgContext
    let menuRect = NSRect(x: margin, y: margin, width: menuW, height: menuH)
    let path = NSBezierPath(roundedRect: menuRect, xRadius: 7, yRadius: 7)

    // Soft shadow + light panel.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: 8,
                  color: NSColor(calibratedWhite: 0, alpha: 0.28).cgColor)
    NSColor(calibratedWhite: 0.98, alpha: 1).setFill()
    path.fill()
    ctx.restoreGState()
    NSColor(calibratedWhite: 0.80, alpha: 1).setStroke()
    path.lineWidth = 1
    path.stroke()

    // Draw rows from the top down (context origin is bottom-left).
    var top = margin + vPad
    func baselineY(_ rowTop: CGFloat) -> CGFloat { H - rowTop - 15 }

    func drawText(_ s: String, x: CGFloat, rowTop: CGFloat, color: NSColor, f: NSFont) {
        (s as NSString).draw(at: NSPoint(x: x, y: baselineY(rowTop)),
                             withAttributes: [.font: f, .foregroundColor: color])
    }

    for row in rows {
        switch row {
        case .check(let t, let on, let indent):
            if on {
                drawText("\u{2713}", x: leftPad + 3, rowTop: top, color: textColor, f: checkFont)
            }
            drawText(t, x: textX(indent: indent), rowTop: top, color: textColor, f: font)
            top += rowH
        case .plain(let t):
            drawText(t, x: textX(indent: false), rowTop: top, color: textColor, f: font)
            top += rowH
        case .header(let t):
            drawText(t, x: leftPad + 6, rowTop: top, color: grayColor, f: font)
            top += rowH
        case .sep:
            let y = H - (top + sepH / 2)
            NSColor(calibratedWhite: 0.85, alpha: 1).setStroke()
            let line = NSBezierPath()
            line.move(to: NSPoint(x: margin + 6, y: y))
            line.line(to: NSPoint(x: margin + menuW - 6, y: y))
            line.lineWidth = 1
            line.stroke()
            top += sepH
        }
    }
}
write(menuData, "menu.png")
