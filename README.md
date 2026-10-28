# Far Far West — In-game Trainer

[简体中文](README.zh-CN.md) · [Download](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.4.0-beta.4) · [Report an issue](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues)

**FFWTrainer · 0.4.0-beta.4 · UE4SS · Windows x64**

Press **F2** to open the trainer inside the game. The panel uses the game font, a dark background and brass accents, with mouse selection, paging, input and scrollable details. Display language follows the game; search accepts Chinese and English in either language.

- Gold, souls, blueprints, Haunted candles and Halloween feathers/pumpkins/skulls: 0–9,999,999.
- Character, 14 weapon and six magic-school levels: 1–100.
- Search 153 collectible Jokers and either drop a pickup or gain the selected card directly during a mission.
- Remove the total upgrade-point budget, then allocate in the original equipment menu. Per-stat limits, gold costs and native confirmation/save remain unchanged.

## Installation

Requires the verified [UE4SS v3.0.1-1181-g83330635 package](https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental/UE4SS_v3.0.1-1181-g83330635.zip). Baseline: Far Far West 0.3.0.7 / UE4SS build 1181.

1. Close the game and download [FFWTrainer-0.4.0-beta.4.zip](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/download/v0.4.0-beta.4/FFWTrainer-0.4.0-beta.4.zip).
2. Extract the ZIP outside the game folder.
3. Copy the contents of GameRoot into the game directory opened through Steam → Manage → Browse local files.
4. Start the game and press F2.

The runtime package contains the Lua mod, without a desktop executable or .NET requirement. Installation needs no terminal or scripts. See [update and removal instructions](INSTALL.en.md) when replacing the old desktop release.

## Controls

| Control | Action |
| --- | --- |
| F2 | Open / close the normal trainer; return from F4 to the last trainer category |
| F4 | Open / close Joker search |
| F1 or Apply | Apply the selected progression value |
| F3 or Spawn one | Use the selected Joker mode while its page is open |
| F5 / F6 | Select the previous / next entry |
| Mouse | Select categories/entries, turn pages, enter values and scroll details |

Edit permanent progression in the saloon. Magic levels represent Acid, Elec, Pyro, Voodoo, Cactus and Frost school XP. Card spawning is available during missions, with at least two seconds between requests. Close the panel to collect the card. Browsing, search and refresh never edit progression.

Halloween resources appear under Resources. Enter the desired total and Apply in the saloon. Stock edits do not alter materials already deposited in the cauldron. Event cleanup/conversion still follows the game rules.

The Settings page controls the total-point budget switch. It persists in the mod’s Data/settings.json and stays enabled when the panel closes. Disabling restores budget checks without removing saved allocations. Opening F7/F8 hides the trainer so another overlay can take mouse input.

## Source and verification

Lua source is under FFWTools/src/FFWTrainer/Scripts, including the dependencies needed to run independently. This repository does not include the separate card-information mod or combat statistics. See [development notes](DEVELOPMENT.md) and [changes](CHANGELOG.md).

Existing progression saving, magic-school levels and native-menu budget unlocking were previously user-confirmed. The previous build passed all 31 offline Lua test files. On 2026-10-28, the user confirmed F2/F4 mouse navigation, paging, a short F3 input burst producing one pickup, pickup interaction, and trainer use after returning to the saloon.

## 0.4.0-beta.4 candidate

In Settings, choose **Drop on ground** (default) or **Gain directly**. The choice is saved. F3 and the existing Joker action button use that mode; no additional key is assigned. Direct mode follows the native acquisition event, including normal card effects and conditional triggers.

The candidate selects the local player for its panel and previews, recovers mouse input when the native menu arrives late or resets it, and stops spawning while 10 uncollected dropped Jokers are within 20 metres. Pick up cards to free space.

At most one spawn request waits for the game thread. Changing the selected card cancels that pending request. Failed native requests still reserve the two-second cooldown, and clicks from a previous local controller are ignored after travel.

The user confirmed the initial beta.4 startup, mouse navigation and both Joker modes. The subsequent input-handoff fixes have offline regression coverage. The reported startup and spawning crashes have not been independently reproduced. If it persists, report the exact button, last spawned card and game/UE4SS versions, along with a log with personal details removed. Fully exit and restart the game after updating.

## Support and license

In [Issues](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues), include the mod/game/UE4SS versions and reproduction steps. Omit saves, account identifiers and personal paths. Maintained by FFWTools contributors. Original code/documentation use the [MIT license](LICENSE); [game-derived text and dependency notices](THIRD-PARTY-NOTICES.md) retain their respective rights.
