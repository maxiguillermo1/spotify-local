#!/usr/bin/env python3
"""Pick the best available iPhone Simulator for Spotify Local."""

from __future__ import annotations

import json
import subprocess
import sys


PREFERRED_NAMES = (
    "iPhone 17 Pro",
    "iPhone 17",
    "iPhone 16 Pro",
    "iPhone 16",
    "iPhone 15 Pro",
    "iPhone 15",
)


def simctl_json() -> dict:
    raw = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"], text=True)
    return json.loads(raw)


def iphone_devices(payload: dict) -> list[dict]:
    found: list[dict] = []
    for runtime, devices in payload.get("devices", {}).items():
        if "iOS" not in runtime and "iPhone" not in runtime:
            continue
        for device in devices:
            name = device.get("name", "")
            if not name.startswith("iPhone"):
                continue
            if not device.get("isAvailable", True):
                continue
            found.append(
                {
                    "udid": device["udid"],
                    "name": name,
                    "state": device.get("state", "Shutdown"),
                    "runtime": runtime,
                }
            )
    return found


def score(device: dict) -> tuple:
    name = device["name"]
    try:
        preferred = PREFERRED_NAMES.index(name)
    except ValueError:
        preferred = 100 + (0 if "Pro" in name else 10)
    booted = 0 if device["state"] == "Booted" else 1
    return (preferred, booted, device["name"])


def pick(devices: list[dict]) -> dict | None:
    if not devices:
        return None
    return sorted(devices, key=score)[0]


def main() -> int:
    try:
        payload = simctl_json()
    except (OSError, subprocess.CalledProcessError) as exc:
        print(f"simctl is unavailable: {exc}", file=sys.stderr)
        return 2
    device = pick(iphone_devices(payload))
    if device is None:
        print("No available iPhone Simulator runtime was found.", file=sys.stderr)
        return 1
    print(f"{device['udid']}\t{device['name']}\t{device['state']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
