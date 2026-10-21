<div align="center">

<h1>Moon Animator 2</h1>

<p><strong>A reviewed fork for Roblox Studio</strong></p>
<p>Focused security fixes, explicit event previews, and four Catppuccin themes.<br>Readable source. Reproducible builds. Documented review limits.</p>

<p>
  <a href="#getting-started"><img src="https://img.shields.io/badge/platform-Roblox_Studio-89b4fa?style=flat-square" alt="Platform: Roblox Studio"></a>
  <a href="https://github.com/Legatto2/moon-animator/actions/workflows/verify-hardening.yml?query=branch%3Amain"><img src="https://img.shields.io/github/actions/workflow/status/Legatto2/moon-animator/verify-hardening.yml?branch=main&amp;style=flat-square&amp;label=candidate_verification" alt="Live candidate verification workflow status"></a>
  <a href="hardening/evidence/verification.json"><img src="https://img.shields.io/badge/local_tests-167_passed-a6e3a1?style=flat-square" alt="Recorded local tests: 167 passed"></a>
  <a href="hardening/REVIEW.md"><img src="https://img.shields.io/badge/status-review_candidate-f9e2af?style=flat-square" alt="Status: review candidate"></a>
</p>

<p>
  <a href="https://raw.githubusercontent.com/Legatto2/moon-animator/07127379c6dd44219c7e4d4bdde5e1852cc34d09/hardening/candidate/Moon_Animator_2_review_candidate.rbxm"><strong>Download review candidate</strong></a>
  &nbsp;&middot;&nbsp;
  <a href="hardening/README.md">Build guide</a>
  &nbsp;&middot;&nbsp;
  <a href="#documentation">Documentation</a>
  &nbsp;&middot;&nbsp;
  <a href="hardening/REVIEW.md">Read the audit</a>
</p>

<p><sub>Unofficial &middot; Based on Moon Animator 2 v34000 &middot; Maintained in Legatto2/moon-animator</sub></p>

</div>

---

