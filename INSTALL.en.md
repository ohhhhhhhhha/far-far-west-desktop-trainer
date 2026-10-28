# Installation and troubleshooting — 0.4.0-beta.4

## Downloads and compatibility

Windows x64; tested baseline Far Far West 0.3.0.7 and [UE4SS v3.0.1-1181-g83330635](https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental/UE4SS_v3.0.1-1181-g83330635.zip). The framework is separate. Download **FFWTrainer-0.4.0-beta.4-installation-update.zip** from the [release page](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.4.0-beta.4); the source ZIP is not the install package. Exit the game completely before installing. Use normal Windows extraction and copying.

## 1. Locate the game

In Steam, right-click Far Far West → Manage → Browse local files. This opens the **game root**. From there open FarFarWest → Binaries → Win64: this **executable folder** contains FarFarWest-Win64-Shipping.exe. These are two different destinations.

## 2. Install and verify UE4SS

If the tested build is already working, keep it and proceed to step 3. Otherwise extract the official UE4SS ZIP into a separate temporary folder. Copy its **dwmapi.dll** and **ue4ss** folder directly into the executable folder. Verify:

    <game root>/FarFarWest/Binaries/Win64/
      FarFarWest-Win64-Shipping.exe
      dwmapi.dll
      ue4ss/UE4SS.dll
      ue4ss/UE4SS-settings.ini
      ue4ss/Mods/shared/UEHelpers/UEHelpers.lua

The UE4SS ZIP includes default settings and a mod list. If an existing UE4SS or another proxy DLL is present, first back up the existing files and configuration outside the game directory. Do not blindly overwrite other mods, settings, mod lists or their proxy DLLs. The steps above describe a fresh install. Preserve other mods and use one compatible UE4SS installation; do not mix builds.

For a fresh install, start the game once **before adding FFWTrainer**, then exit. Check that ue4ss/UE4SS.log was newly created or updated. The tested build may identify itself as v3.0.1 Beta #0; also check Git SHA 83330635. If the game already crashes or there is no fresh log, resolve the UE4SS setup before adding the trainer. Game updates and other mods can affect compatibility.

## 3. Install the trainer

Extract the trainer runtime ZIP separately. Open its **GameRoot** folder and copy everything *inside it* into the game root opened through Steam. Merge folders. Do not copy the GameRoot folder itself or put its FarFarWest folder inside Win64. Verify:

    <game root>/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/
      enabled.txt
      Scripts/main.lua
      Scripts/Spawner.lua
      Scripts/TrainerUI.lua
      Data/  (may be empty)

The included enabled.txt enables the mod. If Windows hides file extensions, check it is actually enabled.txt, not enabled.txt.txt. Keep all included Scripts together. The separate card-info and combat-statistics mods are not required.

## 4. Verify and troubleshoot

Start the game and enter the saloon. F2 opens the trainer; F4 opens Joker search. F3 works on its Joker page during a mission. Choose ground or direct mode in Settings; leave at least two seconds between requests.

If F2/F4 do nothing, check the UE4SS.log timestamp, paths above, enabled marker and log for “Starting Lua mod 'FFWTrainer'” and “[FFWTrainer]”. A “disabled: Missing …” line identifies a missing API and the tested build. If a fresh log has no trainer entry, check installation and activation; share a redacted log if unresolved.

Before updating, back up FFWTrainer outside Mods. Merge the new runtime package into the game root and preserve Data/settings.json and other mods. The package contains no personal settings or saves.

If startup crashes after adding the trainer, exit, temporarily move its enabled.txt out of the mod folder and, if FFWTrainer also appears in Mods/mods.txt, set that entry to 0. Restart to compare; restore the marker to re-enable. This does not delete your save. If it also crashes with the trainer disabled, investigate UE4SS, the game and other mods separately. Otherwise report game version, exact UE4SS build, trainer version and last steps. Remove personal paths and account identifiers from logs; do not upload saves or credentials.

[UE4SS official installation guide](https://docs.ue4ss.com/installation-guide) · [Lua mod layout](https://docs.ue4ss.com/guides/creating-a-lua-mod.html)
