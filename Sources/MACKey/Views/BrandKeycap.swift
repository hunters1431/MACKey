import SwiftUI

/// The MACKey brand mark: a keycap with an enlarged ⌘ legend, tinted by the
/// current accent theme. The bottom "wall" gives a subtle physical key feel.
struct BrandKeycap: View {
    var size: CGFloat = 34
    var accent: AccentTheme

    var body: some View {
        let radius = size * 0.26
        let wall = max(2, size * 0.06)
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(accent.wallColor)
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(accent.color)
                .padding(.bottom, wall)
            Text("⌘")
                .font(.system(size: size * 0.58, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.bottom, wall * 0.5)
        }
        .frame(width: size, height: size)
    }
}
