import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

struct ArtworkView: View {
    let artwork: ArtworkReference?
    var size: CGFloat = 52

    var body: some View {
        let art = artwork ?? .missing
        let radius = max(8, size * 0.18)
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(background(for: art))
            .overlay {
                if let data = art.imageData, let image = Self.image(from: data) {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: art.systemSymbol ?? "music.note")
                        .font(.system(size: size * 0.34, weight: .semibold))
                        .foregroundStyle(accent(for: art))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private func background(for art: ArtworkReference) -> LinearGradient {
        let base = Color(hex: art.backgroundHex ?? "3A3A3C")
        return LinearGradient(
            colors: [base.opacity(0.92), base.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func accent(for art: ArtworkReference) -> Color {
        Color(hex: art.accentHex ?? "F2F2F7", fallback: .white.opacity(0.9))
            .opacity(0.92)
    }

    private static func image(from data: Data) -> Image? {
        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #else
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #endif
    }
}
