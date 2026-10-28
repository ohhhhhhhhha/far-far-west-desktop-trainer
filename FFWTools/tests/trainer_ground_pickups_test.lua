package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local T=require('testlib');local S=require('Spawner');local L=require('Locale');L.setCulture('en-US')
local world={IsValid=function()return true end,GetAddress=function()return 1 end}
local function actor(name,x) return {IsValid=function()return true end,GetFullName=function()return name end,GetWorld=function()return world end,K2_GetActorLocation=function()return {X=x or 0,Y=0,Z=0}end,GetActorEnableCollision=function()return true end,isPlayerDropped=true} end
local pawn=actor('BP_Player_C /Game/Levels/L_Map_FarWest.L_Map_FarWest:PersistentLevel.Player');function pawn:GetActorForwardVector()return {X=1,Y=0,Z=0}end
local pc=actor('PC');function pc:IsLocalPlayerController()return true end
local ps=actor('PS');local calls=0;function ps:F_SpawnJoker_Server()calls=calls+1 end
local ctx={controller=pc,pawn=pawn,playerState=ps,gameInstance={refChallengeManager=actor('Manager')}}
FName=function(x)return x end
local drops={};for i=1,10 do drops[i]=actor('BP_Pickable_Joker_Dropped_C Drop'..i,150) end
FindAllOf=function(class)assert(class=='BP_Pickable_Joker_C');return drops end
T.test('a full nearby pile stops further native spawn requests',function()
 local ok,message=S.spawn('jokerLightWeight',ctx,100)
 T.eq(ok,false);T.eq(calls,0);T.eq(message:find('10',1,true)~=nil,true)
end)
T.test('collecting a card frees space; natural and far-away drops do not consume the nearby dropped-card budget',function()
 calls=0
 drops[1].GetActorEnableCollision=function()return false end
 T.eq(S.spawn('jokerLightWeight',ctx,102),true);T.eq(calls,1)
 drops[1]=actor('Natural',150);drops[1].isPlayerDropped=false
 drops[#drops+1]=actor('Far',10000)
 local other=actor('Other world',150);other.GetWorld=function()return {IsValid=function()return true end,GetAddress=function()return 2 end}end;drops[#drops+1]=other
 T.eq(S.spawn('jokerLightWeight',ctx,104),true);T.eq(calls,2)
end)
T.test('an unreadable pickup scan does not submit a blind spawn request',function()
 calls=0
 FindAllOf=function()error('scan failure')end
 local ok=S.spawn('jokerLightWeight',ctx,106);T.eq(ok,false);T.eq(calls,0)
end)
T.finish()
