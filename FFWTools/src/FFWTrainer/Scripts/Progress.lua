-- Persistent progress editing. Loading this module and read() never write or save.
-- apply() is the explicit user-action boundary and must run on the game thread.
local P={}
local F={
    inventory='runtimeInventory_225_2397F74E446B3491AB63C28E8D13ACEC',
    name='name_2_76A6ED884C1808D1663DD8B1AC4A7534',
    amount='amount_5_BCEA82214D7F817FDA90DF805AF0C332',
    version='versionId_80_0B83F15F4179F3ADD71C3C869047E125',
}
P.fields=F
local entries={
    {id='gold',nameZh='金币',nameEn='Gold',type='resource',inventoryKey='moneyGold',min=0,max=9999999},
    {id='souls',nameZh='灵魂',nameEn='Souls',type='resource',inventoryKey='moneySoul',min=0,max=9999999},
    {id='blueprints',nameZh='蓝图',nameEn='Blueprints',type='resource',inventoryKey='moneyBlueprint',min=0,max=9999999},
    {id='heroLevel',nameZh='角色等级',nameEn='Character level',type='level',inventoryKey='itemHero',min=1,max=100},
}
for _,w in ipairs({
    {'itemPistol','左轮手枪','Revolver'}, {'itemQuadCylinder','四筒枪','Quad Cylinder'},
    {'itemShotgun','霰弹枪','Shotgun'}, {'itemLongRanger','远程步枪','Long Ranger'},
    {'itemMinigun','加特林','Minigun'}, {'itemWinchester','杠杆步枪','Leveredge'},
    {'itemKnuckles','指虎','Knuckles'}, {'itemLasso','套索','Lasso'},
    {'itemBanjo','班卓琴','Banjo'}, {'itemBow','弓','Bow'},
    {'itemDualRevolver','双持左轮','Dual Revolvers'}, {'itemBoomerang','回旋镖','Boomerang'},
    {'itemSheriffStar','警长之星','Sheriff Star'}, {'itemJetpack','喷气背包','Jetpack'},
}) do
    entries[#entries+1]={id=w[1]..'Level',nameZh=w[2]..'等级',nameEn=w[3]..' level',
        type='level',inventoryKey=w[1],min=1,max=100}
end
-- UI_Equipment_Spell reads the selected school's itemName, then passes that
-- inventory amount through F_CalculateXpLevel. Individual itemSpell* rows are
-- spell ownership/unlocks, not levels. See magic-upgrade-limit-evidence.md.
for _,school in ipairs({
    {'itemAcid','酸蚀','Acid'}, {'itemElec','电击','Elec'},
    {'itemFire','火焰','Pyro'}, {'itemVoodoo','巫毒','Voodoo'},
    {'itemCactus','仙人掌','Cactus'}, {'itemIce','冰霜','Frost'},
}) do
    entries[#entries+1]={id=school[1]..'Level',nameZh=school[2]..'魔法等级',nameEn=school[3]..' magic level',
        category='magic',type='level',inventoryKey=school[1],min=1,max=100}
end
-- Halloween 2026: verified against the live cosmetic price tables and
-- runtime inventory keys. *Cauldron keys are deposited ritual state, not stock.
for _,resource in ipairs({
    {'hauntedCandles','幽灵蜡烛（活动代币）','Haunted candles','moneyHauntedCandle'},
    {'halloweenFeathers','万圣节羽毛','Halloween feathers','moneyHauntedFeather'},
    {'halloweenPumpkins','万圣节南瓜','Halloween pumpkins','moneyHauntedPumpkin'},
    {'halloweenSkulls','万圣节骷髅','Halloween skulls','moneyHauntedSkull'},
}) do
    entries[#entries+1]={id=resource[1],nameZh=resource[2],nameEn=resource[3],type='resource',
        inventoryKey=resource[4],min=0,max=9999999,event='halloween2026'}
end
local byId={}
for _,e in ipairs(entries) do e.category=e.category or e.type;byId[e.id]=e end
function P.entries() return entries end
local function usable(v) return v~=nil and not tostring(v):match('^TrivialObject:') end
local function unwrap(v)
    if not usable(v) then return nil end
    local t=type(v)
    if t=='number' or t=='string' or t=='boolean' then return v end
    if t=='table' and type(v.get)~='function' then return v end
    local ok,x=pcall(function() return v:get() end)
    return ok and usable(x) and x or v
