#!/usr/bin/env python3
"""Exercise the reviewed Easy Weld module with inert scene and UI stubs."""

import argparse
import subprocess
import tempfile
from pathlib import Path


def run_suite(luau: Path, module: Path, template: str, baseline: bool) -> None:
    source_marker = "-- MODULE_SOURCE_INSERTION_POINT"
    mode_marker = "-- BASELINE_MODE_INSERTION_POINT"
    if template.count(source_marker) != 1 or template.count(mode_marker) != 1:
        raise ValueError("Expected one source and one test-mode insertion point")
    combined = template.replace(
        mode_marker, "local BASELINE_REPRO = " + ("true" if baseline else "false")
    ).replace(source_marker, module.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="moon-welder-tests-") as directory:
        harness = Path(directory) / "welder-tests.luau"
        harness.write_text(combined, encoding="utf-8")
        subprocess.run([str(luau.resolve()), str(harness)], check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", required=True, type=Path)
    parser.add_argument("--baseline-welder", type=Path)
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    template = (project / "tests/welder.spec.luau").read_text(encoding="utf-8")
    if args.baseline_welder:
        run_suite(args.luau, args.baseline_welder, template, True)
    run_suite(
        args.luau, project / "patches/Moon_Animator_2/Windows/Welder.luau",
        template, False,
    )


if __name__ == "__main__":
    main()
