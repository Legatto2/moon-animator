#!/usr/bin/env python3
"""Test the local startup block, credits, and theme menus with inert Roblox mocks.

Only the delimited bootstrap block and focused UI/theme modules are executed.
The complete init script and MoonAnimator window are never run.
"""

import argparse
import hashlib
import subprocess
import tempfile
from pathlib import Path


def between(source: str, start: str, end: str) -> str:
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError(f"Expected one source boundary: {start!r} / {end!r}")
    return source.split(start, 1)[1].split(end, 1)[0]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", required=True, type=Path, help="Verified Luau CLI path")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    patches = project / "patches/Moon_Animator_2"
    startup = (patches / "init.luau").read_text(encoding="utf-8")
    credits = (patches / "Windows/Activate.luau").read_text(encoding="utf-8")
    window = (patches / "Windows/MoonAnimator.luau").read_text(encoding="utf-8")
    themer = (patches / "Libraries/Themer.luau").read_text(encoding="utf-8")
    menu_item = (patches / "Classes/Menu/MenuItem.luau").read_text(encoding="utf-8")

    # Preserve the original terms exactly while removing the executable gates.
    terms = between(credits, "local EULA = [[", "]]")
    expected_terms_hash = "bcfab256f9243c18ef33207f540efc3fb7ec893a7dde4f42260a28d64c76b156"
    if hashlib.sha256(terms.encode("utf-8")).hexdigest() != expected_terms_hash:
        raise ValueError("The original upstream EULA text changed")
    for forbidden in ("MoonAnimator2Activated_", "MarketplaceService", "GetProductInfo"):
        if forbidden in startup:
            raise ValueError(f"Startup still contains an activation/version gate: {forbidden}")
    for forbidden in ("GetUserId", "StudioService", "Activate_Theme_", "SetSetting"):
        if forbidden in credits:
            raise ValueError(f"Credits still contains account or activation behavior: {forbidden}")
    for forbidden in ("theme_buttons", "AddTheme", "price_frame", "_SetPrice"):
        if forbidden in themer or forbidden in menu_item:
            raise ValueError(f"Obsolete theme entitlement machinery remains: {forbidden}")

    menu_start = "\tlocal FILE_MENU = {"
    menu_end = "\tlocal FM_DEFAULT_DISABLE = {"
    menu_source = menu_start + between(window, menu_start, menu_end) + "\nreturn FILE_MENU\n"
    theme_bindings_start = "\t\tfor _, theme in pairs(_g.Themer.ThemeList) do"
    theme_bindings_end = '\t\t_g.Input:BindAction(Win, "SmallBoneHandles",'
    theme_bindings = theme_bindings_start + between(window, theme_bindings_start, theme_bindings_end)
    credit_bindings = [line for line in window.splitlines() if ':BindAction(Win, "OpenActivate",' in line]
    if len(credit_bindings) != 1:
        raise ValueError("Expected one optional credits menu binding")

    replacements = {
        "-- STARTUP_SOURCE_INSERTION_POINT": between(startup, "-- BEGIN LOCAL STARTUP", "-- END LOCAL STARTUP"),
        "-- THEMER_SOURCE_INSERTION_POINT": themer,
        "-- CREDITS_SOURCE_INSERTION_POINT": credits,
        "-- MENU_SOURCE_INSERTION_POINT": menu_source,
        "-- MENU_BINDINGS_INSERTION_POINT": credit_bindings[0] + "\n" + theme_bindings,
        "-- MENU_ITEM_SOURCE_INSERTION_POINT": menu_item,
    }
    template = (project / "tests/startup.spec.luau").read_text(encoding="utf-8")
    for marker, source in replacements.items():
        if template.count(marker) != 1:
            raise ValueError(f"Expected one harness insertion point: {marker}")
        template = template.replace(marker, source)
    with tempfile.TemporaryDirectory(prefix="moon-startup-tests-") as directory:
        harness = Path(directory) / "startup-tests.luau"
        harness.write_text(template, encoding="utf-8")
        subprocess.run([str(args.luau.resolve()), str(harness)], check=True)


if __name__ == "__main__":
    main()
