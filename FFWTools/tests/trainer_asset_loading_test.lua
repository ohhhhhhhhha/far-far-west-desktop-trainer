package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib')
local hostPath='/Game/Interfaces/UI_Joker_Informations.UI_Joker_Informations_C'
local fontPath='/Game/Materials/Fonts/Font_Text.Font_Text'
local function engine(fn)
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local ok,err=pcall(fn,e);e.restore();if not ok then error(err,0)end
end
local function renderer(e)
 local ui=require('TrainerUI').new{read=function()return {values={}}end};ui:toggle('resources')
 local r=require('CanvasView').new{getController=function()return e.controller end,layout=require('TrainerView').layout,viewport=function()return {width=1280,height=720,dpiScale=1}end}
 return r,ui
end
T.test('cold first open loads the host and font before native widget creation',function()engine(function(e)
 local host,font=StaticFindObject(hostPath),StaticFindObject(fontPath);host.destroyed=true;font.destroyed=true
 local loads={};LoadAsset=function(path)loads[path]=(loads[path]or 0)+1;local object=StaticFindObject(path);object.destroyed=false;return object end
 local lib=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary');local create=lib.Create
 lib.Create=function(self,...)T.eq(host:IsValid(),true);T.eq(font:IsValid(),true,'font must be resolved before Create');return create(self,...)end
 local r,ui=renderer(e);r:render(ui:model())
 T.eq(r.attached,true);T.eq(loads[hostPath],1);T.eq(loads[fontPath],1)
 r:render(ui:model());T.eq(loads[hostPath],1);T.eq(loads[fontPath],1,'normal refresh does not reload assets');r:discard()
end)end)
T.test('failed font load never creates a partial host and can recover on next open',function()engine(function(e)
 local font=StaticFindObject(fontPath);font.destroyed=true;LoadAsset=function()end
 local lib=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary');local create=lib.Create;local creates=0
 lib.Create=function(self,...)creates=creates+1;return create(self,...)end
 local r,ui=renderer(e);local ok=pcall(function()r:render(ui:model())end)
 T.eq(ok,false);T.eq(creates,0);T.eq(r.attached,false)
 font.destroyed=false;r:render(ui:model());T.eq(r.attached,true);r:discard()
end)end)
T.test('invalid widget library CDO cannot receive native Create',function()engine(function(e)
 local lib=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary');local invalid=e.object('InvalidCDO');invalid.destroyed=true
 local calls=0;invalid.Create=function()calls=calls+1;error('invalid native factory')end
 lib.GetCDO=function()return invalid end
 local r,ui=renderer(e);T.eq(pcall(function()r:render(ui:model())end),false);T.eq(calls,0)
end)end)
T.test('native button captions use the TextOverflowPolicy setter with Ellipsis',function()engine(function(e)
 local r,ui=renderer(e);r:render(ui:model())
 for _,entry in pairs(r.mouse.buttons)do T.eq(entry.label.AutoWrapText,false);T.eq(entry.label.TextOverflowPolicy,1);T.eq(entry.label.OverflowPolicy,nil)end
 r:discard()
end)end)
T.finish()