> [!IMPORTANT]
> This is an **unofficial review candidate**, and it has **not been launched in Roblox Studio as part of this review**. The inherited version and activation checks remain; an out-of-date version check may still lock the UI. Read the [review limits](hardening/REVIEW.md) and complete the [Studio acceptance check](hardening/README.md#studio-acceptance-check) before relying on this build.

## What this fork adds

| Explicit event previews | Themes and usability | Repairs you can inspect |
| :--- | :--- | :--- |
| Four restricted JSON commands for sound and particles, with a **Preview ON/OFF** control and approval limited to the current session. | **Catppuccin Latte, Frappe, Macchiato, and Mocha**, alongside the original Default theme. | **18 stray cross-rig joints disconnected** in the bundled templates, with normal Motor6D joints and preview cameras preserved. |
| Exact source and target binding, shared resource limits, and cleanup when playback stops. Imported event text is never evaluated as Luau. | Default/Lunar metadata fixes and custom-theme validation before changes are applied. | Empty-container validation in **Easy Weld**, readable snapshots of **all 139 scripts**, a deterministic builder, and focused regression tests. |

The inherited rig, part, and camera animation tools, easing, timeline controls, prop attachment, hide/show, import/export, and named animation markers remain in the source. The [tutorial coverage report](hardening/docs/TUTORIAL-COVERAGE.md) maps those mechanisms to the published tutorial chapters; runtime compatibility still needs Studio testing.

## Getting started

1. **Get the candidate.** Download [Moon_Animator_2_review_candidate.rbxm](https://raw.githubusercontent.com/Legatto2/moon-animator/07127379c6dd44219c7e4d4bdde5e1852cc34d09/hardening/candidate/Moon_Animator_2_review_candidate.rbxm). Its [build manifest](hardening/candidate/Moon_Animator_2_review_candidate.rbxm.manifest.json) records the input, output, and exact changes. The original model at the repository root is the build input.
2. **Open a disposable local place.** Follow the [local-plugin setup and acceptance checklist](hardening/README.md#studio-acceptance-check). Disable other Moon Animator copies while testing to avoid toolbar and global-state collisions.
3. **Check the workflows you use.** Start with a short rig animation and a save/import/export round trip. Then try the theme presets and the event-preview example below. Record any startup, layout, or engine behavior that differs from the checklist.

## Event previews, with explicit approval

For an animated model containing a `Head/Footstep` Sound and a `Muzzle/Flash` ParticleEmitter, put this in an event's **On Begin** field:

```json
{
  "version": 1,
  "actions": [
    {"op": "sound.play", "target": ["Head", "Footstep"]},
    {"op": "particle.emit", "target": ["Muzzle", "Flash"], "count": 12}
  ]
}
```

Adjust the child names to match your scene, choose **Preview: ON**, and click **Save**. The toggle is a draft choice until Save succeeds. Editing the source resets it to OFF; importing or reopening a project requires fresh approval. **Stop** cleans up tracked sounds and touched emitters.

The supported operations are `sound.play`, `sound.stop`, `particle.emit`, and `particle.clear`. Existing Lua event text stays stored and inert. Use the [event guide](hardening/docs/SAFE-EVENTS.md) for On End examples, limits, dedicated-emitter guidance, and migration to named animation markers for custom game behavior.

## Verification you can reproduce

The [recorded local verification](hardening/evidence/verification.json) reports **167 passing focused tests**, **139 of 139 scripts compiling**, and a fresh rebuild whose candidate and manifest match the checked-in files byte for byte. The [full log](hardening/evidence/verification.log) is included.

Behavioral tests use explicit Roblox and UI mocks. Compilation and these tests do not run the complete plugin or establish Studio compatibility. The badge above reports the live [GitHub workflow](https://github.com/Legatto2/moon-animator/actions/workflows/verify-hardening.yml); the local-test badge links to the separately recorded evidence.

<details>
<summary><strong>Rebuild and verify locally</strong></summary>

Use **Python 3.10+** and the official **Luau 0.743** interpreter/compiler. Run these commands from the repository root, choosing a new output filename:

```bash
python hardening/build_candidate.py --input "Moon Animator 2 (v34000).rbxm" --output "Moon_Animator_2_rebuilt.rbxm"
python -B hardening/verify.py --luau-dir /path/to/luau-tools
```

The tools directory should contain `luau` and `luau-compile`, or their `.exe` equivalents on Windows. The verifier requires every focused test to pass without skips, rebuilds in a temporary directory, compares the candidate and manifest, checks all extracted sources against their readable snapshots, and compiles every script. It does not download dependencies or change the checked-in candidate.

The [CI workflow](.github/workflows/verify-hardening.yml) pins its actions and Luau version, checks the Luau download's SHA-256, and uses read-only repository permissions. The Python builder uses the standard library and accepts only the pinned original model.

See the [complete build guide](hardening/README.md) for tool downloads, input hashes, build behavior, and acceptance checks.

</details>

## Documentation

| Start here | What you will find |
| :--- | :--- |
| [Build and setup guide](hardening/README.md) | Candidate contents, local verification, and Studio acceptance checks |
| [Event commands and migration](hardening/docs/SAFE-EVENTS.md) | Supported operations, approval rules, resource limits, and named markers |
| [Tutorial coverage](hardening/docs/TUTORIAL-COVERAGE.md) | Published tutorial chapters mapped to the retained implementation |
| [Repository review](hardening/REVIEW.md) | Findings, changes, scope, and remaining uncertainty |
| [Source changes](hardening/changes.patch) · [Readable sources](hardening/reviewed-sources/Moon_Animator_2) | The focused patch and every packaged script |
| [Verification evidence](hardening/evidence/verification.json) · [Build manifest](hardening/candidate/Moon_Animator_2_review_candidate.rbxm.manifest.json) · [Checksums](hardening/SHA256SUMS.txt) | Test results, artifact identity, and exact rebuild details |

Historical archives remain as upstream material and are outside this candidate's review scope. The original root model is retained as the hash-pinned build input.

## Credits and provenance

Moon Animator's original author is credited upstream as **xsixx**. This fork builds on the v34000 model from [zildjibian/moon-animator](https://github.com/zildjibian/moon-animator) and retains its original credits, embedded terms, activation logic, and theme entitlements. It does not claim original authorship or apply a new license to the engine.

The four Catppuccin palettes come from [catppuccin/moon-animator-2](https://github.com/catppuccin/moon-animator-2). Their [provenance](hardening/optional-themes/catppuccin/README.md) and [MIT license](hardening/optional-themes/catppuccin/LICENSE) are included.

[Original Moon Animator 2](https://create.roblox.com/store/asset/4725618216) &nbsp;&middot;&nbsp; [Support Moon Animator](https://www.patreon.com/moonanimator) &nbsp;&middot;&nbsp; [Moon Plus documentation](https://zildjibian.github.io/moon-plus/)
