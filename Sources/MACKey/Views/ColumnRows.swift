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
            Image(systemName: item.icon)
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
}
