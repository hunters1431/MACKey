<p align="center">
  <img src="docs/icon.png" width="120" alt="MACKey">
</p>

<h1 align="center">MACKey</h1>

<p align="center">
  <a href="https://github.com/hunters1431/MACKey/releases"><img src="https://img.shields.io/github/v/release/hunters1431/MACKey?color=blue&label=release" alt="Latest Release"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?logo=apple&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

<p align="center"><b>Open any app with one key.</b></p>

<p align="center">The macOS shortcut hub: every shortcut at a glance — look up system keys, customize any app, order them your way.</p>

<p align="center"><a href="README.zh.md">中文说明</a></p>

## Why MACKey

- 🚀 **Works out of the box** — your first 10 Dock apps are auto-bound to `⌃1`…`⌃0`; zero setup, instant switching
- 🎯 **Bind anything** — any app × any key combo, global, one keystroke to your most-used apps
- 🔍 **See it all** — system shortcuts ranked by real-world frequency, your customizations synced live; no more digging through System Settings
- 🛡️ **Never collide** — live conflict detection while recording, named warnings like "taken by the system's Screenshot"
- 🔒 **Private by design** — runs 100% locally; no network, no tracking, no data ever leaves your Mac

> A tribute to the classic Snap. As Rosetta 2 retires, Intel apps will stop running on Apple silicon — MACKey is native ARM, picking up the baton.

Menu-bar only · Launch at login · English & Chinese · Free & open source

## Screenshot

<p align="center">
  <img src="docs/screenshot_en.jpg" alt="MACKey English UI" width="800">
</p>

## Install

1. Download the latest `MACKey-x.y.z.dmg` from [Releases](../../releases).
2. Open it and drag `MACKey.app` into `Applications`.
3. First launch: because the app isn't notarized (no paid Apple Developer account), Gatekeeper will block it. **Right-click → Open**, then confirm. (Once only.)
   - Or run: `xattr -dr com.apple.quarantine /Applications/MACKey.app`
4. Grant **Accessibility** permission (required for global hotkeys):
   System Settings → Privacy & Security → Accessibility → enable MACKey.

## Usage

Click the `⌘K` menu-bar item → "Shortcut Settings…" to open the three-column panel:

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
