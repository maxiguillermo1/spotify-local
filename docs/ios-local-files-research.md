# iOS Local Files — research

This is the destination problem: after a track reaches the iPhone, Spotify still has to index it as a Local File.

**Nothing in this file is claimed as verified on a device we control.** Phase 6 exists to prove the workflow on a real iPhone.

## What Spotify documents

Spotify’s public instructions (as of this writing) are:

1. Spotify → **Settings and privacy** → **Apps and devices** → **Local audio files** on.
2. Allow **Media & Apple Music** access if prompted.
3. Put audio files in **Files → Browse → On My iPhone → Spotify**.
4. The tracks should appear in Spotify’s **Local Files** playlist.

Supported import methods they describe are copy/move in Files, Universal Clipboard paste into that folder, and a legacy USB/Finder path. They also note the Spotify folder can vanish if an internal Help file is deleted; restarting Spotify may recreate it.

Source: [Spotify — Local files](https://support.spotify.com/us/article/local-files/) and Spotify’s iOS FAQ.

## What that means for this app

- We **cannot** assume our process can write into Spotify’s container. That is another app’s sandbox.
- The user-visible location is a Files-app folder owned by Spotify, not a public shared directory.
- `UIDocumentPickerViewController` (folder pick + security-scoped bookmark) is the legitimate API to try if the Spotify folder is user-selectable. Whether iOS actually allows picking and persistently writing that folder is **unproven here**.
- If the picker cannot see or retain that folder, the supported fallback is Share/export into Files, with in-app instructions. That is not as simple as AirDrop, but it is legal and honest.
- Private APIs and sandbox escapes are out of scope.

## Simulator

Do not use Simulator behavior as proof. Spotify may be absent; its Files container is not a reliable simulator fixture. Phase 1–5 should keep a **mock destination** so UI and networking can ship independently.

## Phase 6 plan

On a physical iPhone with Spotify installed:

1. Confirm the On My iPhone → Spotify folder appears after enabling Local audio files.
2. Try a user-granted folder pick. If a security-scoped bookmark can be stored and reused, write downloaded audio there.
3. If not, use the share sheet / “Save to Files” flow and keep the same track states (`On Mac` → `Downloading` → `On iPhone` / `Needs attention`).
4. Never mark a transfer complete unless the file actually landed in a location we can observe.
