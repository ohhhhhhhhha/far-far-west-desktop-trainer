-- Native UMG buttons with per-instance routing, plus a cursor lease shared by
-- independently installed mods/UE4SS Lua VMs. No polling or global input hooks.
local M={}
local Panel={};Panel.__index=Panel
local template='/Game/Interfaces/UI_Template_Button.UI_Template_Button_C'
local clickName='F_ChildClick'
local clickPath=template..':'..clickName
local routes,hook={},nil
local prefix='FFWTools.MousePanel.v1.'
local function valid(o)
    local ok,value=pcall(function() return o and o:IsValid() end);return ok and value==true
end
local function identity(o)
    if not valid(o) then return nil end
    local ok,key=pcall(function() return o:GetFullName()..'@'..tostring(o:GetAddress()) end)
    return ok and key or nil
end
local function world(o)
    local ok,value=pcall(function() return o:GetWorld() end)
    return ok and identity(value) or nil
end
local function field(o,key)
    local ok,value=pcall(function() return o and o[key] end)
    return ok and value or nil
end
local function menuFor(controller)
    local menu=field(field(controller,'Pawn'),'refBpMenu')
    return valid(menu) and menu or nil
end
local function nativeMenuOpen(menu)
    return valid(menu) and (field(menu,'isAnySpecialMenuOpened')==true or field(menu,'isMenuOpened')==true
        or field(field(menu,'ref_Chat'),'chatOpen')==true) or false
end
local function shared(key,value,write)
    -- ModRef is supplied by UE4SS; only primitive values cross Lua VMs. Never
    -- store transient controller/widget pointers in its shared-variable map.
    if write then ModRef:SetSharedVariable(prefix..key,value)
    else return ModRef:GetSharedVariable(prefix..key) end
end
-- Lua cleanup errors (including stale reflected methods) must not strand
-- routes/input ownership. This does not catch native access violations.
local function cleanup(self,fn)
    local ok,err=pcall(fn)
    if not ok then self.cleanupError=tostring(err) end
end
local function color(r,g,b,a) return {R=r,G=g,B=b,A=a or 1} end
local function install()
    local class=StaticFindObject(template)
    if not valid(class) then LoadAsset(template);class=StaticFindObject(template) end
    assert(valid(class),'mouse button template unavailable')
    local fn=StaticFindObject(clickPath)
    assert(valid(fn),'mouse click function unavailable')
    local address=fn:GetAddress()
    if not hook or hook.address~=address then
        if hook then pcall(UnregisterHook,clickPath,hook.pre,hook.post) end
        -- 0.3.0.7 UI_Template_Button F_ChildClick has no parameters, is not a
        -- delegate signature, and jumps straight to return (bytecode @1728).
        -- UE4SS OnClicked:Add requires UObject + existing UFunction, not Lua.
        local pre,post=RegisterHook(clickPath,function(context)
            -- Already-dispatched callbacks can outlive the last released view.
            if not next(routes) then return end
            local object=context:get();local route=routes[identity(object)]
            if not route then return end
            local owner,entry=route.owner,route.entry
            if not owner.active or not entry.visible or not entry.enabled or not owner:ownsInput() then return end
            local controller=owner.options.controller
            if owner.options.getController then controller=owner.options.getController() end
            -- The previous controller may stay valid during travel. Compare
            -- against the current local controller, not the stored one itself.
            if owner:isCurrent(controller) and owner.options.onAction then
                owner.options.onAction(entry.action,entry.value)
            end
        end)
        hook={address=address,pre=pre,post=post}
    end
    return class
end
function M.new(options)
    assert(valid(options.controller) and valid(options.host),'mouse panel needs a local controller and host')
    return setmetatable({options=options,buttons={},token=identity(options.host),controllerKey=identity(options.controller),
        worldKey=world(options.controller),active=false},Panel)
end
function Panel:ownsInput() return shared('owner')==self.token end
function Panel:isCurrent(controller)
    return valid(self.options.host) and identity(controller)==self.controllerKey and world(controller)==self.worldKey
