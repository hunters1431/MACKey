import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject private var store = SettingsStore.shared
    @ObservedObject private var theme = Theme.shared
    @State private var systemShortcuts: [SystemShortcut] = []

    /// First N Dock apps — the ones that get auto-assigned ⌃1…⌃0.
    private var dockApps: [AppEntry] {
        Array(store.entries.prefix(SettingsStore.autoAssignCount))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            columns
        }
        .frame(minWidth: 920, minHeight: 560)
        .tint(theme.accent.color)
        .onAppear(perform: loadSystemShortcuts)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            BrandKeycap(size: 36, accent: theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text("MACKey")
                    .font(.title2.weight(.semibold))
                Text(L("app.subtitle"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            #if APPSTORE
            themePicker
            #endif

            Button {
                store.refreshFromDock()
                loadSystemShortcuts()
            } label: {
                Label(L("btn.refresh"), systemImage: "arrow.clockwise")
            }

            Button {
                DonationWindowController.shared.show()
            } label: {
                Label(L("btn.support"), systemImage: "heart")
                    .font(.callout)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    #if APPSTORE
    /// Five curated accent swatches; the active one gets a ring. App Store only.
    private var themePicker: some View {
        HStack(spacing: 7) {
            ForEach(AccentTheme.allCases) { t in
                Button {
                    theme.accent = t
                } label: {
                    Circle()
                        .fill(t.color)
                        .frame(width: 15, height: 15)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(theme.accent == t ? 0.85 : 0), lineWidth: 1.5)
                                .padding(-3)
                        )
                }
                .buttonStyle(.plain)
                .help(L(t.nameKey))
            }
        }
        .padding(.trailing, 4)
    }
    #endif

    // MARK: - Three columns

    private var systemColumnTitle: String {
        #if APPSTORE
        return L("col.system.store")
        #else
        return L("col.system")
        #endif
    }

    private var columns: some View {
        HStack(spacing: 0) {
            column(
                title: systemColumnTitle, systemImage: "command",
                count: systemShortcuts.count,
                hint: L("hint.system"),
                footer: AnyView(systemSettingsLink)
            ) {
                systemColumnContent
            }

            Divider()

            column(
                title: L("col.custom"), systemImage: "star.fill",
                count: store.customEntries.count,
                hint: L("hint.custom"),
                note: store.customEntries.count > 1 ? L("note.reorder") : nil,
                accessory: AnyView(addButton)
            ) {
                if store.customEntries.isEmpty {
                    emptyHint(L("empty.custom"))
                } else {
                    List {
                        ForEach(store.customEntries) { CustomAppRow(entry: $0) }
                            .onMove { store.moveCustomEntry(from: $0, to: $1) }
                    }
                    .listStyle(.plain)
                }
            }

            Divider()

            column(
                title: L("col.dock"), systemImage: "menubar.dock.rectangle",
                count: dockApps.count,
                hint: L("hint.dock")
            ) {
                if dockApps.isEmpty {
                    emptyHint(L("empty.dock"))
                } else {
                    List(dockApps) { AppRowView(entry: $0) }
                        .listStyle(.plain)
                }
            }
        }
    }

    // MARK: - Column scaffold

    @ViewBuilder
    private func column<Content: View>(
        title: String,
        systemImage: String,
        count: Int,
        hint: String,
        note: String? = nil,
        accessory: AnyView? = nil,
        footer: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                if let note {
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Text("\(count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                Spacer()
                if let accessory { accessory }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)

            Divider()

            content()

            Divider()

            Group {
                if let footer {
                    footer
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text(hint)
                            .font(.caption2)
                        Spacer()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Column ① (system shortcuts)

    @ViewBuilder
    private var systemColumnContent: some View {
        if systemShortcuts.isEmpty {
            emptyHint(L("empty.system"))
        } else {
            List(systemShortcuts) { SystemShortcutRow(item: $0) }
                .listStyle(.plain)
        }
    }

    private var systemSettingsLink: some View {
        Button(action: openKeyboardSettings) {
            HStack(spacing: 5) {
                Image(systemName: "gearshape")
                    .font(.system(size: 10))
                Text(L("sys.openSettings"))
                    .font(.caption2)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9))
            }
            .foregroundColor(.secondary)
        }
        .buttonStyle(.borderless)
    }

    private func openKeyboardSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private var addButton: some View {
        Button(action: addCustomApp) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 15))
                .foregroundColor(theme.accent.color)
        }
        .buttonStyle(.borderless)
        .help(L("tip.add"))
    }

    private func addCustomApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = L("panel.add")
        panel.message = L("panel.msg")
        if panel.runModal() == .OK {
            panel.urls.forEach { SettingsStore.shared.addCustomApp(at: $0) }
        }
    }

    private func emptyHint(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func loadSystemShortcuts() {
        systemShortcuts = SystemShortcutReader.curatedList()
    }
}
