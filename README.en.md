<p align="center">
  <img src="docs/icon.png" width="120" alt="MACKey">
</p>

<h1 align="center">MACKey</h1>

<p align="center">Your all-in-one macOS keyboard-shortcut hub — browse system shortcuts, bind custom ones to any app, and quick-launch from the Dock.</p>

<p align="center"><a href="README.md">中文说明</a></p>

On macOS, shortcuts are scattered everywhere: system ones are buried in System Settings, every app keeps its own, and there's no single place to add a global hotkey for a program. **MACKey lives in your menu bar and brings all three together in one panel** — so you can see and control every shortcut at a glance.

## Three pillars

### 1️⃣ Browse system shortcuts
See macOS's built-in global shortcuts in one place — Spotlight, screenshots, Mission Control, input-source switching, Spaces, and more. It merges the **factory defaults with your own customizations**, so you don't have to dig through System Settings. When you set your own shortcut, conflicts are flagged **by name**: "taken by the system's Screenshot."

### 2️⃣ Custom app shortcuts
Bind **any** key combo to **any** app (not just Dock apps). Click +, pick an app, record `⌥ + 1`, `⌃ + ⇧ + K`, anything — it works globally, taking you straight to the apps you use most.

### 3️⃣ Dock shortcuts
The first 10 Dock apps work **out of the box**, auto-bound to `⌃1`…`⌃0` for instant launch / switch — re-mappable anytime. Inspired by the classic Snap.

---

Plus: live **conflict detection** while recording (system / other-app clashes highlighted by name), a **launch-at-login** toggle, **menu-bar-only** footprint, and **English / Chinese** following your system language.

## Install

1. Download the latest `MACKey-x.y.z.dmg` from [Releases](../../releases).
2. Open it and drag `MACKey.app` into `Applications`.
3. First launch: because the app isn't notarized (no paid Apple Developer account), Gatekeeper will block it. **Right-click → Open**, then confirm. (Once only.)
   - Or run: `xattr -dr com.apple.quarantine /Applications/MACKey.app`
4. Grant **Accessibility** permission (required for global hotkeys):
   System Settings → Privacy & Security → Accessibility → enable MACKey.

## Usage

Click the `⌘K` menu-bar item → "Shortcut Settings…" to open the three-column panel, one per pillar:

- **System Shortcuts** (left): read-only reference of what's already taken.
- **App Shortcuts** (middle): click + to add any app and record any combo.
- **By Dock Order** (right): first 10 Dock apps are pre-bound to `⌃digit`; click a field to rebind.

While recording, press a combo that includes `⌘/⌃/⌥/⇧`. `Esc` cancels, `×` clears.

> Note: `⌃1`–`⌃3` may clash with "Switch to Desktop N" if Spaces shortcuts are enabled — just pick another key (the red hint flags it).

## Build from source

Requires macOS 13+ and the Swift 6 toolchain.

```bash
git clone https://github.com/hunters1431/MACKey.git
cd MACKey
swift run             # run (debug)
./scripts/make_icon.swift  # regenerate the app icon (optional)
./scripts/package.sh  # produce MACKey.app + DMG
```

Built with Swift + SwiftUI + AppKit; global hotkeys via [HotKey](https://github.com/soffes/HotKey).

## Support

If MACKey helps you, consider supporting development — see the "☕ Support" item in the menu, or [Ko-fi](https://ko-fi.com/hunters1431) / [PayPal](https://paypal.me/hunters1431).

## License

[MIT](LICENSE)
