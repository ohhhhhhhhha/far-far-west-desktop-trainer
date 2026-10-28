# Far Far West — UE4SS compatibility

The current release is **FFWTrainer 0.4.0-beta.6**. Use the complete [Nexus UE4SS for FarFarWest player package (mod 2)](https://www.nexusmods.com/farfarwest/mods/2?tab=files): **UE4SS-FarFarWest 3.0.1.1183 Frostburn, file 242**, by anro / AnroG772.

Install the framework's dwmapi.dll and ue4ss folder beside FarFarWest-Win64-Shipping.exe under `<Steam game root>/FarFarWest/Binaries/Win64`. Keep its configuration, mod list, DLLs and all signatures together.

The beta.6 runtime ZIP installs only `ue4ss/Mods/FFWTrainer`. It does not include or overwrite framework signatures. Copy the contents of its GameRoot into the Steam game root as described in the [full installation guide](../../../INSTALL.en.md). Preserve mod Data and privately back up `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames` with the game closed.

## Older beta.5 attachment

The archived beta.5 ZIP is unchanged and contains an old ProcessLocalScriptFunction.lua override. If installing that old release on the Nexus framework, copy only its `GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer` folder into `<game root>/FarFarWest/Binaries/Win64/ue4ss/Mods/`. Do not merge its whole GameRoot or copy its UE4SS_Signatures. The old override and license remain available in the beta.5 source history.

## Verified scope

43/43 offline Lua test files passed. On the local Nexus 1183 setup, the user confirmed a same-value Apply check and a gold increase of 1 that remained after returning to the title and re-entering the saloon. This does not certify every level field, multiplayer role or computer.

Recheck the Nexus page after game updates. [UE4SS upstream project](https://github.com/UE4SS-RE/RE-UE4SS).
