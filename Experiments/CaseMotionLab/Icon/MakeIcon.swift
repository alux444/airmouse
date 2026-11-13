import AppKit

let outputPath = CommandLine.arguments[1]
let sizes: [(String, Int)] = [
    ("icp4", 16), ("icp5", 32), ("icp6", 64),
    ("ic07", 128), ("ic08", 256), ("ic09", 512), ("ic10", 1024)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func drawIcon() {
    let background = NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 202, yRadius: 202)
    NSGradient(starting: color(0.31, 0.38, 0.46), ending: color(0.14, 0.19, 0.25))!
        .draw(in: background, angle: 90)

    let shadow = NSShadow()
    shadow.shadowColor = color(0.02, 0.04, 0.07, 0.32)
    shadow.shadowBlurRadius = 45
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    let caseShape = NSBezierPath(roundedRect: NSRect(x: 237, y: 277, width: 550, height: 437), xRadius: 152, yRadius: 152)
    NSGradient(starting: color(1, 1, 1), ending: color(0.79, 0.82, 0.85))!
        .draw(in: caseShape, angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    caseShape.addClip()
    let seam = NSBezierPath()
    seam.move(to: NSPoint(x: 237, y: 561))
    seam.curve(to: NSPoint(x: 787, y: 561), controlPoint1: NSPoint(x: 388, y: 546), controlPoint2: NSPoint(x: 636, y: 546))
    seam.lineWidth = 3
    color(0.43, 0.47, 0.51, 0.45).setStroke()
    seam.stroke()
    NSGraphicsContext.restoreGraphicsState()

    color(0.45, 0.66, 0.59).setFill()
    NSBezierPath(ovalIn: NSRect(x: 503, y: 430, width: 18, height: 18)).fill()

    let cursor = NSBezierPath()
    cursor.move(to: NSPoint(x: 690, y: 303))
    cursor.line(to: NSPoint(x: 690, y: 157))
    cursor.line(to: NSPoint(x: 728, y: 193))
    cursor.line(to: NSPoint(x: 749, y: 147))
    cursor.line(to: NSPoint(x: 776, y: 160))
    cursor.line(to: NSPoint(x: 755, y: 205))
    cursor.line(to: NSPoint(x: 807, y: 207))
    cursor.close()
    cursor.lineJoinStyle = .round
    cursor.lineWidth = 14
    color(0.17, 0.22, 0.28).setStroke()
    cursor.stroke()
    NSColor.white.setFill()
    cursor.fill()
}

func iconChunk(type: String, image: Data) -> Data {
    var chunk = Data(type.utf8)
    var length = UInt32(image.count + 8).bigEndian
    withUnsafeBytes(of: &length) { chunk.append(contentsOf: $0) }
    chunk.append(image)
    return chunk
}

var iconImages = Data()
for (type, pixels) in sizes {
    let image = NSImage(size: NSSize(width: pixels, height: pixels))
    image.lockFocus()
    let transform = NSAffineTransform()
    transform.scale(by: CGFloat(pixels) / 1024)
    transform.concat()
    drawIcon()
    image.unlockFocus()
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render app icon")
    }
    iconImages.append(iconChunk(type: type, image: png))
}
try iconChunk(type: "icns", image: iconImages).write(to: URL(fileURLWithPath: outputPath))
