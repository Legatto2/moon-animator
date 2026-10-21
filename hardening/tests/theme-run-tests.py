#!/usr/bin/env python3
"""Run focused theme unit tests using inert Roblox API mocks, without Studio.

The optional baseline path must refer to the already-reviewed Themer source.
No full plugin is executed, and no repository dependency is installed.
"""

import argparse
import subprocess
import tempfile
from pathlib import Path


def run_harness(luau: Path, template: str, themer: Path, editor: Path, baseline: bool) -> None:
    replacements = {
        "-- THEMER_SOURCE_INSERTION_POINT": themer.read_text(encoding="utf-8"),
        "-- THEME_EDITOR_SOURCE_INSERTION_POINT": editor.read_text(encoding="utf-8"),
        "-- BASELINE_MODE_INSERTION_POINT": "local baselineMode = " + str(baseline).lower(),
    }
    for marker, source in replacements.items():
        if template.count(marker) != 1:
            raise ValueError(f"The test template must contain exactly one {marker}")
        template = template.replace(marker, source)
    with tempfile.TemporaryDirectory(prefix="moon-theme-tests-") as temp_dir:
        harness = Path(temp_dir) / "theme-tests.luau"
        harness.write_text(template, encoding="utf-8")
        subprocess.run([str(luau.resolve()), str(harness)], check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", required=True, type=Path, help="Verified Luau CLI path")
    parser.add_argument("--baseline-themer", type=Path, help="Reviewed original source, to reproduce two failures")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    patched = project / "patches/Moon_Animator_2/Libraries/Themer.luau"
    editor = project / "patches/Moon_Animator_2/Windows/EditTheme.luau"
    template = (project / "tests/theme.spec.luau").read_text(encoding="utf-8")
    if args.baseline_themer:
        run_harness(args.luau, template, args.baseline_themer, editor, True)
    run_harness(args.luau, template, patched, editor, False)


if __name__ == "__main__":
    main()
