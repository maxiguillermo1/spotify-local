import SwiftUI
import UniformTypeIdentifiers

struct MusicImportModifier: ViewModifier {
    @Bindable var appState: AppState

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: $appState.isFileImporterPresented,
                allowedContentTypes: Self.allowedTypes,
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    Task { await appState.importURLs(urls) }
                case .failure(let error):
                    appState.importError = error.localizedDescription
                }
            }
            .dropDestination(for: URL.self) { urls, _ in
                Task { await appState.importURLs(urls) }
                return true
            } isTargeted: { targeted in
                appState.isDropTargeted = targeted
            }
            .alert("Couldn’t add music", isPresented: errorPresented) {
                Button("OK", role: .cancel) { appState.importError = nil }
            } message: {
                Text(appState.importError ?? "")
            }
            .overlay {
                if appState.isDropTargeted {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(StatusGreen.ready, lineWidth: 2)
                        .padding(10)
                        .overlay {
                            Text("Add to Your Music")
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .allowsHitTesting(false)
                }
            }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { appState.importError != nil },
            set: { if !$0 { appState.importError = nil } }
        )
    }

    private static var allowedTypes: [UTType] {
        var types: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav, .aiff, .folder]
        for ext in ["m4a", "aac", "flac", "alac", "aif"] {
            if let type = UTType(filenameExtension: ext) {
                types.append(type)
            }
        }
        return types
    }
}

struct AddMusicButton: View {
    var compact: Bool = false
    var isBusy: Bool = false
    let action: () -> Void

    var body: some View {
        if compact {
            Button(action: action) {
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
            .accessibilityLabel("Add Music")
        } else {
            Button(action: action) {
                HStack(spacing: 8) {
                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Add Music")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
            .foregroundStyle(Color.appBackground)
            .disabled(isBusy)
            .accessibilityLabel("Add Music")
        }
    }
}
