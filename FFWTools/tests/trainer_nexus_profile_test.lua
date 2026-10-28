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
-- Uses the unmodified UEHelpers.lua and settings file from Nexus mod 2/file 242.
local ini=assert(io.open('/Nexus1183/UE4SS-settings.ini','rb'));local settings=ini:read('*a');ini:close()
eq(settings:find('DefaultExecuteInGameThreadMethod = EngineTick',1,true)~=nil,true)
eq(settings:find('HookEngineTick = 1',1,true)~=nil,true)
eq(settings:find('HookUObjectProcessEvent = 0',1,true)~=nil,true)
CreateInvalidObject=function()return {IsValid=function()return false end}end
for _,role in ipairs({'host','client'})do
 local c=fixture();local other=fixture()
 c.controller.Pawn=c.pawn;c.controller.PlayerState=c.playerState
 other.controller.Pawn=other.pawn;other.controller.PlayerState=other.playerState
 function c.controller:IsPlayerController()return true end
 function other.controller:IsPlayerController()return true end
 function other.controller:IsLocalPlayerController()return false end
 FindFirstOf=function(name)if name=='GameInstance'then return c.gameInstance end;return CreateInvalidObject()end
 FindAllOf=function(name)if name=='PlayerController'then return {other.controller,c.controller}end;return {}end
 package.loaded.UEHelpers=dofile('/Nexus1183/UEHelpers.lua')
 eq(package.loaded.UEHelpers.GetPlayerController(),other.controller,'actual framework helper can return the remote player first')
 local context=P.context();eq(context.controller,c.controller,role..' local controller');eq(context.playerState,c.playerState,role..' local state')
 c.playerDatas.IsValid=function()return true end;c.functionLibrary.IsValid=function()return true end
 StaticFindObject=function(path)
  local lib=path:find('BPFL_PlayerDatas',1,true) and c.playerDatas or c.functionLibrary
  return {IsValid=function()return true end,GetCDO=function()return lib end}
 end
 local read=P.read();eq(read.canApply,true)
 local ok,_,d=P.apply('gold','26');eq(ok,true);eq(d.after,26);eq(d.saveRequested,true);eq(d.savePrepared,true);eq(d.persisted,false)
 eq(raw(c,'moneyGold'),26);eq(other.gameInstance.saveCalls,0);eq(raw(other,'moneyGold'),25)
 ok,_,d=P.apply('itemIceLevel','60');eq(ok,true);eq(d.rawAfter,59000);eq(d.savePrepared,true);eq(raw(c,'itemIce'),59000)
end
print('trainer_nexus_profile_test: '..checks..' checks passed (real dependency Lua/config; simulated native save boundary)')
