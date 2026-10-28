# Far Far West — UE4SS 兼容与 beta.5 安装

使用完整的 [Nexus 游戏专用 UE4SS 玩家包（mod 2）](https://www.nexusmods.com/farfarwest/mods/2?tab=files)：**UE4SS-FarFarWest 3.0.1.1183 Frostburn，文件 242**，作者 anro / AnroG772。它提供配套游戏配置和签名。将其 dwmapi.dll 及 ue4ss 文件夹放在 `<Steam 游戏根目录>/FarFarWest/Binaries/Win64`，与 FarFarWest-Win64-Shipping.exe 同级。

## 现有 beta.5 附件

冻结的 Trainer beta.5 压缩包包含旧 ProcessLocalScriptFunction.lua 覆盖签名和旧说明。**不要用该签名覆盖 Nexus 框架。** 仅将包内 `GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer` 复制到 `<Steam 游戏根目录>/FarFarWest/Binaries/Win64/ue4ss/Mods/`。

完整保留 Nexus 的全部签名、UE4SS-settings.ini、Mods/mods.txt 及框架 DLL。保留每个 Mod 的 Data，并在游戏关闭时备份 `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames`。beta.5 附件字节不变，本在线指南替代其旧安装说明。

完整步骤见[安装、迁移与排障指南](../../../INSTALL.zh-CN.md)。先验证完整 Nexus 框架，再添加内容 Mod。框架能进入标题画面不代表所有原生 Mod 操作或保存均已成功；请按指南检查应用和重载后的数值，反馈准确错误。

## 历史来源

源码目录保留的旧签名来自 [halu103/farfarwest-frostburn-modkit](https://github.com/halu103/farfarwest-frostburn-modkit/blob/main/config/ue4ss/UE4SS_Signatures/ProcessLocalScriptFunction.lua)，按 MIT 许可保留，授权见 [licenses/FrostburnModKit.txt](licenses/FrostburnModKit.txt)。来源说明不代表需要安装该旧签名。

[UE4SS 上游项目](https://github.com/UE4SS-RE/RE-UE4SS)。游戏更新后重新查看 Nexus 框架页面，本指南不承诺兼容所有游戏或框架版本。
