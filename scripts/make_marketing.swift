// Renders App Store marketing screenshots (2560×1600) for MACKey.
//   marketing/three-col/teal/<lang>.png   — 5 languages
//   marketing/three-col/amber/en.png
//   marketing/three-col/coral/en.png
//   marketing/privacy/<lang>.png          — 5 languages, teal
// Per region, ship 4: three-col/teal/<lang>, three-col/amber/en,
//   three-col/coral/en, privacy/<lang>.
// Run:  swift scripts/make_marketing.swift
import AppKit

let W = 2560, H = 1600
let M: CGFloat = 150

let teal  = NSColor(srgbRed: 0x0F/255, green: 0x6E/255, blue: 0x56/255, alpha: 1)
let amber = NSColor(srgbRed: 0xC2/255, green: 0x82/255, blue: 0x0C/255, alpha: 1)
let coral = NSColor(srgbRed: 0xCE/255, green: 0x5A/255, blue: 0x2E/255, alpha: 1)
let dots = [teal, amber, coral,
            NSColor(srgbRed: 0x2E/255, green: 0x68/255, blue: 0xD0/255, alpha: 1),
            NSColor(srgbRed: 0x58/255, green: 0x58/255, blue: 0x5B/255, alpha: 1)]

let inkDark = NSColor(srgbRed: 0.169, green: 0.157, blue: 0.137, alpha: 1)
let inkGray = NSColor(srgbRed: 0.60,  green: 0.59,  blue: 0.56,  alpha: 1)
let capNeutFill = NSColor(srgbRed: 0.945, green: 0.937, blue: 0.914, alpha: 1)
let capNeutEdge = NSColor(srgbRed: 0.86,  green: 0.85,  blue: 0.82,  alpha: 1)
let rowLine = NSColor(srgbRed: 0.93, green: 0.92, blue: 0.895, alpha: 1)

struct Lang {
    let code: String
    let h: String; let s: String
    let c1: String; let c2: String; let c3: String
    let s1: String; let s2: String; let s3: String
    let d1: String; let d2: String; let d3: String
    let ph: String; let psub: String
}

func sysFont(_ s: CGFloat, _ w: NSFont.Weight = .regular) -> NSFont { NSFont.systemFont(ofSize: s, weight: w) }
func monoFont(_ s: CGFloat, _ w: NSFont.Weight = .semibold) -> NSFont { NSFont.monospacedSystemFont(ofSize: s, weight: w) }

func fitFont(_ str: String, base: CGFloat, weight: NSFont.Weight, maxW: CGFloat, minSize: CGFloat) -> NSFont {
    var size = base
    while size > minSize {
        let f = sysFont(size, weight)
        if (str as NSString).size(withAttributes: [.font: f]).width <= maxW { return f }
        size -= 2
    }
    return sysFont(minSize, weight)
}

func text(_ s: String, font: NSFont, color: NSColor, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, align: NSTextAlignment = .left) {
    let p = NSMutableParagraphStyle(); p.alignment = align; p.lineBreakMode = .byTruncatingTail
    (s as NSString).draw(in: NSRect(x: x, y: y, width: w, height: h),
                         withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: p])
}

func roundRect(_ r: NSRect, _ radius: CGFloat, fill: NSColor?, stroke: NSColor? = nil, lw: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
    if let f = fill { f.setFill(); path.fill() }
    if let st = stroke { st.setStroke(); path.lineWidth = lw; path.stroke() }
}

/// Draws an SF Symbol tinted to `color`, optically centered in `box`.
/// (Text glyphs sit high in their line box; symbol images center cleanly.)
func symbol(_ name: String, pointSize: CGFloat, color: NSColor, in box: NSRect) {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)) else { return }
    let tinted = NSImage(size: base.size)
    tinted.lockFocus()
    base.draw(at: .zero, from: NSRect(origin: .zero, size: base.size), operation: .sourceOver, fraction: 1)
    color.set(); NSRect(origin: .zero, size: base.size).fill(using: .sourceAtop)
    tinted.unlockFocus()
    tinted.draw(in: NSRect(x: box.midX - base.size.width/2, y: box.midY - base.size.height/2,
                           width: base.size.width, height: base.size.height))
}

