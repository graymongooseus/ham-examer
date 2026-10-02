import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("Icon-20@2x.png", 40), ("Icon-20@3x.png", 60),
    ("Icon-29@2x.png", 58), ("Icon-29@3x.png", 87),
    ("Icon-40@2x.png", 80), ("Icon-40@3x.png", 120),
    ("Icon-60@2x.png", 120), ("Icon-60@3x.png", 180),
    ("Icon-1024.png", 1024)
]

func drawIcon(filename: String, size: Int) throws {
    guard let bitmapContext = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { throw NSError(domain: "IconGenerator", code: 1) }
    let context = NSGraphicsContext(cgContext: bitmapContext, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.interpolationQuality = .high

    let s = CGFloat(size)
    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    NSGradient(colors: [NSColor(calibratedRed: 0.025, green: 0.086, blue: 0.133, alpha: 1), NSColor(calibratedRed: 0.055, green: 0.196, blue: 0.275, alpha: 1)])!.draw(in: rect, angle: -45)

    // Subtle technical grid from the study site's background.
    NSColor(calibratedRed: 0.35, green: 0.84, blue: 0.96, alpha: 0.07).setStroke()
    let grid = NSBezierPath(); grid.lineWidth = max(1, s * 0.002)
    stride(from: s * 0.1, through: s, by: s * 0.15).forEach { x in grid.move(to: NSPoint(x: x, y: 0)); grid.line(to: NSPoint(x: x, y: s)) }
    stride(from: s * 0.1, through: s, by: s * 0.15).forEach { y in grid.move(to: NSPoint(x: 0, y: y)); grid.line(to: NSPoint(x: s, y: y)) }
    grid.stroke()

    let center = NSPoint(x: s * 0.5, y: s * 0.52)
    let ringRect = NSRect(x: s * 0.18, y: s * 0.18, width: s * 0.64, height: s * 0.64)
    let glow = NSBezierPath(ovalIn: ringRect)
    NSColor(calibratedRed: 1.0, green: 0.75, blue: 0.28, alpha: 0.10).setFill(); glow.fill()
    NSColor(calibratedRed: 1.0, green: 0.75, blue: 0.28, alpha: 0.45).setStroke(); glow.lineWidth = s * 0.018; glow.stroke()

    // Radio waves: cyan outside, warm signal at the center.
    for (radius, alpha) in [(s * 0.28, 0.92), (s * 0.20, 0.78)] {
        for angles in [(38.0, 142.0), (218.0, 322.0)] {
            let arc = NSBezierPath()
            arc.appendArc(withCenter: center, radius: radius, startAngle: angles.0, endAngle: angles.1)
            arc.lineWidth = s * 0.026; arc.lineCapStyle = .round
            NSColor(calibratedRed: 0.35, green: 0.84, blue: 0.96, alpha: alpha).setStroke(); arc.stroke()
        }
    }

    let amber = NSColor(calibratedRed: 1.0, green: 0.75, blue: 0.28, alpha: 1)
    let mast = NSBezierPath()
    mast.move(to: NSPoint(x: center.x, y: s * 0.30)); mast.line(to: NSPoint(x: center.x, y: s * 0.67))
    mast.lineWidth = s * 0.045; mast.lineCapStyle = .round; amber.setStroke(); mast.stroke()
    let tower = NSBezierPath()
    tower.move(to: NSPoint(x: center.x, y: s * 0.57)); tower.line(to: NSPoint(x: s * 0.37, y: s * 0.29))
    tower.move(to: NSPoint(x: center.x, y: s * 0.57)); tower.line(to: NSPoint(x: s * 0.63, y: s * 0.29))
    tower.move(to: NSPoint(x: s * 0.40, y: s * 0.36)); tower.line(to: NSPoint(x: s * 0.60, y: s * 0.36))
    tower.lineWidth = s * 0.033; tower.lineCapStyle = .round; tower.lineJoinStyle = .round; tower.stroke()
    let signal = NSBezierPath(ovalIn: NSRect(x: center.x - s * 0.055, y: s * 0.64, width: s * 0.11, height: s * 0.11))
    amber.setFill(); signal.fill()
    NSColor.white.withAlphaComponent(0.45).setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - s * 0.023, y: s * 0.69, width: s * 0.03, height: s * 0.03)).fill()

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let image = bitmapContext.makeImage() else { throw NSError(domain: "IconGenerator", code: 2) }
    let bitmap = NSBitmapImageRep(cgImage: image)
    let data = bitmap.representation(using: .png, properties: [:])!
    try data.write(to: output.appendingPathComponent(filename))
}

for (filename, size) in sizes { try drawIcon(filename: filename, size: size) }
try Data(contentsOf: output.appendingPathComponent("Icon-1024.png")).write(to: output.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("AppIcon-1024.png"))
print("Generated \(sizes.count) opaque app icons at \(output.path)")
