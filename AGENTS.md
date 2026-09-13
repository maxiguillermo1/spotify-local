# Agent notes — Spotify Local

Phase 1 is the only completed slice. Do not jump to Bonjour servers, Spotify folder writes, or extra product surface until `spotify local` reliably launches the iPhone app.

## Product constraints

- Personal/local audio files the user already owns. Never rip, decrypt, or fetch Spotify catalog audio.
- No USB, cloud, accounts, or Spotify Web API in the core product.
- `spotify local` is the single developer entry point.
- Keep the architecture: Mac companion → local protocol → `BridgeClient` → `AppState` → SwiftUI.

## Day-to-day

```bash
./scripts/install-cli
spotify local
spotify local doctor
./tests/run
```

## Phase map

1. Foundation — CLI, simulator launch, mock SwiftUI app (current)
2. Polish UI states
3. Mac companion indexing + Bonjour
4. `LocalBridgeClient` on the real protocol
5. File transfer
6. Real-device Spotify Local Files destination (verify, then smallest supported flow)

## Rules of thumb

- Default CLI output stays tiny. Logs go under `.run/logs/`.
- Stop only pids this repo owns (see `.run/companion.pid`).
- Do not claim an iOS/Spotify capability works until it has been verified on a real device.
- If a `spotify` binary already exists, never overwrite it silently.
