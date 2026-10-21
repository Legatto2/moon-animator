"""Portable package integrity tests; never execute the Windows helper or plugin."""

from __future__ import annotations

import io
import json
from pathlib import Path
import stat
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_install_package as package


class InstallPackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        candidate_path = package.ROOT / "candidate" / package.CANDIDATE_NAME
        cls.candidate, cls.expected = package.read_candidate(
            candidate_path, candidate_path.with_suffix(".rbxm.manifest.json"))
        cls.built = package.build_package(cls.candidate, cls.expected)

    def test_zip_contains_exactly_three_flat_regular_files_and_original_candidate(self):
        with zipfile.ZipFile(io.BytesIO(self.built)) as archive:
            self.assertEqual(tuple(archive.namelist()), package.ENTRY_NAMES)
            self.assertIsNone(archive.testzip())
            self.assertEqual(archive.read(package.CANDIDATE_NAME), self.candidate)
            self.assertEqual(archive.read("START_HERE.txt"), package.START_HERE)
            for info in archive.infolist():
                self.assertEqual(info.date_time, package.ZIP_DATE)
                self.assertEqual(info.compress_type, zipfile.ZIP_STORED)
                self.assertTrue(stat.S_ISREG(info.external_attr >> 16))
                self.assertEqual(info.extra, b"")
                self.assertEqual(info.comment, b"")
            self.assertEqual(archive.comment, b"")

    def test_repeated_builds_are_byte_identical(self):
        for _ in range(3):
            self.assertEqual(package.build_package(self.candidate, self.expected), self.built)
        package.verify_package(self.built, self.candidate)

    def test_helper_embeds_exact_hash_and_uses_windows_line_endings(self):
        with zipfile.ZipFile(io.BytesIO(self.built)) as archive:
            installer = archive.read("Install.cmd")
        self.assertEqual(installer.count(self.expected.encode("ascii")), 1)
        self.assertNotIn(package.HASH_TOKEN.encode("ascii"), installer)
        self.assertNotIn(b"\n", installer.replace(b"\r\n", b""))
        self.assertTrue(installer.startswith(b"@echo off\r\n"))
        self.assertIn(b"DisableDelayedExpansion", installer)
        self.assertIn(b"-NoProfile -NonInteractive -Command", installer)
        self.assertIn(b"$env:MOON_ANIMATOR_INSTALL_DIR", installer)
        self.assertIn(b"$env:LOCALAPPDATA", installer)
        self.assertIn(b"pause\r\nexit /b %MOON_ANIMATOR_INSTALL_STATUS%", installer)

    def test_helper_is_offline_and_preserves_the_installation_transaction(self):
        command = package.render_installer(self.expected).decode("ascii")
        for forbidden in ("ExecutionPolicy", "EncodedCommand", "Invoke-Expression", "Invoke-WebRequest",
                          "DownloadFile", "http://", "https://", "Stop-Process", "taskkill", "reg.exe",
                          "RunAs", "Remove-Item", "Get-FileHash"):
            self.assertNotIn(forbidden.casefold(), command.casefold())
        self.assertIn("Get-Process -ErrorAction Stop", command)
        self.assertIn("[Security.Cryptography.SHA256]::Create()", command)
        self.assertIn("$algorithm.ComputeHash($stream)", command)
        self.assertIn("$stream.Dispose()", command)
        self.assertIn("[IO.FileAttributes]::ReparsePoint", command)
        self.assertIn("'MoonAnimator2\\Backups'", command)
        self.assertIn(".rbxm.bak", command)
        self.assertLess(command.index("if ((Get-Hash $source)"), command.index("CreateDirectory($plugins)"))
        self.assertLess(command.index("Assert-StudioClosed;"), command.index("CreateDirectory($plugins)"))
        self.assertLess(command.index("if ((Get-Hash $stage)"), command.index("[IO.File]::Replace("))
        self.assertLess(command.index("if ((Get-Hash $backup)"), command.index("[IO.File]::Replace("))
        # Windows PowerShell 5.1 otherwise binds $null to an empty string for
        # this .NET string parameter, which File.Replace rejects as a path.
        self.assertIn("[IO.File]::Replace($stage, $destination, "
                      "[System.Management.Automation.Language.NullString]::Value)", command)
        self.assertNotIn("[IO.File]::Replace($stage, $destination, $null)", command)
        self.assertIn("[IO.File]::Move($stage, $destination)", command)
        # Every model pathname is fixed or taken from env data, not interpolated
        # into command text through a cmd expansion of a user-controlled path.
        powershell = command.split("-Command", 1)[1].split("\r\nset ", 1)[0]
        self.assertNotIn("%", powershell)

    def test_changed_model_helper_extra_entry_or_metadata_fail_exact_verification(self):
        with zipfile.ZipFile(io.BytesIO(self.built)) as original:
            contents = {name: original.read(name) for name in original.namelist()}
        variants = []
        for name in (package.CANDIDATE_NAME, "Install.cmd", "START_HERE.txt"):
            changed = dict(contents)
            changed[name] += b"tampered"
            variants.append(changed)
        variants.append({**contents, "unexpected.ps1": b"extra"})
        for changed in variants:
            output = io.BytesIO()
            with zipfile.ZipFile(output, "w") as archive:
                for name, content in changed.items():
                    archive.writestr(name, content)
            with self.subTest(entries=tuple(changed)), self.assertRaises(package.PackageError):
                package.verify_package(output.getvalue(), self.candidate)
        with self.assertRaises(package.PackageError):
            package.verify_package(self.built + b"trailing bytes", self.candidate)

    def test_wrong_hash_empty_input_and_hash_injection_are_rejected(self):
        with self.assertRaises(package.PackageError):
            package.build_package(self.candidate + b"changed", self.expected)
        with self.assertRaises(package.PackageError):
            package.build_package(b"", package.sha256(b""))
        for invalid in ("0" * 63, "A" * 64, "x" * 64, "'; exit 0; '"):
            with self.subTest(hash=invalid), self.assertRaises(package.PackageError):
                package.render_installer(invalid)

    def test_manifest_mismatch_and_malformed_metadata_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, manifest = root / "input.rbxm", root / "manifest.json"
            source.write_bytes(self.candidate)
            good = {"schema_version": 1, "output": {"sha256": self.expected, "bytes": len(self.candidate)}}
            manifest.write_text(json.dumps(good), encoding="utf-8")
            self.assertEqual(package.read_candidate(source, manifest), (self.candidate, self.expected))
            for invalid in ({}, {**good, "schema_version": 2},
                            {**good, "output": {"sha256": self.expected, "bytes": 1}},
                            {**good, "output": {"sha256": "0" * 64, "bytes": len(self.candidate)}}):
                manifest.write_text(json.dumps(invalid), encoding="utf-8")
                with self.subTest(manifest=invalid), self.assertRaises(package.PackageError):
                    package.read_candidate(source, manifest)
            manifest.write_bytes(b"not JSON")
            with self.assertRaises(package.PackageError):
                package.read_candidate(source, manifest)

    def test_existing_output_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "install.zip"
            output.write_bytes(b"existing output")
            with self.assertRaises(FileExistsError):
                package.write_package(output, self.built)
            self.assertEqual(output.read_bytes(), b"existing output")
            output.unlink()
            package.write_package(output, self.built)
            self.assertEqual(output.read_bytes(), self.built)

    def test_link_or_windows_junction_output_is_rejected(self):
        junction = SimpleNamespace(st_mode=stat.S_IFDIR | 0o755, st_file_attributes=0x400)
        with patch.object(Path, "lstat", return_value=junction):
            with self.assertRaises(package.candidate_builder.BuildError):
                package.write_package(Path("linked-output") / "install.zip", self.built)


if __name__ == "__main__":
    unittest.main(verbosity=2)
