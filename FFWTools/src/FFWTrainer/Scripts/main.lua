-- Runtime API guard runs before loading modules or registering native work.
for _,api in ipairs({'RegisterKeyBind','ExecuteInGameThread','LoopInGameThreadWithDelay'}) do
    if type(_G[api])~='function' then
        local message='Missing '..api..'. Install the current Far Far West player framework from nexusmods.com/farfarwest/mods/2; see INSTALL.en.md.'
        print('[FFWTrainer] disabled: '..message..'\n')
        local disabled={enabled=false,compatibilityError=message};_G.FFWTrainer=disabled
        return disabled
    end
end
-- Game-native trainer. No desktop client, command polling or background progress writes.
local directory=debug.getinfo(1,'S').source:sub(2):gsub('\\','/'):match('^(.*)/')
assert(directory,'FFWTrainer needs a file-backed entry point')
local shared={Cards=true,Effects=true,Inventory=true,Panel=true,HeroRules=true,WeaponRules=true,UpgradeRules=true}
local allowed={Spawner=true,Progress=true,Bridge=true,UpgradeLimit=true,Json=true,Locale=true,TrainerUI=true,TrainerView=true,CanvasView=true,MousePanel=true}
local modules,environment={},nil;local globalRequire=require
 environment=setmetatable({require=function(name)
    if not shared[name] and not allowed[name] then return globalRequire(name) end
    if not modules[name] then
        local chunk,err=loadfile(directory..'/'..name..'.lua','t',environment)
        if not chunk and shared[name] then chunk,err=loadfile(directory..'/../../FFWJokerInfo/Scripts/'..name..'.lua','t',environment) end
        if not chunk and (name=='Json' or name=='CanvasView' or name=='MousePanel') then chunk,err=loadfile(directory..'/../../Common/'..name..'.lua','t',environment) end
        modules[name]=assert(chunk,err)()
    end
    return modules[name]
end},{__index=_G})
local function module(name) return environment.require(name) end
local Progress,Spawner,Inventory=module('Progress'),module('Spawner'),module('Inventory')
local L,Bridge,Json=module('Locale'),module('Bridge'),module('Json')
local S={enabled=true,visible=false,errors=0,Progress=Progress,Locale=L};_G.FFWTrainer=S
local function log(m) print('[FFWTrainer] '..tostring(m)..'\n') end
local function protected(fn)
    local ok,err=pcall(fn)
    if not ok then S.errors=S.errors+1;if S.lastError~=tostring(err) then S.lastError=tostring(err);log(err) end end
    return ok,err
end
S.limit=module('UpgradeLimit').new{getController=function() return Spawner.context().controller end}
local settingsPath=directory..'/../Data/settings.json'
local settings={unlimited=false,spawnMode='ground'}
local saved=Bridge.readFile(settingsPath)
if saved then
    local ok,value=pcall(Json.decode,saved)
    if ok and type(value)=='table' then settings=value end
end
settings.unlimited=settings.unlimited==true
settings.spawnMode=settings.spawnMode=='direct' and 'direct' or 'ground'
local restoreUnlimited=settings.unlimited
local function writeSettings(unlimited,mode)
    local nextSettings={};for k,v in pairs(settings) do nextSettings[k]=v end
    nextSettings.unlimited=unlimited;nextSettings.spawnMode=mode
    local ok,err=Bridge.writeFile(settingsPath,Json.encode(nextSettings))
    if ok then settings=nextSettings end
    return ok,err
end
local function setSpawnMode(mode)
    if mode~='ground' and mode~='direct' then return false,'无效的刷卡方式。','Invalid Joker mode.' end
    local ok,err=writeSettings(settings.unlimited,mode)
    if not ok then log(err);return false,'设置未保存，请重试。','Settings could not be saved; try again.' end
    return true,'刷卡方式已保存。','Joker mode saved.'
end
local function setUnlimited(enabled)
    local previous=S.limit:status().enabled
    local ok,zh,en=S.limit:setEnabled(enabled);if not ok then return ok,zh,en end
    local written,err=writeSettings(enabled,settings.spawnMode)
    if not written then
        S.limit:setEnabled(previous);log(err)
        return false,'设置未保存，已恢复原状态。','Settings could not be saved; the previous state was restored.'
    end
    return true,zh,en
end
S.ui=module('TrainerUI').new{read=Progress.read,inventory=function()
    local context=Spawner.context()
    return Inventory.readObjects(context.gameInstance,context.playerState,context.pawn)
end,apply=Progress.apply,spawn=Spawner.spawn,
    canSpawn=Spawner.canSpawn,getUnlimited=function() return S.limit:status() end,setUnlimited=setUnlimited,setSpawnMode=setSpawnMode,spawnMode=settings.spawnMode}
local function inputs(requireTarget)
    if not S.ui.visible or not S.renderer.attached then return false,'panel_unavailable' end
    local query=S.renderer:input('query');if query and S.ui.section~='settings' then S.ui:setQuery(query) end
    if S.ui.section~='jokers' and S.ui.section~='settings' then
        local target,inputError=S.renderer:input('target')
        local entry=S.renderer.inputs and S.renderer.inputs.target
        if target==nil and requireTarget then return false,'input_unavailable',inputError end
        if (not entry or entry.resetKey~=S.ui.inputRevision) and requireTarget then return false,'input_not_synced' end
        if target and entry and entry.resetKey==S.ui.inputRevision then S.ui:setTarget(target) end
    end
    return true
