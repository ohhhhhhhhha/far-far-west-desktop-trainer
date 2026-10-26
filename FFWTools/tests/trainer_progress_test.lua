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
local entries,ids=P.entries(),{}
for _,e in ipairs(entries) do
    eq(ids[e.id],nil,'unique entry IDs');ids[e.id]=e
    eq(type(e.nameZh),'string');eq(type(e.nameEn),'string');eq(type(e.inventoryKey),'string')
end
eq(#entries,24,'three currencies, hero, fourteen weapons and six magic schools')
eq(ids.gold.category,'resource');eq(ids.heroLevel.category,'level')
eq(ids.itemPistolLevel.category,'level')
for _,key in ipairs({'itemAcid','itemElec','itemFire','itemVoodoo','itemCactus','itemIce'}) do
    local entry=ids[key..'Level']
    eq(type(entry),'table','magic school XP is selectable: '..key)
    eq(entry.inventoryKey,key);eq(entry.category,'magic');eq(entry.type,'level')
    eq(entry.min,1);eq(entry.max,100)
end
eq(ids.itemSpellFireBallLevel,nil,'individual spell ownership is not XP progression')
eq(ids.heroLevel.inventoryKey,'itemHero','current game consumes itemHero, not legacy itemHeroLvl')
eq(ids.itemPistolLevel.inventoryKey,'itemPistol');eq(ids.itemPistolLevel.max,100)
eq(P.levelForXp(0),1);eq(P.levelForXp(999),1);eq(P.levelForXp(1000),2)
eq(P.levelForXp(99999),100);eq(P.xpForLevel(1),1,'level one remains owned')
eq(P.xpForLevel(2),1000);eq(P.xpForLevel(100),99000)
for level=1,100 do eq(P.levelForXp(P.xpForLevel(level)),level,'level round trip') end
for _,bad in ipairs({'',' ','-1','1.1','1e3','0x10','1,000','nan','Infinity','10000000','999999999999999999'}) do
    eq(P.validate('gold',bad),nil,'bad resource input '..bad)
end
eq(P.validate('gold',' 123 '),123);eq(P.validate('gold','0'),0)
eq(P.validate('heroLevel','0'),nil);eq(P.validate('heroLevel','101'),nil)
eq(P.validate('heroLevel','100'),100);eq(P.validate('not-an-entry','1'),nil)
local ctx=fixture()
local s=P.read(ctx)
eq(s.available,true);eq(s.canApply,true);eq(s.values.gold.value,25);eq(s.values.heroLevel.value,5)
eq(s.values.itemPistolLevel.raw,1750);eq(s.values.itemPistolLevel.value,2)
eq(s.values.itemBowLevel.present,false);eq(s.values.itemBowLevel.value,1,'known absent XP is level one')
eq(ctx.gameInstance.saveCalls,0,'reads never save');eq(raw(ctx,'moneyGold'),25)
local ok,message,detail=P.apply('gold','1200',ctx)
eq(ok,true,message);eq(detail.before,25);eq(detail.after,1200);eq(detail.rawAfter,1200)
eq(detail.saveRequested,true);eq(detail.persisted,false,'request does not prove disk durability')
eq(type(detail.messageZh),'string');eq(type(detail.messageEn),'string')
eq(raw(ctx,'moneyGold'),1200);eq(raw(ctx,'moneySoul'),13);eq(raw(ctx,'moneyBlueprint'),8)
eq(raw(ctx,'itemHero'),4500);eq(raw(ctx,'someUnknownFutureKey'),123)
eq(ctx.gameInstance.playerProgress.unrelated,'untouched');eq(ctx.gameInstance.saveCalls,1)
eq(detail.savePrepared,true,'save object receives the edited runtime inventory')
local savedGold
ctx.gameInstance.SG_PlayerProgress.playerProgress[F.inventory]:ForEach(function(_,v)
    local r=v:get();if fname(r[F.name])=='moneyGold' then savedGold=r[F.amount] end
end)
eq(savedGold,1200)
eq(ctx.playerDatas.calls>=2,true,'native getters verify before and after')
ok,message,detail=P.apply('itemPistolLevel','100',ctx)
eq(ok,true,message);eq(raw(ctx,'itemPistol'),99000);eq(raw(ctx,'itemPistolLvl'),77,'legacy field untouched')
eq(detail.before,2);eq(detail.after,100);eq(detail.rawBefore,1750);eq(ctx.gameInstance.saveCalls,2)
eq(P.apply('itemPistolLevel','1',ctx),true);eq(raw(ctx,'itemPistol'),1)
eq(P.apply('itemBowLevel','12',ctx),true,'missing selected row can be appended')
eq(raw(ctx,'itemBow'),11000);eq(raw(ctx,'moneyGold'),1200);eq(raw(ctx,'someUnknownFutureKey'),123)
local beforeNoop=ctx.gameInstance.saveCalls
ok,message,detail=P.apply('gold','1200',ctx)
eq(ok,true);eq(detail.changed,false);eq(ctx.gameInstance.saveCalls,beforeNoop,'no unnecessary save')
eq(P.apply('gold','garbage',ctx),false);eq(P.apply('heroLevel','101',ctx),false)
eq(ctx.gameInstance.saveCalls,beforeNoop);eq(raw(ctx,'itemHero'),4500)
-- Observed failure: the real GI sets isGameTime=true five seconds after
-- startup, including while the local player is in the saloon.
local saloon=fixture()
saloon.pawn=obj('BP_Player_Lobby_C /Game/Levels/L_Lobby.L_Lobby:PersistentLevel.BP_Player_Lobby_C_123')
saloon.gameInstance.isGameTime=true
saloon.gameInstance.playerProgress[F.inventory].rows[8]=row('itemDualRevolver',3500)
local lobbyRead=P.read(saloon)
eq(lobbyRead.canApply,true,'saloon remains editable after the global startup timer begins')
eq(lobbyRead.values.itemDualRevolverLevel.value,4)
local changed,why,levelResult=P.apply('itemDualRevolverLevel','60',saloon)
eq(changed,true,why);eq(levelResult.before,4);eq(levelResult.after,60)
eq(raw(saloon,'itemDualRevolver'),59000);eq(levelResult.savePrepared,true)
eq(saloon.gameInstance.saveCalls,1,'valid saloon level edit reaches native save')
for _,test in ipairs({{'souls','moneySoul',13},{'blueprints','moneyBlueprint',8},{'heroLevel','itemHero',4500}}) do
    local c=fixture()
    local worked,why,d=P.apply(test[1],'12',c)
    eq(worked,true,why);eq(raw(c,'moneyGold'),25,'other resource untouched')
    eq(raw(c,test[2]),test[1]=='heroLevel' and 11000 or 12)
    eq(raw(c,'itemPistol'),1750);eq(c.gameInstance.playerProgress.unrelated,'untouched')
end
for _,breakContext in ipairs({
    function(c) c.controller=nil end,
    function(c) function c.controller:IsLocalPlayerController() return false end end,
    function(c) c.pawn=obj('BP_Player_C /Game/Levels/L_Map_FarWest.L_Map_FarWest:PersistentLevel.Player') end,
    function(c) c.pawn=obj('BP_Player_C /Game/Levels/L_Map_TitleScreen.L_Map_TitleScreen:PersistentLevel.Player') end,
    function(c) c.gameInstance.SG_PlayerProgress=nil end,
    function(c) c.gameInstance.PlayerId='' end,
    function(c) c.gameInstance.playerProgress[F.version]=8 end,
    function(c) c.gameInstance.SG_PlayerProgress.playerProgress=nil end,
}) do
    local c=fixture();breakContext(c)
    eq(P.apply('gold','100',c),false,'unready or wrong scene must not write')
    eq(raw(c,'moneyGold'),25);eq(c.gameInstance.saveCalls,0)
end
ctx=fixture();ctx.gameInstance.playerProgress[F.inventory]={ForEach=function() error('unreadable array') end}
s=P.read(ctx);eq(s.available,false);eq(s.values.gold,nil,'unreadable is not zero')
eq(P.apply('gold','100',ctx),false);eq(ctx.gameInstance.saveCalls,0)
ctx=fixture();ctx.gameInstance.playerProgress[F.inventory].rows[8]=row('MONEYGOLD',42)
eq(P.apply('gold','100',ctx),false,'duplicate target cannot be silently normalized')
eq(raw(ctx,'moneyGold'),25);eq(ctx.gameInstance.saveCalls,0)
ctx=fixture();ctx.playerDatas.F_GetAmountFromInventory=function() error('native getter unavailable') end
eq(P.apply('gold','100',ctx),false);eq(raw(ctx,'moneyGold'),25,'getter checked before writing')
ctx=fixture();ctx.functionLibrary.F_CalculateXpLevel=function(_,xp,world,level) level.CurrentLevel=99 end
eq(P.apply('heroLevel','10',ctx),false,'changed native formula rejected before writing')
eq(raw(ctx,'itemHero'),4500);eq(ctx.gameInstance.saveCalls,0)
ctx=fixture();local native=ctx.playerDatas.F_GetAmountFromInventory
function ctx.playerDatas:F_GetAmountFromInventory(progress,key,world,amount,contains)
    native(self,progress,key,world,amount,contains)
    if self.calls>1 then amount.amount=999 end
end
ok,message,detail=P.apply('gold','100',ctx)
eq(ok,false,'mismatched native readback cannot report success');eq(ctx.gameInstance.saveCalls,0)
eq(detail.persisted,false);eq(detail.changed,true)
ctx=fixture();function ctx.gameInstance:F_ForceSave() error('save failed') end
ok,message,detail=P.apply('gold','100',ctx)
eq(ok,false,'save exception must be visible');eq(detail.changed,true);eq(detail.saveRequested,false)
eq(detail.persisted,false);eq(detail.after,100)
ctx=fixture();function ctx.gameInstance:F_ForceSave() self.saveCalls=self.saveCalls+1 end
ok,message,detail=P.apply('gold','100',ctx)
eq(ok,false,'returning save call alone cannot confirm the save object was updated')
eq(detail.changed,true);eq(detail.saveRequested,true);eq(detail.savePrepared,false)
eq(detail.persisted,false)
-- Each magic school uses its own XP row; the similarly named individual spell
-- remains an ownership count and must never be edited by a school-level action.
for _,key in ipairs({'itemAcid','itemElec','itemFire','itemVoodoo','itemCactus','itemIce'}) do
    local c=fixture()
    local inventory=c.gameInstance.playerProgress[F.inventory].rows
    inventory[#inventory+1]=row(key,4500)
    inventory[#inventory+1]=row('itemSpellFireBall',1)
    eq(P.read(c).values[key..'Level'].value,5,'school display consumes XP')
    local worked,why,d=P.apply(key..'Level','60',c)
    eq(worked,true,why);eq(d.before,5);eq(d.after,60)
    eq(raw(c,key),59000);eq(raw(c,'itemSpellFireBall'),1)
    eq(raw(c,'itemHero'),4500);eq(raw(c,'itemPistol'),1750)
    eq(d.savePrepared,true);eq(c.gameInstance.saveCalls,1)
    eq(P.validate(key..'Level','101'),nil)
end
local magicAbsent=fixture()
eq(P.apply('itemIceLevel','12',magicAbsent),true,'an absent school XP row is appended explicitly')
eq(raw(magicAbsent,'itemIce'),11000);eq(raw(magicAbsent,'itemHero'),4500)
ctx=fixture();local source=ctx.gameInstance.playerProgress[F.inventory]
ctx.gameInstance.playerProgress[F.inventory]=setmetatable({}, {__index=function(_,k) if k=='ForEach' then return source.ForEach end;if k=='rows' then return source.rows end;return 'TrivialObject: 0' end})
eq(P.read(ctx).values.gold.value,25,'native wrappers are read without assuming Lua primitives')
print('trainer_progress_test: '..checks..' checks passed')
