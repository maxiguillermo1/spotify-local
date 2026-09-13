#!/usr/bin/env python3
"""Write a 1024×1024 App Icon PNG (dark field, quiet green disc)."""

from __future__ import annotations

import struct
import zlib
from pathlib import Path

SIZE = 1024
OUT = Path(__file__).resolve().parents[2] / "ios/SpotifyLocal/SpotifyLocal/Assets.xcassets/AppIcon.appiconset/AppIcon.png"


def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def pixel(x: int, y: int) -> tuple[int, int, int]:
    cx = cy = SIZE / 2
    dx = x - cx
    dy = y - cy
    dist = (dx * dx + dy * dy) ** 0.5
    bg = (18, 18, 20)
    green = (48, 199, 90)
    if dist < 86:
        return green
    return bg


def main() -> None:
    rows = []
    for y in range(SIZE):
        row = bytearray()
        for x in range(SIZE):
            row.extend(pixel(x, y))
        rows.append(b"\x00" + bytes(row))
    raw = b"".join(rows)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(png)


if __name__ == "__main__":
    main()
