import SwiftUI

struct AppRowView: View {
    let entry: AppEntry
    @ObservedObject private var theme = Theme.shared   // re-render pills on theme change
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 10) {
            appIcon
            appName
            Spacer()
            ShortcutRecorderView(
                shortcut: Binding(
                    get: { entry.shortcut },
                    set: { SettingsStore.shared.updateShortcut(for: entry.id, binding: $0) }
                ),
                isRecording: $isRecording,
                entryID: entry.id
            )
            .frame(width: 136, height: 24)

            clearButton
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

    private var appName: some View {
        Text(entry.name)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    @ViewBuilder
    private var clearButton: some View {
        if entry.shortcut != nil {
            Button {
                SettingsStore.shared.updateShortcut(for: entry.id, binding: nil)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        } else {
            // placeholder to keep layout stable
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.clear)
        }
    }
}
