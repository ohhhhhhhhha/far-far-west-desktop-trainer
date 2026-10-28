package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib')
T.test('relocated standalone trainer handles local host/client travel and bilingual DPI layouts without progress writes',function()
 for _,root in ipairs({'/Install With Spaces','/中文 安装/测试游戏'})do
  local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
  local keys,queue={},{};local gi=e.object('GI');local remote=e.object('RemoteController');function remote:IsLocalPlayerController()return false end
  local function configure(pc)
   function pc:IsLocalPlayerController()return true end
   pc.PlayerState=e.object('PlayerState');return pc
  end
  configure(e.controller)
  package.loaded.UEHelpers=nil;package.preload.UEHelpers=function()return {GetPlayerController=function()return remote end,GetGameInstance=function()return gi end}end
  local env=setmetatable({},{__index=_G});env._G=env
  env.Key={F1=1,F2=2,F3=3,F4=4,F5=5,F6=6,F7=7,F8=8}
  env.RegisterKeyBind=function(k,f)keys[k]=f end
  env.ExecuteInGameThread=function(f)queue[#queue+1]=f end
  env.LoopInGameThreadWithDelay=function()end
  env.FindAllOf=function(class)if class=='PlayerController'then return {remote,e.controller}end;return {}end
  local mode='host';local file=root..'/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/Scripts/main.lua'
  local mod=assert(loadfile(file,'t',env))();local view={width=1280,height=720,dpiScale=1}
  mod.renderer.options.viewport=function()return view end
  local function flush()local jobs=queue;queue={};for _,f in ipairs(jobs)do f()end end
  for _,size in ipairs({{1280,720,1},{1024,768,1.25},{1920,1080,1.5},{3840,2160,2}})do
   view.width,view.height,view.dpiScale=table.unpack(size)
   for _,lang in ipairs({'zh-CN','en-US'})do
    mod.Locale.setCulture(lang)
    for _,role in ipairs({'host','client'})do
     mode=role;keys[2]();flush();if not mod.ui.visible then keys[2]();flush()end
     mod.action('section','weapons');flush();mod.ui:setQuery(lang=='zh-CN' and '双持' or 'DUAL');mod.renderer:render(mod.ui:model())
     T.eq(mod.ui.selectedId,'itemDualRevolverLevel');T.eq(mod.renderer.controller,e.controller,'never use remote controller')
     local old=mod.renderer.mouse.buttons.close;local oldHost=mod.renderer.host
     e.click(old.button) -- queued in old world
     configure(e.newController(false));flush();T.eq(mod.ui.visible,true,'stale close cannot change new-world intent')
     mod.update();T.eq(mod.renderer.host~=oldHost,true);T.eq(mod.renderer.attached,true)
     for _,cmd in ipairs(mod.renderer.lastScene.commands)do
      T.eq(cmd.x>=0 and cmd.y>=0 and cmd.x+cmd.width<=mod.renderer.lastScene.width+.1 and cmd.y+cmd.height<=mod.renderer.lastScene.height+.1,true)
     end
     e.click(mod.renderer.mouse.buttons.close.button);flush();T.eq(mod.visible,false);T.eq(e.controller.lookIgnores,0);T.eq(e.controller.bShowMouseCursor,false)
    end
   end
  end
  T.eq(mod.errors,0);mod.stop();e.restore()
  -- The panel exercise never asks Apply, Spawn, budget or Settings persistence.
  local save=io.open(root..'/FarFarWest/Binaries/Win64/ue4ss/Mods/FFWTrainer/Data/settings.json','rb');T.eq(save,nil)
 end
end)
T.finish()
