# Changelog / 更新记录

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
