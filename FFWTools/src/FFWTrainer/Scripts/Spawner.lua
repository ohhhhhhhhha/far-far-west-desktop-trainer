-- User-triggered test pickups. Does not write card arrays or save-game values.
local Cards=require('Cards')
local I=require('Inventory')
local P=require('Panel')
local L=require('Locale')
local Spawner={}
local lastRequest=-math.huge
local lastScanError
-- Retained /Game/Gamework/E_Rarity export: enumerator suffixes are NOT ordinals.
local rarityBytes={['E_Rarity::NewEnumerator0']=0,['E_Rarity::NewEnumerator1']=1,
    ['E_Rarity::NewEnumerator2']=2,['E_Rarity::NewEnumerator4']=3,
    ['E_Rarity::NewEnumerator5']=4,['E_Rarity::NewEnumerator6']=5}
local function collectible(card)
    return card and card.enabled and not card.id:lower():find('jokerupgrade',1,true) and rarityBytes[card.rarity]~=nil
end
local function queryText(query) return (tostring(query or ''):match('^%s*(.-)%s*$')) end
local function messageText(message)
    if type(message)~='table' then return L.text(message) end
    if message.cardId and message.mode=='direct' then
        return L.choose('已请求直接获得「','Direct grant requested: "')..L.card(message.cardId,'name')..L.choose('」一张。','".')
    end
    if message.cardId then
        return L.choose('已请求生成「','Requested spawn: "')..L.card(message.cardId,'name')..
            L.choose('」一张；关闭面板后到面前拾取。','". Close the panel and pick it up in front of you.')
    end
    return L.text(message.text)
