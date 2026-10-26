# Development / 开发说明

All runtime Lua modules and required dependencies are under FFWTools/src/FFWTrainer/Scripts. TrainerUI owns selection/search/actions, TrainerView builds the layout, and CanvasView renders native widgets through MousePanel. main.lua owns hotkeys and game-thread scheduling. Progress, Spawner and UpgradeLimit retain the existing gameplay boundaries. Bridge is retained for its settings file helpers; its desktop protocol is not polled by main.lua.

The root package.mjs exports buildRelease({ root, outputDirectory, JSZip }). package-manifest.json is the explicit allowlist; release.json provides the version. Node.js and JSZip 3.10.1 are development dependencies. The API produces runtime/source ZIPs and SHA-256 manifests without launching a process or the game. No GUI compilation is needed.

Lua checks are under FFWTools/tests, adapted to this standalone layout. Use a Lua 5.4 capable IDE/runner with the repository as working directory. The new interface was also exercised against a synthetic Unreal boundary, including mouse ownership, persistent editing input, bilingual search and 720p geometry. Live game font/IME behavior remains a separate acceptance check. Never treat offline results as live-game validation.

The existing GitHub workflow reads prepared release manifests on publish/* branches and uses the official JavaScript API. It verifies each asset’s size and SHA-256 before publishing. No shell commands are used; upload payloads stay off main and outside source archives.

本仓库所有运行依赖都位于自身 Scripts 目录。控制器、布局、画布和鼠标输入分层，保存与刷卡入口保持明确操作边界。打包 API 按清单生成运行/源码 ZIP 与校验文件，不需要 GUI 编译，也不启动游戏或命令行。测试在独立仓库目录下执行，界面原生表现另行实测；不要纳入玩家 Data、存档、日志或个人路径。

Follow [UE4SS’s Lua layout](https://docs.ue4ss.com/guides/creating-a-lua-mod.html). [UE5LuaModKit](https://github.com/qycnet/UE5LuaModKit) is an organizational reference, not the UE4SS API contract.
