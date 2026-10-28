# Trainer installation, use and recovery — 0.4.0-beta.6

## Required downloads

1. **Framework:** [UE4SS for FarFarWest — Nexus mod 2](https://www.nexusmods.com/farfarwest/mods/2?tab=files), by anro / AnroG772. Select the player Main File **UE4SS-FarFarWest**, version **3.0.1.1183 / Frostburn**, file 242 (archive named UE4SS-FarFarWest-v3.0.1-1183-frostburn.zip). Do not select the zDEV developer package. Check the current page if the game or framework has since updated.

2. **Content mod:** download **FFWTrainer-0.4.0-beta.6.zip** from the Trainer release files. The source ZIP is for development and is not the install package.

Install the complete Nexus player package, including its game-specific signatures and configuration. [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) is the upstream source project.

## Back up your game save before installing or changing progress

1. Fully exit the game. In File Explorer, paste `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames` into the address bar and press Enter. This is a folder location, not a command to run.

2. Copy the entire **SaveGames** folder to a dated backup outside the game installation. Keep the original in place. If it does not exist yet, skip this backup until the game has created a save; do not create or download someone else's save.

3. Separately back up `ue4ss/Mods/FFWTrainer/Data` if already installed. Mod settings and game saves are different: backing up one does not back up the other. Keep both backups private.

## Find the two different folders

Steam → Far Far West → Manage → Browse local files opens the **game root**. Inside it, FarFarWest/Binaries/Win64 is the **executable folder**, containing FarFarWest-Win64-Shipping.exe.

    <game root>/
      FarFarWest/Binaries/Win64/
        FarFarWest-Win64-Shipping.exe
        dwmapi.dll
        ue4ss/
          UE4SS.dll
          UE4SS-settings.ini
          UE4SS_Signatures/
          Mods/

The framework ZIP starts with dwmapi.dll and ue4ss; extract these into **Win64**. The Trainer ZIP starts with **GameRoot**; copy everything *inside GameRoot* into the **game root**. Do not create an extra GameRoot folder or another FarFarWest folder inside Win64.

## First installation

1. Fully exit the game and make the backups above. Extract downloads into separate temporary folders first.

2. Install the complete Nexus player framework into the executable folder. Keep its settings, mod list and all included signatures together. Do not overlay generic framework files or old custom signatures.

3. Start the game to confirm this complete framework reaches the title screen, then fully exit. Check a newly updated ue4ss/UE4SS.log if it fails. Do not install only the DLL without the package's signatures.

4. Copy the Trainer runtime's GameRoot contents into the game root. This package installs FFWTrainer under Mods and preserves the framework, settings, mod list and signatures.

5. Check the following path, then start the game and enter the saloon:

    <game root>/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/
      enabled.txt
      Scripts/main.lua
      Scripts/Progress.lua
      Scripts/TrainerUI.lua
      Data/

Data may initially be empty. Keep all Scripts files. Confirm enabled.txt is not accidentally named enabled.txt.txt with hidden Windows extensions.

## Migrating an old framework safely

Exit the game. Back up the entire old ue4ss folder and the existing dwmapi.dll **outside the game directory**, including each mod's Data. Move/rename the old framework into that backup before installing the complete Nexus package fresh. Do not follow a blanket deletion instruction that would discard mod data.

Install current compatible content mods into the fresh framework and restore each mod's Data to its matching folder. Do not restore an old UE4SS.dll, UE4SS-settings.ini, Mods/mods.txt or signature directory over the Nexus package; old forced engine-version settings can defeat the new profile. Keep unrelated proxy files intact unless you have identified what owns them. Game saves are separate and must not be deleted for this migration.

## Updating only the Trainer

With the game closed, back up Mods/FFWTrainer outside Mods. Replace its Scripts with the new runtime files and retain Data/settings.json and the enabled marker. Do not reinstall the framework if it is already working. Completely restart the game: returning to the title screen does not reload Lua, and the Nexus profile disables automatic/hot reload by default.

## Open, apply and verify a saved value

- F2: normal trainer; F4: bilingual Joker search.
- F1 or Apply: apply the selected permanent progress target.
- F3: use the selected Joker mode while the Joker page is open in a mission.
- F5/F6: previous/next item. Mouse: category, row and page selection, text entry and scrolling.
- Settings: choose ground pickup or direct acquisition; F3 uses that choice. The total-point budget option still uses the game's original equipment menu.
- F7/F8 hide the trainer when switching to those other optional panels. The framework also binds console keys; their existence is not proof that a Trainer action succeeded.

For resources/levels:

1. Return to the saloon and wait for the local character and save to load. The trainer edits your local persistent progress, not teammates' records.

2. Select the exact entry. The displayed value must be available and Apply enabled.

3. On the first check after installation or a framework change, enter the displayed **current value unchanged** and click Apply/F1 once. An unchanged result checks the input/readiness/read-back path without changing that value or requesting a save. If it fails, use the diagnostic below before making an actual change.

4. After this check passes, click the target input, select its contents, enter the desired **total** as digits (for example 26, not +1, 1,000 or 1e3). Click Apply or press F1 once.

5. Read the result. “Verified …; the game save was requested” confirms runtime/native read-back and the save-object check; it does not by itself prove the disk write completed. An unchanged value makes no save request.

6. Let the game finish its normal save, then return to the title and re-enter the saloon or fully restart to check persistence. Do not repeatedly apply while a failure is unresolved.

Resources accept 0–9,999,999; character/weapon/magic-school levels accept 1–100. Ground/direct Jokers are mission effects, not the same operation as permanently changing a level.

## If the game crashes on startup

1. Fully exit the game and disable only FFWTrainer using the disable instructions below. Retest once. If it now starts, keep Trainer disabled and report the Trainer version and relevant new log lines. A successful framework-only launch does not prove that every Trainer operation works.

2. If it still crashes, follow the migration steps above to back up and move the old framework outside the game folder, then install the complete Nexus player package without restoring content mods or old global settings. Check whether this framework-only setup reaches the title screen. Do not repeatedly overwrite individual DLLs or signatures from different packages.

3. If the clean framework-only setup also crashes, check the framework page for the installed game version and report the exact framework file/version plus the new log to its author. If it starts, fully exit and add content mods back one at a time to identify which addition changes the result.

The log is `<game root>/FarFarWest/Binaries/Win64/ue4ss/UE4SS.log`; check its modified time matches the failed launch. If no new log appears, first recheck the Win64 location and the complete framework files. Do not delete game saves as a startup-crash remedy.

## If F2 opens but Apply does not work

Opening a panel alone does not validate writes. Check the visible reason and the latest local UE4SS.log:

- not_saloon: return to the saloon.
- player_not_ready / not_local_player: wait for the local character; do not attempt to edit a remote player's progress.
- save_object_unavailable / save_slot_unavailable / save_version_unavailable / runtime_version_mismatch / save_version_mismatch: the local save is not ready or its format is inconsistent. Do not bypass the check.
- input_unavailable / input_not_synced: the target text was not safely read. Nothing was submitted; reopen the panel and re-enter it.
- nativeRead / levelRead failure: the native inventory/XP interface failed before writing.
- verification_failed / save_call_failed / save_object_not_updated: the message states whether a value changed or a save was requested. Stop repeating the action and provide the diagnostic.
Logs identify the entry, stage and reason, without logging the entered target or save-slot identifier. Repeated identical input failures are deduplicated.

For support, provide Trainer version, exact Nexus framework file/version, game version, saloon/mission state, local host/client role and the displayed reason. Redact personal paths/account identifiers from relevant logs. Do not upload saves, Data folders or credentials.

## Disable, uninstall or roll back

Exit the game. Move FFWTrainer/enabled.txt out of its folder; if Mods/mods.txt also enables FFWTrainer, set that entry to 0. To uninstall, move only Mods/FFWTrainer into your backup. Preserve Data and leave the Nexus framework/signatures for other mods. To roll back, restore the previous Trainer files and matching Data backup, then restart. Removing the trainer does not reverse progress already saved by the game.

## Compatibility and paths

This guide uses the Nexus mod-2 player package, version 3.0.1.1183 Frostburn (file 242). After a game update, check that framework page for compatibility instructions before replacing files. If the log identifies a Lua loading error caused by a non-ASCII installation path, use Steam's storage UI to move the game to a library path containing only ASCII characters. A system-locale change is not required by this guide.
