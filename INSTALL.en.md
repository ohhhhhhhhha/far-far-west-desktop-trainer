# Installation, update and removal

Requires Windows x64, Far Far West and a working UE4SS installation. Baseline: game 0.3.0.7 / UE4SS 1181. Framework binaries are not included.

## Install

Close the game. Extract the release ZIP, then copy everything inside GameRoot into the game root opened by Steam → Manage → Browse local files. Merge folders; do not copy the GameRoot folder itself. The entry point becomes FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/Scripts/main.lua. The included enabled.txt activates this independent mod. Start the game and press F2, or F4 for Joker search. No installer, shell commands or desktop app are required.

## Update from the desktop version

1. Close the game and the old desktop trainer.
2. Copy the old FFWTrainer mod folder outside Mods as a backup.
3. Replace only its Scripts folder with the new package; keep Data, including settings.json.
4. Move the old game-root FFWTrainer/FFWTrainer.exe to a backup folder or remove it. The new version ignores desktop command files.
5. Copy the remaining GameRoot files, restart the game and use F2/F4.

The package does not include personal settings, saves or statistics. An empty Data directory does not replace existing files when merging folders.

## Disable, remove or restore

Close the game and remove the component’s enabled.txt. If mods.txt also contains FFWTrainer, set that entry to 0. The enabled.txt marker otherwise overrides that flag. Remove only the mod’s Scripts folder to uninstall; keep Data if you want its settings. Restore the backed-up files and activation marker to revert. Removing the mod does not reverse progression already saved by the game.

[UE4SS layout](https://docs.ue4ss.com/guides/creating-a-lua-mod.html) · [Activation rules](https://docs.ue4ss.com/guides/installing-a-c%2B%2B-mod.html)

## Verified UE4SS download

Use [UE4SS v3.0.1-1181-g83330635](https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental/UE4SS_v3.0.1-1181-g83330635.zip) from the [official experimental archive](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental). The log may identify it as v3.0.1 Beta #0; also check Git SHA 83330635. The experimental latest build changes over time, so this link pins the version tested with this mod.

Close the game and place the framework ZIP's dwmapi.dll and ue4ss folder in FarFarWest/Binaries/Win64, then install the trainer as described above. Use normal file extraction/copying. Preserve existing mods and configuration.

For a startup crash, verify the framework version and location, then temporarily disable FFWTrainer as described above and test whether the title screen loads. If a required Lua API is missing, this candidate disables the trainer and names the missing API and verified build in UE4SS.log. It cannot intercept a native loader crash before Lua starts.
