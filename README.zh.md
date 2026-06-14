<p align="center">
  <img src="docs/icon.png" width="120" alt="MACKey">
</p>

<h1 align="center">MACKey</h1>

<p align="center">
  <a href="https://github.com/hunters1431/MACKey/releases"><img src="https://img.shields.io/github/v/release/hunters1431/MACKey?color=blue&label=release" alt="最新版本"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?logo=apple&logoColor=white" alt="平台">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="许可证">
</p>

<p align="center"><b>一键秒开任何应用。</b></p>

<p align="center">macOS 快捷键中心：所有快捷键一目了然 —— 系统键可查、任意 App 可定制、顺序随心排。</p>

<p align="center"><a href="README.md">English</a></p>

## 为什么是 MACKey

- 🚀 **装好即用** —— 程序坞前 10 个应用自动绑定 `⌃1`…`⌃0`，零配置，按下秒切
- 🎯 **想绑就绑** —— 任意程序 × 任意组合键，全局生效，常用 App 一键直达
- 🔍 **一眼查全** —— 系统快捷键按使用频率排序，你的改动实时同步，不再翻系统设置
- 🛡️ **绝不撞键** —— 录制时实时冲突检测，具名提醒「该键已被系统『截屏』占用」
- 🔒 **隐私安全** —— 纯本地运行，不联网、不收集、不传输任何数据

> 致敬经典工具 Snap。Rosetta 2 即将谢幕，Intel 应用将无法在 Apple 芯片上运行 —— MACKey 原生 ARM，接棒续航。

纯菜单栏常驻 · 开机自启 · 中英双语 · 免费开源

## 截图

<p align="center">
  <img src="marketing/demo.gif" alt="MACKey 动态演示" width="820">
</p>
<p align="center">
  <img src="marketing/privacy/zh-Hans.png" alt="MACKey 纯本地运行" width="820">
</p>

## 安装

1. 从 [Releases](../../releases) 下载最新的 `MACKey-x.y.z.dmg`。
2. 打开 DMG，把 `MACKey.app` 拖进「应用程序」。
3. 首次打开：由于本应用未经 Apple 公证（无付费开发者账号），Gatekeeper 会拦截。**右键点击 → 打开**，在弹窗里再次点「打开」即可（只需一次）。
   - 或在终端执行：`xattr -dr com.apple.quarantine /Applications/MACKey.app`
4. 首次运行会请求**辅助功能（Accessibility）权限** —— 全局快捷键必须授权才能生效：
   系统设置 → 隐私与安全性 → 辅助功能 → 勾选 MACKey。

## 使用

点菜单栏的 `⌘K` → 「设置快捷键…」打开三列面板：

- **系统快捷键清单**（左）：只读速查，了解哪些键已被系统占用。
- **定向程序快捷键**（中）：点「+」添加任意程序，录制任意组合键。
- **按程序坞排序**（右）：前 10 个 Dock 应用已绑好 `⌃数字`，点快捷键栏可改键。

录制时按下含 `⌘/⌃/⌥/⇧` 的组合键即可，`Esc` 取消，`×` 清除。

> 注意：`⌃1`～`⌃3` 在开启「多桌面切换」时可能与系统「切换到桌面 N」冲突，届时改成其他键即可（红色提示会帮你识别）。

## 从源码构建

需要 macOS 13+ 和 Swift 6 工具链。

```bash
git clone https://github.com/hunters1431/MACKey.git
cd MACKey
swift run            # 直接运行（调试）
./scripts/package.sh # 打包出 MACKey.app 和 DMG
```

技术栈：Swift + SwiftUI + AppKit，全局热键基于 [HotKey](https://github.com/soffes/HotKey)。

## 支持作者

如果这个小工具帮到了你，欢迎请我喝杯咖啡 ☕：

- 国内：打开 App 菜单「☕ 支持作者…」扫码（微信 / 支付宝）
- 国外：[Ko-fi](https://ko-fi.com/hunters1431) · [PayPal](https://paypal.me/hunters1431)

## License

[MIT](LICENSE)
