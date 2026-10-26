-- Original-menu total attribute budget switch, for the verified 0.3.0.7 UI.
-- Does not allocate attributes, write inventory, confirm purchases or save.
-- Public mutating methods run on the game thread. Registration alone is queued
-- through ExecuteAsync; Blueprint RegisterHook callbacks run AFTER the function.
local U={}
local PATH='/Game/Interfaces/Equipment/UI_Equipment_Item.UI_Equipment_Item_C:F_UpdatePriceAndUpgradesAmount'
local function usable(v) return v~=nil and not tostring(v):match('^TrivialObject:') end
local function unwrap(v)
    if not usable(v) then return nil end
    if type(v)=='number' or type(v)=='string' or type(v)=='boolean' then return v end
    local ok,value=pcall(function() return v:get() end)
    if ok then return usable(value) and value or nil end
    return v
end
local function field(o,key)
    if not usable(o) then return nil end
    local ok,value=pcall(function() return o[key] end)
    if ok then return unwrap(value) end
end
local function valid(o)
    local ok,result=pcall(function() return usable(o) and o:IsValid() end)
    return ok and result==true
end
local function integer(v) return type(v)=='number' and v>=0 and v<=2147483647 and v%1==0 end
local function identity(o) return tostring(o:GetAddress()) end
local function eligible(ui)
    if not valid(ui) then return false end
    local ok,result=pcall(function()
        if ui:GetFullName():find('Default__',1,true) then return false end
        local pc=ui:GetOwningPlayer()
        if not valid(pc) or pc:IsLocalPlayerController()~=true then return false end
        local pawn=field(pc,'Pawn')
        return valid(pawn) and pawn:GetFullName():find('/L_Lobby.',1,true)~=nil
    end)
    return ok and result==true
end
local function visible(ui)
    local ok,result=pcall(function() return ui:IsVisible() end)
    return ok and result==true
end
local function spent(ui)
    local total=0
    -- UE4SS TMap:ForEach supplies key and value RemoteUnrealParam wrappers.
    -- Read the native pending map; the misleading amountAvailableUpgrades field
    -- actually holds SPENT points and is the only field this controller changes.
    local values=field(ui,'bufferNewTweaks')
    assert(usable(values),'Native upgrade map unavailable')
    values:ForEach(function(_,value)
        local amount=unwrap(value)
        assert(integer(amount),'Native upgrade amount unavailable')
        total=total+amount
        assert(integer(total),'Native upgrade total is invalid')
    end)
    return total
end
local function label(ui,text)
    local widget=field(ui,'UpgradesAvailableMax')
    assert(valid(widget),'Native upgrade label unavailable')
    widget:SetText(FText(text))
