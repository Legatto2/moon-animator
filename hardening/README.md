# Moon Animator 2 — reviewed build

This directory maintains a focused security and reliability patch for the
pinned v34000 model in [Legatto2/moon-animator](https://github.com/Legatto2/moon-animator).
The baseline comes from the user's fork of `zildjibian/moon-animator`.
The review date is 2026-10-21. This is an unofficial testing candidate;
Roblox Studio integration has **not** been tested.

## Build and changes

The plugin is [candidate/Moon_Animator_2_review_candidate.rbxm](candidate/Moon_Animator_2_review_candidate.rbxm).
Its adjacent manifest records the exact input, output, changed scripts, and
disconnected rig-template joints. Use this candidate when testing the changes.
The original model in the repository root remains the pinned build input.

- **Restricted animation events:** approved JSON commands can play/stop sounds
  and emit/clear particles on the animated scene item. Imported event text is
  never evaluated as Luau. Approval is local to the current session and binds
  the exact text, track, root, and resolved objects.
- **Explicit preview controls:** the event editor has On Begin/On End fields,
  inline examples, a Preview ON/OFF choice, and a Save action. New edits reset
  preview OFF. Save commits the edits before granting approval. Validation
  errors and partial approval failures leave a clear message in the editor.
- **Cleanup and limits:** Stop, track removal/disable, and revocation clean up
  tracked sounds and particle emitters. Shared operation budgets, bounded
  parsing, and bounded event traversal limit preview work.
- **Theme fixes and presets:** Default/Lunar background metadata no longer
  enters the RGB constructor. Imports validate before application. Catppuccin
  Latte, Frappe, Macchiato, and Mocha are available in the theme menu.
- **Rig-template repair:** 18 pre-existing cross-rig Snap/Weld objects have
  their endpoints cleared. Normal Motor6D joints, geometry, and both preview
  cameras retain their original serialized data.
- **Easy Weld input validation:** cleaning an empty or unsupported container
  reports an error before scene mutation instead of reaching a nil part.
- **Repeatable verification:** a dependency-free Python builder, readable
  source snapshots, focused tests, and a pinned CI workflow make the packaged
  code and review reproducible.

Ordinary named Roblox animation markers, rig/part/camera tracks, easing,
timeline controls, prop attachment, and import/export mechanisms remain.
[The tutorial coverage report](docs/TUTORIAL-COVERAGE.md) maps each published
chapter of the linked official tutorial to its implementation.

## Use event previews

Read [SAFE-EVENTS.md](docs/SAFE-EVENTS.md) for the full schema, limits, and
migration guidance. For an animated model containing `Head/Footstep` (Sound)
and `Muzzle/Flash` (ParticleEmitter), On Begin can contain:

```json
{
  "version": 1,
  "actions": [
    {"op": "sound.play", "target": ["Head", "Footstep"]},
    {"op": "particle.emit", "target": ["Muzzle", "Flash"], "count": 12}
  ]
}
```

Select the event, edit its commands, set **Preview: ON**, and click **Save**.
Importing or reopening a project does not preserve approval. Existing Luau
text stays in the project but is inert; convert its effects to supported
commands or use named animation markers with code you control in the game.

## Contents

| Path | Purpose |
| --- | --- |
| `candidate/` | Built RBXM and deterministic change manifest |
| `patches/` | Replacement Luau source used by the builder |
| `reviewed-sources/` | All 139 scripts extracted from the candidate |
| `changes.patch` | Source diff against the pinned input |
| `build_candidate.py` | Bounded binary editor using only Python's standard library |
| `verify.py`, `tests/` | Rebuild, comparison, syntax checks, and focused behavior tests |
| `docs/` | Event guide and tutorial source coverage |
| `optional-themes/catppuccin/` | Original palette JSON, provenance, and MIT license |
| `evidence/` | Script inventory, comparisons, and measured verification results |
| `REVIEW.md` | Audit findings, scope, and limitations |
| `SHA256SUMS.txt` | Hashes of the files in this directory, excluding itself |

## Rebuild

Use Python 3.10 or newer and the exact original model already in the repository.
From the repository root, choose a new output filename:

```bash
python hardening/build_candidate.py --input "Moon Animator 2 (v34000).rbxm" --output "Moon_Animator_2_rebuilt.rbxm"
```

Pinned input identity:

```text
Upstream: https://github.com/zildjibian/moon-animator
Commit:   69b88295776351b5aec1cdff783bb12a194daf43
File:     Moon Animator 2 (v34000).rbxm
Bytes:    420075
SHA-256:  f757db4c6dd9eb68fea11891e12ac4e8cbe776b4d6d26d1c89625c5826d23206
```

The builder refuses a different input hash, unsupported binary structures,
unknown patch targets, symbolic links/reparse points, and existing outputs.
It writes a JSON manifest beside the model and never runs the plugin.
Unmodified chunks are copied byte-for-byte. Changed chunks use the binary
format's standard uncompressed representation.

The builder accepts the replacement source supplied by the person running it.
It does not make arbitrary new patches or upstream versions trustworthy.

## Verify

Download the official [Luau 0.743 command-line tools](https://github.com/luau-lang/luau/releases/tag/0.743),
then run from the repository root:

```bash
python -B hardening/verify.py --luau-dir /path/to/luau-tools
```

On Windows, the supplied directory should contain `luau.exe` and
`luau-compile.exe`. On Linux/macOS it should contain `luau` and `luau-compile`.
The verifier requires all focused tests to pass without skips, rebuilds in a
temporary directory, byte-compares the candidate and manifest, compares every
extracted script to its readable snapshot, and compiles all 139 scripts.
It does not download dependencies or modify the checked-in candidate.

The GitHub workflow performs the same check on Ubuntu with Python 3.12. Actions
are pinned to commit SHAs, checkout does not retain credentials, and the Luau
download is checked against a recorded SHA-256 before execution. The workflow
has read-only repository permissions and does not execute the complete plugin.

Exact local test totals and hashes are in
[evidence/verification.json](evidence/verification.json). Behavioral tests use
explicit Roblox/UI mocks; syntax compilation is not a Studio integration test.

## Studio acceptance check

Use a disposable local place for the first launch. Import the candidate and
save it as a local plugin using Studio's
[documented local-plugin workflow](https://create.roblox.com/docs/studio/plugins).
Disable other copies while testing to avoid toolbar/global-state collisions.

1. Open the plugin and both character preview panels; insert an R6 rig.
2. Animate a rig and a part, change easing/duration, animate the camera, and
   hide/show the UI. Attach a prop using Easy Weld.
3. Clean an empty Folder/Model and confirm it produces a message with no scene
   changes. Check ordinary cleaning with a backed-up part-containing model.
4. Save/reopen a short project, export a rig animation, and import it again.
   Check a named keyframe marker's name/value through the round trip.
5. Import an event with legacy Luau text and confirm it stays inert. Approve
   the example sound/particle commands and check their begin/end behavior.
6. Stop while a looping event sound is active. Verify it stops, touched emitters
   clear, and editing/replacing a target requires fresh approval.
7. Select each Catppuccin preset and test one valid and one malformed theme
   import. Confirm a rejection leaves the current theme intact.

The baseline's version/activation logic is retained. Its product-description
version check may display an out-of-date UI lock; startup under that check has
not been verified. The current build also does not validate arbitrary fetched
assets or every possible imported-project structure. See the full review for
the precise boundary of the work.

## Credits

Moon Animator's upstream credits identify the original author as xsixx.
The baseline is an unofficial distribution by zildjibian. Existing credits,
embedded terms, activation logic, and original theme entitlements are retained.
This work does not apply a new license to the engine.

The four added Catppuccin palettes come from
[catppuccin/moon-animator-2](https://github.com/catppuccin/moon-animator-2)
at `7541ad7e017c3447cf53f0c4b79ee2963fe7528b`; their MIT license is included.
