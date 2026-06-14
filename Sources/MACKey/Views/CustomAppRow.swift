import SwiftUI

/// Row for column ② (定向程序快捷键): a user-added app with an arbitrary
/// custom shortcut and a remove button.
struct CustomAppRow: View {
    let entry: AppEntry
    @ObservedObject private var theme = Theme.shared   // re-render pill on theme change
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 10) {
            appIcon
            Text(entry.name)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            ShortcutRecorderView(
                shortcut: Binding(
                    get: { entry.shortcut },
                    set: { SettingsStore.shared.updateCustomShortcut(for: entry.id, binding: $0) }
                ),
                isRecording: $isRecording,
                entryID: entry.id
            )
            .frame(width: 136, height: 24)

            Button {
                SettingsStore.shared.removeCustomEntry(id: entry.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            .help(L("tip.remove"))
        }
        .padding(.vertical, 7)
    }

    @ViewBuilder
    private var appIcon: some View {
        if let icon = entry.icon {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: "app.dashed")
                .frame(width: 24, height: 24)
                .foregroundColor(.secondary)
        }
    }
}
