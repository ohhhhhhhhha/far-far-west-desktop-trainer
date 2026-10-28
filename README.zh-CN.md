# Far Far West — 游戏内修改器（0.4.0-beta.6）

[English](README.md) · [下载 beta.6](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.4.0-beta.6) · [完整安装指南](INSTALL.zh-CN.md)

玩家优先安装 [Nexus 游戏专用框架（mod 2）](https://www.nexusmods.com/farfarwest/mods/2?tab=files)。选择 UE4SS-FarFarWest 3.0.1.1183 Frostburn 玩家主文件（文件 242）。它自带游戏签名与配置，本内容包不覆盖这些框架文件。[UE4SS GitHub](https://github.com/UE4SS-RE/RE-UE4SS)保留为上游来源。

F2 打开修改器，F4 中英搜索奇术卡。永久进度在酒馆修改：选中项目、输入目标总量数字、按应用/F1 一次，阅读提示并在正常保存、重新加载后确认保留。完整指南覆盖具体目录、首次安装、旧版迁移、启用、键位、应用保存和回滚。

安装或修改进度前，完整退出游戏，通过资源管理器备份 `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames`，并单独保留 Mod 的 Data 备份。完整指南补充了同值应用检查，以及启动崩溃、无法修改数据的分步排查。

功能包括金币、灵魂、蓝图与万圣节资源，角色/武器/魔法流派等级，原菜单总点数解限；设置中选择地面或直接获得奇术卡，任务内按 F3 执行。

目标框读取失败时会取消应用并显示原因。应用失败会标明出错阶段，可按安装指南排查。修改永久进度前，需要在酒馆等自己的角色和存档加载完成。

原创代码和文档采用 [MIT](LICENSE)，游戏资料与依赖遵循[第三方声明](THIRD-PARTY-NOTICES.md)。

43/43 份离线 Lua 测试通过。本机 Nexus 1183 环境已由用户确认：同值应用通过，金币增加 1 后回标题重新进入酒馆仍保留。本次检查不涵盖全部等级字段、每台电脑或所有联机身份。
