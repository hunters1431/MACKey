import SwiftUI

// MARK: - Keycaps

/// Renders a key combination as separate keycaps (no "+"), e.g. ⌘ Space.
/// `accent` non-nil → filled accent keycaps with white legend (columns ②③);
/// nil → neutral outlined keycaps (column ①, read-only reference).
struct KeyCapsView: View {
    let tokens: [String]
    var accent: Color? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                Text(token)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(accent == nil ? .primary : .white)
                    .padding(.horizontal, 6)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(keycapBackground)
            }
        }
        .fixedSize()
    }

    @ViewBuilder
    private var keycapBackground: some View {
        if let accent {
            RoundedRectangle(cornerRadius: 5).fill(accent)
        } else {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.secondary.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
        }
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
            KeyCapsView(tokens: item.displayTokens)
        }
        .padding(.vertical, 6)
    }
}
