#!/usr/bin/env python3
"""Run the real CMD/Windows PowerShell installer against temporary directories.

This runner requires Windows and never skips a test. It does not run Roblox
Studio or any plugin source. Every installer subprocess receives an isolated
LOCALAPPDATA and closed stdin after a newline, so the helper's pause cannot hang.
The portable verifier has separate package tests and does not call this runner.
"""

from __future__ import annotations

import argparse
import io
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_install_package as package

PACKAGE_PATH = package.ROOT / "candidate" / package.PACKAGE_NAME


class WindowsInstallerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        candidate_path = package.ROOT / "candidate" / package.CANDIDATE_NAME
        cls.candidate, cls.expected = package.read_candidate(
            candidate_path, candidate_path.with_suffix(".rbxm.manifest.json"))
        cls.bundle_bytes = package.candidate_builder.read_bounded_file(
            PACKAGE_PATH, package.MAX_PACKAGE_BYTES)
        package.verify_package(cls.bundle_bytes, cls.candidate)

    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="moon-installer-native-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name) / "Riley's files & copies (safe)!"
        self.bundle = self.root / "Extracted installer & plugin"
        self.bundle.mkdir(parents=True)
        with zipfile.ZipFile(io.BytesIO(self.bundle_bytes)) as archive:
            for name in package.ENTRY_NAMES:
                (self.bundle / name).write_bytes(archive.read(name))
        self.local = self.root / "User's App Data & more (isolated)!"
        self.local.mkdir()
        self.plugins = self.local / "Roblox" / "Plugins"
        self.destination = self.plugins / package.CANDIDATE_NAME
        self.backups = self.local / "MoonAnimator2" / "Backups"
        self.environment = dict(os.environ)
        self.environment["LOCALAPPDATA"] = str(self.local)
        self.environment["MOON_ANIMATOR_TEST_SCRIPT"] = str(self.bundle / "Install.cmd")
        self.cmd = Path(os.environ["SystemRoot"]) / "System32" / "cmd.exe"
        self.assertTrue(self.cmd.is_file(), "Built-in cmd.exe is required")

    def run_installer(self) -> subprocess.CompletedProcess[str]:
        # Pass the batch path through an environment variable and quote it inside
        # cmd's /s /c outer quote pair. User path text is never command source.
        command = f'"{self.cmd}" /d /v:off /s /c ""%MOON_ANIMATOR_TEST_SCRIPT%""'
        return subprocess.run(command, shell=False, cwd=self.root, env=self.environment,
                              input="\n", stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              text=True, errors="replace", timeout=30, check=False)

    def seed_existing(self) -> tuple[bytes, Path]:
        previous = b"previous managed plugin - never execute this fixture"
        self.plugins.mkdir(parents=True)
        self.destination.write_bytes(previous)
        unrelated = self.plugins / "Unrelated_Plugin.rbxm"
        unrelated.write_bytes(b"unrelated plugin sentinel")
        return previous, unrelated

    def assert_unchanged(self, previous: bytes, unrelated: Path) -> None:
        self.assertEqual(self.destination.read_bytes(), previous)
        self.assertEqual(unrelated.read_bytes(), b"unrelated plugin sentinel")
        self.assertEqual(sorted(path.name for path in self.plugins.iterdir()),
                         sorted([package.CANDIDATE_NAME, unrelated.name]))
        self.assertFalse(self.backups.exists(), "Failure must not create a backup or replace the original")

    def create_junction(self, link: Path, target: Path) -> None:
        link.parent.mkdir(parents=True, exist_ok=True)
        target.mkdir(parents=True, exist_ok=True)
        environment = dict(self.environment)
        environment["MOON_INSTALL_TEST_LINK"] = str(link)
        environment["MOON_INSTALL_TEST_TARGET"] = str(target)
        command = (f'"{self.cmd}" /d /v:off /c mklink /J '
                   '"%MOON_INSTALL_TEST_LINK%" "%MOON_INSTALL_TEST_TARGET%"')
        result = subprocess.run(command, shell=False, env=environment, input="",
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, errors="replace", timeout=15, check=False)
        self.assertEqual(result.returncode, 0, result.stdout)
        # Remove the junction itself before TemporaryDirectory traverses the tree.
        self.addCleanup(lambda: link.rmdir() if link.exists() else None)

    def test_fresh_install_and_sha256_in_paths_with_shell_characters(self):
        result = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("SUCCESS:", result.stdout)
        self.assertEqual(self.destination.read_bytes(), self.candidate)
        self.assertEqual(package.sha256(self.destination.read_bytes()), self.expected)
        self.assertEqual([path.name for path in self.plugins.iterdir()], [package.CANDIDATE_NAME])
        self.assertFalse(self.backups.exists())

    def test_same_name_replacement_backs_up_and_preserves_other_plugins_and_settings(self):
        previous, unrelated = self.seed_existing()
        settings = self.local / "Roblox" / "settings-sentinel.json"
        settings.write_bytes(b"settings must stay unchanged")
        result = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.destination.read_bytes(), self.candidate)
        self.assertEqual(unrelated.read_bytes(), b"unrelated plugin sentinel")
        self.assertEqual(settings.read_bytes(), b"settings must stay unchanged")
        backups = list(self.backups.iterdir())
        self.assertEqual(len(backups), 1)
        self.assertTrue(backups[0].name.endswith(".rbxm.bak"))
        self.assertEqual(backups[0].read_bytes(), previous)
        self.assertFalse(backups[0].is_relative_to(self.plugins))
        self.assertEqual(sorted(path.name for path in self.plugins.iterdir()),
                         sorted([package.CANDIDATE_NAME, unrelated.name]))

    def test_tampered_source_fails_before_touching_existing_installation(self):
        previous, unrelated = self.seed_existing()
        (self.bundle / package.CANDIDATE_NAME).write_bytes(self.candidate + b"tampered")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("SHA256", result.stdout)
        self.assert_unchanged(previous, unrelated)

    def test_missing_source_fails_before_touching_existing_installation(self):
        previous, unrelated = self.seed_existing()
        (self.bundle / package.CANDIDATE_NAME).unlink()
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("missing", result.stdout)
        self.assert_unchanged(previous, unrelated)

    def test_plugins_parent_junction_is_rejected_without_touching_link_target(self):
        outside = self.root / "Outside plugins target"
        self.create_junction(self.local / "Roblox", outside)
        sentinel = outside / "untouched.txt"
        sentinel.write_bytes(b"outside target sentinel")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("Linked/junction", result.stdout)
        self.assertEqual([path.name for path in outside.iterdir()], [sentinel.name])
        self.assertEqual(sentinel.read_bytes(), b"outside target sentinel")

    def test_backup_junction_is_rejected_before_replacement(self):
        previous, unrelated = self.seed_existing()
        outside = self.root / "Outside backup target"
        self.create_junction(self.backups, outside)
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("Linked/junction", result.stdout)
        self.assertEqual(self.destination.read_bytes(), previous)
        self.assertEqual(unrelated.read_bytes(), b"unrelated plugin sentinel")
        self.assertEqual(list(outside.iterdir()), [])
        self.assertFalse(any(path.suffix == ".tmp" for path in self.plugins.iterdir()))

    def test_running_studio_name_is_refused_without_stopping_the_process(self):
        previous, unrelated = self.seed_existing()
        # A renamed copy of Microsoft's cmd.exe supplies only a process-name
        # fixture. It waits for stdin; Roblox Studio is never launched or killed.
        fake_studio = self.root / "RobloxStudioBeta.exe"
        shutil.copyfile(self.cmd, fake_studio)
        command = f'"{fake_studio}" /d /q /c "set /p MOON_INSTALL_TEST_WAIT="'
        process = subprocess.Popen(command, shell=False, stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        try:
            self.assertIsNone(process.poll(), "The process-name fixture must remain alive")
            result = self.run_installer()
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn("Close Roblox Studio", result.stdout)
            self.assertIsNone(process.poll(), "Installer must not stop a running Studio process")
            self.assert_unchanged(previous, unrelated)
        finally:
            try:
                process.communicate(b"done\n", timeout=5)
            except subprocess.TimeoutExpired:
                process.terminate()  # Only this test's own cmd.exe fixture.
                process.communicate(timeout=5)

    def test_missing_localappdata_fails_without_falling_back_to_real_user_folders(self):
        self.environment.pop("LOCALAPPDATA", None)
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("LOCALAPPDATA", result.stdout)
        self.assertEqual(list(self.local.iterdir()), [])

    def test_directory_at_managed_filename_is_preserved_and_rejected(self):
        self.destination.mkdir(parents=True)
        sentinel = self.destination / "keep.txt"
        sentinel.write_bytes(b"keep directory contents")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("directory occupies", result.stdout)
        self.assertEqual(sentinel.read_bytes(), b"keep directory contents")
        self.assertFalse(self.backups.exists())


def main(argv: list[str] | None = None) -> int:
    global PACKAGE_PATH
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, default=PACKAGE_PATH)
    args = parser.parse_args(argv)
    if os.name != "nt":
        print("Native installer tests require Windows; no tests were skipped or reported as passed.", file=sys.stderr)
        return 2
    PACKAGE_PATH = args.package
    result = unittest.TextTestRunner(verbosity=2).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(WindowsInstallerTests))
    if result.skipped or not result.testsRun:
        print("All native installer tests are required; skips are forbidden.", file=sys.stderr)
        return 1
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
