import SwiftUI
import AppKit

struct DonationView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                Text("支持 MACKey 开发")
                    .font(.headline)
                Text("If MACKey helps you, consider buying me a coffee ☕")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)

            qrCodes

            if !DonationConfig.links.isEmpty {
                Divider()
                linkButtons
            }

            Spacer(minLength: 0)

            Text("感谢你的支持 · Thank you")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - QR codes (国内)

    @ViewBuilder
    private var qrCodes: some View {
        let wechat = bundleImage(DonationConfig.wechatQRName)
        let alipay = bundleImage(DonationConfig.alipayQRName)

        if wechat != nil || alipay != nil {
            HStack(spacing: 20) {
                if let w = wechat { qrTile(image: w, label: "微信") }
                if let a = alipay { qrTile(image: a, label: "支付宝") }
            }
        } else {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundColor(.secondary.opacity(0.4))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Text("放入 wechat_qr.png /\nalipay_qr.png 后显示")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    )
            }
        }
    }

    private func qrTile(image: NSImage, label: String) -> some View {
        VStack(spacing: 6) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)   // keep original proportions — no distortion
                .frame(width: 150, height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: - Link buttons (国外 / 持续)

    private var linkButtons: some View {
        VStack(spacing: 8) {
            ForEach(DonationConfig.links) { link in
                Button {
                    if let url = URL(string: link.url) { NSWorkspace.shared.open(url) }
                } label: {
                    HStack {
                        Image(systemName: link.systemImage)
                        Text(link.title)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func bundleImage(_ name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }
}
