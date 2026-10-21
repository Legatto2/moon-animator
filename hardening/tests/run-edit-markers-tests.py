#!/usr/bin/env python3
"""Test the event editor with reviewed input controls and inert Roblox/UI mocks.

This does not run the full plugin, parse scene files, or test Studio layout.
The command interpreter has its own focused tests; its approval API is mocked
here to exercise UI consent, validation order, and failure handling.
"""

import argparse
from pathlib import Path
import subprocess
import tempfile


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", required=True, type=Path, help="Verified Luau CLI path")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    template = (project / "tests/edit-markers.spec.luau").read_text(encoding="utf-8")
    sources = {
        "EDIT_MARKERS": project / "patches/Moon_Animator_2/Windows/EditMarkers.luau",
    }
    controls = project / "reviewed-sources/Moon_Animator_2/Classes/GuiElement/InputBox"
    for name, filename in (
        ("INPUT_BOX", "InputBox"), ("TEXT_INPUT", "TextInput"),
        ("MULTI_INPUT", "MultiInput"), ("TIME_INPUT", "TimeInput"),
    ):
        sources[name] = controls / (filename + ".luau")
    for name, path in sources.items():
        marker = f"-- {name}_SOURCE_INSERTION_POINT"
        if template.count(marker) != 1:
            raise ValueError(f"Expected exactly one {marker}")
        template = template.replace(marker, path.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="moon-event-editor-tests-") as directory:
        harness = Path(directory) / "edit-markers-tests.luau"
        harness.write_text(template, encoding="utf-8")
        subprocess.run([str(args.luau.resolve()), str(harness)], check=True)


if __name__ == "__main__":
    main()
