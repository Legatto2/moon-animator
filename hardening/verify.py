#!/usr/bin/env python3
"""Verify the reviewed Moon Animator candidate without network access or Studio.

Requires Python 3.10+ and a supplied directory containing the Luau interpreter
and compiler. Checks the pinned input, runs focused tests, rebuilds in a temporary
directory, compares committed artifacts and source snapshots, and compiles every
extracted script. It does not execute the complete plugin or update any artifact.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
import build_candidate as builder
import build_install_package as installer


ROOT = Path(__file__).resolve().parent
CANDIDATE_NAME = "Moon_Animator_2_review_candidate.rbxm"


class VerificationError(ValueError):
    """A test, rebuild, snapshot comparison, or compile check failed."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VerificationError(message)


def run(command: list[str], label: str, environment: dict[str, str]) -> str:
    result = subprocess.run(
        command, cwd=ROOT, env=environment, text=True, encoding="utf-8",
        errors="replace", stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        check=False,
    )
    if result.returncode:
        if result.stdout:
            print(result.stdout, file=sys.stderr, end="" if result.stdout.endswith("\n") else "\n")
        raise VerificationError(f"{label} failed with exit status {result.returncode}")
    return result.stdout


def find_luau_tool(directory: Path, name: str) -> Path:
    executable = directory / (name + ".exe" if os.name == "nt" else name)
    require(executable.is_file(), f"Missing Luau tool: {executable}")
    return executable.absolute()


def run_focused_tests(luau: Path, environment: dict[str, str]) -> dict[str, int]:
    counts = {}
    for name, test_file in (("builder", "test_build_candidate.py"),
                            ("installer_package", "test_install_package.py")):
        output = run(
            [sys.executable, "-B", "-m", "unittest", "discover", "-s", str(ROOT / "tests"),
             "-p", test_file, "-v"],
            f"{name} tests", environment,
        )
        match = re.search(r"^Ran (\d+) tests? in ", output, re.MULTILINE)
        require(match is not None and int(match.group(1)) > 0,
                f"{name} tests did not report a nonempty test run")
        require(re.search(r"^OK$", output, re.MULTILINE) is not None,
                f"{name} tests must all pass without skips; inspect the test environment")
        counts[name] = int(match.group(1))
        print(f"PASS {name} tests: {counts[name]}", flush=True)

    for name, runner in (
        ("marker", "run-marker-track-tests.py"),
        ("theme", "theme-run-tests.py"),
        ("startup", "run-startup-tests.py"),
        ("editor", "run-edit-markers-tests.py"),
        ("playback", "run-playback-handler-tests.py"),
        ("welder", "run-welder-tests.py"),
    ):
        output = run(
            [sys.executable, "-B", str(ROOT / "tests" / runner), "--luau", str(luau)],
            f"{name.capitalize()} tests", environment,
        )
        count = len(re.findall(r"^PASS ", output, re.MULTILINE))
        require(count > 0, f"{name.capitalize()} tests did not report any passed cases")
        counts[name] = count
        print(f"PASS {name} tests: {count} (mocked Roblox APIs)", flush=True)
    return counts


def snapshot_files(directory: Path) -> dict[str, Path]:
    builder.reject_links(directory)
    require(directory.is_dir(), f"Missing reviewed source directory: {directory}")
    files: dict[str, Path] = {}

    def walk_error(error: OSError) -> None:
        raise error

    for current, directories, filenames in os.walk(directory, followlinks=False, onerror=walk_error):
        for name in directories + filenames:
            builder.reject_links(Path(current) / name)
        for name in filenames:
            path = Path(current) / name
            relative = path.relative_to(directory).as_posix()
            require(path.is_file() and path.suffix == ".luau",
                    f"Unexpected reviewed source entry: {relative}")
            files[relative] = path
    return files


