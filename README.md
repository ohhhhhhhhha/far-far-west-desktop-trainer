# Far Far West — In-game Trainer (0.4.0-beta.6)

[简体中文](README.zh-CN.md) · [Download beta.6](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.4.0-beta.6) · [Full installation guide](INSTALL.en.md)

Use the [Far Far West Nexus player framework (mod 2)](https://www.nexusmods.com/farfarwest/mods/2?tab=files). Install the UE4SS-FarFarWest 3.0.1.1183 Frostburn player Main File, file 242. Its game signatures and settings are part of that framework; this content package does not overwrite them. [UE4SS upstream](https://github.com/UE4SS-RE/RE-UE4SS) is credited as the source project.

F2 opens the trainer. F4 opens Chinese/English Joker search. Edit local permanent progress in the saloon: select an entry, enter the target total as digits and press Apply/F1 once. Read the result and verify persistence after the game's normal save and a reload. See the full guide for exact folders, first installation, migration, enable/disable, keys and rollback.

Before installation or progress edits, fully exit the game and privately back up `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames` through File Explorer. Keep a separate backup of the mod's Data folder. The full guide includes a same-value Apply check and separate steps for startup crashes and unavailable writes.

Features: gold/souls/blueprints/Halloween resources; character, weapon and magic-school levels; native-menu total-point budget unlocking; ground or direct Joker mode in Settings, activated by F3 in missions.

If the target input cannot be read, Apply is cancelled and the panel shows the reason. Apply errors identify the failed stage so you can follow the troubleshooting steps in the installation guide. Permanent progress changes require your local character and save to be ready in the saloon.

Original code/documentation use [MIT](LICENSE); game material and dependencies retain their respective rights. See [third-party notices](THIRD-PARTY-NOTICES.md).

43/43 offline Lua test files passed. On the local Nexus 1183 setup, the user confirmed same-value Apply and gold +1 persisted after a title-screen return and saloon reload. This check does not certify every level field, computer or multiplayer role.
