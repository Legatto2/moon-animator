# Repository review and focused hardening

Reviewed: 2026-10-21. Method: pinned repository inspection, binary/XML parsing,
source comparison, static code review, isolated behavior tests, and syntax
compilation. The complete plugin was not executed or installed in Roblox
Studio. The tested artifact is identified by its manifest and checksums.

## Recommendation

The user's selected fork, `Legatto2/moon-animator`, contains the reviewed
top-level v34000 package from `zildjibian/moon-animator`. It is the more
conservative technical baseline among these unofficial copies. This candidate
is built from that exact input. Catppuccin supplies the four added color
presets. Neither the repository name nor
the removal of an out-of-date lock establishes the safety of an animation
plugin.

| Repository | Purpose and reviewed scope | Assessment |
| --- | --- | --- |
| `befexx/Moon-Animator-2-Unlocked` | Two complete XML plugin models and README at commit `46c66165879061eafff646d1b9be72e6ad73557d`. | Unofficial modified copies. Both have executable event playback and cross-rig joints. The newer model adds 64 such joints and additional behavior changes. |
| `zildjibian/moon-animator` | Current top-level v34000 binary, matching current release, and one archive spot check at commit `69b88295776351b5aec1cdff783bb12a194daf43`. | Best baseline among these copies for focused hardening, but still unofficial and still contains the shared defects. Historical archives were not comprehensively reviewed. |
| `catppuccin/moon-animator-2` | Four JSON themes, README, license, generator template, and build recipe at commit `7541ad7e017c3447cf53f0c4b79ee2963fe7528b`. | Appearance data, not an animation engine. The four importable files contain six RGB triples each, with no executable expressions or URLs. Preview images were outside code-review scope. |

Primary repositories:

- <https://github.com/befexx/Moon-Animator-2-Unlocked>
- <https://github.com/zildjibian/moon-animator>
- <https://github.com/catppuccin/moon-animator-2>

## What the plugin does

The inspected Moon Animator distribution is a Roblox Studio animation and
scene-editing plugin. It provides a timeline, tracks, keyframes, easing,
playback, animation import/export, rig and camera animation, character
insertion, and welding tools. It stores Moon Animator project data and can
export Roblox animation data. Its event tracks also store source text that the
original implementation attempted to execute at event boundaries.

Ordinary named animation markers are distinct from that executable event
source. Blocking the latter does not require deleting marker names, timing, or
the saved source strings.

## Source relationship and package quality

Each complete model inspected contains 139 scripts: one LocalScript entry
point and 138 ModuleScripts. The current zildjibian model and Befexx's older
`Moon Animator 2 Unlocked.rbxmx` have **all 138 modules byte-identical**. Only
the entry point differs. Zildjibian retains a 40-line version/UI-lock section
that Befexx removes.

The newer Befexx `Moon Animator 2.rbxmx` shares 134 scripts with the zildjibian
baseline. Its five differing scripts alter startup activation, theme
availability, activation UI, character preview fallback behavior, and
save/export/conversion behavior. That makes it a less conservative starting
point for this focused patch.

The binary zildjibian model retains two preview Camera instances under the
CharacterInserter's Presets and FaceEdit templates. Both are absent from the
Befexx XML models, which explains the newer Befexx source's fallback-camera
change. The chosen binary also has 18 cross-rig Snap/Weld joints, compared with
82 in the newer Befexx package. These counts describe serialized object
references; the review did not measure their runtime physical effects.

The current zildjibian release download matched its top-level v34000 model
byte-for-byte. A spot check of the latest archived v34000/av361 model showed
differences beyond the removed plugin-name guard, so the claim that only one
line was removed does not establish an authenticated original baseline. This
review makes no claim that the archive is a verified original release.

## Security findings

### 1. Imported project event source reaches an evaluator

**Confirmed code path; executable capability, not proof of malicious intent.**

The original `Classes/LayerSystemItem/MarkerTrack` module passes `codeBegin`
and `codeEnd` text to `loadstring(code)()`. Project deserialization preserves
these properties, populated tracks can be enabled automatically, and playback
visits event start/end boundaries. An imported Moon Animator project can
therefore carry executable event source to this call path. The exact runtime
availability and permissions of the evaluator were not tested in Studio.

Reviewed chain within the extracted baseline:

- `Classes/GuiElement/LayerSystem/LayerSystem.luau`, project loading and
  deserialization.
- `Classes/GuiElement/LayerSystem/ItemObject.luau`, marker import.
- `Classes/TrackItem/Marker.luau`, copying marker properties.
- `Classes/LayerSystemItem/Track.luau`, track enabling.
- `Classes/LayerSystemItem/MarkerTrack.luau`, event-boundary execution.