def verify_candidate(source: bytes, compiler: Path, environment: dict[str, str]) -> int:
    with tempfile.TemporaryDirectory(prefix="moon-animator-verify-") as directory:
        temporary = Path(directory).resolve()
        rebuilt = temporary / CANDIDATE_NAME
        rebuilt_manifest = rebuilt.with_suffix(rebuilt.suffix + ".manifest.json")
        candidate, manifest = builder.build_candidate(source, ROOT / "patches")
        builder.write_outputs(rebuilt, rebuilt_manifest, candidate, manifest)

        for generated in (rebuilt, rebuilt_manifest):
            committed = ROOT / "candidate" / generated.name
            actual = builder.read_bounded_file(committed, builder.MAX_FILE_BYTES)
            require(actual == generated.read_bytes(),
                    f"Committed {generated.name} differs from a fresh rebuild")
        print("PASS rebuilt candidate and manifest match committed files byte-for-byte", flush=True)

        committed_zip = builder.read_bounded_file(
            ROOT / "candidate" / installer.PACKAGE_NAME, installer.MAX_PACKAGE_BYTES)
        installer.verify_package(committed_zip, candidate)
        print("PASS Windows installation ZIP matches a fresh deterministic package byte-for-byte", flush=True)

        sources = builder.extract_script_sources(candidate)
        require(len(sources) == builder.EXPECTED_SCRIPTS, "Extracted script inventory differs from the pinned model")
        snapshots = snapshot_files(ROOT / "reviewed-sources")
        missing, extra = set(sources) - set(snapshots), set(snapshots) - set(sources)
        require(not missing and not extra,
                f"Reviewed source inventory mismatch: missing={sorted(missing)}, extra={sorted(extra)}")

        extracted: list[tuple[str, Path]] = []
        for relative, content in sorted(sources.items()):
            expected = builder.read_bounded_file(snapshots[relative], builder.MAX_SCRIPT_BYTES)
            require(content == expected, f"Reviewed source differs from candidate: {relative}")
            path = temporary / "extracted" / Path(*PurePosixPath(relative).parts)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
            extracted.append((relative, path))
        print(f"PASS all {len(sources)} extracted scripts match reviewed source snapshots", flush=True)

        for relative, path in extracted:
            run([str(compiler), "--null", str(path)], f"Compile {relative}", environment)
        print(f"PASS all {len(sources)} extracted scripts compile (no plugin execution)", flush=True)
        return len(sources)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog="Example: python hardening/verify.py --luau-dir /path/to/luau-tools",
    )
    parser.add_argument(
        "--input", type=Path, default=ROOT.parent / builder.SOURCE_FILENAME,
        help="Pinned v34000 RBXM; defaults to the original file in the repository root",
    )
    parser.add_argument(
        "--luau-dir", required=True, type=Path,
        help="Directory containing trusted luau and luau-compile executables (.exe on Windows)",
    )
    args = parser.parse_args(argv)
    try:
        input_path = args.input.absolute()
        source = builder.read_bounded_file(input_path, builder.SOURCE_BYTES)
        require(len(source) == builder.SOURCE_BYTES and builder.sha256(source) == builder.SOURCE_SHA256,
                "Input does not match the reviewed v34000 SHA-256")
        print(f"PASS pinned input SHA-256: {builder.SOURCE_SHA256}", flush=True)
        luau = find_luau_tool(args.luau_dir, "luau")
        compiler = find_luau_tool(args.luau_dir, "luau-compile")
        environment = dict(os.environ)
        environment["MOON_ANIMATOR_TEST_INPUT"] = str(input_path)
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        counts = run_focused_tests(luau, environment)
        scripts = verify_candidate(source, compiler, environment)
    except (VerificationError, builder.BuildError, installer.PackageError, OSError) as exc:
        print(f"Verification failed: {exc}", file=sys.stderr)
        return 1
    print(f"Verification passed: {sum(counts.values())} focused tests; {scripts} scripts compiled.")
    print("Roblox Studio integration has not been tested.")
    print("Native Windows installer tests run separately in the Windows CI job.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
