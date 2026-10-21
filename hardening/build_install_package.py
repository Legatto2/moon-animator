#!/usr/bin/env python3
"""Build the deterministic, offline three-file Windows installation ZIP.

The reviewed candidate and its build manifest must agree. No model code is run,
no network is used, and existing output files are refused. The Windows helper
uses only built-in cmd.exe and Windows PowerShell; its native tests run separately
on Windows. Example: python -B hardening/build_install_package.py
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import stat
import sys
import zipfile

sys.dont_write_bytecode = True
import build_candidate as candidate_builder


ROOT = Path(__file__).resolve().parent
CANDIDATE_NAME = "Moon_Animator_2_review_candidate.rbxm"
PACKAGE_NAME = "Moon_Animator_2_Windows_Install.zip"
ENTRY_NAMES = ("Install.cmd", CANDIDATE_NAME, "START_HERE.txt")
MAX_CANDIDATE_BYTES = candidate_builder.MAX_FILE_BYTES
MAX_PACKAGE_BYTES = MAX_CANDIDATE_BYTES + 64 * 1024
TEMPLATE_PATH = ROOT / "installer" / "Install.cmd.in"
HASH_TOKEN = "__CANDIDATE_SHA256__"
ZIP_DATE = (1980, 1, 1, 0, 0, 0)
START_HERE = (
    "MOON ANIMATOR 2 - WINDOWS INSTALL\r\n"
    "\r\n"
    "1. Right-click the ZIP and choose Extract All.\r\n"
    "2. Close Roblox Studio.\r\n"
    "3. Open the extracted folder and double-click Install.cmd.\r\n"
    "4. After SUCCESS, open Studio and use the Plugins tab.\r\n"
    "\r\n"
    "Keep all three files together. No administrator access is needed.\r\n"
    "Only Moon_Animator_2_review_candidate.rbxm is installed or replaced.\r\n"
    "An existing copy is backed up to %LOCALAPPDATA%\\MoonAnimator2\\Backups.\r\n"
    "If installation fails, read its message or use the repository's manual steps.\r\n"
).encode("ascii")


class PackageError(ValueError):
    """The source, manifest, installer template, or package is inconsistent."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PackageError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_candidate(candidate_path: Path, manifest_path: Path) -> tuple[bytes, str]:
    candidate = candidate_builder.read_bounded_file(candidate_path, MAX_CANDIDATE_BYTES)
    raw_manifest = candidate_builder.read_bounded_file(manifest_path, 1024 * 1024)
    try:
        manifest = json.loads(raw_manifest)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise PackageError("Candidate manifest is not valid UTF-8 JSON") from exc
    require(isinstance(manifest, dict) and manifest.get("schema_version") == 1,
            "Unsupported candidate manifest")
    output = manifest.get("output")
    require(isinstance(output, dict), "Candidate manifest is missing output identity")
    expected = output.get("sha256")
    require(isinstance(expected, str) and re.fullmatch(r"[0-9a-f]{64}", expected) is not None,
            "Candidate manifest has an invalid SHA-256")
    require(type(output.get("bytes")) is int and output["bytes"] == len(candidate),
            "Candidate byte count differs from its build manifest")
    require(sha256(candidate) == expected, "Candidate SHA-256 differs from its build manifest")
    return candidate, expected


def render_installer(expected_sha256: str) -> bytes:
    require(re.fullmatch(r"[0-9a-f]{64}", expected_sha256) is not None,
            "Installer requires a lowercase SHA-256")
    raw = candidate_builder.read_bounded_file(TEMPLATE_PATH, 16 * 1024)
    try:
        template = raw.decode("ascii").replace("\r\n", "\n")
    except UnicodeDecodeError as exc:
        raise PackageError("Installer template must use ASCII") from exc
    require(template.count(HASH_TOKEN) == 1, "Installer template must contain exactly one hash token")
    rendered = template.replace(HASH_TOKEN, expected_sha256)
    # cmd.exe expands this continued command as one line (limit 8191 characters).
    command = rendered.split('"%SystemRoot%', 1)[1].split("\nset ", 1)[0]
    require(len(command.replace("^\n", " ")) < 7600,
            "Embedded PowerShell command is too long for cmd.exe")
    return rendered.replace("\n", "\r\n").encode("ascii")


def build_package(candidate: bytes, expected_sha256: str) -> bytes:
    require(0 < len(candidate) <= MAX_CANDIDATE_BYTES, "Candidate is empty or exceeds the package limit")
    require(sha256(candidate) == expected_sha256, "Candidate SHA-256 does not match the requested installer")
    entries = (render_installer(expected_sha256), candidate, START_HERE)
    output = io.BytesIO()
    # Stored entries avoid zlib-version differences. Fixed order/date/mode make
    # this archive byte-identical across rebuilds, independent of source mtimes.
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_STORED, allowZip64=False) as archive:
        for name, content in zip(ENTRY_NAMES, entries):
            info = zipfile.ZipInfo(name, ZIP_DATE)
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            info.compress_type = zipfile.ZIP_STORED
            archive.writestr(info, content)
    package = output.getvalue()
    require(len(package) <= MAX_PACKAGE_BYTES, "Installation ZIP exceeds its size limit")
    return package


def verify_package(package: bytes, candidate: bytes) -> None:
    require(len(package) <= MAX_PACKAGE_BYTES, "Installation ZIP exceeds its size limit")
    expected = build_package(candidate, sha256(candidate))
    require(package == expected,
            "Installation ZIP differs from the deterministic package of the reviewed candidate")


def write_package(output: Path, package: bytes) -> None:
    candidate_builder.reject_links(output)
    require(output.parent.is_dir(), "Installation ZIP output directory does not exist")
    created = False
    try:
        with output.open("xb") as handle:
            created = True
            handle.write(package)
            handle.flush()
            os.fsync(handle.fileno())
    except BaseException:
        if created:
            output.unlink(missing_ok=True)
        raise


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate", type=Path, default=ROOT / "candidate" / CANDIDATE_NAME)
    parser.add_argument("--manifest", type=Path,
                        help="Defaults to the candidate's .rbxm.manifest.json file")
    parser.add_argument("--output", type=Path, default=ROOT / "candidate" / PACKAGE_NAME,
                        help="New installation ZIP path; existing files are refused")
    args = parser.parse_args(argv)
    manifest_path = args.manifest or args.candidate.with_suffix(args.candidate.suffix + ".manifest.json")
    try:
        require(args.output.absolute() not in (args.candidate.absolute(), manifest_path.absolute()),
                "Refusing to overwrite an input")
        candidate, expected = read_candidate(args.candidate, manifest_path)
        package = build_package(candidate, expected)
        write_package(args.output, package)
    except (PackageError, candidate_builder.BuildError, OSError) as exc:
        print(f"Installation package refused: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({"output": str(args.output), "sha256": sha256(package),
                      "bytes": len(package), "candidate_sha256": expected,
                      "entries": list(ENTRY_NAMES), "studio_runtime_tested": False}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
