# Far Far West — In-game Trainer

[简体中文](README.zh-CN.md) · [Download](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.4.0-beta.1) · [Report an issue](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues)

**FFWTrainer · 0.4.0-beta.1 · UE4SS · Windows x64**

Press **F2** to open the trainer inside the game. The panel uses the game font, a dark background and brass accents, with mouse selection, paging, input and scrollable details. Display language follows the game; search accepts Chinese and English in either language.

- Gold, souls and blueprints: 0–9,999,999.
- Character, 14 weapon and six magic-school levels: 1–100.
- Search 153 collectible Jokers and spawn a selected pickup during a mission.
- Remove the total upgrade-point budget, then allocate in the original equipment menu. Per-stat limits, gold costs and native confirmation/save remain unchanged.

## Installation

Requires a separate compatible [UE4SS installation](https://github.com/UE4SS-RE/RE-UE4SS/releases). Baseline: Far Far West 0.3.0.7 / UE4SS build 1181.

1. Close the game and download [FFWTrainer-0.4.0-beta.1.zip](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/download/v0.4.0-beta.1/FFWTrainer-0.4.0-beta.1.zip).
2. Extract the ZIP outside the game folder.
3. Copy the contents of GameRoot into the game directory opened through Steam → Manage → Browse local files.
4. Start the game and press F2.

The runtime package contains the Lua mod, without a desktop executable or .NET requirement. Installation needs no terminal or scripts. See [update and removal instructions](INSTALL.en.md) when replacing the old desktop release.

## Controls

| Control | Action |
| --- | --- |
| F2 | Open / close the trainer |
| F4 | Open / close Joker search |
| F1 or Apply | Apply the selected progression value |
| F3 or Spawn one | Spawn the selected Joker while its page is open |
| F5 / F6 | Select the previous / next entry |
| Mouse | Select categories/entries, turn pages, enter values and scroll details |

Edit permanent progression in the saloon. Magic levels represent Acid, Elec, Pyro, Voodoo, Cactus and Frost school XP. Card spawning is available during missions, with at least two seconds between requests. Close the panel to collect the card. Browsing, search and refresh never edit progression.

The Settings page controls the total-point budget switch. It persists in the mod’s Data/settings.json and stays enabled when the panel closes. Disabling restores budget checks without removing saved allocations. Opening F7/F8 hides the trainer so another overlay can take mouse input.

## Source and verification

Lua source is under FFWTools/src/FFWTrainer/Scripts, including the dependencies needed to run independently. This repository does not include the separate card-information mod or combat statistics. See [development notes](DEVELOPMENT.md) and [changes](CHANGELOG.md).

The existing progression, magic-level saving and original-menu budget unlock were user-confirmed. This version passed offline Lua, native-widget boundary and 720p/bilingual layout checks. The new panel still needs live acceptance for game font, IME and input behavior; this is a prerelease.

## Support and license

In [Issues](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues), include the mod/game/UE4SS versions and reproduction steps. Omit saves, account identifiers and personal paths. Maintained by FFWTools contributors. Original code/documentation use the [MIT license](LICENSE); [game-derived text and dependency notices](THIRD-PARTY-NOTICES.md) retain their respective rights.
