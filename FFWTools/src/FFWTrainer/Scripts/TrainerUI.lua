-- In-game controller. Reads are passive; writes only enter explicit action handlers.
local L,Progress,Spawner=require('Locale'),require('Progress'),require('Spawner')
local UI={};local Controller={};Controller.__index=Controller
local sections={{'resources','资源','Resources'},{'character','角色','Character'},{'weapons','武器','Weapons'},
    {'magic','魔法','Magic'},{'jokers','奇术卡','Jokers'},{'settings','设置','Settings'}}
local function section(entry)
    if entry.type=='resource' then return 'resources' end
    if entry.id=='heroLevel' then return 'character' end
    return entry.category=='magic' and 'magic' or 'weapons'
end
local function trim(v) return tostring(v or ''):match('^%s*(.-)%s*$') end
function UI.new(options)
    return setmetatable({options=options or {},visible=false,section='resources',trainerSection='resources',query='',page=1,target='',inputRevision=0,
        queryRevision=0,spawnMode=options and options.spawnMode=='direct' and 'direct' or 'ground',progress={values={}},unlimited={enabled=false}},Controller)
end
function Controller:entries()
    if self.section=='jokers' then return Spawner.entries(self.query) end
    local rows={};local q=trim(self.query):lower()
    for _,e in ipairs(Progress.entries()) do
        if section(e)==self.section and (q=='' or e.nameZh:lower():find(q,1,true) or e.nameEn:lower():find(q,1,true) or e.id:lower():find(q,1,true)) then rows[#rows+1]=e end
    end
    return rows
end
function Controller:select(id)
    local entries=self:entries();local found
    for i,e in ipairs(entries) do if e.id==id then found=e;self.page=math.floor((i-1)/8)+1;break end end
    if not found then found=entries[1];self.page=1 end
    local key=found and found.id or nil
    if self.selectedId~=key then
        self.selectedId=key;self.message=nil;self.inputRevision=self.inputRevision+1
        local value=key and self.progress.values and self.progress.values[key]
        self.target=value and tostring(value.value) or ''
    end
    return found
end
function Controller:refresh()
    if not self.visible then return end
    self.progress=self.options.read and self.options.read() or Progress.read()
    self.unlimited=self.options.getUnlimited and self.options.getUnlimited() or {enabled=false}
    if self.section=='jokers' and self.options.inventory then self.inventory=self.options.inventory() end
    self:select(self.selectedId)
end
function Controller:toggle(sectionId)
    if not sectionId then
        if self.visible and self.section~='jokers' then self.visible=false;return end
        sectionId=self.trainerSection or 'resources'
    elseif self.visible and self.section==sectionId then self.visible=false;return end
    self.visible=true
    if sectionId and sectionId~=self.section then self:action('section',sectionId) end
    self:refresh()
end
function Controller:setTarget(text) self.target=tostring(text or '') end
function Controller:setQuery(text)
    text=tostring(text or '')
    if self.query~=text then self.query=text;self:select(nil) end
end
function Controller:move(step)
    local entries=self:entries();if #entries==0 then return end
    local index=1;for i,e in ipairs(entries) do if e.id==self.selectedId then index=i end end
    self:select(entries[(index-1+step)%#entries+1].id)
end
function Controller:action(action,value)
    if not self.visible then return false end
    if action=='close' then self.visible=false;return true
    elseif action=='section' then
        local known=false;for _,s in ipairs(sections) do if s[1]==value then known=true end end
        if not known then return false end
        if value~='jokers' then self.trainerSection=value end
        self.section=value;self.query='';self.queryRevision=self.queryRevision+1;self.selectedId=nil;self.target='';self.message=nil;self.page=1
        self:refresh()
        if value=='jokers' then self:select('jokerLightWeight') end
    elseif action=='spawnMode' and self.section=='settings' then
        if value~='ground' and value~='direct' then return false end
        if value==self.spawnMode then return true end
        if not self.options.setSpawnMode then return false end
        local ok,zh,en=self.options.setSpawnMode(value)
        if ok then self.spawnMode=value end
        self.message={zh=zh,en=en,success=ok==true}
    elseif action=='select' then self:select(value)
    elseif action=='previousPage' or action=='nextPage' then
        local entries=self:entries();local count=math.max(1,math.ceil(#entries/8))
        local page=math.max(1,math.min(count,self.page+(action=='nextPage' and 1 or -1)))
        if entries[(page-1)*8+1] then self:select(entries[(page-1)*8+1].id) end
    elseif action=='apply' and self.section~='jokers' and self.section~='settings' and self.selectedId then
        local ok,zh,detail=(self.options.apply or Progress.apply)(self.selectedId,self.target)
        self.lastApplyResult={id=self.selectedId,success=ok==true}
        if type(detail)=='table' then for k,v in pairs(detail)do self.lastApplyResult[k]=v end end
        self.message={zh=zh,en=type(detail)=='table' and detail.messageEn or detail,success=ok==true}
        if not ok and self.lastApplyResult.reasonCode then
            local suffix=' ['..tostring(self.lastApplyResult.stage or 'apply')..'/'..self.lastApplyResult.reasonCode..']'
            self.message.zh=(self.message.zh or '')..suffix;self.message.en=(self.message.en or '')..suffix
        end
        self:refresh()
    elseif action=='spawn' and self.section=='jokers' and self.selectedId then
        local ok,_,status=(self.options.spawn or Spawner.spawn)(self.selectedId,nil,nil,self.spawnMode)
        self.message={spawn=status,success=ok==true}
    elseif action=='unlimited' and self.section=='settings' and self.options.setUnlimited then
        local ok,zh,en=self.options.setUnlimited(not self.unlimited.enabled)
        self.message={zh=zh,en=en,success=ok==true};self:refresh()
    else return false end
    return true
end
function Controller:model()
    if not self.visible then return nil end
    local entries=self:entries();local selected=self:select(self.selectedId)
    local model={section=self.section,spawnMode=self.spawnMode,query=self.query,queryKey=self.queryRevision,rows={},tabs={},selected=selected,
        inputValue=self.target,inputKey=self.inputRevision,page=self.page,pageCount=math.max(1,math.ceil(#entries/8)),count=#entries,
        canApply=self.progress.canApply==true,unlimited=self.unlimited.enabled==true}
    for _,s in ipairs(sections) do model.tabs[#model.tabs+1]={id=s[1],label=L.choose(s[2],s[3]),selected=self.section==s[1]} end
    for i=(self.page-1)*8+1,math.min(self.page*8,#entries) do
        local entry=entries[i];local v=self.progress.values and self.progress.values[entry.id]
        model.rows[#model.rows+1]={id=entry.id,name=self.section=='jokers' and L.card(entry.id,'name') or L.choose(entry.nameZh,entry.nameEn),
            selected=selected and entry.id==selected.id,value=self.section~='jokers' and v and v.value or nil}
    end
    if self.section=='settings' then
        model.heading=L.choose('修改器设置','Trainer settings')
        model.detail=L.choose('解除装备属性的总点数限制。继续在游戏原菜单分配属性点并确认购买。\n\n单项属性限制与金币费用沿用游戏规则。',
            'Remove the total attribute point budget. Allocate points and confirm purchases in the original game menu.\n\nPer-attribute limits and gold costs follow the game rules.')
        model.status=L.choose(self.unlimited.messageZh or '',self.unlimited.messageEn or '')
    elseif not selected then
        model.heading=L.choose('没有匹配结果','No matches');model.detail=L.choose('请修改搜索词或清空搜索框。','Change or clear the search text.')
    elseif self.section=='jokers' then
        model.heading=L.card(selected.id,'name')
        local snapshot=self.inventory or require('Inventory').fromSnapshot({})
        local index=1;for i,e in ipairs(entries) do if e.id==selected.id then index=i end end
        local page=Spawner.page(snapshot,index,nil,self.query,self.spawnMode)
        model.detail=page.plainDetail or page.detail;model.noBonus=page.noBonus
        model.canSpawn=self.options.canSpawn and self.options.canSpawn() or false
    else
        model.heading=L.choose(selected.nameZh,selected.nameEn)
        local value=self.progress.values and self.progress.values[selected.id]
        model.current=value and tostring(value.value) or L.choose('无法读取','Unavailable')
        model.detail=L.choose('可设置范围：','Allowed range: ')..selected.min..'–'..selected.max..'\n\n'..
            (selected.type=='level' and L.choose('等级会换算为该等级的起始经验。','The level is converted to its starting XP.') or '')
        model.status=L.choose(self.progress.messageZh or '',self.progress.messageEn or '')
        if not model.canApply and self.progress.reasonCode then model.status=model.status..' ['..self.progress.reasonCode..']' end
    end
    if self.message then
        model.message=self.message.spawn and Spawner.messageText(self.message.spawn) or L.choose(self.message.zh or '',self.message.en or '')
        model.success=self.message.success
    end
    return model
end
return UI
