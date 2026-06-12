<p align="center">
  <img src="docs/icon.png" width="120" alt="MACKey">
</p>

<h1 align="center">MACKey</h1>

<p align="center">给程序坞里的应用一键绑定全局快捷键，秒速启动 / 切换 —— macOS 上的轻量 Snap 替代品。</p>

MACKey 是一个常驻菜单栏的小工具。它读取你「程序坞（Dock）」里的应用，自动为**前 10 个**绑定 `⌃1`…`⌃0`，按下即可启动或切换到对应 App。同时它能列出 macOS 系统自带的全局快捷键，帮你避开冲突。

## 功能

- **按程序坞顺序自动绑定**：前 10 个 Dock 应用对应 `⌃1 ⌃2 … ⌃9 ⌃0`，开箱即用，也可自定义改键。
- **三列设置界面**：
  - 系统快捷键清单（合并读取系统默认 + 你的自定义）
  - 已绑定的程序快捷键汇总
  - 程序坞应用 + 快捷键录制器
- **冲突检测**：录制时若与系统快捷键或其他程序冲突，会高亮提示（系统快捷键还能显示具体名称）。
- **开机自启动**：菜单里一键开关。
- **纯菜单栏**：不占程序坞，不打扰。

## 安装

1. 从 [Releases](../../releases) 下载最新的 `MACKey-x.y.z.dmg`。
2. 打开 DMG，把 `MACKey.app` 拖进「应用程序」。
3. 首次打开：由于本应用未经 Apple 公证（无付费开发者账号），Gatekeeper 会拦截。**右键点击 → 打开**，在弹窗里再次点「打开」即可（只需一次）。
   - 或在终端执行：`xattr -dr com.apple.quarantine /Applications/MACKey.app`
4. 首次运行会请求**辅助功能（Accessibility）权限** —— 全局快捷键必须授权才能生效：
   系统设置 → 隐私与安全性 → 辅助功能 → 勾选 MACKey。

## 使用

- 点菜单栏的键盘图标 → 「设置快捷键…」打开三列窗口。
- 前 10 个应用已自动绑好 `⌃数字`；想改某个，在第三列点它的快捷键栏，按下新组合键（需含 `⌘/⌃/⌥/⇧`）。
- `Esc` 取消录制，`×` 清除绑定。

> 注意：`⌃1`～`⌃3` 在开启「多桌面切换」时可能与系统「切换到桌面 N」冲突，届时改成其他键即可（红色提示会帮你识别）。

## 从源码构建

需要 macOS 13+ 和 Swift 6 工具链。

```bash
git clone <your-repo-url>
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
