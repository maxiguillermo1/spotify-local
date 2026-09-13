# Spotify Local

A small iPhone app and Mac companion for moving **your own local audio files** from a MacBook to Spotify Local Files on iPhone, over the same Wi-Fi network.

There is no USB flow, no cloud backend, no account, and no Spotify OAuth. This project does not download, rip, or extract Spotify catalog music.

## What it is

On the Mac, one folder is the source of truth:

```text
~/Desktop/Spotify Local/
```

Add files you already own. The companion watches that folder. The iPhone app discovers the Mac with Bonjour, lets you browse the library, and downloads selected tracks toward Spotify’s Local Files area on the phone.

## Developer quick start

```bash
git clone <this-repo> spotify-local
cd spotify-local
./scripts/install-cli
spotify local
```

That is the only command you need day to day. It is idempotent.

Without Xcode it launches the same SwiftUI app in a Mac window. With Xcode installed it builds and launches the iPhone Simulator instead.

| Command | What it does |
| --- | --- |
| `spotify local` | Start the Mac companion if needed, then launch the app |
| `spotify local status` | Short environment summary |
| `spotify local stop` | Stop processes this project started |
| `spotify local doctor` | Check prerequisites and explain fixes |
| `spotify local logs` | Tail local logs |
| `spotify local --verbose` | Same as start, with extra diagnostic output |

Uninstall the developer command:

```bash
./scripts/install-cli --uninstall
```

If a different `spotify` command already exists on your machine, install will not overwrite it. It installs a shim so `spotify local` still reaches this repo, and leaves every other `spotify …` invocation to the original tool.

## How do I add music?

Use **Add Music** in the app, press `⌘O`, or drag audio onto the window. Files are copied into `~/Desktop/Spotify Local`.

You can also drop files into that folder in Finder. Spotify Desktop can point Local Files at the same folder.

Supported formats: mp3, m4a, aac, wav, aiff, flac, alac.

Override the folder for development:

```bash
SPOTIFY_LOCAL_MUSIC_DIR=/path/to/music spotify local
```

## How does the iPhone find the Mac?

Bonjour service type `_spotifylocal._tcp` on the same Wi-Fi. The user never types an IP, port, or URL. Real networking is not wired yet; the Mac window reads the local folder directly.

## How are files transferred?

Indexed files from the music folder will later stream to the iPhone over the local network. Only files inside that folder can be served. Path traversal is rejected.

Getting those files into Spotify’s Local Files playlist is a **real-device** problem. Officially, Spotify reads audio copied into **Files → On My iPhone → Spotify** after Local audio files is enabled in Spotify settings. This app cannot write into Spotify’s sandbox on its own. See [`docs/ios-local-files-research.md`](docs/ios-local-files-research.md).

## What currently works

- `spotify local` developer CLI (collision-safe install)
- Mac companion stub and Desktop music folder
- Add Music: picker, drag-and-drop, and Finder
- Native SwiftUI app (home, library, search, track detail, download states)
- Mac window launch when Xcode is not installed
- iPhone Simulator launch when Xcode is installed

## What still requires a real iPhone

- Confirming whether user-granted access to Spotify’s Files folder can persist
- Actually placing a track where Spotify Local Files will index it
- End-to-end Wi-Fi transfer against a physical phone

## Tests

```bash
./tests/run
```
