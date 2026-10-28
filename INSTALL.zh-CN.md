# 安装与故障排查 — 0.4.0-beta.5

[English](INSTALL.en.md)

## 下载正确的两个包

- **框架：**[Nexus 游戏专用 UE4SS（mod 2）](https://www.nexusmods.com/farfarwest/mods/2?tab=files)，作者 anro / AnroG772。选择玩家主文件 **UE4SS-FarFarWest，3.0.1.1183 Frostburn / 文件 242**，不选 zDEV。说明中的包名为 UE4SS-FarFarWest-v3.0.1-1183-frostburn.zip。
- **修改器：**[FFWTrainer-0.4.0-beta.5.zip](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/download/v0.4.0-beta.5/FFWTrainer-0.4.0-beta.5.zip)。source 源码 ZIP 用于开发，不是安装包。

**beta.5 附件保持原样，其中包含旧安装说明和单独的签名。请以本在线指南为准：仅安装 FFWTrainer 文件夹，完整保留 Nexus 框架的签名与配置，不要合并整个 GameRoot。**

使用 Windows 普通解压和复制即可，不需要终端或批处理。游戏更新后，先核对 Nexus 框架页面的兼容说明。

## 1. 备份并找到两个目录

完全退出游戏，在资源管理器地址栏粘贴 `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames`，把整个 SaveGames 文件夹复制到游戏目录之外，并用日期区分备份；保留原文件夹。尚未生成存档时可暂时跳过。另行备份已安装 Mod 的 Data，Mod 设置与游戏存档不能互相替代。备份仅自己保留。

Steam → Far Far West → 管理 → 浏览本地文件，打开**游戏根目录**。再进入 `FarFarWest/Binaries/Win64`，才是包含 `FarFarWest-Win64-Shipping.exe` 的**游戏程序目录**。

## 2. 安装完整 Nexus 框架

首次安装时，将 Nexus 框架解压到临时目录，把其中的 **dwmapi.dll** 和 **ue4ss** 文件夹复制到游戏程序目录。核对：

    <游戏根目录>/FarFarWest/Binaries/Win64/
      FarFarWest-Win64-Shipping.exe
      dwmapi.dll
      ue4ss/UE4SS.dll
      ue4ss/UE4SS-settings.ini
      ue4ss/UE4SS_Signatures/
      ue4ss/Mods/shared/UEHelpers/UEHelpers.lua

配套的 DLL、设置、Mod 列表及全部签名应一起保留；不要只复制 DLL，也不要混入通用 UE4SS 包中的文件。

从旧框架迁移时，先把整个旧 ue4ss 文件夹及 dwmapi.dll 备份到游戏目录之外，包含每个 Mod 的 Data。将旧框架移入备份后，全新安装完整 Nexus 包，再逐个恢复兼容的内容 Mod 和各自 Data。不要把旧 UE4SS.dll、UE4SS-settings.ini、Mods/mods.txt 或 UE4SS_Signatures 覆盖回新框架。未确认归属的其他代理文件保持原样。

先验证完整 Nexus 框架单独安装可以进入标题画面，再完全退出。失败时先看新生成或更新的 `ue4ss/UE4SS.log`，暂不添加修改器。已经正常工作的这套完整 Nexus 框架无需重装。

## 3. 只复制修改器子文件夹

将修改器 ZIP 解压到游戏目录之外，在解压内容中打开：

    GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/

仅将这个 **FFWTrainer** 文件夹复制到：

    <游戏根目录>/FarFarWest/Binaries/Win64/ue4ss/Mods/

安装后应为：

    <游戏根目录>/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/
      enabled.txt
      Scripts/main.lua
      Scripts/Progress.lua
      Scripts/Spawner.lua
      Scripts/TrainerUI.lua
      Data/  （初始可为空）

**不要复制修改器包中旁边的 UE4SS_Signatures 目录及 ProcessLocalScriptFunction.lua。保留 Nexus 的全部签名、UE4SS-settings.ini、Mods/mods.txt 和框架 DLL。** 不要多套一层 GameRoot 或 FFWTrainer。

Scripts 文件应完整保留，更新时保留原 Data/settings.json。确认启用文件是 enabled.txt，而非 enabled.txt.txt。卡牌说明与战斗统计是独立 Mod，不是修改器的必装依赖。

## 4. 启动与操作

完整重启游戏并进入酒馆。仅回标题不会重载 Mod，Nexus 配置默认关闭自动/热重载。

| 操作 | 功能 |
| --- | --- |
| F2 | 打开/关闭常规修改器 |
| F4 | 打开/关闭中英奇术卡搜索 |
| F1 或“应用” | 应用选中项目的永久进度目标值 |
| F3 或刷卡按钮 | 任务中打开奇术卡页面后，按所选模式获得卡牌 |
| F5 / F6 | 上一项/下一项 |
| 鼠标 | 选择分类与条目、翻页、输入、滚动详情 |

永久资源或等级需要在酒馆、自己的角色及存档加载完成后修改。选中准确项目，确认当前值可读取；输入期望的**总量**，只用数字，例如 26，不填 +1、1,000 或 1e3。应用一次并阅读结果。等游戏正常保存，再回标题重进酒馆或完整重启，核对是否保留。面板能打开或运行中数值已变，不等于存档已经写入磁盘。

资源范围 0–9,999,999；角色、武器和魔法流派等级为 1–100。魔法指酸蚀、电击、火焰、巫毒、仙人掌与冰霜流派。

在“设置”选择**生成到地面**或**直接获得**，任务中 F3 使用所选模式，两次请求至少间隔两秒。拾取地面卡前关闭面板；周围 20 米已有 10 张未拾取掉落卡时，地面刷取会暂停。总点数解限继续使用游戏原装备菜单加点。

## 5. 故障排查

### 启动即崩溃

1. 退出游戏，按下方步骤只禁用 FFWTrainer，再启动一次。
2. 若恢复正常，先保持修改器禁用，反馈其版本及本次日志中的相关错误。
3. 若仍崩溃，按上面的备份/迁移流程，测试全新完整 Nexus 框架，暂不恢复内容 Mod 或旧全局设置。
4. 若仅装这套框架仍崩溃，核对框架页面支持的游戏版本，向框架作者提供准确文件/版本及本次日志。若能启动，每次完全退出后逐个恢复兼容内容 Mod。

不要通过删除存档处理启动崩溃，也不要反复混搭不同包的 DLL 和签名。

### F2/F4 没反应，或鼠标无法使用

核对安装目录、启用标记，以及以下日志的修改时间：

    <游戏根目录>/FarFarWest/Binaries/Win64/ue4ss/UE4SS.log

检查是否有新的 FFWTrainer 启动记录。框架有日志而修改器没有时，先检查目录和启用状态。更新后完全重启，确保仅保留一份 FFWTrainer，且 Scripts 文件完整。鼠标仍失效时，说明是光标无法移动，还是可见按钮无法点击，以及当时还打开了哪些菜单/覆盖层。F5/F6 可用于切换条目。

### F2 能打开，但数值不能修改或重进后恢复

返回酒馆，等自己的角色和存档加载完成，确认选中项目当前值可读取、“应用”可用。重新输入目标总量，并记录**准确界面提示**。不要根据面板能够打开就判断保存可用。应用失败或重进后恢复时，停止重复请求，提供提示及相关日志。

beta.5 不包含后续诊断改动。若旧错误提示仍写了较早框架构建，请连同实际安装的 Nexus 文件版本一起反馈，不要仅因旧提示提到其他构建就替换 Nexus 配置。

反馈包含修改器/游戏/框架版本、酒馆或任务位置、房主/客机身份、具体操作和结果。日志先去掉个人路径和账号标识，不要上传存档、Data 或凭据。本次安装说明修正不代表所有崩溃或保存故障均已解决。

## 更新、禁用与卸载

关闭游戏，将 Mods/FFWTrainer 备份到 Mods 之外。更新 beta.5 时，仅从解压后的 FFWTrainer 文件夹替换本组件 Scripts，保留 Data/settings.json 和 enabled.txt。不要合并 GameRoot，也不必重装已正常工作的 Nexus 框架。

禁用时移走 FFWTrainer/enabled.txt；若 Mods/mods.txt 也启用了 FFWTrainer，仅将其条目改为 0。恢复标记/条目即可重新启用。卸载时只把 Mods/FFWTrainer 移入备份，保留 Data 和共用的 Nexus 框架/签名。回滚时恢复上一版 Trainer 文件及对应 Data 备份。卸载不会撤销已由游戏保存的进度修改。

## 兼容性与路径

参见[框架兼容指南](FFWTools/src/RuntimeCompatibility/README.zh-CN.md)。若日志明确指出非 ASCII 安装路径导致 Lua 加载失败，可通过 Steam 存储管理迁移到仅含 ASCII 字符的库目录。本指南不要求修改 Windows 系统区域设置。