let capFont = monoFont(40, .semibold)
func capWidth(_ token: String) -> CGFloat { max(64, (token as NSString).size(withAttributes: [.font: capFont]).width + 34) }

func keycap(_ token: String, x: CGFloat, centerY: CGFloat, accent: NSColor?) -> CGFloat {
    let w = capWidth(token); let h: CGFloat = 66
    let r = NSRect(x: x, y: centerY - h/2, width: w, height: h)
    if let ac = accent { roundRect(r, 13, fill: ac) } else { roundRect(r, 13, fill: capNeutFill, stroke: capNeutEdge, lw: 1.5) }
    let tc = accent != nil ? NSColor.white : inkDark
    let ts = (token as NSString).size(withAttributes: [.font: capFont])
    text(token, font: capFont, color: tc, x: x, y: centerY - ts.height/2, w: w, h: ts.height + 4, align: .center)
    return w
}

func newCanvas() -> (NSBitmapImageRep, CGContext) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let cg = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    cg.translateBy(x: 0, y: CGFloat(H)); cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    return (rep, cg)
}

func render3col(_ lang: Lang, ac: NSColor, ring: Int) -> Data {
    let (rep, _) = newCanvas()
    ac.setFill(); NSRect(x: 0, y: 0, width: CGFloat(W), height: CGFloat(H)).fill()

    let chip = NSRect(x: M, y: 118, width: 54, height: 54)
    roundRect(chip, 13, fill: NSColor(white: 1, alpha: 0.18))
    symbol("command", pointSize: 28, color: .white, in: chip)
    text("MACKey", font: sysFont(35, .medium), color: .white, x: M + 74, y: 129, w: 600, h: 52)

    let maxW = CGFloat(W) - 2*M
    let hFont = fitFont(lang.h, base: 108, weight: .semibold, maxW: maxW, minSize: 60)
    text(lang.h, font: hFont, color: .white, x: M, y: 228, w: maxW, h: 150)
    let sFont = fitFont(lang.s, base: 48, weight: .regular, maxW: maxW, minSize: 32)
    text(lang.s, font: sFont, color: NSColor(white: 1, alpha: 0.88), x: M, y: 378, w: maxW, h: 72)

    let barH: CGFloat = 104, headH: CGFloat = 104, rowH: CGFloat = 150
    let winW = CGFloat(W) - 2*M
    let winH = barH + headH + 3*rowH + 26
    let winY = 470 + (CGFloat(H) - 470 - winH) / 2
    let win = NSRect(x: M, y: winY, width: winW, height: winH)
    roundRect(win, 30, fill: .white)

    let wchip = NSRect(x: win.minX + 32, y: win.minY + (barH-50)/2, width: 50, height: 50)
    roundRect(wchip, 12, fill: ac)
    symbol("command", pointSize: 26, color: .white, in: wchip)
    text("MACKey", font: sysFont(33, .medium), color: inkDark, x: win.minX + 96, y: win.minY + barH/2 - 25, w: 360, h: 50)
    var dx = win.maxX - 36 - CGFloat(dots.count) * 32 + 8
    for (i, c) in dots.enumerated() {
        let r = NSRect(x: dx, y: win.minY + barH/2 - 12, width: 24, height: 24)
        if i == ring { NSColor.white.setFill(); NSBezierPath(ovalIn: r.insetBy(dx: -8, dy: -8)).fill()
                       c.setFill(); NSBezierPath(ovalIn: r.insetBy(dx: -4.5, dy: -4.5)).fill() }
        c.setFill(); NSBezierPath(ovalIn: r).fill(); dx += 32
    }
    rowLine.setFill(); NSRect(x: win.minX, y: win.minY + barH, width: win.width, height: 1.5).fill()

    let colW = win.width / 3, bodyTop = win.minY + barH
    let cols: [(String, String)] = [(lang.c1, "20"), (lang.c2, "+"), (lang.c3, "10")]
    for (idx, col) in cols.enumerated() {
        let cx = win.minX + CGFloat(idx) * colW, cRight = cx + colW
        if idx > 0 { rowLine.setFill(); NSRect(x: cx, y: bodyTop, width: 1.5, height: win.maxY - bodyTop).fill() }
        text(col.0, font: sysFont(42, .medium), color: inkDark, x: cx + 36, y: bodyTop + headH/2 - 28, w: colW - 150, h: 56)
        if col.1 == "+" {
            let b = NSRect(x: cRight - 36 - 48, y: bodyTop + headH/2 - 24, width: 48, height: 48)
            roundRect(b, 24, fill: ac)
            text("+", font: sysFont(38, .regular), color: .white, x: b.minX, y: b.midY - 27, w: 48, h: 48, align: .center)
        } else {
            let bw = (col.1 as NSString).size(withAttributes: [.font: sysFont(30)]).width + 30
            let b = NSRect(x: cRight - 36 - bw, y: bodyTop + headH/2 - 21, width: bw, height: 42)
            roundRect(b, 21, fill: capNeutFill)
            text(col.1, font: sysFont(30), color: inkGray, x: b.minX, y: b.midY - 19, w: bw, h: 38, align: .center)
        }
        rowLine.setFill(); NSRect(x: cx, y: bodyTop + headH, width: colW, height: 1.5).fill()
        let rowsTop = bodyTop + headH
        let accent: NSColor? = (idx == 0) ? nil : ac
        let names = idx == 0 ? [lang.s1, lang.s2, lang.s3] : idx == 1 ? ["VS Code", "Notion", ""] : [lang.d1, lang.d2, lang.d3]
        let combos: [[String]] = idx == 0 ? [["⌘","Space"], ["⇧","⌘","4"], ["⌘","⇥"]]
                   : idx == 1 ? [["⌃","⌥","C"], ["⌃","⌥","N"], []] : [["⌃","1"], ["⌃","2"], ["⌃","3"]]
        for i in 0..<3 where !names[i].isEmpty {
            let cy = rowsTop + rowH * (CGFloat(i) + 0.5)
            let pad: CGFloat = 38, gap: CGFloat = 12
            let total = combos[i].map(capWidth).reduce(0, +) + gap * CGFloat(max(0, combos[i].count - 1))
            text(names[i], font: sysFont(46, .regular), color: inkDark, x: cx + pad, y: cy - 32, w: cRight - pad - total - cx - pad - 26, h: 64)
            var x = cRight - pad - total
            for t in combos[i] { x += keycap(t, x: x, centerY: cy, accent: accent) + gap }
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

func renderPrivacy(_ lang: Lang, ac: NSColor) -> Data {
    let (rep, _) = newCanvas()
    ac.setFill(); NSRect(x: 0, y: 0, width: CGFloat(W), height: CGFloat(H)).fill()

    let brand = "MACKey"
    let bf = sysFont(40, .medium)
    let bw = (brand as NSString).size(withAttributes: [.font: bf]).width
    let groupW = 60 + 22 + bw
    let bx = (CGFloat(W) - groupW) / 2
    let chip = NSRect(x: bx, y: 452, width: 60, height: 60)
    roundRect(chip, 15, fill: NSColor(white: 1, alpha: 0.18))
    symbol("command", pointSize: 30, color: .white, in: chip)
    text(brand, font: bf, color: .white, x: bx + 82, y: 462, w: bw + 20, h: 56)

    let box = NSRect(x: (CGFloat(W) - 168)/2, y: 580, width: 168, height: 168)
    roundRect(box, 38, fill: NSColor(white: 1, alpha: 0.15))
    symbol("lock.fill", pointSize: 84, color: .white, in: box)

    let hFont = fitFont(lang.ph, base: 96, weight: .semibold, maxW: CGFloat(W) - 2*M, minSize: 56)
    text(lang.ph, font: hFont, color: .white, x: M, y: 830, w: CGFloat(W) - 2*M, h: 130, align: .center)
    let sFont = fitFont(lang.psub, base: 46, weight: .regular, maxW: CGFloat(W) - 2*M, minSize: 30)
    text(lang.psub, font: sFont, color: NSColor(white: 1, alpha: 0.88), x: M, y: 968, w: CGFloat(W) - 2*M, h: 70, align: .center)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let langs: [Lang] = [
    Lang(code: "zh-Hans", h: "一个面板，掌控全机快捷键", s: "系统键速查 · 任意 App 定制 · 程序坞秒切",
         c1: "系统快捷键清单", c2: "定向程序快捷键", c3: "按程序坞排序",
         s1: "聚焦搜索", s2: "区域截屏", s3: "切换应用", d1: "Safari", d2: "邮件", d3: "备忘录",
         ph: "纯本地运行，隐私安全", psub: "不联网 · 不收集 · 不上传任何数据，全部留在你的 Mac"),
    Lang(code: "en", h: "One panel, every shortcut you own", s: "Look up system keys · customize any app · launch from the Dock",
         c1: "System Shortcuts", c2: "App Shortcuts", c3: "By Dock Order",
         s1: "Spotlight Search", s2: "Area Screenshot", s3: "Switch Apps", d1: "Safari", d2: "Mail", d3: "Notes",
         ph: "Runs entirely on your Mac", psub: "No network, no tracking, no data ever leaves your device"),
    Lang(code: "zh-Hant", h: "一個面板，掌握全機快速鍵", s: "系統鍵速查 · 任意 App 定製 · Dock 秒切",
         c1: "系統快速鍵清單", c2: "自訂應用程式快速鍵", c3: "依 Dock 順序",
         s1: "聚焦搜尋", s2: "區域截圖", s3: "切換應用程式", d1: "Safari", d2: "郵件", d3: "備忘錄",
         ph: "純本地運行，隱私安全", psub: "不聯網 · 不收集 · 不上傳任何資料，全部留在你的 Mac"),
    Lang(code: "ja", h: "すべてのショートカットを、ひとつのパネルで", s: "システムキーを確認・アプリを自由に設定・Dock から起動",
         c1: "システムショートカット", c2: "アプリショートカット", c3: "Dock の順序",
         s1: "Spotlight 検索", s2: "範囲スクショ", s3: "アプリ切替", d1: "Safari", d2: "メール", d3: "メモ",
         ph: "すべてローカルで動作", psub: "通信なし・収集なし・データが Mac の外に出ることはありません"),
    Lang(code: "de", h: "Ein Panel für alle Tastaturkürzel", s: "Systemkürzel nachschlagen · Apps anpassen · aus dem Dock starten",
         c1: "Systemkürzel", c2: "App-Kürzel", c3: "Nach Dock-Reihenfolge",
         s1: "Spotlight-Suche", s2: "Bereich-Screenshot", s3: "Apps wechseln", d1: "Safari", d2: "Mail", d3: "Notizen",
         ph: "Läuft komplett lokal", psub: "Kein Netzwerk, kein Tracking, keine Daten verlassen deinen Mac"),
]

let fm = FileManager.default
// Only clear the generated subdirs — preserve hand-made assets like demo.gif/mp4.
try? fm.removeItem(atPath: "marketing/three-col")
try? fm.removeItem(atPath: "marketing/privacy")

func write(_ data: Data, _ path: String) {
    let dir = (path as NSString).deletingLastPathComponent
    try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
    try! data.write(to: URL(fileURLWithPath: path)); print("  \(path)")
}

for lang in langs {
    write(render3col(lang, ac: teal, ring: 0), "marketing/three-col/teal/\(lang.code).png")
    write(renderPrivacy(lang, ac: teal), "marketing/privacy/\(lang.code).png")
}
let en = langs[1]
write(render3col(en, ac: amber, ring: 1), "marketing/three-col/amber/en.png")
write(render3col(en, ac: coral, ring: 2), "marketing/three-col/coral/en.png")
print("done")
