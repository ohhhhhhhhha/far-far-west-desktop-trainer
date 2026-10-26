-- Headless UE4SS connection for the external FFWTrainer.exe. No trainer hotkeys.
local directory=debug.getinfo(1,'S').source:sub(2):gsub('\\','/'):match('^(.*)/')
assert(directory,'FFWTrainer needs a file-backed entry point')
local shared={Cards=true,Effects=true,Inventory=true,Panel=true,HeroRules=true,WeaponRules=true,UpgradeRules=true}
local allowed={Spawner=true,Progress=true,Bridge=true,UpgradeLimit=true,Json=true,Locale=true}
local modules,environment={},nil
local globalRequire=require
environment=setmetatable({require=function(name)
    if not shared[name] and not allowed[name] then return globalRequire(name) end
    if not modules[name] then
        local chunk,err=loadfile(directory..'/'..name..'.lua','t',environment)
        if not chunk and shared[name] then chunk,err=loadfile(directory..'/../../FFWJokerInfo/Scripts/'..name..'.lua','t',environment) end
        if not chunk and name=='Json' then chunk,err=loadfile(directory..'/../../Common/Json.lua','t',environment) end
        modules[name]=assert(chunk,err)()
    end
    return modules[name]
end},{__index=_G})
local I,P=environment.require('Inventory'),environment.require('Panel')
local Spawner,Progress=environment.require('Spawner'),environment.require('Progress')
local Bridge,UpgradeLimit,L=environment.require('Bridge'),environment.require('UpgradeLimit'),environment.require('Locale')
local S={enabled=true,errors=0,visible=false,Progress=Progress,Locale=L}
_G.FFWTrainer=S
local function log(message) print('[FFWTrainer] '..message..'\n') end
local function protected(fn)
    local ok,err=pcall(fn)
    if not ok then
        S.errors=S.errors+1
        if S.lastError~=tostring(err) then S.lastError=tostring(err);log('ERROR '..S.lastError) end
    end
    return ok,err
end
local function inLanguage(language,fn)
    local previous=L.language();L.setCulture(language)
    local ok,result=pcall(fn);L.setCulture(previous)
    if not ok then error(result) end
    return result
end
S.limit=UpgradeLimit.new()
local function snapshot(client)
    L.refresh()
    local progress=Progress.read();local rows={}
    for _,entry in ipairs(Progress.entries()) do
        local value=progress.values[entry.id]
        rows[#rows+1]={id=entry.id,category=entry.category or entry.type,nameZh=entry.nameZh,nameEn=entry.nameEn,
            min=entry.min,max=entry.max,value=value and value.value,raw=value and value.raw,available=value~=nil}
    end
    local canSpawn=Spawner.canSpawn()
    local state={language=L.language(),canApply=progress.canApply==true,canSpawn=canSpawn==true,
        messageZh=progress.messageZh,messageEn=progress.messageEn,entries=rows,unlimited=S.limit:status()}
    local card=client.selectedCardId and environment.require('Cards').get(client.selectedCardId)
    if card then
        local current=I.read()
        local function description() return P.description(card.id,current,nil,'pickup',L.card(card.id,'description')) end
        state.cardPreview={id=card.id,textZh=inLanguage('zh',description),textEn=inLanguage('en',description)}
    end
    return state
end
local function execute(action,payload)
    if action=='setProgress' then
        local ok,zh,details=Progress.apply(payload.id,payload.value)
        log('APPLY '..payload.id..' success='..tostring(ok))
        if not ok then log('APPLY FAILURE '..tostring(details and details.messageEn)..' '..tostring(details and details.error)) end
        return ok,zh,details and details.messageEn
    elseif action=='spawn' then
        local ok,_,status=Spawner.spawn(payload.id)
        log('SPAWN '..payload.id..' requested='..tostring(ok))
        return ok,inLanguage('zh',function() return Spawner.messageText(status) end),inLanguage('en',function() return Spawner.messageText(status) end)
    elseif action=='setUnlimited' then
        local previous=S.limit:status().enabled
        local ok,zh,en=S.limit:setEnabled(payload.enabled)
        if not ok then return ok,zh,en end
        local saved,err=S.bridge:writeJson('settings',{unlimited=payload.enabled})
        if not saved then
            S.limit:setEnabled(previous)
            log('SETTINGS FAILURE '..tostring(err))
            return false,'无法保存开关设置，已恢复原状态。','Could not save the setting. The previous state was restored.'
        end
        return true,zh,en
    end
end
S.bridge=Bridge.new{directory=directory..'/../Data',session=tostring(os.time())..'-'..tostring({}):gsub('table: ',''),
    snapshot=snapshot,execute=execute}
local settings=S.bridge:readJson('settings')
local restoreUnlimited=settings and settings.unlimited==true
local lastLimitTick=-math.huge
function S.update()
    if not S.enabled then return end
    -- Even persisted widget changes wait for the game-thread loop.
    if restoreUnlimited then restoreUnlimited=false;S.limit:setEnabled(true) end
    local now=os.time()
    if now~=lastLimitTick then S.limit:tick();lastLimitTick=now end
    S.bridge:tick()
end
function S.hide() end -- Compatibility with the independent overlays' cross-hide calls.
function S.stop() S.enabled=false;S.limit:stop() end
LoopInGameThreadWithDelay(250,function() if S.enabled then protected(S.update) end end)
log('desktop connection loaded. Open FFWTrainer.exe; game trainer hotkeys are removed.')
return S
