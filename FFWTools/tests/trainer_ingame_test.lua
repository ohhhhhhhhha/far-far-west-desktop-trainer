package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib')
local UI=require('TrainerUI')
local L=require('Locale')
T.test('in-game trainer is read-only until Apply and preserves typed values on refresh',function()
 local writes=0
 local u=UI.new{read=function() return {canApply=true,values={gold={value=123}}} end,
 apply=function(id,value) writes=writes+1;T.eq(id,'gold');T.eq(value,'456');return true,'已保存','Saved' end}
 u:toggle('resources');T.eq(u:model().selected.id,'gold');T.eq(u.target,'123');T.eq(writes,0)
 u:setTarget('456');u:refresh();T.eq(u.target,'456');T.eq(writes,0)
 u:action('apply');T.eq(writes,1);u:refresh();T.eq(writes,1)
 u:action('section','magic');T.eq(u:model().selected.category,'magic');T.eq(u.target,'')
 u:setQuery('FROST');T.eq(#u:model().rows,1);T.eq(u:model().selected.id,'itemIceLevel')
 u:action('close');u:action('apply');T.eq(writes,1)
end)
T.test('search accepts Chinese and English regardless of display language',function()
 local u=UI.new{read=function() return {values={}} end};u:toggle('weapons')
 u:setQuery('双持');T.eq(u:model().selected.id,'itemDualRevolverLevel')
 L.setCulture('en-US');u:setQuery('DUAL');T.eq(#u:model().rows,1)
 u:action('section','jokers');u:setQuery('轻盈体态');T.eq(u:model().selected.id,'jokerLightWeight')
 u:setQuery('LIGHTWEIGHT');T.eq(u:model().selected.id,'jokerLightWeight')
 u:setQuery('no result xyz');T.eq(u:model().selected,nil)
 L.setCulture('zh-CN')
end)
T.test('game styled trainer has roomy aligned mouse controls and stable input contents',function()
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local Canvas,View=require('CanvasView'),require('TrainerView')
 local u=UI.new{read=function() return {canApply=true,values={gold={value=10}}} end};u:toggle('resources')
 local r=Canvas.new{getController=function() return e.controller end,layout=View.layout,
 viewport=function() return {width=1280,height=720,dpiScale=1} end,onAction=function(a,v) u:action(a,v) end}
 r:render(u:model());T.eq(e.controller.bShowMouseCursor,true);T.eq(e.nativeRecentersMouse(),false)
 r.inputs.target.widget:SetText('789');u:refresh();r:render(u:model());T.eq(r:input('target'),'789')
 local apply=r.mouse.buttons.apply;T.eq(apply.label.AutoWrapText,false);T.eq(apply.label.Slot.padding.Top,0)
 for _,cmd in ipairs(r.lastScene.commands) do
  T.eq(cmd.x+cmd.width<=r.lastScene.width+.1,true);T.eq(cmd.y+cmd.height<=r.lastScene.height+.1,true)
  if cmd.kind=='button' then T.eq(cmd.height>=32,true) end
 end
 e.click(r.mouse.buttons.close.button);r:hide();T.eq(u.visible,false);T.eq(e.controller.bShowMouseCursor,false)
 e.restore()
end)
T.test('every trainer tab remains inside 720p and the wider screen in both languages',function()
 local View=require('TrainerView')
 local u=UI.new{read=function() return {canApply=true,values={gold={value=9999999}}} end}
 for _,language in ipairs({'zh-CN','en-US'}) do
  L.setCulture(language)
  for _,size in ipairs({{1280,720},{1024,768}}) do
   for _,section in ipairs({'resources','character','weapons','magic','jokers','settings'}) do
    u.visible=true;u:action('section',section)
    local scene=View.layout(u:model(),{width=size[1],height=size[2],dpiScale=1})
    for _,c in ipairs(scene.commands) do
     T.eq(c.x>=0 and c.y>=0 and c.width>0 and c.height>0,true)
     T.eq(c.x+c.width<=scene.width+.1 and c.y+c.height<=scene.height+.1,true,section..':'..tostring(c.id))
     if c.kind=='button' then T.eq(c.height>=32,true) end
    end
   end
  end
 end
 L.setCulture('zh-CN')
end)
T.finish()
