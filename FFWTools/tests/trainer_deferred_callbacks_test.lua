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
local generated={};local directGranted=0
function ps:F_AddJokerRuntime_Server(id,showUI,heal) directGranted=directGranted+1;eq(id.fname,'jokerLightWeight');eq(showUI,true);eq(heal,true) end
function ps:F_SpawnJoker_Server(_,_,id,dropped) generated[#generated+1]={id=id.fname,dropped=dropped} end
local controller=obj('BP_PlayerController_C Local');controller.PlayerState=ps;controller.Pawn=pawn
controller.bShowMouseCursor=false
function controller:IsLocalPlayerController() return true end
local progress={selectedItemA_207_DB75D0B645F36A6C80EA10BC4BCAA457='itemLongRanger',selectedItemB_208_5EFA92804322145CAD0049B5E0A8B48D='itemPistol',
    itemJokers_221_B68401A4476969C408297F9FD92F3128=collection({itemHero={jokers_13_7822C195413EA2810E969F8C260AA8B6=collection({'jokerLightWeight','jokerLightWeight'})}}),
    itemsUpgrades_216_1E448EF04C663CC03DC815A885A3CB74=collection({})}
local reportedController=controller
package.preload.UEHelpers=function() return {GetPlayerController=function() return reportedController end,
    GetGameInstance=function() return {playerProgress=progress,refChallengeManager=obj('BP_ChallengeManager_C Ready')} end} end
-- Keep real private module loading, card preview, spawn and JSON protocol.
-- Replace only native progression (covered by trainer_progress_test) and IO.
local realLoad=loadfile
local files,applied,limitCalls={},0,0
local progressBackend={
    entries=function() return {{id='gold',type='resource',category='resource',nameZh='金币',nameEn='Gold',min=0,max=9999999},
        {id='itemIceLevel',type='level',category='magic',nameZh='冰霜魔法等级',nameEn='Frost magic level',min=1,max=100}} end,
    read=function() return {canApply=true,values={gold={value=5,raw=5}},messageZh='就绪',messageEn='Ready'} end,
    apply=function(id,value) applied=applied+1;eq(id,'gold');eq(value,'6');return true,'已请求保存',{messageEn='Save requested.'} end}
local limit={enabled=false}
function limit:tick() end
function limit:stop() self.enabled=false end
function limit:status() return {enabled=self.enabled,active=self.enabled,messageZh='额度开关',messageEn='Budget switch'} end
function limit:setEnabled(value) limitCalls=limitCalls+1;self.enabled=value;return true,'完成','Done' end
loadfile=function(path,mode,env)
    if path:match('/CanvasView%.lua$') then return function() return {new=function(options)
        local r={inputs={},values={},attached=false,getController=options.getController}
        function r:render(m)
            self.attached=m~=nil;self.model=m
            if m then
                for _,id in ipairs({'target','query'}) do
                    local key=id=='target' and m.inputKey or m.queryKey
                    if not self.inputs[id] or self.inputs[id].resetKey~=key then
                        self.values[id]=id=='target' and m.inputValue or m.query;self.inputs[id]={resetKey=key}
                    end
                end
            end
        end
        function r:input(id) return self.values[id] end
        function r:hide() self.attached=false end
        return r
    end} end end
    if path:match('/Progress%.lua$') then return function() return progressBackend end end
    if path:match('/UpgradeLimit%.lua$') then return function() return {new=function() return limit end} end end
    local chunk,err=realLoad(path,mode,env)
    if chunk and path:match('/Bridge%.lua$') then return function()
        local b=chunk();b.readFile=function(p) return files[p:match('([^/]+)$')] end
        b.writeFile=function(p,text) files[p:match('([^/]+)$')]=text;return true end
        return b
    end end
    return chunk,err
end
StaticFindObject=function() return nil end
local mod=dofile(arg[1] or 'FFWTools/src/FFWTrainer/Scripts/main.lua')
local Json=dofile('FFWTools/src/FFWTrainer/Scripts/Json.lua')
eq(type(keys[Key.F2]),'function');eq(type(keys[Key.F4]),'function')
eq(controller.bShowMouseCursor,false,'closed trainer leaves input alone')
eq(applied,0);eq(#generated,0);eq(limitCalls,0)
local refresh=mod.Locale.refresh;local cultureCalls=0
mod.Locale.refresh=function()cultureCalls=cultureCalls+1 end
now=now+1;mod.update();eq(cultureCalls,0,'closed trainer must not poll a native language UFunction')
mod.Locale.refresh=refresh
files['client.json']=Json.encode{protocol=1,clientId='legacy',updatedAt=now}
files['command.json']=Json.encode{action='spawn',payload={id='jokerLightWeight'}}
mod.update();eq(files['state.json'],nil);eq(#generated,0,'desktop requests are inert')
local remote=obj('BP_PlayerController_C Remote');function remote:IsLocalPlayerController() return false end
reportedController=remote;FindAllOf=function(kind) if kind=='PlayerController' then return {remote,controller} end;return {} end
eq(mod.renderer.getController(),controller,'the panel must use the local controller even if UEHelpers returns a remote one')
keys[Key.F4]();eq(mod.visible,true)
mod.renderer.values.query='LightWeight';mod.update()
eq(mod.ui:model().selected.id,'jokerLightWeight')
eq(mod.ui:model().detail:find('1.15 → 1.1',1,true)~=nil,true,'real pickup prediction')
mod.Locale.setCulture('en-US');eq(mod.ui:model().detail:find('Gravity',1,true)~=nil,true);mod.Locale.setCulture('zh-CN')
keys[Key.F3]();eq(#generated,1);eq(generated[1].id,'jokerLightWeight');eq(generated[1].dropped,true)
mod.update();eq(#generated,1,'refresh does not repeat spawn')
keys[Key.F3]();eq(#generated,1,'two-second throttle retained')
now=now+3;keys[Key.F3]();eq(#generated,2)
mod.action('section','settings');mod.action('spawnMode','direct')
eq(Json.decode(files['settings.json']).spawnMode,'direct');eq(Json.decode(files['settings.json']).unlimited,false)
mod.action('section','jokers');now=now+3;keys[Key.F3]();eq(directGranted,1);eq(#generated,2)
mod.action('section','resources');mod.renderer.values.target='6';keys[Key.F1]();eq(applied,1)
mod.update();eq(applied,1,'refresh does not save')
mod.action('section','settings');mod.action('unlimited');eq(limit.enabled,true);eq(limitCalls,1)
eq(Json.decode(files['settings.json']).unlimited,true)
keys[Key.F7]();eq(mod.visible,false);keys[Key.F1]();keys[Key.F3]();eq(applied,1);eq(#generated,2)
keys[Key.F4]();mod.renderer.values.query='UpgradeDamage';mod.update();keys[Key.F3]();eq(#generated,2)
pawn.GetFullName=function() return 'BP_Player_Lobby_C /Game/Levels/L_Lobby.L_Lobby:PersistentLevel.Local' end
now=now+3;mod.renderer.values.query='LightWeight';mod.update();keys[Key.F3]();eq(#generated,2);eq(mod.ui:model().canSpawn,false)
mod.stop();eq(mod.enabled,false);eq(limit.enabled,false);eq(mod.errors,0)
keys={};local reloaded=dofile(arg[1] or 'FFWTools/src/FFWTrainer/Scripts/main.lua')
eq(reloaded.ui.spawnMode,'direct','saved mode restored on startup');eq(limitCalls,1,'settings wait for the game thread');reloaded.update();eq(limitCalls,2);eq(limit.enabled,true)
eq(applied,1);reloaded.stop();
-- Delayed game-thread work must not turn a burst of key presses into a spawn backlog.
keys={};pawn.GetFullName=function() return 'BP_Player_C /Game/Levels/L_Map_FarWest.L_Map_FarWest:PersistentLevel.Player' end
local queuedMod=dofile(arg[1] or 'FFWTools/src/FFWTrainer/Scripts/main.lua')
keys[Key.F2]();queuedMod.action('section','settings');queuedMod.action('spawnMode','ground');eq(Json.decode(files['settings.json']).unlimited,true,'mode changes preserve the saved budget toggle before its first restore tick');keys[Key.F4]()
local queue={};ExecuteInGameThread=function(fn) queue[#queue+1]=fn end
local before=#generated
for i=1,100 do keys[Key.F3]() end
for _,fn in ipairs(queue) do now=now+3;fn() end
eq(#generated-before,1,'a lagged burst of spawn key presses must not become a backlog of actors')
eq(queuedMod.errors,0,'queued input must not cause renderer errors')
queue={};keys[Key.F3]();queuedMod.ui:select('jokerMindShot')
for _,fn in ipairs(queue) do now=now+3;fn() end
eq(#generated-before,1,'a delayed spawn must not use a different card selected later')
queue={};keys[Key.F3]();queuedMod.renderer.values.query='LightWeight'
for _,fn in ipairs(queue) do now=now+3;fn() end
eq(#generated-before,1,'editing the search before a queued spawn must not substitute another card')
queue={};keys[Key.F3]();queuedMod.ui.spawnMode='direct'
for _,fn in ipairs(queue) do now=now+3;fn() end
eq(directGranted,1,'changing mode cancels an already queued request');eq(#generated-before,1)
queuedMod.ui.spawnMode='ground'
-- The renderer's input lease can change after a click is queued and before the
-- game thread runs it. Test the actual action backend, with native ownership at
-- this boundary supplied explicitly rather than assuming immediate scheduling.
local source={active=true,current=true,owner=true}
function source:isCurrent(pc) eq(pc,controller);return self.current end
function source:ownsInput() return self.owner end
queuedMod.renderer.mouse=source
queuedMod.renderer.options={getController=function() return controller end}
queue={};keys[Key.F3]();source.current=false
for _,fn in ipairs(queue) do now=now+3;fn() end
eq(#generated-before,1,'travel after dispatch cancels the old click before native spawning')
source.current=true;queue={};keys[Key.F3]();source.owner=false
for _,fn in ipairs(queue) do now=now+3;fn() end
eq(#generated-before,1,'a different overlay taking input cancels the pending click')
source.owner=true;queue={};keys[Key.F3]();queuedMod.stop()
for _,fn in ipairs(queue) do now=now+3;fn() end
eq(#generated-before,1,'stopping the trainer cancels pending spawn input')
ExecuteInGameThread=function(fn)fn()end
keys={};local dead=dofile(arg[1] or 'FFWTools/src/FFWTrainer/Scripts/main.lua')
keys[Key.F2]();local q={};ExecuteInGameThread=function(fn)q[#q+1]=fn end
local reads=0;dead.renderer.input=function()reads=reads+1;error('post-stop input')end
keys[Key.F5]();keys[Key.F4]();dead.stop()
for _,fn in ipairs(q)do fn()end
eq(reads,0,'stop cancels queued input readers');eq(dead.ui.visible,false,'stop cancels queued toggles');eq(dead.errors,0)
ExecuteInGameThread=function(fn)fn()end;loadfile=realLoad

print('joker_spawner_runtime_test: '..checks..' checks passed (in-game trainer)')
