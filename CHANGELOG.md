# Changelog / 更新记录

## 0.4.0-beta.6 — 2026-10-29

- Reject unreadable or stale target input instead of applying a previous value.
- Report readiness, native-read, verification and save phases with clear reason codes and deduplicated local diagnostics.
- Recommend Nexus mod 2/file 242; content archives preserve its DLL, configuration, mod list and three signatures.
- Use the actual Nexus Helper/config profile in simulated host/client apply/save regressions. 43/43 offline test files passed. The user confirmed same-value Apply and a gold +1 change persisted after returning to the title and re-entering the saloon on the local Nexus 1183 setup.

输入读取失败不再提交旧值；补齐从就绪到保存的原因提示。优先使用Nexus游戏专用框架，内容包不覆盖框架文件。43/43份离线测试通过；本机Nexus1183环境已由用户确认同值应用及金币+1回标题重进后保留。本次验收不涵盖全部等级字段、联机身份或所有电脑。

## 0.4.0-beta.5 — 2026-10-29

- Return before reading a delayed native callback context when all view routes have been released.

- Load host/font assets before the first native widget factory call, and validate the widget library CDO.
- Use SetTextOverflowPolicy(Ellipsis) for button captions.

- Recover from stale UMG cleanup methods and release Lua click routes.
- Discard old views across world/controller loss and skip stale edit-box reads.
- Cancel queued toggles/navigation after stop; avoid closed-panel language polling.
- Scope upgrade menu caches to the current local saloon world.
- Include the coordinated game startup signature and license; install it before first launch.
- Preserve both Joker modes, pickup pile guard and all currencies. B07/B08 native access violations are not claimed fixed.

## 0.4.0-beta.4 — 2026-10-28

- Recheck input ownership on the game thread so queued clicks cannot act after travel or another overlay takes input.
- On close, preserve the current native menu after pawn replacement and restore the old menu separately.
- Cache button caption alignment after its initial setup.

- Add saved Settings choices for ground pickups or direct native card acquisition. F3 uses the selected mode; no new key binding.

- Use the verified local controller for both the panel and card previews.
- Recover an active panel after a late native menu or a native cursor reset without resetting normal typing focus.
- Pause spawning while 10 uncollected dropped Jokers are within 20 metres; only explicit spawn attempts scan pickups.
- Stop loading the trainer with an actionable message when required UE4SS Lua APIs are missing. Pin the tested UE4SS 1181 archive link.
- Offline regression coverage added. Native startup/spawn crashes remain unconfirmed; live acceptance is pending.


## 0.4.0-beta.3 — 2026-10-28

- Keep at most one pending spawn request during game-thread stalls; cancel it if the selected card changes.
- Keep the two-second cooldown after failed native spawn calls.
- Reject previous-controller button clicks after travel.
- All 31 offline Lua test files passed. User confirmed F2/F4 mouse navigation/paging, a short F3 burst producing one pickup, pickup interaction, and use after returning to the saloon.
- The original reporter's native crash has not been independently reproduced.

合并积压刷卡请求，保留失败调用冷却，拒绝切图后的旧按钮事件。31 份离线测试通过；用户已确认面板操作、少量刷卡拾取及回酒馆后的操作均正常。原评论者的原生崩溃尚未独立复现。

## 0.4.0-beta.2

- Add Haunted candles and Halloween feathers, pumpkins and skulls to Resources. Preserve deposited cauldron ingredients.
- Fix F2 reopening the last F4 Joker page. F2 returns to the last normal trainer category.
- Establish UI input when opening with an already-visible cursor, and restore game input when no native menu was open. The reporter's exact mouse issue is not yet reproduced.
- Currency keys verified from live game data; no user save was edited during development. New currency save/reload acceptance remains pending.

新增万圣节活动代币与三种材料；修复 F2 串页，补齐鼠标输入模式与关闭恢复。保留坩埚已投入材料。字段已从游戏内读取确认，实际新增代币保存仍待验证。

# 0.4.0-beta.1

- Restored in-game F2 trainer and F4 Joker search, with F1 apply and F3 spawn.
- Added game-font/brass styling, mouse categories, paging, persistent text input and scrolling.
- Removed the desktop GUI and its build/source files from this version. Existing save and budget logic is unchanged.
- Added bilingual search, input-preservation, visibility/action-boundary and 720p layout regression checks. Native UI acceptance remains pending.

恢复游戏内修改器与刷卡面板，增加游戏风格界面和完整鼠标操作；新版移除桌面 GUI。原保存与总点数解限逻辑不变，离线回归通过，新面板实机验收待完成。

# Changes / 更新记录

## 0.3.0-beta.3

- Publish FFWTrainer in its own repository, with independent source and runtime downloads.
- Copy-install packaging, bilingual README and installation/removal instructions; no player command-line steps.
- Include enabled.txt and document its precedence over mods.txt.
- Runtime payload matches the accepted 0.3.0-beta.2 build.

独立仓库、独立源码与运行包；完善双语说明，采用复制安装；运行内容保持已确认版本不变。

## 0.3.0-beta.2

- Accepted desktop progression/magic persistence, native-menu total-budget unlock and bilingual card search/spawning.
