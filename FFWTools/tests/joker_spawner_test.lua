package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;'..package.path
package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;'..package.path
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local loaded,Spawner=pcall(require,'Spawner')
assert(loaded,'specified-card spawner is not implemented: '..tostring(Spawner))
local I=require('Inventory')
local s=I.fromSnapshot({selected={primary='itemLongRanger',secondary='itemPistol'},
    equipped={itemHero={'jokerLightWeight','jokerLightWeight'}},upgrades={},runtime={},
    inputs={buffGravity=0,heldItemName='itemLongRanger',currentGravityScale=1.15}})
local entries=Spawner.entries()
local seen={}
for _,card in ipairs(entries) do
    eq(card.enabled,true);eq(card.id:lower():find('jokerupgrade',1,true),nil)
    eq(seen[card.id],nil);seen[card.id]=true
end
eq(seen.jokerLightWeight,true);eq(seen.jokerMindShot,true)
local page=Spawner.page(s)
eq(page.selected.id,'jokerLightWeight','default selection makes the reported gravity issue quick to reproduce')
eq(page.detail:find('1.15 → 1.1',1,true)~=nil,true,'test menu shows real pickup prediction')
eq(page.detail:find('获得后 3 张',1,true),nil)
local empty=I.fromSnapshot({selected={},equipped={},upgrades={},runtime={}})
local mindShotIndex
for index,card in ipairs(entries) do if card.id=='jokerMindShot' then mindShotIndex=index end end
local notApplicable=Spawner.page(empty,mindShotIndex)
eq(notApplicable.detail:find('当前装备不适用',1,true)~=nil,true)

local function obj(full)
    return {IsValid=function() return true end,GetFullName=function() return full end}
end
local pawn=obj('BP_Player_C /Game/Levels/L_Map_FarWest.L_Map_FarWest:PersistentLevel.Player')
function pawn:K2_GetActorLocation() return {X=1000,Y=2000,Z=300} end
function pawn:GetActorForwardVector() return {X=0,Y=1,Z=0} end
local controller=obj('BP_PlayerController_C Local')
function controller:IsLocalPlayerController() return true end
local ps=obj('BP_PlayerState_C Local');local calls={}
FName=function(value) return {fname=value} end
function ps:F_SpawnJoker_Server(location,rarity,id,dropped)
    assert(type(id)=='table' and type(id.fname)=='string','native boundary requires FName, not a Lua string')
    calls[#calls+1]={location=location,rarity=rarity,id=id.fname,dropped=dropped}
end
local ctx={controller=controller,pawn=pawn,playerState=ps,
    gameInstance={refChallengeManager=obj('BP_ChallengeManager_C Ready')}}
local success,message=Spawner.spawn('jokerLightWeight',ctx,100)
eq(success,true,message);eq(#calls,1)
eq(calls[1].id,'jokerLightWeight');eq(calls[1].rarity,0);eq(calls[1].dropped,true)
eq(calls[1].location.X,1000);eq(calls[1].location.Y,2150);eq(calls[1].location.Z,270)
eq(Spawner.spawn('jokerLightWeight',ctx,101),false,'held/repeated key must not flood actors');eq(#calls,1)
eq(Spawner.spawn('jokerMindShot',ctx,102),true)
eq(#calls,2);eq(calls[2].rarity,5,'NewEnumerator6 is native byte 5, not 6')
eq(Spawner.spawn('jokerCoinFlip',ctx,104),true)
eq(calls[3].rarity,4,'NewEnumerator5 is native byte 4')
eq(Spawner.spawn('jokerUpgradeDamage',ctx,106),false,'permanent upgrade is not a collectible')
eq(Spawner.spawn('not_a_card',ctx,106),false);eq(#calls,3)
ctx.pawn=obj('BP_Player_C /Game/Levels/L_Lobby.L_Lobby:PersistentLevel.Player')
eq(Spawner.spawn('jokerLightWeight',ctx,106),false,'lobby lacks pickup initialization support');eq(#calls,3)
ctx.pawn=pawn;ctx.gameInstance.refChallengeManager=nil
eq(Spawner.spawn('jokerLightWeight',ctx,106),false,'challenge manager must be ready');eq(#calls,3)
ctx.gameInstance.refChallengeManager=obj('BP_ChallengeManager_C Ready')
function controller:IsLocalPlayerController() return false end
eq(Spawner.spawn('jokerLightWeight',ctx,106),false,'cannot use a remote player controller');eq(#calls,3)
ctx.controller=nil
eq(Spawner.spawn('jokerLightWeight',ctx,106),false,'missing local player is a normal unavailable state');eq(#calls,3)
eq(#s.equipped.itemHero,2,'preview and spawning do not directly grant a card')
eq(#s.runtime,0)
print('joker_spawner_test: '..checks..' checks passed')
