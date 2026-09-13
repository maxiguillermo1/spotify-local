# Networking

Planned Bonjour type:

```text
_spotifylocal._tcp
```

The iPhone must not ask for IP addresses, ports, hostnames, or URLs.

## Protocol (version 1)

Shared types live in `shared/Sources/SpotifyLocalCore/WireProtocol.swift`.

Message kinds:

- `hello`
- `deviceStatus`
- `librarySnapshot`
- `trackMetadata`
- `transferRequest`
- `transferProgress`
- `transferComplete`
- `error`

JSON, `protocolVersion` required, ISO-8601 dates.

## Trust

The LAN is not automatically trusted. Phase 1 validates message shape and refuses path traversal. Device pairing is a later addition. The companion must bind only as broadly as needed and must never expose arbitrary filesystem paths.

## Phase 1 status

No sockets yet. The iPhone app talks to `MockBridgeClient`. The Mac companion does not advertise Bonjour.
