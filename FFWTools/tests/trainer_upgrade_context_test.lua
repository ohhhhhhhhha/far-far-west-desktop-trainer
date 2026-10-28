package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib')
local function obj(address)return {IsValid=function()return true end,GetAddress=function()return address end,GetFullName=function()return 'Object' end}end
local world=obj(1);local pc=obj(2);pc.Pawn=obj(3);function pc.Pawn:GetFullName()return 'BP_Player_Lobby_C /Game/Levels/L_Lobby.L_Lobby:Player'end
function pc:IsLocalPlayerController()return true end;function pc:GetWorld()return world end
local oldWorld=world;local ui=obj(4);local touches=0
function ui:GetWorld()return oldWorld end;function ui:GetOwningPlayer()touches=touches+1;return pc end;function ui:IsVisible()return true end
ui.bufferNewTweaks={ForEach=function(_,f)f('x',20)end};ui.maxUpgradesAvailable=20;ui.amountAvailableUpgrades=20
ui.UpgradesAvailableMax=obj(5);function ui.UpgradesAvailableMax:SetText()touches=touches+1 end
local jobs={};ExecuteAsync=function(f)jobs[#jobs+1]=f end;StaticFindObject=function()return obj(6)end
RegisterHook=function()return 1,1 end;UnregisterHook=function()end;FindAllOf=function()return {ui}end;FText=function(s)return s end
T.test('upgrade unlock discards old-world records before restoring or patching UI',function()
 local u=require('UpgradeLimit').new{getController=function()return pc end}
 u:setEnabled(true);for _,f in ipairs(jobs)do f()end;jobs={};u:tick();T.eq(ui.amountAvailableUpgrades,-1)
 touches=0;world=obj(7);u:tick();u:setEnabled(false)
 T.eq(touches,0,'old GetOwningPlayer/SetText must not run after the context changes');T.eq(next(u.records),nil)
 u:stop()
end)
T.finish()
