# Far Far West — UE4SS compatibility and beta.5 installation

Use the complete [Nexus UE4SS for FarFarWest player package (mod 2)](https://www.nexusmods.com/farfarwest/mods/2?tab=files): **UE4SS-FarFarWest 3.0.1.1183 Frostburn, file 242**, by anro / AnroG772. The package supplies the game-specific configuration and signatures. Install its dwmapi.dll and ue4ss folder beside FarFarWest-Win64-Shipping.exe under `<Steam game root>/FarFarWest/Binaries/Win64`.

## Existing beta.5 attachment

The frozen Trainer beta.5 archive contains a historical ProcessLocalScriptFunction.lua override and older instructions. **Do not install that override over the Nexus package.** Copy only `GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer` from the archive into `<Steam game root>/FarFarWest/Binaries/Win64/ue4ss/Mods/`.

Keep all Nexus signatures, UE4SS-settings.ini, Mods/mods.txt and framework DLLs unchanged. Preserve each mod's Data and back up game saves at `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames` while the game is closed. The beta.5 attachment bytes remain unchanged; this online guide supersedes its old installation instructions.

See the [full installation, migration and troubleshooting guide](../../../INSTALL.en.md). Test the complete Nexus framework before adding content mods. A framework-only successful startup does not establish that every native mod operation or save is correct; follow the guide's apply/save verification and report exact failures.

## Historical source attribution

The old override retained in this source tree came from [halu103/farfarwest-frostburn-modkit](https://github.com/halu103/farfarwest-frostburn-modkit/blob/main/config/ue4ss/UE4SS_Signatures/ProcessLocalScriptFunction.lua), under MIT. Its license is retained in [licenses/FrostburnModKit.txt](licenses/FrostburnModKit.txt). This attribution is not an instruction to install the old override.

[UE4SS upstream project](https://github.com/UE4SS-RE/RE-UE4SS). Recheck the Nexus framework page after game updates; this guide does not promise compatibility with every game/framework revision.
