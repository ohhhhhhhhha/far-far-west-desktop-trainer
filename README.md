# Far Far West — In-game Trainer

[简体中文](README.zh-CN.md) · [Download beta.5](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.4.0-beta.5) · [Report an issue](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues)

**FFWTrainer · 0.4.0-beta.5 · UE4SS · Windows x64**

Press **F2** to open the trainer inside the game. The panel uses the game font, a dark background and brass accents. It supports mouse selection, paging, text entry and scrollable details. Display language follows the game; search accepts Chinese and English.

- Gold, souls, blueprints, Haunted candles and Halloween feathers/pumpkins/skulls: 0–9,999,999.
- Character, 14 weapon and six magic-school levels: 1–100.
- Search 153 collectible Jokers and choose ground pickup or direct acquisition during a mission.
- Remove the total upgrade-point budget, then allocate points in the original equipment menu. Per-stat limits, gold costs and native confirmation/save still apply.

## Installation

Use [UE4SS for FarFarWest — Nexus mod 2](https://www.nexusmods.com/farfarwest/mods/2?tab=files), player Main File **UE4SS-FarFarWest**, **3.0.1.1183 Frostburn / file 242**. Install the complete player package, including its signatures and settings. Select the player Main File rather than zDEV.

**For the existing beta.5 ZIP, copy only the FFWTrainer subfolder. Do not merge the whole GameRoot folder or copy its UE4SS_Signatures.** This online guide supersedes the older installation text inside the frozen beta.5 attachment.

1. Fully exit the game. Privately back up `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames` and each installed mod's Data folder.
2. Steam → Manage → Browse local files opens the game root. Install the complete Nexus framework into `FarFarWest/Binaries/Win64`, beside `FarFarWest-Win64-Shipping.exe`.
3. Download [FFWTrainer-0.4.0-beta.5.zip](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/download/v0.4.0-beta.5/FFWTrainer-0.4.0-beta.5.zip) and extract it outside the game directory.
4. Open `GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer` in the extracted ZIP. Copy that **FFWTrainer** folder into `<game root>/FarFarWest/Binaries/Win64/ue4ss/Mods/`.
5. Retain existing FFWTrainer/Data. Keep the Nexus DLL, settings, mod list and **all** Nexus signatures unchanged. Fully restart and enter the saloon; press F2.

See the [full bilingual installation, migration and recovery guide](INSTALL.en.md). No terminal, batch file, desktop executable or .NET installation is required.

## Controls and use

| Control | Action |
| --- | --- |
| F2 | Open/close the trainer; return from F4 to the last trainer category |
| F4 | Open/close bilingual Joker search |
| F1 or Apply | Apply the selected progression value |
| F3 or the Joker action button | Use the selected Joker mode while its page is open |
| F5 / F6 | Select the previous/next entry |
| Mouse | Select categories and entries, turn pages, enter values and scroll details |

Edit permanent progression in the saloon after your local character and save have loaded. Enter the desired **total**, apply once, read the result, then let the game save and reload to verify persistence. Opening F2 alone does not confirm that a write succeeded.

In Settings, choose **Drop on ground** or **Gain directly**. Both use F3 in missions; leave at least two seconds between requests. Ground mode pauses when 10 uncollected dropped Jokers are within 20 metres. Collect cards to free space. Browsing and searching do not edit progress.

Halloween stock edits do not change materials already deposited in the cauldron. Event cleanup/conversion follows game rules. Total-point unlocking is saved in Data/settings.json; turning it off restores the budget check without clearing saved allocations. F7/F8 hide the trainer when switching to other optional panels.

## Support and source

For startup crashes or F2 that opens but cannot apply, follow [troubleshooting](INSTALL.en.md). Report the exact on-screen message, Trainer/game/framework versions, saloon or mission, and whether you are host or client. Remove personal paths and account identifiers from relevant logs; do not upload saves, Data folders or credentials. This documentation update does not claim that every reported crash or saving issue is resolved.

This repository contains the trainer and its Lua dependencies. The card-information and combat-statistics mods are separate. See [development notes](DEVELOPMENT.md), [changes](CHANGELOG.md) and [framework compatibility](FFWTools/src/RuntimeCompatibility/README.en.md).

Original code and documentation use [MIT](LICENSE). Game material and dependencies retain their respective rights; see [third-party notices](THIRD-PARTY-NOTICES.md). [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) is the upstream framework project.
