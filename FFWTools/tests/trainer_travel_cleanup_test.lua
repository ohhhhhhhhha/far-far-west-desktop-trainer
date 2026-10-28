package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib')
local function engine(fn)
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local ok,err=pcall(fn,e);e.restore();if not ok then error(err,0)end
end
local function panel(e,action)
 return dofile('FFWTools/src/FFWTrainer/Scripts/MousePanel.lua').new{host=e.object('Host'),root=e.object('Root'),font=e.object('Font'),controller=e.controller,getController=function()return e.controller end,library=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary'),onAction=action}
end
local function poison(o,k)o[k]={};assert(o:IsValid(),'report fixture remains IsValid')end
T.test('B04 cleanup continues when IsValid objects expose non-callable old methods',function()engine(function(e)
 local hits=0;local p=panel(e,function()hits=hits+1 end)
 p:button('x',{text='x',action='x',x=0,y=0,width=90,height=32});p:show()
 local entry=p.buttons.x;poison(entry.host,'SetVisibility');poison(entry.host,'RemoveFromParent');entry.button.OnClicked.Remove={}
 p:dispose();T.eq(p.active,false);T.eq(next(p.buttons),nil);T.eq(e.shared['FFWTools.MousePanel.v1.owner'],nil)
 e.invoke(entry.host,'F_ChildClick');T.eq(hits,0)
 local hooks=0;for _,hs in pairs(e.hooks)do for _,f in ipairs(hs)do if f then hooks=hooks+1 end end end;T.eq(hooks,0)
end)end)
T.test('B04 new world rebuilds after old hosts and input restore methods fail',function()engine(function(e)
 local Canvas=require('CanvasView');local UI=require('TrainerUI');local View=require('TrainerView')
 local ui=UI.new{read=function()return {values={}}end};ui:toggle('resources')
 local r=Canvas.new{getController=function()return e.controller end,layout=View.layout,viewport=function()return {width=1280,height=720,dpiScale=1}end,onAction=function(a,v)ui:action(a,v)end}
 r:render(ui:model());local old=r.host;local pc=e.controller
 poison(old,'SetVisibility');poison(old,'RemoveFromParent');poison(pc,'SetIgnoreLookInput')
 for _,b in pairs(r.mouse.buttons)do poison(b.host,'SetVisibility');poison(b.host,'RemoveFromParent');b.button.OnClicked.Remove={}end
 e.newController(false);r:render(ui:model());T.eq(r.host~=old,true);T.eq(r.attached,true)
 e.click(r.mouse.buttons.close.button);T.eq(ui.visible,false);r:render(nil);T.eq(r.attached,false);T.eq(e.controller.bShowMouseCursor,false)
 r.mouse:dispose()
end)end)
T.test('B08 old edit controls are never queried after controller/world replacement',function()engine(function(e)
 local r=require('CanvasView').new{getController=function()return e.controller end,layout=require('TrainerView').layout,viewport=function()return {width=1280,height=720,dpiScale=1}end}
 local ui=require('TrainerUI').new{read=function()return {values={}}end};ui:toggle('resources');r:render(ui:model())
 local reads=0;r.inputs.query.widget.GetText=function()reads=reads+1;error('old edit box')end
 e.newController(false);T.eq(r:input('query'),nil);T.eq(reads,0,'skip old-world UFunctions before resolving them')
 r:render(ui:model());r.mouse:dispose()
end)end)
T.test('no widgets are constructed until the local controller has a live world',function()engine(function(e)
 local ui=require('TrainerUI').new{read=function()return {values={}}end};ui:toggle('resources')
 local r=require('CanvasView').new{getController=function()return e.controller end,layout=require('TrainerView').layout,viewport=function()return {width=1280,height=720,dpiScale=1}end}
 local world=e.controller.world;e.controller.world=nil
 r:render(ui:model());T.eq(e.constructed,0);T.eq(r.attached,false)
 e.controller.world=world;r:render(ui:model());T.eq(r.attached,true);r:discard()
end)end)
T.test('abandon drops old-world routes without resolving any old native method',function()engine(function(e)
 local p=panel(e,function()error('old route executed')end);p:button('x',{text='x',action='x',x=0,y=0,width=90,height=32});p:show()
 local entry=p.buttons.x;local touches=0
 local function forbidden()touches=touches+1;error('old native call')end
 entry.host.SetVisibility=forbidden;entry.host.RemoveFromParent=forbidden;entry.button.OnClicked.Remove=forbidden
 e.controller.SetIgnoreLookInput=forbidden
 e.newController(false)
 p:dispose(true);T.eq(touches,0);T.eq(next(p.buttons),nil);T.eq(e.shared['FFWTools.MousePanel.v1.owner'],nil)
 e.invoke(entry.host,'F_ChildClick');T.eq(touches,0)
end)end)
T.test('unloaded game UI classes cannot reach native Create during a map transition',function()engine(function(e)
 local ui=require('TrainerUI').new{read=function()return {values={}}end};ui:toggle('resources')
 local r=require('CanvasView').new{getController=function()return e.controller end,layout=require('TrainerView').layout,viewport=function()return {width=1280,height=720,dpiScale=1}end}
 local cls=StaticFindObject('/Game/Interfaces/UI_Joker_Informations.UI_Joker_Informations_C');cls.destroyed=true
 local lib=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary');local create=lib.Create;local calls=0
 lib.Create=function(...)calls=calls+1;return create(...)end
 pcall(function()r:render(ui:model())end);T.eq(calls,0,'missing host class is rejected before the native factory')
 cls.destroyed=false;r:render(ui:model());T.eq(r.attached,true);r:discard()
end)end)
T.test('same-controller travel releases only this overlay lock through the freshly resolved owner',function()engine(function(e)
 e.controller:SetIgnoreLookInput(true) -- a pre-existing game/menu lock
 local p=panel(e,function()end);p:button('x',{text='x',action='x',x=0,y=0,width=90,height=32});p:show();T.eq(e.controller.lookIgnores,2)
 local touches=0;local oldMenu=e.controller.Pawn.refBpMenu
 oldMenu.GetFullName=function()touches=touches+1;error('old menu identity')end
 local nextMenu=e.object('NewMenu');nextMenu.isUiMode=false;nextMenu.isMenuOpened=false
 e.controller.world=e.object('NextWorld');e.controller.Pawn=e.object('NewPawn');e.controller.Pawn.refBpMenu=nextMenu
 p:dispose(true);T.eq(e.controller.lookIgnores,1,'do not reset game-owned input locks');T.eq(e.controller.bShowMouseCursor,false)
 T.eq(touches,0,'never resolve old menu identity during abandonment')
end)end)
T.test('a queued callback after the last route is disposed never reads its stale context',function()engine(function(e)
 local p=panel(e,function()error('disposed action executed')end)
 p:button('x',{text='x',action='x',x=0,y=0,width=90,height=32});p:show()
 local callback=assert(e.hooks['/Game/Interfaces/UI_Template_Button.UI_Template_Button_C:F_ChildClick'][1])
 p:dispose(true)
 local reads=0
 local ok,err=pcall(callback,{get=function()reads=reads+1;error('stale queued UObject')end})
 T.eq(ok,true,'released routes must return before context:get: '..tostring(err))
 T.eq(reads,0)
end)end)
T.finish()