end
local function field(o,k)
    if not usable(o) then return nil end
    local ok,v=pcall(function() return o[k] end)
    if ok and usable(v) then return unwrap(v) end
end
local function name(v)
    v=unwrap(v);if type(v)=='string' then return v end
    local ok,s=pcall(function() return v:ToString() end)
    if ok and type(s)=='string' then return s end
end
local function valid(o)
    local ok,result=pcall(function() return usable(o) and o:IsValid() end)
    return ok and result==true
end
local function integer(v) return type(v)=='number' and v==v and v%1==0 and math.abs(v)<=2147483647 end
local function out(t,key)
    for k,v in pairs(t) do if type(k)=='string' and k:lower()==key:lower() then return unwrap(v) end end
end
local function each(a,fn)
    if field(a,'ForEach') then a:ForEach(function(_,v) fn(unwrap(v)) end)
    elseif type(a)=='table' then for _,v in ipairs(a) do fn(unwrap(v)) end
    else error('Runtime inventory array is unavailable') end
end
local function rowsFrom(progress)
    local rows,index={},{}
    each(field(progress,F.inventory),function(value)
        local id,amount=name(field(value,F.name)),field(value,F.amount)
        assert(type(id)=='string' and id~='' and integer(amount),'Unreadable runtime inventory row')
        local row={name=id,amount=amount,reference=value}
        rows[#rows+1]=row
        local key=id:lower();index[key]=index[key] or {};index[key][#index[key]+1]=row
    end)
    return rows,index
end
local function stored(index,key)
    local found=index[key:lower()] or {}
    assert(#found<=1,'Duplicate inventory key: '..key)
    return found[1] and found[1].amount or 0,found[1]
end
function P.levelForXp(xp)
    if not integer(xp) or xp<0 then return nil end
    return math.floor(xp/1000)+1
end
function P.xpForLevel(level)
    if not integer(level) or level<1 or level>100 then return nil end
    -- A zero item amount is considered unowned by F_GetAmountFromInventory.
    return math.max(1,(level-1)*1000)
end
function P.validate(id,text)
    local entry=byId[id]
    if not entry then return nil,'请选择修改项目。','Select a progress entry.' end
    if type(text)~='string' and type(text)~='number' then return nil,'请输入整数。','Enter a whole number.' end
    local input=tostring(text):match('^%s*(.-)%s*$')
    if not input:match('^%d+$') then return nil,'请输入整数，不使用小数或符号。','Enter digits only, without decimals or symbols.' end
    local value=tonumber(input)
    if not integer(value) or value<entry.min or value>entry.max then
        return nil,'范围：'..entry.min..'–'..entry.max..'。','Range: '..entry.min..'–'..entry.max..'.'
    end
    return value
end
function P.context()
    local helpers=require('UEHelpers')
    local controller=helpers.GetPlayerController()
    local function localController(c)
        local ok,result=pcall(function() return valid(c) and c:IsLocalPlayerController() end)
        return ok and result==true
    end
    if not localController(controller) then
        controller=nil
        for _,candidate in ipairs(FindAllOf('PlayerController') or {}) do
            if localController(candidate) then controller=candidate;break end
        end
    end
    return {controller=controller,pawn=field(controller,'Pawn'),playerState=field(controller,'PlayerState'),
        gameInstance=helpers.GetGameInstance()}
end
local function ready(c)
    local gi=c.gameInstance
    if not valid(gi) or not valid(c.controller) or not valid(c.pawn) then
        return false,'本地角色尚未就绪。','The local player is not ready.','player_not_ready'
    end
    local ok,isLocal=pcall(function() return c.controller:IsLocalPlayerController() end)
    if not ok or isLocal~=true then return false,'未找到本地玩家。','No local player was found.','not_local_player' end
    local location=name(c.pawn:GetFullName()) or ''
    -- GI.isGameTime becomes true after a startup delay, even in L_Lobby.
    -- The local pawn's actual world identifies the editable saloon scene.
    if not location:find('/L_Lobby.',1,true) then
        return false,'请回到酒馆后修改永久进度。','Return to the saloon to edit persistent progress.','not_saloon'
    end
    local save=field(gi,'SG_PlayerProgress')
    local slot=name(field(gi,'PlayerId'))
    local required=field(gi,'requiredProgressVersion')
    local progress=field(gi,'playerProgress')
    local saved=field(save,'playerProgress')
    if not valid(save) then return false,'玩家存档对象尚未就绪。','The player save object is not ready.','save_object_unavailable' end
    if not slot or slot=='' then return false,'本地存档标识尚未就绪。','The local save slot is not ready.','save_slot_unavailable' end
    if not integer(required) or required<=0 then return false,'无法读取游戏存档版本。','The required save version is unavailable.','save_version_unavailable' end
    if field(progress,F.version)~=required then return false,'当前进度版本尚未就绪。','The runtime progress version is not ready.','runtime_version_mismatch' end
    if field(saved,F.version)~=required then return false,'存档对象版本尚未就绪。','The save object version is not ready.','save_version_mismatch' end
    if not field(gi,'F_ForceSave') then return false,'游戏保存接口不可用。','The game save function is unavailable.','save_api_unavailable' end
    return true,'在酒馆中可修改永久进度。','Persistent progress can be edited in the saloon.','ready'
end
function P.read(context)
    local s={available=false,canApply=false,values={}}
    local ok,err=pcall(function()
        local c=context or P.context()
        assert(valid(c.gameInstance),'Game instance is unavailable')
        local _,index=rowsFrom(field(c.gameInstance,'playerProgress'))
        for _,entry in ipairs(entries) do
            local raw,row=stored(index,entry.inventoryKey)
            assert(raw>=0,'Negative progress amount: '..entry.inventoryKey)
            s.values[entry.id]={value=entry.type=='level' and P.levelForXp(raw) or raw,
                raw=raw,present=raw>0,exists=row~=nil}
        end
        s.available=true
        s.canApply,s.messageZh,s.messageEn,s.reasonCode=ready(c)
    end)
    if not ok then
        s.available=false;s.canApply=false;s.values={};s.error=tostring(err);s.reasonCode='read_failed'
        s.messageZh='进度暂时无法读取。';s.messageEn='Progress is currently unavailable.'
    end
    return s
end
local function library(c,key,path)
    if c[key] then return c[key] end
    local class=StaticFindObject(path)
    assert(valid(class),'Native library unavailable: '..path)
    local cdo=class:GetCDO();assert(valid(cdo),'Native library default object unavailable')
    return cdo
end
local function nativeAmount(lib,gi,key)
    -- UE4SS 1181 requires a Lua table for this non-const OutParm struct reference.
    -- The getter only consumes runtimeInventory; passing it makes a temporary copy.
    local progress={[F.inventory]=field(field(gi,'playerProgress'),F.inventory)}
    local amount,contains={},{}
    lib:F_GetAmountFromInventory(progress,FName(key),gi,amount,contains)
    local n,p=out(amount,'amount'),out(contains,'contains')
    assert(integer(n) and n>=0 and type(p)=='boolean','Missing native inventory getter output')
    return n,p
end
local function nativeLevel(lib,gi,xp)
    local level,required,remaining,percent={},{},{},{}
    lib:F_CalculateXpLevel(xp,gi,level,required,remaining,percent)
    local value=out(level,'CurrentLevel')
    assert(integer(value),'Missing native level getter output')
    return value
end
local function writeSelected(progress,rows,found,key,value)
    if found then
        -- This UScriptStruct refers to the actual array element, not a function copy.
        found.reference[F.amount]=value
    else
        -- S_RuntimeInventory has exactly these two fields. Preserve every old row.
        -- Only the missing selected item is appended; no whole playerProgress write.
        local replacement={}
        for _,row in ipairs(rows) do
            replacement[#replacement+1]={[F.name]=FName(row.name),[F.amount]=row.amount}
        end
        replacement[#replacement+1]={[F.name]=FName(key),[F.amount]=value}
        progress[F.inventory]=replacement
    end
end
function P.apply(id,text,context)
    local value,zh,en=P.validate(id,text)
    local details={id=id,changed=false,saveRequested=false,savePrepared=false,persisted=false}
    local stage='validate'
    local function result(success,cn,english)
        details.messageZh=cn;details.messageEn=english;details.stage=stage
        return success,cn,details
    end
    if value==nil then details.reasonCode='invalid_input';return result(false,zh,en) end
    local entry=byId[id]
    local c,rows,index,found,old,lib,levels
    stage='ready'
    local ok,err=pcall(function()
        c=context or P.context()
        local canApply,cn,english,reason=ready(c)
        if not canApply then zh=cn;en=english;details.reasonCode=reason;return end
        stage='read'
        local progress=field(c.gameInstance,'playerProgress')
        rows,index=rowsFrom(progress)
        old,found=stored(index,entry.inventoryKey)
        assert(old>=0,'Selected progress amount is negative')
        stage='nativeRead'
        lib=library(c,'playerDatas','/Game/Gamework/BPFL_PlayerDatas.BPFL_PlayerDatas_C')
        local observed,contains=nativeAmount(lib,c.gameInstance,entry.inventoryKey)
        assert(observed==old and contains==(old>0),'Native inventory getter disagrees with stored value')
        details.rawBefore=old;details.before=entry.type=='level' and P.levelForXp(old) or old
        details.rawAfter=entry.type=='level' and P.xpForLevel(value) or value
        if entry.type=='level' then
            stage='levelRead'
            levels=library(c,'functionLibrary','/Game/Gamework/BPFL_FunctionLibrary.BPFL_FunctionLibrary_C')
            assert(nativeLevel(levels,c.gameInstance,old)==details.before,'Native level formula changed')
            assert(nativeLevel(levels,c.gameInstance,details.rawAfter)==value,'Native target level does not match')
        end
        if details.before==value then
            details.rawAfter=old;details.after=value;stage='unchanged';return
        end
        stage='write'
        writeSelected(progress,rows,found,entry.inventoryKey,details.rawAfter)
        details.changed=true
        stage='verify'
        local actual,present=nativeAmount(lib,c.gameInstance,entry.inventoryKey)
        details.observedRaw=actual
        assert(actual==details.rawAfter and present==(actual>0),'Native inventory read-back did not match')
        details.after=entry.type=='level' and nativeLevel(levels,c.gameInstance,actual) or actual
        assert(details.after==value,'Native level read-back did not match')
        stage='save'
        c.gameInstance:F_ForceSave()
        details.saveRequested=true
        stage='verifySave'
        local _,savedIndex=rowsFrom(field(field(c.gameInstance,'SG_PlayerProgress'),'playerProgress'))
        local savedAmount=stored(savedIndex,entry.inventoryKey)
        assert(savedAmount==details.rawAfter,'Game save object did not receive the selected value')
        details.savePrepared=true
        -- F_ForceSave is void and retries failed disk writes itself. A returned call
        -- plus runtime read-back cannot establish disk durability.
        stage='done'
    end)
    if not ok then
        details.error=tostring(err);details.stage=stage
        details.reasonCode=({read='read_failed',write='write_failed',verify='verification_failed',save='save_call_failed',verifySave='save_object_not_updated'})[stage] or 'native_call_failed'
        if stage=='save' then
            return result(false,'数值已修改，但游戏保存调用失败。','The value changed, but the game save call failed.')
        elseif stage=='verifySave' then
            return result(false,'数值已修改并请求保存，但存档对象未确认更新。','The value changed and a save was requested, but the save object update was not confirmed.')
        elseif details.changed then
            return result(false,'写入后未能核实数值；未请求保存。','The change could not be verified; no save was requested.')
        end
        return result(false,'无法读取或修改所选进度项目。','The selected progress entry could not be read or updated.')
    end
    if stage=='ready' then return result(false,zh,en) end
    if stage=='unchanged' then details.reasonCode='unchanged';return result(true,'当前数值已是 '..value..'，无需修改。','The current value is already '..value..'; no change was needed.') end
    details.reasonCode='save_requested'
    return result(true,'已核实 '..details.before..' → '..details.after..'；已请求游戏保存。',
        'Verified '..details.before..' → '..details.after..'; the game save was requested.')
end
return P
