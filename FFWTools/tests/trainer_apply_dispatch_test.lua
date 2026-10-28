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
local rawPrint=print;local logs={}
print=function(...)for _,v in ipairs({...})do logs[#logs+1]=tostring(v)end;rawPrint(...)end
local mod=dofile('FFWTools/src/FFWTrainer/Scripts/main.lua')
keys[Key.F2]()
mod.ui.target='6';mod.renderer.values.target='900'
local normalInput=mod.renderer.input
mod.renderer.input=function(self,id)if id=='target'then return nil,'/Example Library/CanvasView.lua:99: native GetText failed' end;return normalInput(self,id)end
keys[Key.F1]()
eq(applied,0,'failed input read must never apply the previous target')
eq(mod.ui:model().success,false,'the panel must show an actionable input failure')
eq(mod.lastApplyResult.stage,'input');eq(mod.lastApplyResult.reasonCode,'input_unavailable')
local count=#logs;keys[Key.F1]();eq(applied,0);eq(#logs,count,'same input failure is logged once')
for _,line in ipairs(logs)do eq(line:find('/Example Library/',1,true),nil,'diagnostics omit absolute source path');eq(line:find('900',1,true),nil,'diagnostics omit the entered target value')end
mod.renderer.input=normalInput;mod.renderer.values.target='6';keys[Key.F1]()
eq(applied,1,'a later valid input can apply normally');eq(mod.lastApplyResult.success,true)
progressBackend.apply=function()return false,'原生读取失败',{messageEn='Native read failed.',stage='nativeRead',reasonCode='native_call_failed',changed=false}end
mod.ui.options.apply=progressBackend.apply
mod.Locale.setCulture('en-US');keys[Key.F1]()
eq(mod.ui:model().message:find('nativeRead/native_call_failed',1,true)~=nil,true,'visible result identifies the failed native stage')
mod.stop();loadfile=realLoad;print=rawPrint
print('trainer_apply_dispatch_test: '..checks..' checks passed')
