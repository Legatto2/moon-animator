# Install Moon Animator 2

## Windows: easiest installation

You need Roblox Studio installed. No coding, activation key, administrator access, or additional software is required.

1. Download [Moon_Animator_2_Windows_Install.zip](../candidate/Moon_Animator_2_Windows_Install.zip?raw=true).
2. In Downloads, right-click the ZIP and select **Extract All**. Open the extracted folder.
3. Save your work and **close Roblox Studio**.
4. Double-click **Install.cmd**. Wait for its success message, then close the installer window.
5. Reopen Studio. Look in the **Plugins** toolbar/menu for **Moon Animator**, **Character Inserter**, and **Easy Weld**. Click the tool you want.

There is no first-run activation dialog. You can start with a blank local place and an R6 rig.

If you previously installed another Moon Animator copy, disable it in Studio's plugin manager before using this build. Running two copies can create duplicate buttons and shared-state conflicts.

### What the installer does

The Windows package contains only three files:

| File | Purpose |
| :--- | :--- |
| `Install.cmd` | Checks the file and installs it using Windows' built-in tools |
| `Moon_Animator_2_review_candidate.rbxm` | The complete plugin model |
| `START_HERE.txt` | Short installation instructions |

The helper verifies the model's SHA-256, checks that Studio is closed, and installs this one file:

```text
%LOCALAPPDATA%\Roblox\Plugins\Moon_Animator_2_review_candidate.rbxm
```

It works offline and does not change your security settings, edit the registry, install dependencies, or modify other plugins. If the same destination filename already exists, the previous copy is backed up outside Studio's plugins folder:

```text
%LOCALAPPDATA%\MoonAnimator2\Backups\
```

If you configured a custom plugins folder in Studio, use the manual option below.

## Manual install: Windows or macOS

1. Download [Moon_Animator_2_review_candidate.rbxm](../candidate/Moon_Animator_2_review_candidate.rbxm?raw=true).
2. In Roblox Studio, open **Plugins → Plugins Folder**. Keep that folder open, then close Studio.
3. Copy the downloaded `.rbxm` file into that folder.
4. Reopen Studio and open **Moon Animator** from the Plugins toolbar/menu.

On Windows, you can also press **Win + R**, enter `%LOCALAPPDATA%\Roblox\Plugins`, and press Enter to open the default local plugins folder.

Copy the `.rbxm` directly into the plugins folder. The ZIP, its containing folder, and the installer are not plugin files. You do not need to insert the model into your game's Workspace or run a command in Studio.

Roblox's documentation also describes [saving a model/script as a local plugin](https://create.roblox.com/docs/studio/plugins#save-plugin-script) if you prefer to manage the installation inside Studio.

## Updating

Close Studio and run the newer package's **Install.cmd**. It uses the same installed filename, so updates replace this copy instead of adding another toolbar. The installer keeps the previous file in its backups folder before replacement.

For a manual update, close Studio, keep a backup outside the plugins folder, and replace the existing file with the new `.rbxm`.

## Removing or restoring this copy

To remove it, close Studio and delete only `Moon_Animator_2_review_candidate.rbxm` from your local plugins folder. Your animation projects are separate and are not removed by deleting the plugin file.

To restore an installer backup, close Studio, copy the desired `.rbxm.bak` file from `%LOCALAPPDATA%\MoonAnimator2\Backups` into the plugins folder, and rename that copy to `Moon_Animator_2_review_candidate.rbxm`. Keep backup files outside the plugins folder until you choose one to restore.

## If something goes wrong

| What you see | What to do |
| :--- | :--- |
| Download returns 404 | Open the repository's current README and use its download button. Avoid links to deleted branches. |
| The installer cannot find the plugin file | Use **Extract All**, then run `Install.cmd` from the extracted folder with the `.rbxm` beside it. |
| The installer asks you to close Studio | Save your work, close every Studio window, and run the installer again. |
| File verification fails | Delete the extracted download and download a fresh ZIP. The installer will not replace the installed plugin with a mismatched file. |
| Windows or an organization policy prevents the helper from running | Use the manual installation steps. The helper does not change execution policies or request elevated access. |
| No Moon Animator button appears | Confirm the `.rbxm` is directly in Studio's actual plugins folder, then fully close and reopen Studio. |
| Two Moon Animator toolbars appear | Disable the older copy in Studio's plugin manager, or move its local file out of the plugins folder while Studio is closed. |
| An old activation dialog appears | An earlier plugin copy is still running. Check which copies are enabled, then install the current review build and restart Studio. |
| The installer reports a linked folder or unexpected destination | Use Studio's actual plugins folder for a manual installation. The helper refuses redirected paths instead of following them. |

## First-use check

Open a disposable local place, launch each of the three tools, choose a theme, and save/reopen a short animation. The full [Studio acceptance checklist](../README.md#studio-acceptance-check) also covers effects, welding, import/export, and undo-related workflows.

The recorded tests are linked from the [build guide](../README.md#verify). The complete plugin has not been run in Roblox Studio in this review environment.