end
function U.new()
    local self={enabled=false,active=false,stopped=false,pending=false,hook=nil,records={},error=nil}
    local function restore(record)
        local ui=record.ui
        if not valid(ui) then return true end
        local ok,total=pcall(spent,ui)
        if not ok then total=record.spent end
        -- The native refresh may already have restored a newer real total.
        if field(ui,'amountAvailableUpgrades')==-1 then ui.amountAvailableUpgrades=total end
        local nativeMax=field(ui,'maxUpgradesAvailable')
        if integer(nativeMax) then label(ui,tostring(total)..'/'..nativeMax) end
        return true
    end
    local function restoreAll()
        local success=true
        for key,record in pairs(self.records) do
            local ok,err=pcall(restore,record)
            if ok then self.records[key]=nil else self.error=tostring(err);success=false end
        end
        self.active=false
        return success
    end
    local function patch(ui)
        if not self.enabled or self.stopped or not self.hook or not eligible(ui) then return false end
        local total=spent(ui)
        local nativeMax=field(ui,'maxUpgradesAvailable')
        assert(integer(nativeMax),'Native upgrade maximum unavailable')
        local key=identity(ui)
        self.records[key]={ui=ui,spent=total}
        -- This runs AFTER F_UpdatePriceAndUpgradesAmount has rendered its native
        -- 20+extra widgets. Leave maxUpgradesAvailable untouched. The two native
        -- click gates compare spent points with the earned/maximum budgets; -1
        -- passes both, including level one. Per-stat clamp and gold confirmation
        -- use other fields/maps and remain native. Next refresh recomputes the
        -- actual spent count before rendering and this post-hook reapplies -1.
        label(ui,tostring(total)..'/∞')
        ui.amountAvailableUpgrades=-1
        return visible(ui)
    end
    local function onRefresh(context)
        if not self.enabled or self.stopped then return end
        local ok,result=pcall(patch,unwrap(context))
        if not ok then self.error=tostring(result)
        elseif result then self.active=true end
    end
    local function scheduleHook()
        if self.pending or self.stopped or not self.enabled then return end
        self.pending=true
        local scheduled,err=pcall(ExecuteAsync,function()
            self.pending=false
            if self.stopped or not self.enabled then return end
            local ok,failure=pcall(function()
                local fn=StaticFindObject(PATH)
                if not valid(fn) then return end -- UI package loads lazily.
                local address=identity(fn)
                if self.hook and self.hook.address==address then return end
                if self.hook then
                    UnregisterHook(PATH,self.hook.pre,self.hook.post)
                    self.hook=nil
                end
                local pre,post=RegisterHook(PATH,onRefresh)
                assert(type(pre)=='number' and type(post)=='number','Native hook registration returned no IDs')
                self.hook={address=address,pre=pre,post=post}
            end)
            self.error=not ok and tostring(failure) or nil
        end)
        if not scheduled then self.pending=false;self.error=tostring(err) end
    end
    function self:status()
        local zh,en
        if self.error then
            zh='原版菜单解锁暂未生效，请重新打开升级菜单。'
            en='The original-menu unlock is unavailable; reopen the upgrade menu.'
        elseif not self.enabled then
            zh='原版总点数限制已恢复；已分配的属性点保持不变。'
            en='The native total budget is restored; allocated attributes are unchanged.'
        elseif self.active then
            zh='已解除总点数限制；请在原版菜单加点并确认购买。'
            en='Total budget unlocked; allocate and confirm purchases in the original menu.'
        else
            zh='已开启，等待酒馆中的原版升级菜单。'
            en='Enabled; waiting for the original upgrade menu in the saloon.'
        end
        return {enabled=self.enabled,active=self.enabled and self.active and not self.error or false,
            messageZh=zh,messageEn=en}
    end
    function self:tick()
        if self.stopped then return end
        if not self.enabled then if next(self.records) then restoreAll() end;return end
        scheduleHook()
        self.active=false
        if not self.hook then return end
        for key,record in pairs(self.records) do
            if not eligible(record.ui) then
                local ok,err=pcall(restore,record)
                if ok then self.records[key]=nil else self.error=tostring(err) end
            end
        end
        local ok,err=pcall(function()
            for _,ui in ipairs(FindAllOf('UI_Equipment_Item_C') or {}) do
                if patch(ui) then self.active=true end
            end
        end)
        if not ok then self.error=tostring(err) end
    end
    function self:setEnabled(value)
        if type(value)~='boolean' or self.stopped then
            return false,'无法应用该总点数开关。','The total-budget switch could not be applied.'
        end
        if value then
            for _,api in ipairs({'ExecuteAsync','StaticFindObject','RegisterHook','UnregisterHook','FindAllOf'}) do
                if type(_G[api])~='function' then
                    return false,'游戏菜单挂钩接口不可用。','The game menu hook interface is unavailable.'
                end
            end
            -- UE4SS's FText constructor is callable userdata, not a Lua function.
            if not usable(FText) then
                return false,'游戏文本接口不可用。','The game text interface is unavailable.'
            end
        end
        self.enabled=value;self.error=nil
        local success=true
        if value then self:tick() else success=restoreAll() end
        local s=self:status()
        return success,s.messageZh,s.messageEn
    end
    function self:stop()
        self.enabled=false;self.stopped=true
        restoreAll()
        if self.hook then
            pcall(UnregisterHook,PATH,self.hook.pre,self.hook.post)
            self.hook=nil
        end
    end
    return self
end
return U
