# Architecture

Spotify Local is intentionally small.

```text
Mac companion  →  local protocol  →  BridgeClient  →  AppState  →  SwiftUI
```

## Pieces

| Piece | Role | Phase 1 |
| --- | --- | --- |
| `bin/spotify` | Repo-owned developer CLI | Done |
| `mac/SpotifyLocalCompanion` | Watches the music folder, later advertises Bonjour and serves files | Stub process only |
| `shared/SpotifyLocalCore` | Models, wire types, path security | Done |
| `ios/SpotifyLocal` | Native iPhone app | Mock `BridgeClient` |

## Source of truth

Default Mac library:

```text
~/Desktop/Spotify Local
```

The companion may only serve indexed files inside that directory. See path security in `shared/Sources/SpotifyLocalCore/PathSecurity.swift`.

## Connection states

Shown to the user as:

- Connected
- Working
- Attention needed
- Mac unavailable

A green dot means the Mac companion has been found and communication is healthy. In Phase 1 the app simulates this with `MockBridgeClient`.

## Why a mock client exists

The iOS Simulator is the right place to finish UI and app structure. It is the wrong place to prove Spotify’s Files container. `LocalBridgeClient` is present but unused until Phase 4.
