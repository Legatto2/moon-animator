#!/usr/bin/env python3
"""Exercise the restricted MarkerTrack with inert JSON/scene mocks and event text."""

import argparse
import subprocess
import tempfile
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", required=True, type=Path, help="Verified Luau CLI path")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    module = project / "patches/Moon_Animator_2/Classes/LayerSystemItem/MarkerTrack.luau"
    template = project / "tests/marker-track.spec.luau"
    insertion_point = "-- MODULE_SOURCE_INSERTION_POINT"
    template_text = template.read_text(encoding="utf-8")
    if template_text.count(insertion_point) != 1:
        raise ValueError("The test template must contain exactly one module insertion point")
    combined = template_text.replace(insertion_point, module.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="moon-marker-track-tests-") as temp_dir:
        harness = Path(temp_dir) / "marker-track-tests.luau"
        harness.write_text(combined, encoding="utf-8")
        subprocess.run([str(args.luau.resolve()), str(harness)], check=True, timeout=30)


if __name__ == "__main__":
    main()