end
function Spawner.entries(query)
    query=queryText(query):lower()
    local entries={}
    for _,card in ipairs(Cards.all()) do
        if collectible(card) and L.matches(card.id,query) then
            entries[#entries+1]=card
        end
    end
    table.sort(entries,function(a,b) return a.name<b.name end)
    return entries
end
function Spawner.page(snapshot,index,message,query,mode)
    query=queryText(query)
    local entries=Spawner.entries(query)
    local hint=L.text('F4 关闭   输入卡名筛选   F5/F6 选卡   Shift+F5/F6 翻页   F3 生成一张')
    if #entries==0 then
        return {index=0,count=0,entries=entries,searchable=true,query=query,
            title=L.text('测试刷卡 · 无匹配结果'),hint=hint,list=L.text('没有找到匹配的奇术卡'),
            detail=L.text('请修改搜索词，或清空搜索框查看全部卡牌。')}
    end
    if not index and query=='' then for k,c in ipairs(entries) do if c.id=='jokerLightWeight' then index=k;break end end end
    index=((index or 1)-1)%#entries+1
    local card=entries[index];local list={}
    local first=math.floor((index-1)/10)*10+1
    for k=first,math.min(first+9,#entries) do
        list[#list+1]=(k==index and '▶ ' or '   ')..(L.card(entries[k].id,'name') or entries[k].name)
    end
    local applies=false
    for _,g in ipairs(I.groups(snapshot)) do if I.applies(card.id,g.itemName) then applies=true;break end end
    local detail,style
    if applies then detail,style=P.description(card.id,snapshot,nil,'pickup',card.description)
    else detail=(L.card(card.id,'description') or card.description)..'\n\n'..L.text('当前装备不适用；更换为适用武器后测试。') end
    local prefix=messageText(message or (mode=='direct' and L.choose('任务中按 F3 直接获得一张，条件效果按游戏规则触发。','Press F3 in a mission to gain one card directly. Conditional effects follow the game rules.') or '任务中按 F3 在面前生成一张，再关闭面板并正常拾取。'))..'\n\n'
    return {index=index,count=#entries,selected=card,entries=entries,searchable=true,query=query,
        title=L.text('测试刷卡 · ')..(L.card(card.id,'name') or card.name)..'  ['..index..'/'..#entries..']',
        hint=hint,
        list=table.concat(list,'\n\n'),detail=prefix..detail,noBonus=style and style.noBonus or false,
        plainDetail=style and style.noBonus and prefix..style.plainText or nil}
end
function Spawner.context()
    local helpers=require('UEHelpers')
    local controller=helpers.GetPlayerController()
    local function isLocal(c)
        local ok,localPlayer=pcall(function() return P.valid(c) and c:IsLocalPlayerController() end)
        return ok and localPlayer
    end
    if not isLocal(controller) then
        controller=nil
        for _,candidate in ipairs(FindAllOf('PlayerController') or {}) do
            if isLocal(candidate) then controller=candidate;break end
        end
    end
    return {controller=controller,playerState=I.field(controller,'PlayerState'),
        pawn=I.field(controller,'Pawn'),gameInstance=helpers.GetGameInstance()}
end
function Spawner.canSpawn(context)
    context=context or Spawner.context()
    local controller,pawn,ps=context.controller,context.pawn,context.playerState
    if not P.valid(controller) or not P.valid(pawn) or not P.valid(ps) then return false,'本地角色尚未就绪。' end
    if not controller:IsLocalPlayerController() then return false,'未找到本地玩家控制器。' end
    local locationName=pawn:GetFullName()
    if locationName:find('/L_Lobby',1,true) or locationName:find('/L_Map_TitleScreen',1,true)
        or not P.valid(I.field(context.gameInstance,'refChallengeManager')) then
        return false,'请进入单人任务后生成；酒馆没有正常任务拾取环境。'
    end
    return true
end
-- Only scan on an explicit spawn request, never during panel refresh.
-- Native F_HideJokerLocally disables actor collision after local pickup.
local function nearbyDroppedCount(pawn,position)
    local drops=FindAllOf('BP_Pickable_Joker_C') or {}
    if #drops==0 then return 0 end
    local world=pawn:GetWorld();assert(P.valid(world),'Player world unavailable')
    local worldAddress=world:GetAddress();local count=0
    for _,drop in ipairs(drops) do
        if P.valid(drop) and not drop:GetFullName():find('Default__',1,true) and I.field(drop,'isPlayerDropped')==true then
            local dropWorld=drop:GetWorld()
            if P.valid(dropWorld) and dropWorld:GetAddress()==worldAddress then
                local active=drop:GetActorEnableCollision()
                assert(type(active)=='boolean','Pickup state unavailable')
                if active then
                    local p=drop:K2_GetActorLocation()
                    local dx,dy,dz=p.X-position.X,p.Y-position.Y,p.Z-position.Z
                    if dx*dx+dy*dy+dz*dz<=2000*2000 then
                        count=count+1;if count>=10 then return count end
                    end
                end
            end
        end
    end
    return count
end
local function spawn(id,context,now,mode)
    mode=mode or 'ground'
    if mode~='ground' and mode~='direct' then return false,L.choose('无效的刷卡方式。','Invalid Joker mode.') end
    local card=Cards.get(id)
    if not collectible(card) then return false,'请选择普通奇术卡；永久升级不能生成拾取物。' end
    context=context or Spawner.context();now=now or os.time()
    local ready,reason=Spawner.canSpawn(context);if not ready then return false,reason end
    local pawn,ps=context.pawn,context.playerState
    if now-lastRequest<2 then return false,'请等 2 秒再生成下一张。' end
    if mode=='direct' then
        -- BP_Pickable_Joker's normal selection path uses these same arguments.
        -- Despite its name this is an owning-client RPC; use only the local PS.
        lastRequest=now
        ps:F_AddJokerRuntime_Server(FName(card.id),true,true)
        return true,nil,card.id,mode
    end
    local position=pawn:K2_GetActorLocation()
    local scanned,pending=pcall(nearbyDroppedCount,pawn,position)
    if not scanned then
        if lastScanError~=tostring(pending) then
            lastScanError=tostring(pending);print('[FFWTrainer] pickup scan failed: '..lastScanError..'\n')
        end
        return false,L.choose('附近掉落物暂时无法读取，请稍后再试。','Nearby pickups are unavailable; try again shortly.')
    end
    lastScanError=nil
    if pending>=10 then return false,L.choose('附近已有 10 张未拾取的掉落卡，请先拾取后再生成。','There are already 10 nearby dropped Jokers. Pick some up before spawning more.') end
    local forward=pawn:GetActorForwardVector()
    local length=math.sqrt(forward.X*forward.X+forward.Y*forward.Y)
    if length==0 then return false,'角色朝向尚未就绪。' end
    local location={X=position.X+150*forward.X/length,Y=position.Y+150*forward.Y/length,Z=position.Z-30}
    -- Dropped=true selects the exact replicated name; false generates random choices.
    -- Reserve the cooldown before crossing the native boundary: a call that
    -- reports an error may already have started creating the pickup.
    lastRequest=now
    ps:F_SpawnJoker_Server(location,rarityBytes[card.rarity],FName(card.id),true)
    return true,nil,card.id,mode
end
function Spawner.spawn(...)
    local ok,message,id,mode=spawn(...)
    local status={text=message,cardId=id,mode=mode}
    return ok,messageText(status),status
end
Spawner.messageText=messageText
return Spawner
