# 安装与故障排查 — 0.4.0-beta.4

## 下载与适用版本

Windows x64；已验证基线为 Far Far West 0.3.0.7 与 [UE4SS v3.0.1-1181-g83330635 官方下载](https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental/UE4SS_v3.0.1-1181-g83330635.zip)。框架需另外下载。在[发布页](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.4.0-beta.4)下载 **FFWTrainer-0.4.0-beta.4-installation-update.zip** 运行包，source 源码包不能直接用作安装包。安装前完全退出游戏；使用 Windows 普通解压和复制即可。

## 1. 找到游戏目录

在 Steam 右键 Far Far West → 管理 → 浏览本地文件，打开的是**游戏根目录**。从这里依次打开 FarFarWest → Binaries → Win64，进入**游戏程序目录**，里面有 FarFarWest-Win64-Shipping.exe。下面两步使用的是两个不同目录。

## 2. 先安装并验证 UE4SS

如果已安装且正常使用上述测试构建，可保留现有安装并跳到第 3 步。否则将官方 UE4SS ZIP 解压到单独的临时文件夹，把里面的 **dwmapi.dll** 和 **ue4ss** 文件夹直接复制到游戏程序目录。核对结果：

    <游戏根目录>/FarFarWest/Binaries/Win64/
      FarFarWest-Win64-Shipping.exe
      dwmapi.dll
      ue4ss/UE4SS.dll
      ue4ss/UE4SS-settings.ini
      ue4ss/Mods/shared/UEHelpers/UEHelpers.lua

UE4SS ZIP 带默认设置和 Mod 列表。如果已有 UE4SS 或其他代理 DLL，先把现有文件和配置备份到游戏目录之外；不要直接覆盖其他 Mod、设置、Mod 列表或代理 DLL。上述步骤适用于首次安装；调整已有环境时应保留其他 Mod，使用一套兼容的 UE4SS，不要混用不同构建的文件。

首次安装时，**先不安装 FFWTrainer**，启动游戏一次后退出，检查 ue4ss/UE4SS.log 是否新建或更新时间已变化。此构建的日志可能显示 v3.0.1 Beta #0，还应核对 Git SHA 83330635。如果此时已崩溃或没有新日志，应先排查 UE4SS 安装再继续。游戏更新或其他 Mod 也可能影响兼容性。

## 3. 安装修改器

将修改器运行 ZIP 解压到另一个文件夹，打开其中的 **GameRoot**，把其**内部全部内容**复制到 Steam 打开的游戏根目录，提示时合并文件夹。不要复制 GameRoot 文件夹本身，也不要把其中的 FarFarWest 文件夹复制到 Win64 里面。核对结果：

    <游戏根目录>/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/
      enabled.txt
      Scripts/main.lua
      Scripts/Spawner.lua
      Scripts/TrainerUI.lua
      Data/  （可为空）

包内 enabled.txt 用于启用修改器。如果 Windows 隐藏扩展名，请确认实际文件名是 enabled.txt，而非 enabled.txt.txt。Scripts 中的文件应一起保留；本修改器不要求安装独立的卡牌说明或战斗统计 Mod。

## 4. 验证与故障排查

启动游戏进入酒馆，F2 打开修改器，F4 打开奇术卡搜索。F3 在任务中的奇术卡页面使用；在“设置”中选择地面生成或直接获得，两次请求至少间隔两秒。

如果 F2/F4 没反应，检查 UE4SS.log 的更新时间、上面的目录、启用标记，以及日志中是否有 “Starting Lua mod 'FFWTrainer'” 和 “[FFWTrainer]”。“disabled: Missing …” 会指出缺少的接口与测试框架版本。如果有新日志却没有修改器启动记录，先检查目录和启用状态；仍无法解决时提供脱敏日志。

更新前，将 FFWTrainer 文件夹备份到 Mods 目录外。把新版运行包合并到游戏根目录时保留 Data/settings.json 与其他 Mod。新包不含个人设置或存档。

如果添加修改器后启动崩溃，退出后暂时移走其 enabled.txt；若 Mods/mods.txt 还有 FFWTrainer 条目，也将其设为 0。重启比较结果，重新启用时恢复标记，不会删除存档。如果禁用后仍崩溃，分别排查 UE4SS、游戏及其他 Mod；否则反馈游戏版本、UE4SS 精确构建号、修改器版本和最后操作。提供日志前去掉个人路径和账号标识，不要上传存档或凭据。

[UE4SS 官方安装文档](https://docs.ue4ss.com/installation-guide) · [Lua Mod 目录规范](https://docs.ue4ss.com/guides/creating-a-lua-mod.html)
