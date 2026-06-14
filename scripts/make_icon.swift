// Generates MACKey.iconset PNGs: a teal squircle tile with a large white ⌘.
// Teal (#0F6E56) is the locked brand color (the in-app theme can recolor the
// UI, but the static app icon stays teal). Run:
//   swift scripts/make_icon.swift
// Then: iconutil -c icns MACKey.iconset -o Resources/AppIcon.icns
import AppKit

let outDir = "MACKey.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func roundedFont(_ size: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: .semibold)
    if let d = base.fontDescriptor.withDesign(.rounded) {
        return NSFont(descriptor: d, size: size) ?? base
    }
    return base
}

func render(_ px: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let gctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gctx
    let ctx = gctx.cgContext
    let s = CGFloat(px)

    // Squircle clip
    let radius = s * 0.225
    let path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                      cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(path); ctx.clip()

    // Teal tile with a subtle vertical lift (top a touch lighter for depth)
    let cs = CGColorSpaceCreateDeviceRGB()
    let top = NSColor(srgbRed: 0x16 / 255, green: 0x84 / 255, blue: 0x68 / 255, alpha: 1).cgColor
    let bottom = NSColor(srgbRed: 0x0C / 255, green: 0x5A / 255, blue: 0x46 / 255, alpha: 1).cgColor
    let grad = CGGradient(colorsSpace: cs, colors: [top, bottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])

    // Large "⌘" centered, white, rounded-semibold
    let fontSize = s * 0.56
    let para = NSMutableParagraphStyle(); para.alignment = .center
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: 0.20)
    shadow.shadowBlurRadius = s * 0.018
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.012)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: roundedFont(fontSize),
        .foregroundColor: NSColor.white,
        .paragraphStyle: para,
        .shadow: shadow,
    ]
    let str = NSAttributedString(string: "⌘", attributes: attrs)
    let tsize = str.size()
    str.draw(in: CGRect(x: (s - tsize.width) / 2, y: (s - tsize.height) / 2,
                        width: tsize.width, height: tsize.height))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let plan: [(Int, String)] = [
    (16, "icon_16x16"), (32, "icon_16x16@2x"),
    (32, "icon_32x32"), (64, "icon_32x32@2x"),
    (128, "icon_128x128"), (256, "icon_128x128@2x"),
    (256, "icon_256x256"), (512, "icon_256x256@2x"),
    (512, "icon_512x512"), (1024, "icon_512x512@2x"),
]

var cache: [Int: Data] = [:]
for (px, name) in plan {
    let data: Data
    if let c = cache[px] {
        data = c
    } else {
        data = render(px).representation(using: .png, properties: [:])!
        cache[px] = data
    }
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
    print("  \(name).png  (\(px)px)")
}
print("iconset written to \(outDir)")
