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
        }
        .frame(minWidth: 920, minHeight: 560)
        .onAppear(perform: loadSystemShortcuts)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            appIcon
            VStack(alignment: .leading, spacing: 1) {
                Text("MACKey")
                    .font(.title2.weight(.semibold))
                Text("程序快捷键启动器")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                DonationWindowController.shared.show()
            } label: {
                Label("支持作者", systemImage: "cup.and.saucer.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .controlSize(.large)

            Button {
                store.refreshFromDock()
                loadSystemShortcuts()
            } label: {
                Label("从 Dock 刷新", systemImage: "arrow.clockwise")
            }
            .controlSize(.large)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var appIcon: some View {
        if let img = Self.appIconImage() {
            Image(nsImage: img)
                .resizable()
                .interpolation(.high)
                .frame(width: 40, height: 40)
        } else {
            Image(systemName: "keyboard")
                .font(.system(size: 30))
                .foregroundColor(.accentColor)
        }
    }

    // MARK: - Three columns

    private var columns: some View {
        HStack(spacing: 0) {
            column(
                title: "系统快捷键清单", systemImage: "command",
                count: systemShortcuts.count,
                hint: "读自系统设置，仅显示已启用项"
            ) {
                if systemShortcuts.isEmpty {
                    emptyHint("未读取到已启用的系统快捷键")
                } else {
                    List(systemShortcuts) { SystemShortcutRow(item: $0) }
                        .listStyle(.plain)
                }
            }

            Divider()

            column(
                title: "定向程序快捷键", systemImage: "star.fill",
                count: store.customEntries.count,
                hint: "点「+」添加任意程序，可绑任意组合键",
                accessory: AnyView(addButton)
            ) {
                if store.customEntries.isEmpty {
                    emptyHint("点右上「+」添加任意程序\n再录制任意组合键")
                } else {
                    List(store.customEntries) { CustomAppRow(entry: $0) }
                        .listStyle(.plain)
                }
            }

            Divider()

            column(
                title: "按程序坞排序", systemImage: "menubar.dock.rectangle",
                count: dockApps.count,
                hint: "前 10 个自动绑定 ⌃ 数字；点快捷键栏可改键"
            ) {
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
        hint: String,
        accessory: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 13))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
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

            HStack(spacing: 5) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                Text(hint)
                    .font(.caption2)
                Spacer()
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var addButton: some View {
        Button(action: addCustomApp) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 15))
                .foregroundColor(.accentColor)
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
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func loadSystemShortcuts() {
        systemShortcuts = SystemShortcutReader.readEnabled()
            .sorted { $0.name < $1.name }
    }

    private static func appIconImage() -> NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return NSApp.applicationIconImage
    }
}
