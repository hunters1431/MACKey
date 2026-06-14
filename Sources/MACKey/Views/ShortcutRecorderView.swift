import SwiftUI
import AppKit

// MARK: - SwiftUI wrapper

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var shortcut: ShortcutBinding?
    @Binding var isRecording: Bool
    /// The entry being edited — used to exclude itself from conflict checking.
    var entryID: UUID?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> RecorderButton {
        let btn = RecorderButton()
        btn.coordinator = context.coordinator
        return btn
    }

    func updateNSView(_ btn: RecorderButton, context: Context) {
        btn.shortcut = shortcut
        btn.entryID = entryID
        if isRecording && !btn.isRecording { btn.beginRecording() }
        btn.refreshAppearance()
    }

    // MARK: Coordinator

    final class Coordinator {
        var parent: ShortcutRecorderView
        init(_ parent: ShortcutRecorderView) { self.parent = parent }

        func commit(_ binding: ShortcutBinding?) {
            parent.shortcut = binding
            parent.isRecording = false
        }

        func cancelRecording() {
            parent.isRecording = false
        }
    }
}

// MARK: - RecorderButton

final class RecorderButton: NSButton {
    var coordinator: ShortcutRecorderView.Coordinator?
    var shortcut: ShortcutBinding?
    var entryID: UUID?
    private(set) var isRecording = false
    private var conflictMessage: String?   // non-nil → show error state
    private var monitor: Any?
    private var conflictClearTask: DispatchWorkItem?

    override init(frame: NSRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    /// True when a real shortcut is shown (not recording / conflict / empty).
    private var isBound: Bool { shortcut != nil && conflictMessage == nil && !isRecording }

    private func setup() {
        isBordered = false   // we draw our own pill background in draw(_:)
        focusRingType = .none
        font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        target = self
        action = #selector(toggle)
        refreshAppearance()
    }

    // MARK: Display

    func refreshAppearance() {
        // Bound state is rendered as individual keycaps in draw(_:), so its
        // title stays empty; other states show a single centered label.
        let text: String
        let color: NSColor
        if let msg = conflictMessage {
            text = msg; color = .systemRed
        } else if isRecording {
            text = L("rec.recording"); color = .systemOrange
        } else if shortcut != nil {
            text = ""; color = .clear
        } else {
            text = L("rec.empty"); color = .secondaryLabelColor
        }
        let para = NSMutableParagraphStyle(); para.alignment = .center
        attributedTitle = NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: color,
            .paragraphStyle: para,
        ])
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        if isBound, let s = shortcut {
            drawKeycaps(s.displayTokens)
            return
        }
        // Empty state: faint outline so it still reads as a clickable field.
        if conflictMessage == nil && !isRecording {
            let tsize = attributedTitle.size()
            let pillW = min(bounds.width, max(tsize.width + 16, 24))
            let pillH = min(bounds.height, tsize.height + 6)
            let rect = NSRect(x: bounds.midX - pillW / 2, y: bounds.midY - pillH / 2,
                              width: pillW, height: pillH).integral
            let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
            NSColor.tertiaryLabelColor.setStroke()
            path.lineWidth = 0.5
            path.stroke()
        }
        super.draw(dirtyRect)
    }

    /// Draws each key token as its own filled accent keycap, centered as a group.
    private func drawKeycaps(_ tokens: [String]) {
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        let gap: CGFloat = 4, padX: CGFloat = 6
        let h = min(bounds.height, 20)

        let sizes = tokens.map { ($0 as NSString).size(withAttributes: attrs) }
        let widths = sizes.map { max(20, $0.width + padX * 2) }
        let total = widths.reduce(0, +) + gap * CGFloat(max(0, tokens.count - 1))

        var x = (bounds.width - total) / 2
        let y = (bounds.height - h) / 2
        let fill = Theme.shared.accent.nsColor

        for (i, token) in tokens.enumerated() {
            let rect = NSRect(x: x, y: y, width: widths[i], height: h).integral
            let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
            fill.setFill(); path.fill()
            let tsize = sizes[i]
            let textRect = NSRect(x: rect.minX, y: rect.midY - tsize.height / 2,
                                  width: rect.width, height: tsize.height)
            let para = NSMutableParagraphStyle(); para.alignment = .center
            var tattrs = attrs; tattrs[.paragraphStyle] = para
            (token as NSString).draw(in: textRect, withAttributes: tattrs)
            x += widths[i] + gap
        }
    }

    // MARK: Toggle

    @objc private func toggle() {
        if conflictMessage != nil { clearConflict(); return }
        isRecording ? stopRecording(save: false) : beginRecording()
    }

    // MARK: Recording lifecycle

    func beginRecording() {
        guard !isRecording else { return }
        isRecording = true
        refreshAppearance()

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            // Esc → cancel
            if event.keyCode == 53 {
                self.stopRecording(save: false)
                return nil
            }

            let mods = event.modifierFlags.intersection([.command, .option, .shift, .control])
            guard !mods.isEmpty else { return event }   // at least one modifier required

            let candidate = ShortcutBinding(
                keyCode: UInt32(event.keyCode),
                modifierFlags: mods.rawValue
            )
            self.validate(candidate)
            return nil
        }
    }

    // MARK: Conflict validation

    private func validate(_ binding: ShortcutBinding) {
        let result = ShortcutManager.shared.checkConflict(binding: binding, excludingID: entryID)
        stopRecording(save: false)   // always end recording first

        switch result {
        case .none:
            coordinator?.commit(binding)

        case .sameApp(let name):
            showConflict(L("rec.conflict.app", name))

        case .systemNamed(let name):
            showConflict(L("rec.conflict.system", name))

        case .system:
            showConflict(L("rec.conflict.other"))
        }
    }

    private func showConflict(_ message: String) {
        conflictClearTask?.cancel()
        conflictMessage = message
        refreshAppearance()

        let task = DispatchWorkItem { [weak self] in
            self?.clearConflict()
        }
        conflictClearTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
    }

    private func clearConflict() {
        conflictMessage = nil
        refreshAppearance()
    }

    // MARK: Stop recording

    private func stopRecording(save: Bool, binding: ShortcutBinding? = nil) {
        isRecording = false
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        if save { coordinator?.commit(binding) }
        refreshAppearance()
    }

    deinit {
        if let m = monitor { NSEvent.removeMonitor(m) }
        conflictClearTask?.cancel()
    }
}
