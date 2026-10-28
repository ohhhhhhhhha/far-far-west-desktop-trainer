# 安装、更新与卸载

需要 Windows x64、Far Far West 和可用的 UE4SS。验证基线：游戏 0.3.0.7 / UE4SS 1181。安装包不含框架 DLL。

## 安装

退出游戏，解压运行 ZIP。通过 Steam → 管理 → 浏览本地文件打开游戏目录，将 GameRoot 里面的全部内容复制进去并合并文件夹，不要复制 GameRoot 文件夹本身。入口为 FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/Scripts/main.lua；包内 enabled.txt 用于启用独立组件。启动后按 F2，F4 直接打开奇术卡搜索。不需要安装器、命令行或桌面程序。

## 从桌面版更新

1. 退出游戏和旧桌面修改器。
2. 把旧 FFWTrainer Mod 文件夹复制到 Mods 目录之外作为备份。
3. 仅替换其 Scripts 文件夹，保留 Data 和 settings.json。
4. 将游戏根目录的 FFWTrainer/FFWTrainer.exe 移至备份或删除。新版不再读取桌面指令文件。
5. 复制新版其余 GameRoot 内容，重新启动游戏，用 F2/F4 操作。

包内不含个人设置、存档或统计记录；合并文件夹时，空 Data 目录不会替换已有文件。

## 禁用、卸载和恢复

退出游戏，移走该组件的 enabled.txt。如果 mods.txt 中还存在 FFWTrainer 条目，将其设为 0；enabled.txt 会覆盖该禁用标志。卸载时仅移除组件 Scripts，可保留 Data 设置。恢复时复制回备份文件与启用标记。卸载不会撤销游戏已保存的进度修改。

[UE4SS 目录规范](https://docs.ue4ss.com/guides/creating-a-lua-mod.html) · [启用规则](https://docs.ue4ss.com/guides/installing-a-c%2B%2B-mod.html)

## 已验证的 UE4SS 下载

使用 [UE4SS v3.0.1-1181-g83330635](https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental/UE4SS_v3.0.1-1181-g83330635.zip)，来自 [UE4SS 官方实验构建归档](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental)。日志可能显示 v3.0.1 Beta #0，请同时核对 Git SHA 83330635，不能只看 3.0.1。实验最新版会变化，此链接固定为本 Mod 已测试的构建。

退出游戏，将此框架 ZIP 中的 dwmapi.dll 和 ue4ss 文件夹放到 FarFarWest/Binaries/Win64，再按上面的步骤安装修改器。无需命令行。保留现有 Mod 和配置。

若启动就崩溃，先检查安装的框架版本与目录，临时停用 FFWTrainer 后测试是否能进入标题；停用方法见上文。缺少修改器必需 Lua 接口时，本候选会停用并在 UE4SS.log 输出缺失接口与所需构建号。发生在 UE4SS 加载 Lua 之前的原生崩溃无法由该检查处理。
