local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local keys={}
local now=100;os.time=function() return now end
Key={F1=1,F2=2,F3=3,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function(key,modifier,callback)
    local k=callback and key..':shift' or key
    assert(not keys[k],'duplicate key');keys[k]=callback or modifier
end
LoopInGameThreadWithDelay=function() end
ExecuteInGameThread=function(fn) fn() end
FText=function(v) return v end;FName=function(v) return {fname=v} end
FindAllOf=function() return {} end
local function obj(full)
    return {IsValid=function() return true end,GetFullName=function() return full end}
end
local function collection(v) return {ForEach=function(_,fn) for k,x in pairs(v) do fn(k,x) end end} end
local pawn=obj('BP_Player_C /Game/Levels/L_Map_FarWest.L_Map_FarWest:PersistentLevel.Player')
local held=obj('BP_Item_LongRanger_C Current');held.itemName='itemLongRanger'
function held:F_GetItemDatas(out) out.isInitialized_21_672D123E4B1D7C80BBD86083F97E9324=true;out.currentMagazineAmmos_10_76E089514907BA2E4DDB1CA16CEC4B6B=6 end
function held:F_GetReloadSpeed(out) out.ReloadSpeed=1 end
pawn.buffGravity=0;pawn.AC_PlayerItems={equipedItem=held};pawn.CharacterMovement={GravityScale=1.15}
function pawn:K2_GetActorLocation() return {X=0,Y=0,Z=90} end
function pawn:GetActorForwardVector() return {X=1,Y=0,Z=0} end
function pawn:GetVelocity() return {X=0,Y=0,Z=0} end
function pawn:F_IsOnGround(_,out) out.OnGround=true end
function pawn:F_IsRunning(out) out.Running=false end
local ps=obj('BP_PlayerState_C Local');ps.AC_PlayerStateJoker={playerLocalJokers=collection({})}
local generated={}
function ps:F_SpawnJoker_Server(_,_,id,dropped) generated[#generated+1]={id=id.fname,dropped=dropped} end
local controller=obj('BP_PlayerController_C Local');controller.PlayerState=ps;controller.Pawn=pawn
controller.bShowMouseCursor=false
function controller:IsLocalPlayerController() return true end
local progress={selectedItemA_207_DB75D0B645F36A6C80EA10BC4BCAA457='itemLongRanger',selectedItemB_208_5EFA92804322145CAD0049B5E0A8B48D='itemPistol',
    itemJokers_221_B68401A4476969C408297F9FD92F3128=collection({itemHero={jokers_13_7822C195413EA2810E969F8C260AA8B6=collection({'jokerLightWeight','jokerLightWeight'})}}),
    itemsUpgrades_216_1E448EF04C663CC03DC815A885A3CB74=collection({})}
package.preload.UEHelpers=function() return {GetPlayerController=function() return controller end,
    GetGameInstance=function() return {playerProgress=progress,refChallengeManager=obj('BP_ChallengeManager_C Ready')} end} end
-- Keep real private module loading, card preview, spawn and JSON protocol.
-- Replace only native progression (covered by trainer_progress_test) and IO.
local realLoad=loadfile
local files,applied,limitCalls={},0,0
local progressBackend={
    entries=function() return {{id='gold',category='resource',nameZh='金币',nameEn='Gold',min=0,max=9999999},
        {id='itemIceLevel',category='magic',nameZh='冰霜魔法等级',nameEn='Frost magic level',min=1,max=100}} end,
    read=function() return {canApply=true,values={gold={value=5,raw=5}},messageZh='就绪',messageEn='Ready'} end,
    apply=function(id,value) applied=applied+1;eq(id,'gold');eq(value,'6');return true,'已请求保存',{messageEn='Save requested.'} end}
local limit={enabled=false}
function limit:tick() end
function limit:stop() self.enabled=false end
function limit:status() return {enabled=self.enabled,active=self.enabled,messageZh='额度开关',messageEn='Budget switch'} end
function limit:setEnabled(value) limitCalls=limitCalls+1;self.enabled=value;return true,'完成','Done' end
loadfile=function(path,mode,env)
    if path:match('/Progress%.lua$') then return function() return progressBackend end end
    if path:match('/UpgradeLimit%.lua$') then return function() return {new=function() return limit end} end end
    local chunk,err=realLoad(path,mode,env)
    if chunk and path:match('/Bridge%.lua$') then return function()
        local b=chunk()
        b.readFile=function(p) return files[p:match('([^/]+)$')] end
        b.writeFile=function(p,text) files[p:match('([^/]+)$')]=text;return true end
        return b
    end end
    return chunk,err
end
StaticFindObject=function() return nil end
local mod=dofile(arg[1] or 'FFWTools/src/FFWTrainer/Scripts/main.lua')
local Json=dofile('FFWTools/src/FFWTrainer/Scripts/Json.lua')
eq(next(keys),nil,'headless Trainer owns no game hotkeys')
eq(controller.bShowMouseCursor,false,'does not capture game input')
eq(applied,0);eq(#generated,0);eq(limitCalls,0,'startup does not enable or change progress')
mod.update();eq(files['state.json'],nil,'closed GUI causes no state publication')
files['client.json']=Json.encode{protocol=1,clientId='test',updatedAt=now,selectedCardId='jokerLightWeight'}
mod.update()
local function state() return Json.decode(files['state.json']) end
eq(state().canSpawn,true);eq(state().entries[2].category,'magic')
eq(state().entries[2].available,false);eq(state().entries[2].value,nil,'unknown magic is not zero')
eq(state().cardPreview.textZh:find('1.15 → 1.1',1,true)~=nil,true,'real pickup prediction')
eq(state().cardPreview.textEn:find('Gravity',1,true)~=nil,true,'bilingual prediction')
local function send(id,action,payload)
    files['command.json']=Json.encode{protocol=1,clientId='test',session=mod.bridge.session,
        requestId=id,createdAt=now,action=action,payload=payload}
    mod.update()
end
send('spawn-1','spawn',{id='jokerLightWeight'});eq(#generated,1);eq(generated[1].id,'jokerLightWeight');eq(generated[1].dropped,true)
eq(state().lastResult.messageEn:find('LIGHTWEIGHT',1,true)~=nil,true)
mod.update();eq(#generated,1,'polling acknowledged spawn does not repeat')
send('spawn-2','spawn',{id='jokerFightOrFlight'});eq(#generated,1,'native two-second throttle')
now=now+3;files['client.json']=Json.encode{protocol=1,clientId='test',updatedAt=now}
send('spawn-3','spawn',{id='jokerFightOrFlight'});eq(#generated,2)
send('save','setProgress',{id='gold',value='6'});eq(applied,1);mod.update();eq(applied,1)
send('toggle','setUnlimited',{enabled=true});eq(limit.enabled,true);eq(limitCalls,1)
eq(Json.decode(files['settings.json']).unlimited,true)
send('bad','setProgress',{id='gold',value=6});eq(applied,1,'invalid payload cannot reach native save')
send('replay','spawn',{id='jokerUpgradeDamage'});eq(#generated,2,'cannot spawn permanent upgrades')
pawn.GetFullName=function() return 'BP_Player_Lobby_C /Game/Levels/L_Lobby.L_Lobby:PersistentLevel.Local' end
now=now+3;files['client.json']=Json.encode{protocol=1,clientId='test',updatedAt=now}
send('lobby','spawn',{id='jokerLightWeight'});eq(state().canSpawn,false);eq(#generated,2)
eq(state().lastResult.success,false)
mod.stop();eq(mod.enabled,false);eq(limit.enabled,false)
eq(mod.errors,0)
files['client.json']=nil;files['command.json']=nil
local reloaded=dofile(arg[1] or 'FFWTools/src/FFWTrainer/Scripts/main.lua')
eq(limitCalls,1,'persisted toggle does not edit widgets from the loading thread')
reloaded.update();eq(limitCalls,2);eq(limit.enabled,true,'persisted toggle restores on game-thread tick')
eq(applied,1,'restoring a setting never saves progression')
reloaded.stop()
loadfile=realLoad
print('joker_spawner_runtime_test: '..checks..' checks passed (desktop bridge)')
