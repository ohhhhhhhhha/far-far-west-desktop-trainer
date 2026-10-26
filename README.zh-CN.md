# Far Far West — 桌面修改器

[English](README.md) · [下载](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/tag/v0.3.0-beta.3) · [问题反馈](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues)

**FFWTrainer · 0.3.0-beta.3 · UE4SS · Windows x64**

- 金币、灵魂和蓝图：0–9,999,999。
- 角色、14 种武器、六种魔法流派等级：1–100。
- 按中文或英文名称搜索 153 张可收集奇术卡，在任务中生成指定拾取物。
- 解除总加点额度，继续在游戏原菜单分配属性；保留单项上限、金币消耗、确认和原生保存。
- 独立 Windows 窗口，不使用 F1–F6 修改快捷键、WeMod 或后台服务。

永久进度请在酒馆修改。魔法等级对应 Acid、Elec、Pyro、Voodoo、Cactus、Frost 流派经验，不代表单个法术解锁。浏览和搜索不会修改进度。解限开关保存在 Mod 的 Data/settings.json；关闭后恢复总额度检查，已保存的属性不会被撤销。

## 安装

验证基线为 Far Far West 0.3.0.7 和 UE4SS build 1181。请另行安装兼容的 [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)。桌面程序另需 .NET Framework 4.x。

1. 退出游戏，下载 [FFWTrainer-0.3.0-beta.3.zip](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/releases/download/v0.3.0-beta.3/FFWTrainer-0.3.0-beta.3.zip)。
2. 解压到游戏目录之外。
3. 从 Steam → 管理 → 浏览本地文件打开游戏目录，将 GameRoot 内的内容复制进去。
4. 双击游戏目录中的 FFWTrainer/FFWTrainer.exe。

无需终端或安装脚本。更新旧版前请先阅读[安装、升级与卸载说明](INSTALL.zh-CN.md)。

## 操作

选择条目，输入目标数值并点击应用；在卡牌页搜索和生成，在设置页切换总点数解限。

## 源码与验证

本仓库只包含桌面修改器及其必要依赖，不包含另一工具或战斗统计/同步 Mod。所需的计算与语言文件随源码独立提供，不依赖另一个仓库。

Lua 源码位于 FFWTools/src/FFWTrainer/Scripts。GUI 源码位于 FFWTools/src/FFWTrainerGui。详见[开发说明](DEVELOPMENT.md)及[更新记录](CHANGELOG.md)。0.3.0-beta.3 的仓库拆分保持已确认有效的运行内容不变；离线检查不代表每一种组合都经过游戏内实测。

## 反馈与许可

由 FFWTools contributors 维护。请在 [GitHub Issues](https://github.com/ohhhhhhhhha/far-far-west-desktop-trainer/issues) 提供工具版本、游戏及 UE4SS 版本、复现步骤和相关错误文字；勿附存档、账号标识或个人路径。

原创代码和文档采用 [MIT 许可](LICENSE)。游戏来源文本和数据保留原权利归属，详见[来源与授权说明](THIRD-PARTY-NOTICES.md)。
