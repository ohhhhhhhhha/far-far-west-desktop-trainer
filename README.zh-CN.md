# Far Far West — 游戏内修改器

[English](README.md) · [下载](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.4.0-beta.1) · [问题反馈](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues)

**FFWTrainer · 0.4.0-beta.1 · UE4SS · Windows x64**

按 **F2** 在游戏中唤出修改器。界面采用游戏字体、深色背景和黄铜色边框，支持鼠标选择、翻页、输入与详情滚动。显示语言跟随游戏，搜索同时接受中文和英文，英文不区分大小写。

- 金币、灵魂、蓝图：0–9,999,999。
- 角色、14 种武器、六种魔法流派等级：1–100。
- 搜索 153 张普通奇术卡，在任务中生成选中拾取物。
- 解除总属性点额度，继续在原装备菜单加点；保留单项限制、金币费用及原生确认保存。

## 安装

需要另行安装兼容的 [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases)。验证基线：Far Far West 0.3.0.7 / UE4SS build 1181。

1. 退出游戏，下载 [FFWTrainer-0.4.0-beta.1.zip](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/download/v0.4.0-beta.1/FFWTrainer-0.4.0-beta.1.zip)。
2. 将 ZIP 解压到游戏目录之外的普通文件夹。
3. 在 Steam → 管理 → 浏览本地文件打开游戏目录，将 GameRoot 内的内容复制进去。
4. 启动游戏，按 F2。

运行包只含游戏内 Lua 组件，无外置 EXE 和 .NET 要求，不需要命令行或安装脚本。旧桌面版更新方法见[安装、更新与卸载](INSTALL.zh-CN.md)。

## 操作

| 操作 | 功能 |
| --- | --- |
| F2 | 打开 / 关闭修改器 |
| F4 | 打开 / 关闭奇术卡搜索页 |
| F1 或“应用” | 应用选中项目的目标数值 |
| F3 或“生成一张” | 在刷卡页打开时生成选中卡牌 |
| F5 / F6 | 上一项 / 下一项 |
| 鼠标 | 选择分类与项目、翻页、输入和滚动详情 |

永久进度在酒馆修改。魔法等级指酸蚀、电击、火焰、巫毒、仙人掌、冰霜流派等级。刷卡在任务中进行，两次请求间隔至少 2 秒；关闭面板后正常拾取。浏览、搜索和刷新不会修改进度。

“设置”页控制总点数解限，开关保存在组件 Data/settings.json；关闭面板不会关闭开关。关闭开关恢复总额度检查，不清除已保存的加点。打开 F7/F8 会收起修改器，让其他面板使用鼠标。

## 源码与验证

源码位于 FFWTools/src/FFWTrainer/Scripts，所需依赖均已包含，可独立使用。本仓库不包含独立卡牌说明 Mod 或战斗统计。参见[开发说明](DEVELOPMENT.md)及[更新记录](CHANGELOG.md)。

原进度保存、魔法等级和原菜单点数解限已由用户确认。本版通过离线 Lua、原生控件边界及 720p/双语布局检查；新面板的游戏字体、输入法和实际操作仍待实机验收，因此以预发布版本提供。

## 反馈与许可

在 [Issues](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues) 提供 Mod、游戏和 UE4SS 版本及复现步骤，请勿附存档、账号标识或个人路径。由 FFWTools contributors 维护。原创代码和文档采用 [MIT](LICENSE)，游戏文本与第三方依赖遵循[对应权利声明](THIRD-PARTY-NOTICES.md)。
