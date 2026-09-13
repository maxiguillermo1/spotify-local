#!/usr/bin/env python3
import unittest
import importlib.util
from pathlib import Path

MODULE = Path(__file__).resolve().parents[2] / "scripts/lib/pick_simulator.py"
spec = importlib.util.spec_from_file_location("pick_simulator", MODULE)
pick = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pick)


class PickSimulatorTests(unittest.TestCase):
    def test_prefers_iphone_17_pro(self):
        devices = [
            {"udid": "a", "name": "iPhone 16", "state": "Booted", "runtime": "iOS26"},
            {"udid": "b", "name": "iPhone 17 Pro", "state": "Shutdown", "runtime": "iOS26"},
        ]
        chosen = pick.pick(devices)
        self.assertEqual(chosen["udid"], "b")

    def test_uses_booted_when_names_tie(self):
        devices = [
            {"udid": "a", "name": "iPhone 16 Pro", "state": "Shutdown", "runtime": "iOS26"},
            {"udid": "b", "name": "iPhone 16 Pro", "state": "Booted", "runtime": "iOS26"},
        ]
        chosen = pick.pick(devices)
        self.assertEqual(chosen["udid"], "b")

    def test_empty(self):
        self.assertIsNone(pick.pick([]))


if __name__ == "__main__":
    unittest.main()
