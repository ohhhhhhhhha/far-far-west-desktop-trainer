# Far Far West — Desktop Trainer

[简体中文](README.zh-CN.md) · [Download](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.3.0-beta.3) · [Report an issue](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues)

**FFWTrainer · 0.3.0-beta.3 · UE4SS · Windows x64**

- Gold, souls and blueprints: 0–9,999,999.
- Character, 14 weapon and six magic-school levels: 1–100.
- Search 153 collectible Jokers by Chinese or English name and spawn a selected pickup during a mission.
- Remove the total upgrade-point budget while allocating points in the game’s original menu. Per-stat limits, gold costs, confirmation and native saving remain in place.
- A separate Windows GUI; no F1–F6 trainer hotkeys, WeMod or background service.

Change permanent progression in the saloon. The magic entries represent Acid, Elec, Pyro, Voodoo, Cactus and Frost school XP, not individual spell unlocks. Browsing and searching do not edit progression. The budget switch persists in the mod’s Data/settings.json; turning it off restores budget checks but does not undo saved allocations.

## Install

Tested with Far Far West 0.3.0.7 and UE4SS build 1181. Install a compatible [UE4SS build](https://github.com/UE4SS-RE/RE-UE4SS) separately. The desktop GUI also needs .NET Framework 4.x.

1. Close the game and download [FFWTrainer-0.3.0-beta.3.zip](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/download/v0.3.0-beta.3/FFWTrainer-0.3.0-beta.3.zip).
2. Extract the ZIP outside the game folder.
3. Copy the contents of GameRoot into the game folder opened through Steam → Manage → Browse local files.
4. Double-click FFWTrainer/FFWTrainer.exe in the game folder.

No terminal or installation script is required. Read [installation, update and removal instructions](INSTALL.en.md) before updating an older version.

## Controls

Select a value, enter a new number and click Apply. Use the Cards tab to search/spawn and Settings to change the total-budget switch.

## Source and verification

This repository contains only Desktop Trainer and its required dependencies. The other tool and combat-statistics/synchronization mods are not included. Shared calculation and language files are copied into this repository, so it can be used independently.

Lua source is under FFWTools/src/FFWTrainer/Scripts. GUI source is under FFWTools/src/FFWTrainerGui. See [development notes](DEVELOPMENT.md) and [changes](CHANGELOG.md). The v0.3.0-beta.3 split preserves the accepted runtime payload. Offline checks do not mean every possible combination was tested in-game.

## Support and license

Maintained by FFWTools contributors. In [GitHub Issues](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues), provide the tool version, game/UE4SS versions, reproduction steps and relevant error text. Omit saves, account identifiers and personal paths.

Original code and documentation use the [MIT license](LICENSE). Game-derived text and data retain their original rights; see [third-party notices](THIRD-PARTY-NOTICES.md).
