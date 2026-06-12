import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject private var store = SettingsStore.shared
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
            Divider()
            footer
        }
        .frame(minWidth: 880, minHeight: 540)
        .onAppear(perform: loadSystemShortcuts)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "keyboard")
                .font(.title3)
                .foregroundColor(.accentColor)
            Text("MACKey")
                .font(.headline)
            Spacer()
            Button {
                store.refreshFromDock()
                loadSystemShortcuts()
            } label: {
                Label("从 Dock 刷新", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Three columns

    private var columns: some View {
        HStack(spacing: 0) {
            // ① System shortcuts (read-only)
            column(title: "系统快捷键清单", systemImage: "command", count: systemShortcuts.count) {
                if systemShortcuts.isEmpty {
                    emptyHint("未读取到已启用的系统快捷键")
                } else {
                    List(systemShortcuts) { SystemShortcutRow(item: $0) }
                        .listStyle(.plain)
                }
            }

            Divider()

            // ② User-curated apps with arbitrary custom shortcuts (editable)
            column(title: "定向程序快捷键", systemImage: "star.fill",
                   count: store.customEntries.count, accessory: AnyView(addButton)) {
                if store.customEntries.isEmpty {
                    emptyHint("点右上「+」添加任意程序\n再录制任意组合键")
                } else {
                    List(store.customEntries) { CustomAppRow(entry: $0) }
                        .listStyle(.plain)
                }
            }

            Divider()

            // ③ First 10 Dock apps, auto-assigned ⌃1…⌃0 (editable)
            column(title: "按程序坞排序", systemImage: "menubar.dock.rectangle", count: dockApps.count) {
                if dockApps.isEmpty {
                    emptyHint("未从 Dock 读取到应用")
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
        accessory: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                Spacer()
                if let accessory { accessory }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var addButton: some View {
        Button(action: addCustomApp) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
        }
        .buttonStyle(.borderless)
        .help("添加应用")
    }

    private func addCustomApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "添加"
        panel.message = "选择要绑定快捷键的程序"
        if panel.runModal() == .OK {
            panel.urls.forEach { SettingsStore.shared.addCustomApp(at: $0) }
        }
    }

    private func emptyHint(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            Text("前 10 个程序坞应用已自动绑定 ⌃1…⌃0；点快捷键栏可改键，红色提示表示与系统或其他程序冲突")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                DonationWindowController.shared.show()
            } label: {
                Label("支持作者", systemImage: "cup.and.saucer")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Data

    private func loadSystemShortcuts() {
        systemShortcuts = SystemShortcutReader.readEnabled()
            .sorted { $0.name < $1.name }
    }
}
