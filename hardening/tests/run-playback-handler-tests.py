#!/usr/bin/env python3
"""Exercise Stop in the patched PlaybackHandler using inert host API stubs."""

import argparse
from pathlib import Path
import subprocess
import tempfile


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", required=True, type=Path)
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    module = project / "patches/Moon_Animator_2/Classes/GuiElement/LayerSystem/PlaybackHandler.luau"
    template = (project / "tests/playback-handler.spec.luau").read_text(encoding="utf-8")
    insertion = "-- MODULE_SOURCE_INSERTION_POINT"
    if template.count(insertion) != 1:
        raise ValueError("The test template must contain exactly one module insertion point")
    combined = template.replace(insertion, module.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="moon-playback-handler-tests-") as directory:
        path = Path(directory) / "playback-handler-tests.luau"
        path.write_text(combined, encoding="utf-8")
        subprocess.run([str(args.luau.resolve()), str(path)], check=True)


if __name__ == "__main__":
    main()
