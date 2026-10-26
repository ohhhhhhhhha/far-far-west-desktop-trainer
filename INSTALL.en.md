# Install, update and remove — Desktop Trainer

Requires Windows x64 and a working UE4SS installation for Far Far West. Tested baseline: game 0.3.0.7 / UE4SS build 1181. The GUI requires .NET Framework 4.x. UE4SS is not bundled.

## Install

1. Exit the game. In Steam, choose Manage → Browse local files.
2. Extract the runtime ZIP outside that directory.
3. Copy the contents of GameRoot into the game directory, merging folders.
4. Double-click FFWTrainer/FFWTrainer.exe in the game folder.

The Lua entry must be at FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/Scripts/main.lua. The included FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/enabled.txt enables this component. The GUI goes at FFWTrainer/FFWTrainer.exe, and the package creates an empty Data directory inside the mod. No command, installation script or replacement mods.txt is needed.

For a custom UE4SS working directory, copy the FFWTrainer mod folder to its actual Mods directory. The desktop GUI expects the standard ue4ss directory layout above.

## Update

Close the game and GUI. Back up the old FFWTrainer folder outside Mods. Remove only its Scripts subfolder, then copy the new GameRoot contents. Preserve Data and other custom files. This clears removed scripts from earlier versions without replacing other mods or global settings.

## Disable or remove

Move enabled.txt out of the FFWTrainer folder. If mods.txt already contains a FFWTrainer entry, change that entry to 0 as well: enabled.txt bypasses mods.txt. To remove the component, remove its Scripts subfolder after disabling it. The GUI file may also be removed. Keep Data if you want to retain the budget setting; uninstalling does not undo progression saved by the game.

## References

- [UE4SS installation](https://docs.ue4ss.com/dev/installation-guide.html)
- [Lua mod entry layout](https://docs.ue4ss.com/guides/creating-a-lua-mod.html)
- [Activation marker and load ordering](https://docs.ue4ss.com/guides/installing-a-c%2B%2B-mod.html)
