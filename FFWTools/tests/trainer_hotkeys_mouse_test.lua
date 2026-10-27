package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib')
local UI=require('TrainerUI')
T.test('F2 opens the trainer rather than the last F4 Joker page',function()
 local ui=UI.new{read=function() return {values={}} end}
 ui:toggle('jokers');ui:toggle('jokers');T.eq(ui.visible,false)
 ui:toggle();T.eq(ui.visible,true);T.eq(ui.section,'resources')
 ui:toggle();T.eq(ui.visible,false)
end)
T.test('F2 returns from F4 to the last normal category then closes that panel',function()
 local ui=UI.new{read=function() return {values={}} end}
 ui:toggle('weapons');ui:toggle('jokers');T.eq(ui.section,'jokers')
 ui:toggle();T.eq(ui.visible,true);T.eq(ui.section,'weapons')
 ui:toggle();T.eq(ui.visible,false)
 ui:toggle();T.eq(ui.section,'weapons');T.eq(ui.visible,true)
end)
T.test('a visible cursor still needs UI input routing when opening the trainer',function()
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local ok,err=pcall(function()
  e.controller.bShowMouseCursor=true
  local Mouse=dofile('FFWTools/src/FFWTrainer/Scripts/MousePanel.lua')
  local panel=Mouse.new{host=e.object('Host'),root=e.object('Canvas'),tree=e.object('Tree'),font=e.object('Font'),
   controller=e.controller,library=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary')}
  panel:show();T.eq(e.modes[#e.modes] and e.modes[#e.modes].mode,'gameAndUI')
  local calls=#e.modes;panel:show();T.eq(#e.modes,calls,'refresh must preserve text-editing focus')
  panel:hide();T.eq(e.controller.bShowMouseCursor,true,'the original cursor state is retained')
  T.eq(e.modes[#e.modes].mode,'gameOnly','no native menu was open, so restore gameplay input')
  panel:dispose()
 end)
 e.restore();if not ok then error(err,0) end
end)
T.test('closing the trainer preserves an already-open native menu',function()
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local ok,err=pcall(function()
  e.controller.bShowMouseCursor=true;e.controller.Pawn.refBpMenu.isMenuOpened=true
  local Mouse=dofile('FFWTools/src/FFWTrainer/Scripts/MousePanel.lua')
  local panel=Mouse.new{host=e.object('Host'),root=e.object('Canvas'),tree=e.object('Tree'),font=e.object('Font'),
   controller=e.controller,library=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary')}
  panel:show();panel:hide()
  T.eq(e.controller.bShowMouseCursor,true);T.eq(e.controller.Pawn.refBpMenu.isUiMode,true)
  T.eq(e.modes[#e.modes].mode,'viewportFocus');panel:dispose()
 end)
 e.restore();if not ok then error(err,0) end
end)
T.finish()
