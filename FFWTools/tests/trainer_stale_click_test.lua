package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib')
T.test('old panel clicks cannot reach trainer actions after a local controller replacement',function()
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local Mouse=dofile('FFWTools/src/FFWTrainer/Scripts/MousePanel.lua')
 local actions=0
 local p=Mouse.new{host=e.object('Host'),root=e.object('Canvas'),tree=e.object('Tree'),font=e.object('Font'),
  controller=e.controller,getController=function() return e.controller end,
  library=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary'),onAction=function() actions=actions+1 end}
 p:button('spawn',{text='Spawn one',action='spawn',x=0,y=0,width=100,height=32});p:show()
 e.click(p.buttons.spawn.button);T.eq(actions,1)
 local old=e.controller;e.newController(false)
 T.eq(old:IsValid(),true,'seamless travel can leave the previous controller alive')
 e.click(p.buttons.spawn.button)
 local called=actions;p:dispose();e.restore()
 T.eq(called,1,'stale native click must not execute against the next world')
end)
T.test('panel survives repeated native clicks, close, widget collection and a new world',function()
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local methods=getmetatable(e.controller).__index
 for name,fn in pairs(methods) do
  if name~='IsValid' then methods[name]=function(self,...)
   assert(not self.destroyed,'native access on a collected widget: '..name)
   return fn(self,...)
  end end
 end
 local Canvas=dofile('FFWTools/src/FFWTrainer/Scripts/CanvasView.lua')
 local u=require('TrainerUI').new{read=function() return {values={gold={value=5}}} end}
 local r=Canvas.new{getController=function() return e.controller end,layout=require('TrainerView').layout,
  viewport=function() return {width=1280,height=720,dpiScale=1} end,onAction=function(a,v) u:action(a,v) end}
 u:toggle('resources');r:render(u:model())
 local constructed=e.constructed
 for i=1,100 do
  e.click(r.mouse.buttons.close.button);r:render(u:model())
  T.eq(e.controller.lookIgnores,0,'closing releases mouse capture')
  u:toggle('resources');r:render(u:model())
 end
 T.eq(e.constructed,constructed,'reopening reuses the existing widget tree')
 local function collect(o,seen)
  if not o or seen[o] then return end;seen[o]=true;o.destroyed=true
  collect(o.WidgetTree,seen);collect(o.RootWidget,seen);collect(o.Slot,seen)
  for _,child in ipairs(o.children or {}) do collect(child,seen) end
 end
 r:hide();collect(r.host,{})
 e.newController(false);r:render(u:model())
 e.click(r.mouse.buttons.close.button);r:render(u:model())
 T.eq(u.visible,false);T.eq(e.controller.lookIgnores,0)
 r.mouse:dispose();e.restore()
end)
T.test('all Joker previews remain usable with a large accumulated mission inventory',function()
 local Spawner=require('Spawner');local Inventory=require('Inventory')
 local entries=Spawner.entries();local runtime={}
 for _,card in ipairs(entries) do for i=1,100 do runtime[#runtime+1]=card.id end end
 local snapshot=Inventory.fromSnapshot{selected={primary='itemLongRanger',secondary='itemPistol'},
  equipped={},upgrades={},runtime=runtime,inputs={heldItemName='itemLongRanger',buffGravity=0}}
 local ui=require('TrainerUI').new{read=function() return {values={}} end,inventory=function() return snapshot end}
 ui:toggle('jokers')
 for _,card in ipairs(entries) do
  ui:select(card.id);local model=ui:model()
  T.eq(model.selected.id,card.id)
  T.eq(type(model.detail),'string');T.eq(#model.detail>0,true)
 end
 ui:action('section','resources');T.eq(ui:model().selected.id,'gold')
end)
T.finish()
