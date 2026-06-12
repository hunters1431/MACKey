import SwiftUI

// MARK: - Shortcut chip

/// A small monospaced pill rendering a key combination, e.g. "⌘1".
struct ShortcutChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.15))
            )
            .fixedSize()
    }
}

// MARK: - Column ① row: system shortcut (read-only)

struct SystemShortcutRow: View {
    let item: SystemShortcut

    var body: some View {
        HStack(spacing: 8) {
            Text(item.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 6)
            ShortcutChip(text: item.displayString)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Column ② row: an app that already has a binding (read-only summary)

struct AssignedAppRow: View {
    let entry: AppEntry

    var body: some View {
        HStack(spacing: 8) {
            icon
            Text(entry.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 6)
            if let s = entry.shortcut {
                ShortcutChip(text: s.displayString)
            }
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private var icon: some View {
        if let img = entry.icon {
            Image(nsImage: img)
                .resizable()
                .interpolation(.high)
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: "app.dashed")
                .frame(width: 18, height: 18)
                .foregroundColor(.secondary)
        }
    }
}
