# Far Far West — 游戏内修改器

[English](README.md) · [下载 beta.5](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.4.0-beta.5) · [问题反馈](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues)

**FFWTrainer · 0.4.0-beta.5 · UE4SS · Windows x64**

按 **F2** 在游戏内打开修改器。面板采用游戏字体、深色背景和黄铜色边框，支持鼠标选择、翻页、输入与详情滚动。显示语言跟随游戏，搜索同时接受中文和英文。

- 金币、灵魂、蓝图、幽灵蜡烛和万圣节羽毛/南瓜/骷髅：0–9,999,999。
- 角色、14 种武器和六种魔法流派等级：1–100。
- 搜索 153 张普通奇术卡，在任务中选择地面生成或直接获得。
- 解除总属性点额度，继续在原装备菜单加点；保留单项限制、金币费用及原生确认保存。

## 安装

使用 [Nexus 游戏专用 UE4SS（mod 2）](https://www.nexusmods.com/farfarwest/mods/2?tab=files)，选择玩家主文件 **UE4SS-FarFarWest，3.0.1.1183 Frostburn / 文件 242**。完整安装其配套签名和配置，选择玩家主文件，不选 zDEV 开发包。

**现有 beta.5 ZIP 只复制 FFWTrainer 子文件夹。不要合并整个 GameRoot，也不要复制包内 UE4SS_Signatures。** 本在线指南替代冻结 beta.5 附件内的旧安装说明。

1. 完全退出游戏，私下备份 `%LOCALAPPDATA%\FarFarWest\Saved\SaveGames` 和各已安装 Mod 的 Data。
2. Steam → 管理 → 浏览本地文件，打开游戏根目录。将完整 Nexus 框架安装到 `FarFarWest/Binaries/Win64`，与 `FarFarWest-Win64-Shipping.exe` 同级。
3. 下载 [FFWTrainer-0.4.0-beta.5.zip](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/download/v0.4.0-beta.5/FFWTrainer-0.4.0-beta.5.zip)，解压到游戏目录之外。
4. 在解压内容中打开 `GameRoot/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer`，只将这个 **FFWTrainer** 文件夹复制到 `<游戏根目录>/FarFarWest/Binaries/Win64/ue4ss/Mods/`。
5. 保留已有 FFWTrainer/Data，以及 Nexus 的 DLL、设置、Mod 列表和**全部**签名。完整重启，进入酒馆后按 F2。

详见[完整安装、迁移与回滚指南](INSTALL.zh-CN.md)。不需要终端、批处理、外置 EXE 或 .NET。

## 操作

| 操作 | 功能 |
| --- | --- |
| F2 | 打开/关闭修改器，从 F4 返回上次分类 |
| F4 | 打开/关闭中英奇术卡搜索 |
| F1 或“应用” | 应用选中项目的目标数值 |
| F3 或刷卡按钮 | 在奇术卡页面按所选模式获得卡牌 |
| F5 / F6 | 上一项/下一项 |
| 鼠标 | 选择分类与条目、翻页、输入、滚动详情 |

永久进度在酒馆修改，先等自己的角色和存档加载完成。输入期望的**总量**，应用一次并阅读结果；等游戏保存，再重新加载核对。F2 能打开不等于写入成功。

在“设置”中选择**生成到地面**或**直接获得**，两种模式均在任务中用 F3 执行，请间隔至少两秒。地面模式在周围 20 米已有 10 张未拾取掉落卡时暂停，拾取后恢复。浏览和搜索不会修改进度。

活动资源修改不改变已投入坩埚的材料，活动清理与兑换遵循游戏规则。总点数解限保存在 Data/settings.json；关闭开关恢复额度检查，不清除已保存加点。F7/F8 切换其他可选面板时会收起修改器。

## 反馈与源码

启动崩溃或 F2 能打开但无法应用时，先按[排障步骤](INSTALL.zh-CN.md)检查。反馈准确界面提示、修改器/游戏/框架版本、酒馆或任务位置以及房主/客机身份。相关日志先去掉个人路径和账号标识，不要上传存档、Data 或凭据。本次文档更新不代表所有崩溃或保存反馈均已解决。

本仓库包含修改器及其 Lua 依赖；卡牌说明和战斗统计是独立 Mod。参见[开发说明](DEVELOPMENT.md)、[更新记录](CHANGELOG.md)及[框架兼容说明](FFWTools/src/RuntimeCompatibility/README.zh-CN.md)。

原创代码和文档采用 [MIT](LICENSE)，游戏资料与依赖遵循[第三方声明](THIRD-PARTY-NOTICES.md)。[UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)为上游框架项目。
