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
