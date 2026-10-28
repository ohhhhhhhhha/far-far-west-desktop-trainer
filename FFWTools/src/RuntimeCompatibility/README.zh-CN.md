# Far Far West — UE4SS 兼容说明

当前版本为 **FFWTrainer 0.4.0-beta.6**。使用完整的 [Nexus 游戏专用 UE4SS 玩家包（mod 2）](https://www.nexusmods.com/farfarwest/mods/2?tab=files)：**UE4SS-FarFarWest 3.0.1.1183 Frostburn，文件 242**，作者 anro / AnroG772。

将框架的 dwmapi.dll 和 ue4ss 放在 `<Steam 游戏根目录>/FarFarWest/Binaries/Win64`，与 FarFarWest-Win64-Shipping.exe 同级；保留其配套配置、Mod 列表、DLL 和全部签名。

beta.6 运行 ZIP 只安装 `ue4ss/Mods/FFWTrainer`，不包含或覆盖框架签名。按[完整安装指南](../../../INSTALL.zh-CN.md)将其 GameRoot 内部内容复制到 Steam 游戏根目录。保留 Mod Data，并在游戏关闭时私下备份 `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames`。

## 旧 beta.5 附件

归档 beta.5 ZIP 保持原样，其中包含旧 ProcessLocalScriptFunction.lua。若在 Nexus 框架上安装旧版，只将其 `GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer` 复制到 `<游戏根目录>/FarFarWest/Binaries/Win64/ue4ss/Mods/`；不要合并整个 GameRoot，也不要复制 UE4SS_Signatures。旧签名及许可保留在 beta.5 源码历史中。

## 已验证范围

43/43 份离线 Lua 测试通过。本机 Nexus 1183 环境已由用户确认：同值应用通过，金币增加 1 后回标题重新进入酒馆仍保留。这不代表已验证全部等级字段、所有联机身份或每台电脑。

游戏更新后请重新核对 Nexus 页面。[UE4SS 上游项目](https://github.com/UE4SS-RE/RE-UE4SS)。
