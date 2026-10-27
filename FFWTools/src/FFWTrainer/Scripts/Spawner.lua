-- User-triggered test pickups. Does not write card arrays or save-game values.
local Cards=require('Cards')
local I=require('Inventory')
local P=require('Panel')
local L=require('Locale')
local Spawner={}
local lastRequest=-math.huge
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
function Spawner.page(snapshot,index,message,query)
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
    local prefix=messageText(message or '任务中按 F3 在面前生成一张，再关闭面板并正常拾取。')..'\n\n'
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
local function spawn(id,context,now)
    local card=Cards.get(id)
    if not collectible(card) then return false,'请选择普通奇术卡；永久升级不能生成拾取物。' end
    context=context or Spawner.context();now=now or os.time()
    local ready,reason=Spawner.canSpawn(context);if not ready then return false,reason end
    local pawn,ps=context.pawn,context.playerState
    if now-lastRequest<2 then return false,'请等 2 秒再生成下一张。' end
    local position=pawn:K2_GetActorLocation();local forward=pawn:GetActorForwardVector()
    local length=math.sqrt(forward.X*forward.X+forward.Y*forward.Y)
    if length==0 then return false,'角色朝向尚未就绪。' end
    local location={X=position.X+150*forward.X/length,Y=position.Y+150*forward.Y/length,Z=position.Z-30}
    -- Dropped=true selects the exact replicated name; false generates random choices.
    -- Reserve the cooldown before crossing the native boundary: a call that
    -- reports an error may already have started creating the pickup.
    lastRequest=now
    ps:F_SpawnJoker_Server(location,rarityBytes[card.rarity],FName(card.id),true)
    return true,nil,card.id
end
function Spawner.spawn(...)
    local ok,message,id=spawn(...)
    local status={text=message,cardId=id}
    return ok,messageText(status),status
end
Spawner.messageText=messageText
return Spawner
