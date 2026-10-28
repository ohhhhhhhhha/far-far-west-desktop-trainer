# 修改器安装、应用与回滚指南 — 0.4.0-beta.6

## 下载正确的两个包

1. **框架：**优先使用 [Nexus 游戏专用 UE4SS（mod 2）](https://www.nexusmods.com/farfarwest/mods/2?tab=files)，作者 anro / AnroG772。选择玩家主文件 **UE4SS-FarFarWest**，当前核对版本为 **3.0.1.1183 / Frostburn**、文件 242，说明中的包名为 UE4SS-FarFarWest-v3.0.1-1183-frostburn.zip。不要选 zDEV 开发包；游戏更新后应重新核对页面说明。

2. **内容 Mod：**从修改器发布文件下载 **FFWTrainer-0.4.0-beta.6.zip**。source 源码 ZIP 用于开发，不是安装包。

请完整安装 Nexus 玩家包及其配套的游戏签名与配置。[UE4SS GitHub 项目](https://github.com/UE4SS-RE/RE-UE4SS)是框架的上游源码项目。

## 安装或修改进度前，备份游戏存档

1. 完全退出游戏，在资源管理器地址栏粘贴 `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames`，按回车打开。这是文件夹地址，不需要运行命令。

2. 将整个 **SaveGames** 文件夹复制到游戏安装目录之外，并用日期区分备份；保留原文件夹。尚未生成存档时可以暂时跳过，不要自行新建或下载别人的存档。

3. 已安装修改器时，另行备份 `ue4ss/Mods/FFWTrainer/Data`。Mod 设置与游戏存档是两份不同数据，不能互相替代；备份仅自己保留。

## 区分两个目录

Steam → Far Far West → 管理 → 浏览本地文件，打开**游戏根目录**。再进入 FarFarWest/Binaries/Win64，才是包含 FarFarWest-Win64-Shipping.exe 的**游戏程序目录**。

    <游戏根目录>/
      FarFarWest/Binaries/Win64/
        FarFarWest-Win64-Shipping.exe
        dwmapi.dll
        ue4ss/
          UE4SS.dll
          UE4SS-settings.ini
          UE4SS_Signatures/
          Mods/

框架 ZIP 根部直接是 dwmapi.dll 和 ue4ss，应解压到 **Win64**。修改器 ZIP 的 **GameRoot 内部内容**则复制到**游戏根目录**。不要多套一层 GameRoot，也不要在 Win64 内再套 FarFarWest。

## 首次安装

1. 完全退出游戏并按上文备份，把两个下载包分别解压到临时目录。

2. 将完整 Nexus 玩家框架放进游戏程序目录，保留它配套的设置、Mod 列表和全部签名；不要再用通用框架文件或旧签名覆盖。

3. 先确认这套完整框架可以进入标题画面，再完全退出。失败时检查新生成或更新的 ue4ss/UE4SS.log；不要只装 DLL 而遗漏框架签名。

4. 将修改器运行包的 GameRoot 内容合并到游戏根目录。本包安装 Mods/FFWTrainer，并保留现有框架、配置、Mod 列表和签名。

5. 核对下列位置，然后启动并进入酒馆：

    <游戏根目录>/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/
      enabled.txt
      Scripts/main.lua
      Scripts/Progress.lua
      Scripts/TrainerUI.lua
      Data/

Data 初始可为空，Scripts 文件应完整保留。Windows 隐藏扩展名时，确认启用文件不是 enabled.txt.txt。

## 从旧框架迁移：先备份，不删玩家数据

退出游戏，把整个旧 ue4ss 文件夹与原 dwmapi.dll 备份到**游戏目录之外**，包括每个 Mod 的 Data。将旧框架移动或重命名到备份后，再全新安装完整 Nexus 包；不要直接删除整个 ue4ss 而丢失 Mod 数据。

逐个安装兼容的内容 Mod，再把各自 Data 恢复到对应文件夹。不要将旧 UE4SS.dll、UE4SS-settings.ini、Mods/mods.txt 或签名目录整体覆盖回 Nexus 安装；旧的强制引擎版本配置可能破坏新配置。未确认归属的其他代理文件保持原样。游戏存档另行保存，不能为迁移删除。

## 仅更新修改器

游戏关闭时，把 Mods/FFWTrainer 备份到 Mods 目录之外。替换新版 Scripts，保留 Data/settings.json 和启用标记。框架已经正常时无需重装。必须完整重启游戏：回标题不会重载 Lua，Nexus 默认也关闭了自动/热重载。

## 打开、应用和确认保存

- F2：常规修改器；F4：中英双语奇术卡搜索。
- F1 或“应用”：应用当前永久进度目标值。
- F3：任务中的奇术卡页面按已选模式获得卡牌。
- F5/F6：上一项/下一项。鼠标支持分类、条目、翻页、输入和滚动。
- “设置”：选择地面生成或直接获得，F3 沿用该选择；总点数解限仍在游戏原装备菜单加点。
- F7/F8 切换其他可选面板时会隐藏修改器。框架另有控制台键位，控制台能打开不代表修改器数据操作成功。

资源/等级的完整操作：

1. 返回酒馆，等本地角色和存档加载完成。修改的是自己的永久进度，不是队友记录。

2. 选择准确项目，确认当前值可读取、“应用”可用。

3. 安装或更换框架后的首次检查，先输入界面显示的**当前值**，点“应用”或按 F1 一次。应提示数值未变；这一步检查输入、就绪条件和读回，不改变该数值、不请求保存。失败时先按下文定位原因，再进行实际修改。

4. 检查通过后，点击目标输入框，全选后输入期望的**总量**，只用数字，例如 26；不要填 +1、1,000 或 1e3。点“应用”或按 F1 一次。

5. 阅读结果。“已核实…已请求游戏保存”表示运行值/原生接口读回和存档对象检查已通过，不等于已证明落盘。当前数值已相同则不会请求保存。

6. 等游戏正常保存，再回标题重新进入酒馆或完整重启，核对是否保留。失败原因未明确前不要反复应用。

资源范围 0–9,999,999；角色、武器和魔法流派等级 1–100。地面/直接获得奇术卡是局内卡牌操作，与永久等级修改不同。

## 启动即崩溃时

1. 完全退出游戏，按下方禁用步骤只禁用 FFWTrainer，再启动一次。若恢复正常，先保持修改器禁用，反馈修改器版本及本次日志中的相关错误。框架能够启动不代表所有修改器操作均已通过。

2. 若仍崩溃，按上方迁移步骤把旧框架备份并移出游戏目录，重新安装完整 Nexus 玩家包，暂不恢复内容 Mod 或旧全局设置。检查仅装这套框架能否进入标题画面；不要反复混搭不同包的 DLL 和签名。

3. 若全新的框架单独安装仍崩溃，核对框架页面支持的游戏版本，向框架作者提供准确文件/版本及本次日志。若能启动，则每次完全退出后逐个恢复内容 Mod，定位从哪一步开始出现异常。

日志位置为 `<游戏根目录>/FarFarWest/Binaries/Win64/ue4ss/UE4SS.log`，先确认修改时间对应刚才的启动。没有新日志时，优先检查 Win64 位置和框架文件是否完整。不要通过删除游戏存档来处理启动崩溃。

## F2 能打开，但无法修改

面板显示成功不等于写入通过。看界面原因以及最新 UE4SS.log：

- not_saloon：返回酒馆。
- player_not_ready / not_local_player：等待本地角色，不绕过检查去改远端进度。
- save_object_unavailable / save_slot_unavailable / save_version_unavailable / runtime_version_mismatch / save_version_mismatch：存档未就绪或格式不一致，不应取消保护。
- input_unavailable / input_not_synced：未安全读到目标输入，未提交；重新打开面板并输入。
- nativeRead / levelRead 失败：写入前的原生库存/经验接口失败。
- verification_failed / save_call_failed / save_object_not_updated：根据提示区分数值是否已改、是否已请求保存，停止重复操作并提供诊断。

日志记录项目、阶段和原因，不记录输入目标或存档标识；相同输入故障去重。反馈需包含修改器版本、Nexus 框架文件/版本、游戏版本、酒馆/任务位置、本地房主/客机角色和界面提示。提供相关日志前去掉个人路径及账号标识，不要上传存档、Data 或凭据。

## 禁用、卸载和回滚

退出游戏，移走 FFWTrainer/enabled.txt；若 Mods/mods.txt 也启用了 FFWTrainer，将该条目改为 0。卸载时只把 Mods/FFWTrainer 移入备份，保留 Data，并保留其他 Mod 仍需要的 Nexus 框架及签名。回滚时恢复旧 Trainer 文件和对应 Data 备份，再重启。卸载不会撤销游戏已经保存的进度修改。

## 兼容性与路径

本指南使用 Nexus mod 2 的 3.0.1.1183 Frostburn 玩家包（文件 242）。游戏更新后，先查看框架页面的兼容说明再替换文件。若日志明确指出非 ASCII 安装路径导致 Lua 加载失败，可通过 Steam 存储管理将游戏迁移到仅含 ASCII 字符的库目录；本指南不要求修改系统区域设置。
