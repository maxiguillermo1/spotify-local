import SwiftUI

struct EmptyLibraryView: View {
    var isBusy: Bool = false
    var onAdd: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recently Added")
                .font(.title3.weight(.semibold))
            Text("Add the audio files you already own. They stay in your Spotify Local music folder.")
                .font(.body)
                .foregroundStyle(.secondary)
            if onAdd != nil {
                AddMusicButton(isBusy: isBusy, action: { onAdd?() })
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

struct OfflineStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Waiting for your Mac")
                .font(.title3.weight(.semibold))
            Text("Make sure this iPhone and your MacBook are on the same Wi‑Fi, then run Spotify Local on the Mac.")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}