end
function Panel:button(id,spec)
    local entry=self.buttons[id]
    if not entry then
        local class=install()
        local host=self.options.library:Create(self.options.controller,class,self.options.controller)
        assert(valid(host),'mouse control host creation failed')
        host.bHasScriptImplementedPaint=false;host.bHasScriptImplementedTick=false;host.bIsFocusable=false
        host.playerHoverSound=false
        local button=StaticConstructObject(StaticFindObject('/Script/UMG.Button'),host.WidgetTree)
        local label=StaticConstructObject(StaticFindObject('/Script/UMG.TextBlock'),host.WidgetTree)
        assert(valid(button) and valid(label),'mouse control creation failed')
        button.IsFocusable=false
        host.WidgetTree.RootWidget=button
        label:SetVisibility(3);label:SetAutoWrapText(false);label:SetTextOverflowPolicy(1)
        button:AddChild(label)
        local slot=self.options.root:AddChildToCanvas(host)
        entry={host=host,button=button,label=label,slot=slot,routeKey=identity(host)};self.buttons[id]=entry
        routes[entry.routeKey]={owner=self,entry=entry}
        button.OnClicked:Add(host,clickName)
    end
    entry.action,entry.value=spec.action,spec.value
    entry.visible,entry.enabled=spec.visible~=false,spec.enabled~=false
    entry.slot:SetPosition({X=spec.x,Y=spec.y});entry.slot:SetSize({X=spec.width,Y=spec.height})
    entry.label:SetText(FText(spec.text or ''))
    local font=entry.label.Font;font.FontObject=self.options.font;font.Size=spec.size or 15;entry.label:SetFont(font)
    local tint=entry.label.ColorAndOpacity;tint.SpecifiedColor=color(.94,.95,.97);entry.label:SetColorAndOpacity(tint)
    entry.button:SetBackgroundColor(spec.selected and color(.32,.23,.1) or color(.08,.13,.18))
    entry.button:SetIsEnabled(entry.enabled)
    entry.host:SetVisibility(self.active and entry.visible and 4 or 2)
    return entry
end
function Panel:show(focus)
    local controller=self.options.controller
    if self.active then
        if not self:ownsInput() or not self:isCurrent(controller) then return end
        local menu=menuFor(controller)
        if identity(menu)~=self.menuKey then
            if valid(self.menu) then self.menu.isUiMode=self.priorUiMode or nativeMenuOpen(self.menu) end
            self.menu=menu;self.menuKey=identity(menu);self.priorUiMode=field(menu,'isUiMode')==true
            shared('menu',identity(menu),true);shared('uiMode',self.priorUiMode,true)
        end
        if self.menu then self.menu.isUiMode=true end
        -- Native pickup/menu transitions can return input to gameplay while
        -- our panel stays open. Reacquire only when the cursor was removed;
        -- ordinary refresh must preserve the user's text editing focus.
        if controller.bShowMouseCursor~=true then
            controller.bShowMouseCursor=true
            self.options.library:SetInputMode_GameAndUIEx(controller,focus or self.options.host,0,false,false)
        end
        return
    end
    assert(self:isCurrent(controller),'mouse panel owner changed')
    local inherited=shared('owner') and shared('controller')==self.controllerKey
    local cursor=controller.bShowMouseCursor==true
    if inherited then cursor=shared('cursor')==true end
    self.priorCursor=cursor
    self.menu=menuFor(controller)
    self.menuKey=identity(self.menu)
    self.priorUiMode=field(self.menu,'isUiMode')==true
    if inherited and shared('menu')==identity(self.menu) then self.priorUiMode=shared('uiMode')==true end
    -- BP_Manager_Menu's tick recenters the mouse every 0.1s unless its own
    -- UI state is set. UE input mode/cursor visibility alone do not stop it.
    if self.menu then self.menu.isUiMode=true end
    self.ownsLook=inherited and shared('lookLock')==true
    if not self.ownsLook then controller:SetIgnoreLookInput(true);self.ownsLook=true end
    shared('menu',identity(self.menu),true);shared('uiMode',self.priorUiMode,true);shared('lookLock',self.ownsLook,true)
    shared('controller',self.controllerKey,true);shared('cursor',cursor,true);shared('owner',self.token,true)
    self.active=true
    controller.bShowMouseCursor=true
    focus=focus or self.options.host
    -- Cursor visibility does not establish the current Slate input mode.
    -- Route input to the panel on open, including an already-visible cursor.
    self.options.library:SetInputMode_GameAndUIEx(controller,focus,0,false,false)
    for _,entry in pairs(self.buttons) do entry.host:SetVisibility(entry.visible and 4 or 2) end
