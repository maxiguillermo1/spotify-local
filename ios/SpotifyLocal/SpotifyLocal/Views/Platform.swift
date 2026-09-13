import SwiftUI

extension Color {
    static var appBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var appFill: Color {
        #if os(iOS)
        Color(.tertiarySystemFill)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var appTertiaryLabel: Color {
        #if os(iOS)
        Color(.tertiaryLabel)
        #else
        Color(nsColor: .tertiaryLabelColor)
        #endif
    }

    init(hex: String, fallback: Color = .appFill) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else {
            self = fallback
            return
        }
        let r, g, b: Double
        switch cleaned.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
        default:
            self = fallback
            return
        }
        self.init(red: r, green: g, blue: b)
    }
}

enum StatusGreen {
    static let ready = Color(red: 0.20, green: 0.78, blue: 0.35)
}

extension View {
    @ViewBuilder
    func appNavigationBarHidden(_ hidden: Bool) -> some View {
        #if os(iOS)
        self.toolbar(hidden ? .hidden : .visible, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appLargeNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

    func appSearchable(text: Binding<String>) -> some View {
        #if os(iOS)
        self.searchable(
            text: text,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search"
        )
        #else
        self.searchable(text: text, prompt: "Search")
        #endif
    }
}