end
local function render()
    S.visible=S.ui.visible;S.renderer:render(S.ui:model())
    if S.visible and S.ui.section~='jokers' and S.ui.section~='settings' then
        local p=S.ui.progress
        if p and p.canApply~=true and p.reasonCode then
            local detail=p.error and tostring(p.error):gsub('^.-([%w_]+%.lua:%d+:)','%1') or ''
            local key=p.reasonCode..detail
            if key~=S.lastReadyLog then
                S.lastReadyLog=key;log('progress readiness='..p.reasonCode)
                if detail~='' then log('read detail: '..detail:sub(1,1000)) end
            end
        else S.lastReadyLog=nil end
    end
    if S.renderer.cleanupError and S.renderer.cleanupError~=S.lastCleanupError then
        S.lastCleanupError=S.renderer.cleanupError;log('view cleanup recovered: '..S.lastCleanupError)
    end
end
local function recordApply(result)
    S.lastApplyResult=result
    local errorText=result.error and tostring(result.error):gsub('^.-([%w_]+%.lua:%d+:)','%1') or ''
    local message='apply '..tostring(result.id or '')..' stage='..tostring(result.stage or 'done')..' result='..tostring(result.reasonCode or (result.success and 'ok' or 'failed'))
    local key=message..errorText
    if result.success or key~=S.lastApplyLog then
        S.lastApplyLog=key;log(message)
        if errorText~='' then log('apply detail: '..errorText:sub(1,1000)) end
    end
end
local function rejectApply(stage,reason,errorText)
    local result={id=S.ui.selectedId,success=false,stage=stage,reasonCode=reason,error=errorText}
    S.ui.message={zh='未应用：['..reason..']，请重新打开面板后重试。',en='Not applied ['..reason..']; reopen the panel and retry.',success=false}
    recordApply(result)
end
local spawnPending=false
function S.action(action,value)
    if not S.enabled then return end
    local inputSource=S.renderer and S.renderer.mouse
    local spawning=action=='spawn'
    local applying=action=='apply' and S.ui.visible and S.ui.section~='jokers' and S.ui.section~='settings'
    local selectedId=S.ui.selectedId
    local spawnMode=S.ui.spawnMode
    if spawning then
        if spawnPending or not S.ui.visible or S.ui.section~='jokers' then return end
        spawnPending=true
    end
    -- Keep one outstanding spawn intent. A slow frame must not turn repeated
    -- F3/click input into actors queued for later, after the cooldown expires.
    local scheduled=protected(function() ExecuteInGameThread(function()
        protected(function()
            if not S.enabled then return end
            -- Native clicks/key actions wait for the game thread. Revalidate
            -- their panel lease there, after any travel or overlay handoff.
            if inputSource and (inputSource~=S.renderer.mouse or not inputSource.active or not inputSource:ownsInput()
                or not inputSource:isCurrent(S.renderer.options.getController())) then
                if applying then rejectApply('dispatch','input_context_changed') end
                return
            end
            local read,reason,inputError=inputs(applying)
            if applying and not read then rejectApply('input',reason,inputError);render();return end
            if spawning and (S.ui.section~='jokers' or S.ui.selectedId~=selectedId or S.ui.spawnMode~=spawnMode) then return end
            S.ui:action(action,value)
            if applying and S.ui.lastApplyResult then recordApply(S.ui.lastApplyResult) end
            render()
        end)
        if spawning then spawnPending=false end
    end) end)
    if not scheduled and spawning then spawnPending=false end
end
S.renderer=module('CanvasView').new{getController=function() return Spawner.context().controller end,
    layout=module('TrainerView').layout,onAction=S.action,zOrder=9960}
function S.toggle(section)
    if not S.enabled then return end
    ExecuteInGameThread(function() protected(function()
        if not S.enabled then return end
        inputs();L.refresh();S.ui:toggle(section);render()
    end) end)
end
function S.hide()
    if not S.visible then return end
    ExecuteInGameThread(function() protected(function() if not S.enabled then return end;S.ui.visible=false;render() end) end)
end
local lastTick=-math.huge
function S.update()
    if not S.enabled then return end
    if restoreUnlimited then restoreUnlimited=false;S.limit:setEnabled(true) end
    inputs()
    local now=os.time()
    if now~=lastTick then
        S.limit:tick()
        if S.visible then L.refresh();S.ui:refresh() end
        lastTick=now
    end
    if S.visible then render() end
end
function S.stop() S.enabled=false;S.ui.visible=false;S.visible=false;S.renderer:hide();S.limit:stop() end
local function bind(key,fn) if Key and Key[key] then RegisterKeyBind(Key[key],fn) end end
bind('F2',function() S.toggle() end)
bind('F4',function() S.toggle('jokers') end)
bind('F1',function() S.action('apply') end)
bind('F3',function() S.action('spawn') end)
for _,entry in ipairs({{'F5',-1},{'F6',1}}) do bind(entry[1],function()
    if S.visible then ExecuteInGameThread(function() protected(function() if not S.enabled or not S.visible then return end;inputs();S.ui:move(entry[2]);render() end) end) end
end) end
bind('F7',S.hide);bind('F8',S.hide)
LoopInGameThreadWithDelay(250,function() if S.enabled then protected(S.update) end end)
log('in-game trainer 0.4.0-beta.6 loaded: F2 toolkit, F4 joker search, F1 apply, F3 spawn. Desktop commands are disabled.')
return S