end
function Panel:hide(abandon)
    if abandon then
        self.active=false
        if self:ownsInput() then
            -- A seamless transition may retain this PlayerController. Only a
            -- fresh local lookup may release our single lock; old view/menu
            -- references and replaced controllers are never touched.
            local ok,current=pcall(function() return self.options.getController and self.options.getController() end)
            if ok and identity(current)==self.controllerKey and world(current) then
                local menu=menuFor(current);local sameMenu=identity(menu)==self.menuKey
                local otherUi=nativeMenuOpen(menu);local keepUi=self.priorUiMode
                if not sameMenu then keepUi=field(menu,'isUiMode')==true end
                if sameMenu and valid(menu) then cleanup(self,function() menu.isUiMode=self.priorUiMode or otherUi end) end
                if self.ownsLook then cleanup(self,function() current:SetIgnoreLookInput(false) end) end
                cleanup(self,function()
                    if keepUi or otherUi then self.options.library:SetFocusToGameViewport()
                    else self.options.library:SetInputMode_GameOnly(current,false) end
                end)
                cleanup(self,function() current.bShowMouseCursor=self.priorCursor or otherUi or (not sameMenu and keepUi) end)
            end
            for _,key in ipairs({'owner','controller','cursor','menu','uiMode','lookLock'}) do shared(key,nil,true) end
        end
        return
    end
    if self.active then
        self.active=false
        if self:ownsInput() then
            -- The later-opened overlay inherits the original cursor baseline.
            -- A delayed hide from the older overlay must not release its input.
            local controller=self.options.controller
            -- Possession/menu replacement can happen before our next render.
            -- Restore the current native menu's input, not the old pawn's UI.
            local currentMenu=menuFor(controller)
            local sameMenu=identity(currentMenu)==identity(self.menu)
            local keepUi=self.priorUiMode
            if not sameMenu then keepUi=field(currentMenu,'isUiMode')==true end
            local otherUi=nativeMenuOpen(currentMenu)
            if valid(self.menu) and field(self.menu,'isUiMode')==true then
                cleanup(self,function() self.menu.isUiMode=self.priorUiMode or nativeMenuOpen(self.menu) end)
            end
            if valid(controller) then
                if self.ownsLook then cleanup(self,function() controller:SetIgnoreLookInput(false) end) end
                cleanup(self,function()
                    if keepUi or otherUi then self.options.library:SetFocusToGameViewport()
                    else self.options.library:SetInputMode_GameOnly(controller,false) end
                end)
                cleanup(self,function() controller.bShowMouseCursor=self.priorCursor or otherUi or (not sameMenu and keepUi) end)
            end
            shared('owner',nil,true);shared('controller',nil,true);shared('cursor',nil,true)
            shared('menu',nil,true);shared('uiMode',nil,true);shared('lookLock',nil,true)
        end
    end
    for _,entry in pairs(self.buttons) do if valid(entry.host) then cleanup(self,function() entry.host:SetVisibility(2) end) end end
end
function Panel:dispose(abandon)
    self:hide(abandon)
    for _,entry in pairs(self.buttons) do
        routes[entry.routeKey]=nil
        if not abandon and valid(entry.button) and valid(entry.host) then cleanup(self,function() entry.button.OnClicked:Remove(entry.host,clickName) end) end
        if not abandon and valid(entry.host) then cleanup(self,function() entry.host:RemoveFromParent() end) end
    end
    self.buttons={}
    self.menu=nil
    if abandon then self.options={} end
    if not abandon and not next(routes) and hook then
        pcall(UnregisterHook,clickPath,hook.pre,hook.post);hook=nil
    end
end
return M
