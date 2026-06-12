import Foundation

/// Donation links and assets. Replace placeholders with your real URLs.
/// Leave a string empty ("") to hide that button. Put QR images at
/// Resources/wechat_qr.png and Resources/alipay_qr.png — package.sh bundles them.
enum DonationConfig {
    // 国内：微信 / 支付宝收款码（图片放 Resources/）
    static let wechatQRName = "wechat_qr"                       // Resources/wechat_qr.png
    static let alipayQRName = "alipay_qr"                       // Resources/alipay_qr.png

    // 国外 / international
    static let githubSponsors = "https://github.com/sponsors/yourID"
    static let koFi = "https://ko-fi.com/yourID"
    static let buyMeACoffee = ""                               // 留空则不显示

    struct Link: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let url: String
    }

    /// Non-empty link buttons, in display order.
    static var links: [Link] {
        [
            Link(title: "GitHub Sponsors", systemImage: "heart.circle", url: githubSponsors),
            Link(title: "Ko-fi", systemImage: "cup.and.saucer", url: koFi),
            Link(title: "Buy Me a Coffee", systemImage: "cup.and.saucer", url: buyMeACoffee),
        ].filter { !$0.url.isEmpty }
    }
}
