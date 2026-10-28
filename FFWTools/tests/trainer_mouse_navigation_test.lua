package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib');local UI=require('TrainerUI');local Canvas=require('CanvasView');local View=require('TrainerView');local L=require('Locale')
local function run(fn)
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local queue,actions={},{};local writes=0
 local ui=UI.new{read=function()return {canApply=true,values={gold={value=10}}}end,apply=function()writes=writes+1 end}
 local vp={width=1280,height=720,dpiScale=1};local renderer
 renderer=Canvas.new{getController=function()return e.controller end,viewport=function()return vp end,layout=View.layout,
  onAction=function(action,value)queue[#queue+1]=function()actions[#actions+1]=action;ui:action(action,value);renderer:render(ui:model())end end}
 local function click(id)
  e.click(assert(renderer.mouse.buttons[id],id).button)
  local pending=queue;queue={};for _,callback in ipairs(pending)do callback()end
 end
 ui:toggle('resources');renderer:render(ui:model())
 local ok,err=pcall(fn,e,ui,renderer,click,vp,actions)
 renderer:hide();if renderer.mouse then renderer.mouse:dispose()end
 T.eq(writes,0,'navigation never applies progress');e.restore();L.setCulture('zh-CN')
 if not ok then error(err,0)end
end
T.test('native mouse categories, paging and reused rows select the visible weapon in both languages',function()
 for _,language in ipairs({'zh-CN','en-US'})do
  L.setCulture(language)
  run(function(e,ui,r,click)
   click('section-weapons');T.eq(ui.section,'weapons');T.eq(ui.selectedId,'itemPistolLevel')
   click('nextPage');T.eq(ui.page,2);T.eq(ui.selectedId,'itemBanjoLevel')
   click('row-3');T.eq(ui.selectedId,'itemDualRevolverLevel')
   click('previousPage');T.eq(ui.page,1);click('row-4');T.eq(ui.selectedId,'itemLongRangerLevel')
   click('close');T.eq(ui.visible,false);T.eq(e.controller.lookIgnores,0);T.eq(e.controller.bShowMouseCursor,false)
  end)
 end
end)
T.test('search hides unused native rows and disabled paging cannot dispatch an action',function()
 run(function(e,ui,r,click,vp,actions)
  click('section-weapons');click('nextPage')
  ui:setQuery('DUAL');r:render(ui:model());T.eq(ui.selectedId,'itemDualRevolverLevel')
  local before=#actions
  click('row-2');click('nextPage');click('previousPage')
  T.eq(#actions,before,'hidden or disabled native controls must not act')
  T.eq(ui.selectedId,'itemDualRevolverLevel')
  click('row-1');T.eq(#actions,before+1);T.eq(ui.selectedId,'itemDualRevolverLevel')
 end)
end)
T.test('resizing updates existing mouse hitboxes at the viewport DPI without re-registering input',function()
 run(function(e,ui,r,click,vp)
  click('section-weapons');local close=r.mouse.buttons.close;local modes=#e.modes
  vp.width=1024;vp.height=768;vp.dpiScale=1.5;r:render(ui:model())
  T.eq(r.mouse.buttons.close,close,'native controls are reused')
  T.eq(math.abs(close.slot.position.X-860/1.5)<1e-6,true)
  T.eq(math.abs(close.slot.size.X-92/1.5)<1e-6,true)
  T.eq(#e.modes,modes,'resize must not steal current input focus')
  click('nextPage');T.eq(ui.page,2);click('row-3');T.eq(ui.selectedId,'itemDualRevolverLevel')
 end)
end)
T.finish()
