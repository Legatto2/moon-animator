<div align="center">

<h1>Moon Animator 2</h1>

<p><strong>Animation tools for Roblox Studio</strong></p>
<p>Animate rigs, props, and cameras.<br>Simple local installation. No activation step. Eighteen included themes.</p>

<p>
  <a href="#getting-started"><img src="https://img.shields.io/badge/platform-Roblox_Studio-89b4fa?style=flat-square" alt="Platform: Roblox Studio"></a>
  <a href="https://github.com/Legatto2/moon-animator/actions/workflows/verify-hardening.yml?query=branch%3Amain"><img src="https://img.shields.io/github/actions/workflow/status/Legatto2/moon-animator/verify-hardening.yml?branch=main&amp;style=flat-square&amp;label=candidate_verification" alt="Live candidate verification workflow status"></a>
  <a href="#getting-started"><img src="https://img.shields.io/badge/activation-none-a6e3a1?style=flat-square" alt="No activation required"></a>
  <a href="hardening/REVIEW.md"><img src="https://img.shields.io/badge/status-review_candidate-f9e2af?style=flat-square" alt="Status: review candidate"></a>
</p>

<p>
  <a href="https://raw.githubusercontent.com/Legatto2/moon-animator/07fcce707c17f03f6a1a8059c1bace613a741e1d/hardening/candidate/Moon_Animator_2_Windows_Install.zip"><strong>Download for Windows</strong></a>
  &nbsp;&middot;&nbsp;
  <a href="hardening/docs/INSTALL.md">Installation help</a>
  &nbsp;&middot;&nbsp;
  <a href="#documentation">Documentation</a>
  &nbsp;&middot;&nbsp;
  <a href="https://raw.githubusercontent.com/Legatto2/moon-animator/07fcce707c17f03f6a1a8059c1bace613a741e1d/hardening/candidate/Moon_Animator_2_review_candidate.rbxm">Download plugin file</a>
</p>

<p><sub>Unofficial &middot; Based on Moon Animator 2 v34000 &middot; Maintained in Legatto2/moon-animator</sub></p>

</div>

---

> [!NOTE]
> This is an **unofficial review build**. Automated checks and their exact scope are recorded in the [verification evidence](hardening/evidence/verification.json). The complete plugin still needs a [Roblox Studio smoke test](hardening/README.md#studio-acceptance-check).

## What this fork adds

| Simple startup and event previews | Themes and usability | Repairs you can inspect |
| :--- | :--- | :--- |
| Open all three tools immediately, including on a fresh installation. **No activation dialog, key, or online version gate.** | All **18 bundled themes** are selectable, including **Catppuccin Latte, Frappe, Macchiato, and Mocha**. | **18 stray cross-rig joints disconnected** in the bundled templates, with normal Motor6D joints and preview cameras preserved. |
| Four restricted JSON commands for sound and particles, with a **Preview ON/OFF** control, session approval, resource limits, and Stop cleanup. Imported event text is never evaluated as Luau. | Default/Lunar metadata fixes and custom-theme validation before changes are applied. | Empty-container validation in **Easy Weld**, readable snapshots of **all 139 scripts**, a deterministic builder, and focused regression tests. |

The inherited rig, part, and camera animation tools, easing, timeline controls, prop attachment, hide/show, import/export, and named animation markers remain in the source. The [tutorial coverage report](hardening/docs/TUTORIAL-COVERAGE.md) maps those mechanisms to the published tutorial chapters; runtime compatibility still needs Studio testing.

## Getting started

1. **Download** the [Windows install ZIP](https://raw.githubusercontent.com/Legatto2/moon-animator/07fcce707c17f03f6a1a8059c1bace613a741e1d/hardening/candidate/Moon_Animator_2_Windows_Install.zip).
2. **Extract it.** Right-click the ZIP, choose **Extract All**, and open the extracted folder.
3. **Install.** Close Roblox Studio, double-click **Install.cmd**, and wait for the success message. Reopen Studio and find **Moon Animator** in the Plugins toolbar/menu.

No activation button, license key, or coding is needed. The installer works offline, checks the bundled plugin file, and copies it into your local Studio plugins folder. Updating the same installed filename creates a backup first.

Already have another Moon Animator installed? Disable that copy in Studio's plugin manager so you only run one version. For macOS, a custom plugins folder, or installation without a helper, follow the [manual instructions](hardening/docs/INSTALL.md#manual-install-windows-or-macos).

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

The supported operations are `sound.play`, `sound.stop`, `particle.emit`, and `particle.clear`. This preview permission protects your scene from imported event content; it is separate from plugin activation. Existing Lua event text stays stored and inert. Use the [event guide](hardening/docs/SAFE-EVENTS.md) for On End examples, limits, dedicated-emitter guidance, and migration to named animation markers for custom game behavior.

## Verification you can reproduce

The [recorded verification](hardening/evidence/verification.json) contains the exact focused test results, compilation of **all 139 scripts**, and byte-for-byte rebuild checks for the model, manifest, and Windows package. The [full local log](hardening/evidence/verification.log), [passing Windows installer checks](hardening/evidence/windows-installer-ci.log), and [GitHub workflow](https://github.com/Legatto2/moon-animator/actions/workflows/verify-hardening.yml) are available for developers.

Plugin behavior tests use explicit Roblox and UI mocks. Compilation and these tests do not run the complete plugin or establish Studio compatibility. The Windows workflow tests the installer in temporary folders; it does not launch Studio. The badge above reports the workflow on `main`.

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
| [Installation and troubleshooting](hardening/docs/INSTALL.md) | Windows setup, manual installation, updates, backups, and removal |
| [Build and setup guide](hardening/README.md) | Candidate contents, local verification, and Studio acceptance checks |
| [Event commands and migration](hardening/docs/SAFE-EVENTS.md) | Supported operations, approval rules, resource limits, and named markers |
| [Tutorial coverage](hardening/docs/TUTORIAL-COVERAGE.md) | Published tutorial chapters mapped to the retained implementation |
| [Repository review](hardening/REVIEW.md) | Findings, changes, scope, and remaining uncertainty |
| [Source changes](hardening/changes.patch) · [Readable sources](hardening/reviewed-sources/Moon_Animator_2) | The focused patch and every packaged script |
| [Verification evidence](hardening/evidence/verification.json) · [Build manifest](hardening/candidate/Moon_Animator_2_review_candidate.rbxm.manifest.json) · [Checksums](hardening/SHA256SUMS.txt) | Test results, artifact identity, and exact rebuild details |

Historical archives remain as upstream material and are outside this candidate's review scope. The original root model is retained as the hash-pinned build input.

## Credits and provenance

Moon Animator's original author is credited upstream as **xsixx**. This fork builds on the v34000 model from [zildjibian/moon-animator](https://github.com/zildjibian/moon-animator) and preserves the original credits and embedded terms. The legacy activation flow, remote version restriction, and named-theme locks have been removed. This work does not claim original authorship or apply a new license to the animation engine.

The four Catppuccin palettes come from [catppuccin/moon-animator-2](https://github.com/catppuccin/moon-animator-2). Their [provenance](hardening/optional-themes/catppuccin/README.md) and [MIT license](hardening/optional-themes/catppuccin/LICENSE) are included.

[Original Moon Animator 2](https://create.roblox.com/store/asset/4725618216) &nbsp;&middot;&nbsp; [Support Moon Animator](https://www.patreon.com/moonanimator) &nbsp;&middot;&nbsp; [Moon Plus documentation](https://zildjibian.github.io/moon-plus/)
