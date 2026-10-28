# Installation and troubleshooting — 0.4.0-beta.5

[简体中文](INSTALL.zh-CN.md)

## Required downloads

- **Framework:** [UE4SS for FarFarWest — Nexus mod 2](https://www.nexusmods.com/farfarwest/mods/2?tab=files), by anro / AnroG772. Select the player Main File **UE4SS-FarFarWest**, **3.0.1.1183 Frostburn, file 242**, not zDEV. Its archive is named UE4SS-FarFarWest-v3.0.1-1183-frostburn.zip.
- **Trainer:** [FFWTrainer-0.4.0-beta.5.zip](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/download/v0.4.0-beta.5/FFWTrainer-0.4.0-beta.5.zip). The source ZIP is for development, not installation.

**The beta.5 attachment is unchanged and contains older installation text and a separate signature. Follow this online guide: install only its FFWTrainer folder, and keep every signature/configuration file from the complete Nexus framework. Do not merge the whole GameRoot folder.**

Use normal Windows extraction and copying. No terminal or batch file is needed. After a game update, check the Nexus framework page for compatibility instructions.

## 1. Back up and locate the folders

Fully exit the game. Paste `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames` into the File Explorer address bar and copy the entire SaveGames folder to a dated backup outside the game directory. Keep the original in place. If no save exists yet, skip this backup until the game creates one. Separately back up existing mods' Data folders; mod settings and game saves are different. Keep these backups private.

Steam → Far Far West → Manage → Browse local files opens the **game root**. Inside it, `FarFarWest/Binaries/Win64` is the **executable folder**, containing `FarFarWest-Win64-Shipping.exe`.

## 2. Install the complete Nexus framework

For a fresh installation, extract the Nexus framework into a temporary folder. Copy its **dwmapi.dll** and **ue4ss** folder into the executable folder. Verify:

    <game root>/FarFarWest/Binaries/Win64/
      FarFarWest-Win64-Shipping.exe
      dwmapi.dll
      ue4ss/UE4SS.dll
      ue4ss/UE4SS-settings.ini
      ue4ss/UE4SS_Signatures/
      ue4ss/Mods/shared/UEHelpers/UEHelpers.lua

Keep the Nexus package's DLL, settings, mod list and all included signatures together. Do not copy only the DLL or mix the package with generic UE4SS files.

If migrating an older framework, first back up the complete old ue4ss folder and dwmapi.dll outside the game directory, including every mod's Data. Move the old framework into that backup, then install the complete Nexus package fresh. Restore compatible content mods one at a time and their matching Data. Do not restore old UE4SS.dll, UE4SS-settings.ini, Mods/mods.txt or UE4SS_Signatures over the new framework. Leave unrelated proxy files intact unless you have identified their owner.

Start the complete Nexus framework alone to confirm it reaches the title screen, then fully exit. If it fails, inspect the newly updated `ue4ss/UE4SS.log` before adding the Trainer. An existing working installation of this complete Nexus profile does not need reinstalling.

## 3. Copy only the Trainer folder

Extract the Trainer ZIP outside the game directory. Open this folder inside the extracted archive:

    GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/

Copy that **FFWTrainer** folder into:

    <game root>/FarFarWest/Binaries/Win64/ue4ss/Mods/

The final layout must be:

    <game root>/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/
      enabled.txt
      Scripts/main.lua
      Scripts/Progress.lua
      Scripts/Spawner.lua
      Scripts/TrainerUI.lua
      Data/  (may initially be empty)

**Do not copy the archive's sibling UE4SS_Signatures directory or its ProcessLocalScriptFunction.lua. Preserve all Nexus signatures, UE4SS-settings.ini, Mods/mods.txt and framework DLLs.** Do not add an extra GameRoot or nested FFWTrainer folder.

Keep every Scripts file. Retain existing Data/settings.json when updating. Check that enabled.txt is not accidentally named enabled.txt.txt. The card-information and combat-statistics mods are separate and are not required.

## 4. Start and use the Trainer

Fully restart the game and enter the saloon. Returning to the title screen alone does not reload the mod; the Nexus profile disables automatic/hot reloading.

| Control | Action |
| --- | --- |
| F2 | Open/close the normal trainer |
| F4 | Open/close Chinese/English Joker search |
| F1 or Apply | Apply the selected permanent-progress target |
| F3 or Joker action button | Use the chosen mode while the Joker page is open in a mission |
| F5 / F6 | Previous/next entry |
| Mouse | Select categories/entries, turn pages, enter values, scroll details |

For permanent resources or levels, wait for your local character and save to load in the saloon. Select the exact entry and confirm its current value is readable. Enter the desired **total** as digits, such as 26; do not enter +1, 1,000 or 1e3. Apply once and read the result. Allow the game to save normally, then return to the title and re-enter the saloon or fully restart to verify persistence. A successful panel opening or in-memory value alone does not prove a disk save.

Resources accept 0–9,999,999; character/weapon/magic-school levels accept 1–100. Magic levels represent Acid, Elec, Pyro, Voodoo, Cactus and Frost schools.

In Settings, choose **Drop on ground** or **Gain directly**. F3 uses that choice during a mission; leave at least two seconds between requests. Close the panel to collect dropped cards. Ground mode pauses at 10 nearby uncollected dropped Jokers within 20 metres. The total-point budget option lets you continue allocating points through the game's original equipment menu.

## 5. Troubleshooting

### Game crashes on startup

1. Exit the game. Disable only FFWTrainer as described below and restart once.
2. If it now starts, leave Trainer disabled and report its version plus the relevant new log lines.
3. If it still crashes, use the backup/migration procedure above to test a fresh, complete Nexus framework without restoring content mods or old global settings.
4. If that framework-only setup also crashes, check the framework page against your installed game version and report the exact framework file/version and new log to its author. If it starts, exit fully and add compatible content mods back one at a time.

Do not delete game saves as a crash remedy or repeatedly replace individual DLLs/signatures from different packages.

### F2/F4 do nothing or the mouse does not work

Check the paths above, enabled marker and the modification time of:

    <game root>/FarFarWest/Binaries/Win64/ue4ss/UE4SS.log

Look for a new FFWTrainer startup entry. If the framework logs but Trainer does not, check the folder and activation. Fully restart after updating; keep one FFWTrainer installation with its complete Scripts folder. If the mouse still fails, report whether the cursor cannot move or visible buttons cannot be clicked, and which other overlay/menu was open. F5/F6 remain available for entry navigation.

### F2 opens, but a value cannot be changed or does not stay saved

Return to the saloon, wait for your own character and save to load, and check that the selected value is readable and Apply is available. Re-enter the desired total and record the **exact displayed message**. Do not assume an open panel means saving is available. If the application fails or the value reverts after reloading, stop repeated requests and provide the message plus relevant log lines.

Beta.5 does not include later diagnostic changes. If its error text still names an older framework build, report that text and the exact Nexus file you installed; do not replace the Nexus profile solely because an old message names another build.

For support, include Trainer/game/framework versions, saloon or mission state, host/client role, exact action and result. Redact personal paths/account identifiers from logs. Do not upload saves, Data folders or credentials. These installation changes do not establish that all reported crashes or saving failures are resolved.

## Updating, disabling and uninstalling

With the game closed, back up Mods/FFWTrainer outside Mods. To update beta.5, replace only that component's Scripts from the extracted FFWTrainer folder and keep Data/settings.json and enabled.txt. Do not merge GameRoot or reinstall a working Nexus framework.

To disable, move FFWTrainer/enabled.txt outside its folder. If Mods/mods.txt also enables FFWTrainer, set only that entry to 0. Restore the marker/entry to re-enable. To uninstall, move only Mods/FFWTrainer into your backup; retain its Data and the shared Nexus framework/signatures. Restore the previous Trainer files and matching Data backup to roll back. Uninstalling does not undo progress already saved by the game.

## Compatibility and paths

See the [framework compatibility guide](FFWTools/src/RuntimeCompatibility/README.en.md). If the log identifies Lua loading failures caused by a non-ASCII installation path, use Steam's storage UI to move the game to an ASCII-only library path. This guide does not require changing the Windows system locale.
