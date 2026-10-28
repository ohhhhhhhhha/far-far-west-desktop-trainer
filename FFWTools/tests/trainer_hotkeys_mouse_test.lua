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
T.test('an active panel acquires a late menu and recovers native cursor reset without stealing edit focus',function()
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local menu=e.controller.Pawn.refBpMenu;e.controller.Pawn.refBpMenu=nil
 local Mouse=dofile('FFWTools/src/FFWTrainer/Scripts/MousePanel.lua')
 local panel=Mouse.new{host=e.object('Host'),root=e.object('Canvas'),tree=e.object('Tree'),font=e.object('Font'),controller=e.controller,library=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary')}
 panel:show();local calls=#e.modes
 e.controller.Pawn.refBpMenu=menu;panel:show()
 T.eq(e.nativeRecentersMouse(),false,'late menu must not keep recentering the cursor')
 T.eq(#e.modes,calls,'normal refresh must not steal typing focus')
 menu.isUiMode=false;e.controller.bShowMouseCursor=false;panel:show()
 T.eq(e.nativeRecentersMouse(),false);T.eq(e.controller.bShowMouseCursor,true)
 T.eq(e.modes[#e.modes].mode,'gameAndUI')
 panel:hide();T.eq(menu.isUiMode,false);T.eq(e.controller.lookIgnores,0)
 panel:dispose();e.restore()
end)
T.test('closing before the next refresh preserves a native menu on the replacement pawn',function()
 local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
 local Mouse=dofile('FFWTools/src/FFWTrainer/Scripts/MousePanel.lua')
 local panel=Mouse.new{host=e.object('Host'),root=e.object('Canvas'),tree=e.object('Tree'),font=e.object('Font'),controller=e.controller,library=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary')}
 local original=e.controller.Pawn.refBpMenu;panel:show()
 local newMenu=e.object('Replacement native menu');newMenu.isUiMode=true;newMenu.isMenuOpened=true
 e.controller.Pawn=e.object('Replacement pawn');e.controller.Pawn.refBpMenu=newMenu
 panel:hide()
 T.eq(e.controller.bShowMouseCursor,true,'closing trainer must not hide the new native menu cursor')
 T.eq(e.modes[#e.modes].mode,'viewportFocus')
 T.eq(newMenu.isUiMode,true);T.eq(original.isUiMode,false);T.eq(e.controller.lookIgnores,0)
 panel:dispose();e.restore()
end)
T.finish()
