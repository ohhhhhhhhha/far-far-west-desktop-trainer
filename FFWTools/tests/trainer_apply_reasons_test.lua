package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;'..package.path
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local loaded,P=pcall(require,'Progress')
assert(loaded,'trainer progress backend is not implemented: '..tostring(P))
local F=P.fields
local function obj(full)
    return {IsValid=function() return true end,GetFullName=function() return full end}
end
FName=function(s) return {ToString=function() return s end} end
local function fname(s) return type(s)=='string' and s or s:ToString() end
local function remote(v) return {get=function() return v end} end
local function array(rows)
    local t={rows=rows}
    function t:ForEach(fn) for i,v in ipairs(self.rows) do fn(i,remote(v)) end end
    return t
end
local function row(id,n) return {[F.name]=FName(id),[F.amount]=n} end
local function copied(rows)
    local result={}
    for _,v in ipairs(rows) do result[#result+1]=row(fname(v[F.name]),v[F.amount]) end
    return result
end
local function fixture()
    local ctx={}
    ctx.controller=obj('BP_PlayerController_C Local')
    function ctx.controller:IsLocalPlayerController() return true end
    ctx.pawn=obj('BP_Player_C /Game/Levels/L_Lobby.L_Lobby:PersistentLevel.Player')
    ctx.playerState=obj('BP_PlayerState_C Local')
    local inventory=array({row('moneyGold',25),row('moneySoul',13),row('moneyBlueprint',8),
        row('itemHero',4500),row('itemPistol',1750),row('itemPistolLvl',77),row('someUnknownFutureKey',123)})
    local saved=obj('SG_PlayerProgress_C Local')
    saved.playerProgress={[F.version]=9,[F.inventory]=array(copied(inventory.rows))}
    ctx.gameInstance=obj('BP_CanyonGameInstance_C Local')
    local gi=ctx.gameInstance
    gi.playerProgress={[F.version]=9,[F.inventory]=inventory,unrelated='untouched'}
    gi.requiredProgressVersion=9;gi.SG_PlayerProgress=saved;gi.PlayerId='local-test-slot';gi.isGameTime=false
    gi.saveCalls=0
    function gi:F_ForceSave()
        self.saveCalls=self.saveCalls+1
        local a=self.playerProgress[F.inventory]
        self.SG_PlayerProgress.playerProgress={[F.version]=9,[F.inventory]=array(copied(a.rows or a))}
    end
    ctx.playerDatas={calls=0}
    function ctx.playerDatas:F_GetAmountFromInventory(progress,key,world,amount,contains)
        assert(type(progress)=='table' and progress[F.inventory],'UE4SS non-const struct reference requires an out table')
        assert(type(key)=='table' and key.ToString,'native FName required')
        assert(world==gi,'native world context')
        assert(type(amount)=='table' and type(contains)=='table','native outputs require tables')
        self.calls=self.calls+1
        local a=progress[F.inventory];local value=0
        for _,v in ipairs(a.rows or a) do if fname(v[F.name]):lower()==fname(key):lower() then value=v[F.amount];break end end
        amount.amount=math.max(0,value);contains.contains=value>0
    end
    ctx.functionLibrary={}
    function ctx.functionLibrary:F_CalculateXpLevel(xp,world,level,required,remaining,percent)
        assert(world==gi and type(level)=='table' and type(required)=='table' and type(remaining)=='table' and type(percent)=='table')
        level.CurrentLevel=math.floor(xp/1000)+1;required.RequiredTotalXpForThisLevel=1000
        remaining.XpRequiredToCompleteLevel=1000-xp%1000;percent.CompletionPercentage=math.floor(xp%1000/10)
    end
    return ctx
end
local function raw(ctx,key)
    local a=ctx.gameInstance.playerProgress[F.inventory]
    for _,v in ipairs(a.rows or a) do if fname(v[F.name]):lower()==key:lower() then return v[F.amount] end end
end
local cases={
 {'not_saloon',function(c)c.pawn.GetFullName=function()return 'BP_Player_C /Game/Levels/L_Map_Desert.L_Map_Desert:Player'end end},
 {'not_local_player',function(c)c.controller.IsLocalPlayerController=function()return false end end},
 {'save_object_unavailable',function(c)c.gameInstance.SG_PlayerProgress=nil end},
 {'save_slot_unavailable',function(c)c.gameInstance.PlayerId=''end},
 {'save_version_unavailable',function(c)c.gameInstance.requiredProgressVersion=nil end},
 {'runtime_version_mismatch',function(c)c.gameInstance.playerProgress[F.version]=8 end},
 {'save_version_mismatch',function(c)c.gameInstance.SG_PlayerProgress.playerProgress[F.version]=8 end},
 {'save_api_unavailable',function(c)c.gameInstance.F_ForceSave=nil end},
}
for _,case in ipairs(cases)do
 local c=fixture();case[2](c);local state=P.read(c)
 eq(state.canApply,false);eq(state.reasonCode,case[1],'read reason identifies the failed gate')
 local ok,_,d=P.apply('gold','26',c)
 eq(ok,false);eq(d.stage,'ready');eq(d.reasonCode,case[1]);eq(d.changed,false);eq(c.gameInstance.saveCalls,0)
 eq(raw(c,'moneyGold'),25,'blocked checks never modify progress')
end
local c=fixture();c.playerDatas.F_GetAmountFromInventory=function()error('incompatible native getter')end
local ok,_,d=P.apply('gold','26',c);eq(ok,false);eq(d.stage,'nativeRead');eq(d.reasonCode,'native_call_failed');eq(c.gameInstance.saveCalls,0)
print('trainer_apply_reasons_test: '..checks..' checks passed')
