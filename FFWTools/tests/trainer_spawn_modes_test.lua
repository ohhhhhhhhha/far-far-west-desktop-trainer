package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib');local S=require('Spawner');local UI=require('TrainerUI');local L=require('Locale')
local function object(name)return {IsValid=function()return true end,GetFullName=function()return name end}end
local pawn=object('BP_Player_C /Game/Levels/L_Map_FarWest.L_Map_FarWest:PersistentLevel.Player')
function pawn:K2_GetActorLocation()error('direct mode must not spawn a ground actor')end
local pc=object('PC');function pc:IsLocalPlayerController()return true end
local ps=object('PS');local grants=0
FName=function(s)return {name=s}end
function ps:F_AddJokerRuntime_Server(id,showUI,heal)
 T.eq(id.name,'jokerLightWeight');T.eq(showUI,true);T.eq(heal,true);grants=grants+1
end
local ctx={controller=pc,pawn=pawn,playerState=ps,gameInstance={refChallengeManager=object('Manager')}}
FindAllOf=function()error('direct mode must not scan ground pickups')end
T.test('direct mode uses the normal acquisition event and shares its cooldown',function()
 L.setCulture('en-US');local ok,message,status=S.spawn('jokerLightWeight',ctx,100,'direct')
 T.eq(ok,true);T.eq(grants,1);T.eq(status.mode,'direct');T.eq(message:find('Direct',1,true)~=nil,true)
 T.eq(S.spawn('jokerLightWeight',ctx,101,'ground'),false);T.eq(grants,1)
 T.eq(S.spawn('jokerUpgradeDamage',ctx,102,'direct'),false)
 T.eq(S.spawn('jokerLightWeight',ctx,102,'unknown'),false)
end)
T.test('mode is a Settings choice and failed persistence leaves the existing choice active',function()
 local saved,modeSeen
 local ui=UI.new{read=function()return {values={}}end,setSpawnMode=function(mode)saved=mode;return true,'完成','Saved' end,spawn=function(id,context,now,mode)modeSeen=mode;return true,nil,{cardId=id,mode=mode}end}
 ui:toggle('settings');T.eq(ui:model().spawnMode,'ground')
 ui:action('spawnMode','direct');T.eq(saved,'direct');T.eq(ui:model().spawnMode,'direct')
 ui:action('section','jokers');ui:action('spawn');T.eq(modeSeen,'direct')
 ui:action('section','settings');ui.options.setSpawnMode=function()return false,'失败','Failed'end
 ui:action('spawnMode','ground');T.eq(ui:model().spawnMode,'direct')
 T.eq(ui:action('spawnMode','invalid'),false)
end)
T.finish()