**Fix:** Remove dynamic evaluation from playback entirely. A restricted
interpreter accepts JSON version 1 programs with only `sound.play`,
`sound.stop`, `particle.emit`, and `particle.clear`. Every target must be a
Sound or ParticleEmitter reached by literal child names under the animated
scene item. No arbitrary property/method access, environment mutation, module
loading, or source evaluation is available through the command format.

The editor requires an explicit Preview ON choice followed by Save. Private
session grants bind the marker, exact source, playback handler, root ancestry,
and resolved object identities. Imported properties cannot create a grant.
Changed text or replaced/reparented objects invalidate approval on checking.
Cancel does not grant approval. Batch failures revoke the selection and report
whether text was saved while preview remained OFF.

The interpreter preflights both programs at approval and the complete selected
program at execution. Bounded parsing/path traversal, shared token buckets,
per-play particle limits, and a frame-scan cap restrict preview work. Stop and
track/marker revocation clean tracked sounds and touched emitters. Sound and
particle methods still have real effects: clearing an emitter affects its
current particles, and those transient effects cannot be fully rolled back.
The [event guide](docs/SAFE-EVENTS.md) documents exact limits and semantics.

Stored legacy text and ordinary named marker data remain in projects. Legacy
Luau is inert and must be converted for preview. Named markers can trigger
reviewed game code through Roblox's documented
[`AnimationTrack:GetMarkerReachedSignal`](https://create.roblox.com/docs/animation/events)
mechanism without putting executable source into imported animation data.

### 2. No confirmed malicious payload found in the reviewed scripts

The static review did not find a bundled credential-stealing payload, an
external webhook, a remote HTTP source loader, a numeric asset-ID `require`,
or script-source injection into the user's place. The inspected imports
resolve to bundled modules; `LinkedSource` values were empty. `HttpService`
usage in these files was JSON encoding/decoding rather than external HTTP
requests.

These are scoped negative findings, not a safety certification. The plugin
does fetch normal Roblox assets/avatar data, and the zildjibian entry point
reads product metadata through `MarketplaceService:GetProductInfo`. Future
repository changes, other releases, fetched asset contents, external Moon
Animator projects, and all historical archives are outside this conclusion.

### 3. Provenance is not established by an unlock label

The plugin models are unofficial modified distributions. The repositories do
not provide an authenticated comparison with the original author's current
release. Catppuccin's MIT license covers its theme project and should not be
read as a license for Moon Animator's engine. The hardening candidate retains
the baseline's credits and embedded terms. At the user's request, the legacy
local activation flow, remote version/UI restriction, and named-theme locks
have been removed. This is a description of runtime behavior, not a grant of
new rights to the inherited engine.

## Reliability findings and fixes

### Background metadata passed as RGB

The original `Themer:SetTheme` treats every recognized Default-theme key as a
three-component color. `_bgOuter` is actually an array containing an image
URI, a scale-type name, opacity, and optionally a resampler name. Default and
Lunar therefore pass strings into `Color3.fromRGB`. Both defects were
reproduced with a numeric-only Color3 mock.

**Fix:** Preserve all four metadata fields, distinguish metadata from colors,
and validate/stage the entire supplied theme before mutating active state.
RGB values must be finite numbers from 0 through 255. Background opacity must
be finite from 0 through 1, and enum names must be recognized. The editor now
reports rejected imports rather than declaring success.

Partial palettes, the `locked` color-field alias, and callbacks remain
supported. Unknown fields and empty/malformed themes are deliberately
rejected. The four reviewed Catppuccin palettes are registered as named
presets with their license retained. Default remains the initial theme.
All 18 bundled names are now selectable; the unused `AddTheme` registration
path, separate named-theme allowlist, and price presentation have been
removed. Selecting a theme still goes through the staged input validation.

Official enum references:

- <https://create.roblox.com/docs/reference/engine/enums/ScaleType>
- <https://create.roblox.com/docs/reference/engine/enums/ResamplerMode>

### First-run activation and remote version restriction

The baseline's three toolbar buttons initially opened an EULA/activation
window. A local `MoonAnimator2Activated_2` setting selected the path that
refreshed files, connected the actual tool callbacks, and restored the saved
theme. The inspected code did not perform an activation-key, purchase, or
online ownership check; the visible account ID was a label only.

A separate Marketplace product-description request could detect a newer
version and hide activation controls, title labels, and shared UI elements.
Request failures were swallowed. A newer-version result blocked first-time
activation by hiding its button and changed the UI for previously activated
users; it was not a universal removal of every existing tool callback.

**Change:** Initialize files, tool callbacks, and the saved theme directly.
Remove the activation setting, acceptance handlers, account-status display,
and remote version request/UI restriction. Preserve the original terms in an
optional **Credits & terms** window. The old serialized window/file name may
remain for compatibility with the packaged hierarchy; it has no activation
behavior. Roblox's `Plugin:Activate`/`Deactivate` mouse-interaction methods
are unrelated to licensing and remain intact.

The event editor's explicit session preview approval also remains intact.
Removing plugin activation does not authorize imported event content.

### Beginner Windows installation

The deterministic Windows ZIP contains only the reviewed model, a readable
`Install.cmd`, and `START_HERE.txt`. Its helper validates the embedded model
hash, requires Studio to be closed, stages the destination file, and backs up
an existing managed copy before replacement. Backups live outside the active
plugins directory. It does not fetch code, request administrator access,
change PowerShell execution policy, edit the registry, or modify other
plugins. A manual installation route is documented.

Portable tests check package content and reproducibility. A separate native
Windows CI job exercises the actual helper with temporary local-app-data
directories, including failed validation and replacement behavior. This
checks the installer; it does not establish full Roblox Studio compatibility.

### Cross-rig joints

The chosen baseline contains six Snap and twelve Weld objects with endpoints
belonging to different top-level rig templates. These references should not
tie separate templates together.

**Fix:** Keep the instances and clear both endpoint references. This makes the
change narrow and reproducible without rebuilding the hierarchy or renumbering
objects. Regular Motor6D joints and all other object properties retain their
original serialized values. The manifest names all affected objects and their
previous endpoints.

### Save/export concerns from the newer Befexx model

The newer Befexx variant changes rig-only save/export behavior and disables a
conversion guard with `if false and ...`. Those edits are absent from the
selected zildjibian baseline. This candidate therefore avoids those added
changes; it does not claim that every existing save/import/export bug has been
found or repaired.

### Empty Easy Weld input

The tutorial coverage check confirmed that Clean Tool is enabled for selected
Tool, Model, and Folder containers, even if they hold no BaseParts. The old
cleaner reaches `newBasePart.Position` with no selected part. A baseline test
reproduced that exception.

**Fix:** Preflight every selected cleaning input before creating, cloning,
destroying, or reparenting scene objects. Empty/unsupported input produces an
understandable error without a partial batch edit. Normal cleaning, handle
selection, Weld/Motor6D creation, and in-place offsets remain covered by the
focused tests. This is a correction within the tutorial's existing workflow.

### Tutorial comparison

The published chapters of the user's linked
[official tutorial](https://www.youtube.com/watch?v=q8tGNMo_jHg) were mapped to
actual source for rig insertion/animation, easing, duration, welding/props,
parts, camera, UI hiding, export/import, and named markers. No missing mechanism
was established from those chapter descriptions. The full mapping is in
[TUTORIAL-COVERAGE.md](docs/TUTORIAL-COVERAGE.md). A transcript and visual playback
were not retrieved; no claim is made that the tutorial was watched or reproduced
inside current Studio.

## Build and verification boundaries

The builder accepts only the exact source SHA-256 in `README.md`. It parses
bounded binary chunks, applies supplied replacement Source values, clears the
18 reviewed joints' references, and reparses the result. The manifest records
script hashes and every modified property chunk. Unmodified chunks must remain
byte-identical, and changed property values must match the intended edits.

The binary format reference is <https://dom.rojo.space/binary.html>. Modified
chunks use its uncompressed representation; other chunks keep their original
bytes. This is a narrow editor for the pinned package, not a general model
converter or a security validator for arbitrary third-party patches.

The included evidence records the actual focused checks and source compilation
results. Event, editor, playback, theme, startup, and welding harnesses use explicit Roblox mocks. They
verify the relevant module behavior without launching the complete plugin.
Compilation of extracted sources checks syntax only. None of these checks
establish Studio UI rendering, current Roblox API compatibility, save/export
integration, fetched-asset safety, or complete runtime startup in Studio.

The repository's verifier rebuilds the candidate, requires its bytes and
manifest to match the checked-in files, compares all source snapshots, and
compiles every extracted script. CI uses pinned actions and a checksum-verified
Luau tool download with read-only repository permissions. The builder also
rejects Windows reparse points on Python 3.10/3.11, where `Path.is_junction`
is unavailable, using `lstat` attributes instead.

The remaining Studio smoke test covers startup and preview cameras; a short
animation saved, reopened, and exported; named markers; approved effects and
inert legacy source; Stop cleanup; empty-container welding; and valid/invalid
theme imports. Fetched-asset behavior and complete Studio runtime behavior
remain unverified. Preserve a known working plugin and animation backup until those
flows pass.
