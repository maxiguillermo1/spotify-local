import SwiftUI
#if canImport(SpotifyLocalCore)
import SpotifyLocalCore
#endif

struct ConnectionHeader: View {
    let hostName: String
    let status: ConnectionStatus

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(dotColor)
                .frame(width: 9, height: 9)
                .overlay {
                    if status == .working {
                        Circle()
                            .stroke(StatusGreen.ready.opacity(0.35), lineWidth: 6)
                            .scaleEffect(1.6)
                    }
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(hostName)
                    .font(.headline)
                Text(status.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(hostName), \(status.title)")
    }

    private var dotColor: Color {
        switch status {
        case .connected, .working:
            StatusGreen.ready
        case .attention:
            Color.orange
        case .unavailable:
            Color.appTertiaryLabel
        }
    }
}

#if os(iOS)
#Preview("Connected") {
    ConnectionHeader(hostName: "MacBook", status: .connected)
        .padding()
}

#Preview("Unavailable") {
    ConnectionHeader(hostName: "MacBook", status: .unavailable)
        .padding()
}
#endif
