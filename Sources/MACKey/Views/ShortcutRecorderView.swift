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

    private func setup() {
        bezelStyle = .rounded
        focusRingType = .none
        font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        target = self
        action = #selector(toggle)
        refreshAppearance()
    }

    // MARK: Display

    func refreshAppearance() {
        if let msg = conflictMessage {
            title = msg
            contentTintColor = .systemRed
        } else if isRecording {
            title = L("rec.recording")
            contentTintColor = .systemOrange
        } else if let s = shortcut {
            title = s.displayString
            contentTintColor = .labelColor
        } else {
            title = L("rec.empty")
            contentTintColor = .secondaryLabelColor
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
