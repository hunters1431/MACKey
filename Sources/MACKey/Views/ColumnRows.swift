import SwiftUI

// MARK: - Shortcut chip

/// A monospaced bordered pill rendering a key combination, e.g. "⌘ + Space".
/// Styled to match the recorder pills in columns ②③ for a consistent look.
struct ShortcutChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13.5, weight: .semibold, design: .monospaced))
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                    )
            )
            .fixedSize()
    }
}

// MARK: - Column ① row: system shortcut (read-only)

struct SystemShortcutRow: View {
    let item: SystemShortcut

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: Self.icon(for: item.name))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
            Text(item.name)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            ShortcutChip(text: item.displayString)
        }
        .padding(.vertical, 6)
    }

    /// A meaningful SF Symbol per system shortcut, keyed on its name.
    static func icon(for name: String) -> String {
        switch true {
        case name.contains("截屏"):                       return "camera"
        case name.contains("输入法"):                     return "globe"
        case name.contains("Spotlight"), name.contains("聚焦"): return "magnifyingglass"
        case name.contains("调度中心"), name.contains("应用程序窗口"): return "rectangle.3.group"
        case name.contains("空间"), name.contains("桌面"): return "rectangle.split.3x1"
        case name.contains("启动台"):                     return "square.grid.3x3"
        case name.contains("通知"):                       return "bell"
        case name.contains("听写"):                       return "mic"
        case name.contains("勿扰"):                       return "moon"
        case name.contains("备忘"):                       return "note.text"
        default:                                         return "command"
        }
    }
}
