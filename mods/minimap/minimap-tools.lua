DRAGONFLIGHT()

local minimap = {}

minimap.textures = {
    border = media['tex:minimap:uiminimapborder.tga'],
    shadow = media['tex:minimap:uiminimapshadow.tga'],
    backdrop = media['tex:generic:backdrop_rounded.blp'],
    roundBorder = media['tex:generic:generic_round_border_shiny.blp'],
    zoomIn = media['tex:minimap:ZoomIn32.tga'],
    zoomInPush = media['tex:minimap:ZoomIn32-push.tga'],
    zoomInOver = media['tex:minimap:ZoomIn32-over.tga'],
    zoomInDisabled = media['tex:minimap:ZoomIn32-disabled.tga'],
    zoomOut = media['tex:minimap:ZoomOut32.tga'],
    zoomOutPush = media['tex:minimap:ZoomOut32-push.tga'],
    zoomOutOver = media['tex:minimap:ZoomOut32-over.tga'],
    zoomOutDisabled = media['tex:minimap:ZoomOut32-disabled.tga']
}

minimap.config = {
    width = 150,
    height = 150,
    topPanelHeight = 20,
    buttonSize = 32
}

function minimap:CreateMinimapCluster()
    local frame = CreateFrame('Frame', 'DF_MinimapCluster', UIParent)
    frame:SetHeight(self.config.height)
    frame:SetWidth(self.config.width)
    frame:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -50, -70)
    frame:SetFrameStrata('MEDIUM')
    return frame
end

function minimap:CreateTopPanel(cluster)
    local panel = CreateFrame('Frame', 'DF_TopPanel', UIParent)
    panel:SetHeight(self.config.topPanelHeight)
    panel:SetWidth(self.config.width - 30)
    panel:SetPoint('BOTTOM', cluster, 'TOP', 0, 30)

    local border = panel:CreateTexture(nil, 'ARTWORK')
    border:SetAllPoints(panel)
    border:SetTexture(self.textures.backdrop)
    border:SetVertexColor(0, 0, 0, 0.4)

    local timeText = DF.ui.Font(panel, 11, '00:00', {1, 1, 1}, 'RIGHT')
    timeText:SetPoint('RIGHT', panel, 'RIGHT', -11, 0)

    local zoneFrame = CreateFrame('Frame', nil, panel)
    zoneFrame:SetPoint('LEFT', panel, 'LEFT', 0, 0)
    zoneFrame:SetHeight(self.config.topPanelHeight)
    zoneFrame:EnableMouse(true)
    zoneFrame:SetFrameLevel(panel:GetFrameLevel())

    local zoneText = DF.ui.Font(zoneFrame, 11, 'Zone', {1, 0.82, 0}, 'CENTER')
    zoneFrame:SetWidth(zoneText:GetStringWidth() + 15)
    zoneText:SetPoint('CENTER', zoneFrame, 'CENTER', 0, 0)

    zoneFrame:SetScript('OnEnter', function()
        local pvpType, factionName, isArena = GetZonePVPInfo()
        GameTooltip:SetOwner(this, 'ANCHOR_LEFT')
        GameTooltip:AddLine(GetMinimapZoneText(), '', 1.0, 1.0, 1.0)
        if (pvpType == 'friendly') or (pvpType == 'hostile') then
            GameTooltip:AddLine(string.format(FACTION_CONTROLLED_TERRITORY, factionName), '', 1.0, 1.0, 1.0)
        elseif pvpType == 'contested' then
            GameTooltip:AddLine(CONTESTED_TERRITORY, '', 1.0, 1.0, 1.0)
        elseif pvpType == 'arena' then
            GameTooltip:AddLine(FREE_FOR_ALL_TERRITORY, '', 1.0, 1.0, 1.0)
        end
        GameTooltip:Show()
    end)
    zoneFrame:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    return panel, timeText, zoneText
end

function minimap:CreateZoomButtons(cluster)
    local zoomIn = CreateFrame('Button', 'DF_MinimapZoomIn', cluster)
    zoomIn:SetHeight(self.config.buttonSize)
    zoomIn:SetWidth(self.config.buttonSize)
    zoomIn:SetPoint('TOPLEFT', Minimap, 'BOTTOMRIGHT', -5, 20)
    zoomIn:SetNormalTexture(self.textures.zoomIn)
    zoomIn:SetPushedTexture(self.textures.zoomInPush)
    zoomIn:SetHighlightTexture(self.textures.zoomInOver)
    zoomIn:SetDisabledTexture(self.textures.zoomInDisabled)

    zoomIn:SetScript('OnEnter', function()
        GameTooltip:SetOwner(this, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Zoom In')
        GameTooltip:Show()
    end)
    zoomIn:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    local zoomOut = CreateFrame('Button', 'DF_MinimapZoomOut', cluster)
    zoomOut:SetHeight(self.config.buttonSize)
    zoomOut:SetWidth(self.config.buttonSize)
    zoomOut:SetPoint('TOPRIGHT', zoomIn, 'BOTTOMLEFT', -0, -0)
    zoomOut:SetNormalTexture(self.textures.zoomOut)
    zoomOut:SetPushedTexture(self.textures.zoomOutPush)
    zoomOut:SetHighlightTexture(self.textures.zoomOutOver)
    zoomOut:SetDisabledTexture(self.textures.zoomOutDisabled)

    zoomOut:SetScript('OnEnter', function()
        GameTooltip:SetOwner(this, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Zoom Out')
        GameTooltip:Show()
    end)
    zoomOut:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    return zoomIn, zoomOut
end

function minimap:SetupMinimap(cluster)
    Minimap:SetParent(cluster)
    Minimap:ClearAllPoints()
    Minimap:SetPoint('CENTER', cluster, 'CENTER', 0, -10)
    Minimap:SetHeight(150)
    Minimap:SetWidth(150)
    Minimap:SetFrameStrata('MEDIUM')

    local border = Minimap:CreateTexture(nil, 'ARTWORK')
    border:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -12, 13)
    border:SetPoint('BOTTOMRIGHT', Minimap, 'BOTTOMRIGHT', 12, -11)
    border:SetTexture(self.textures.border)

    local shadow = Minimap:CreateTexture('MinimapShadow', 'BORDER')
    shadow:SetTexture(self.textures.shadow)
    shadow:SetAllPoints(Minimap)
    shadow:Hide()

    DF.common.KillFrame(MinimapCluster)
    DF.common.KillFrame(MinimapBackdrop)
    DF.common.KillFrame(MinimapZoomIn)
    DF.common.KillFrame(MinimapZoomOut)

    return border, shadow
end

function minimap:SetupZoomLogic(zoomIn, zoomOut)
    zoomIn:SetScript('OnClick', function()
        PlaySound('igMiniMapZoomIn')
        Minimap:SetZoom(Minimap:GetZoom() + 1)
        if Minimap:GetZoom() == (Minimap:GetZoomLevels() - 1) then
            zoomIn:Disable()
        end
        zoomOut:Enable()
    end)

    zoomOut:SetScript('OnClick', function()
        PlaySound('igMiniMapZoomOut')
        Minimap:SetZoom(Minimap:GetZoom() - 1)
        if Minimap:GetZoom() == 0 then
            zoomOut:Disable()
        end
        zoomIn:Enable()
    end)

    local currentZoom = Minimap:GetZoom()
    if currentZoom == 0 then
        zoomOut:Disable()
    end
    if currentZoom == (Minimap:GetZoomLevels() - 1) then
        zoomIn:Disable()
    end
end

function minimap:SetupZoneUpdater(zoneText)
    local updater = CreateFrame('Frame')
    updater:RegisterEvent('MINIMAP_ZONE_CHANGED')
    updater:RegisterEvent('PLAYER_ENTERING_WORLD')
    updater:SetScript('OnEvent', function()
        zoneText:SetText(GetMinimapZoneText())
    end)
    zoneText:SetText(GetMinimapZoneText())
    return updater
end

function minimap:SetupTimeUpdater(timeText)
    DF.timers.every(1, function()
        timeText:SetText(DF.date.currentTime)
    end)
end

function minimap:SetupBlizzardIcons()
    MiniMapMailFrame:ClearAllPoints()
    MiniMapMailFrame:SetPoint('BOTTOMRIGHT', Minimap, 'TOPLEFT', 15, 10)
    MiniMapMailIcon:SetTexture(media['tex:minimap:mail.tga'])
    MiniMapMailIcon:SetWidth(32)
    MiniMapMailIcon:SetHeight(32)
    MiniMapMailBorder:Hide()

    MiniMapTrackingFrame:ClearAllPoints()
    MiniMapTrackingFrame:SetPoint('BOTTOMRIGHT', Minimap, 'TOPLEFT', 35, -35)
    MiniMapTrackingFrame:SetFrameLevel(Minimap:GetFrameLevel() + 1)
    MiniMapTrackingFrame:SetScale(.8)
    MiniMapTrackingBorder:Hide()

    local trackingBorder = MiniMapTrackingFrame:CreateTexture(nil, 'OVERLAY')
    trackingBorder:SetPoint('TOPLEFT', MiniMapTrackingFrame, 'TOPLEFT', 2, -1)
    trackingBorder:SetPoint('BOTTOMRIGHT', MiniMapTrackingFrame, 'BOTTOMRIGHT', 3, -3)
    trackingBorder:SetTexture(minimap.textures.roundBorder)
end

-- public
function DF.lib.CreateMinimapUI()
    local cluster = minimap:CreateMinimapCluster()
    local border, shadow = minimap:SetupMinimap(cluster)
    local topPanel, timeText, zoneText = minimap:CreateTopPanel(cluster)
    local zoomIn, zoomOut = minimap:CreateZoomButtons(cluster)

    minimap:SetupZoomLogic(zoomIn, zoomOut)
    local zoneUpdater = minimap:SetupZoneUpdater(zoneText)
    minimap:SetupTimeUpdater(timeText)
    minimap:SetupBlizzardIcons()

    return cluster, border, shadow, topPanel, timeText, zoneText, zoomIn, zoomOut
end

function DF.lib.CreateGameTimeButton(parent)
    local button = CreateFrame('Frame', 'DF_GameTimeButton', parent)
    button:SetWidth(25)
    button:SetHeight(25)
    button:EnableMouse(true)
    button.timeOfDay = 0

    local border = button:CreateTexture(nil, 'OVERLAY')
    border:SetPoint('TOPLEFT', button, 'TOPLEFT', 1, -1)
    border:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -1, 1)
    border:SetTexture(minimap.textures.roundBorder)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints(button)
    icon:SetTexture('Interface\\Minimap\\UI-TOD-Indicator')

    button:SetScript('OnUpdate', function()
        local hour, minute = GetGameTime()
        local time = (hour * 60) + minute
        if time ~= this.timeOfDay then
            this.timeOfDay = time
            local minx, maxx = 0, 50/128
            local miny, maxy = 0, 50/64
            if time < 330 or time >= 1260 then
                minx = minx + 0.5
                maxx = maxx + 0.5
            end
            icon:SetTexCoord(minx, maxx, miny, maxy)
        end
    end)

    button:SetScript('OnEnter', function()
        local hour, minute = GetGameTime()
        GameTooltip:SetOwner(this, 'ANCHOR_RIGHT')
        GameTooltip:SetText(string.format('%02d:%02d', hour, minute))
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    DF.common.KillFrame(GameTimeFrame)

    return button, border, icon
end

function DF.lib.CreateCustomPlayerArrow()
    local playerArrow
    for k, v in pairs({Minimap:GetChildren()}) do
        if v:IsObjectType('Model') and not v:GetName() then
            local model = v:GetModel()
            if model and string.find(string.lower(model), 'interface\\minimap\\minimaparrow') then
                playerArrow = v
                playerArrow:Hide()
                break
            end
        end
    end

    local arrowFrame = CreateFrame('Frame', nil, Minimap)
    arrowFrame:SetWidth(32)
    arrowFrame:SetHeight(32)
    arrowFrame:SetPoint('CENTER', Minimap, 'CENTER', 1, 1)
    arrowFrame:SetFrameStrata('MEDIUM')

    local arrowTex = arrowFrame:CreateTexture(nil, 'OVERLAY')
    arrowTex:SetTexture(media['tex:minimap:MinimapArrow.blp'])
    arrowTex:SetAllPoints(arrowFrame)

    arrowFrame:SetScript('OnUpdate', function()
        if playerArrow then
            local facing = playerArrow:GetFacing()
            if facing then
                local angle = facing - (3 * math.pi / 2)
                if angle < 0 then angle = angle + (2 * math.pi) end
                angle = angle * 180 / math.pi
                angle = angle + 49

                local s = math.sin(math.rad(angle))
                local c = math.cos(math.rad(angle))
                arrowTex:SetTexCoord(
                    0.5 - s, 0.5 + c,
                    0.5 + c, 0.5 + s,
                    0.5 - c, 0.5 - s,
                    0.5 + s, 0.5 - c
                )
            end
        end
    end)

    return arrowFrame, arrowTex, playerArrow
end

function DF.lib.CreateButtonSkinner(onChanged)
    local ignored = {'Note', 'JQuest', 'Naut_', 'MinimapIcon', 'GatherMatePin', 'WestPointer', 'Chinchilla_', 'SmartMinimapZoom', 'QuestieNote', 'smm', 'pfMiniMapPin', 'MiniMapBattlefieldFrame', 'pfMinimapButton', 'GatherNote', 'MiniNotePOI', 'FWGMinimapPOI', 'RecipeRadarMinimapIcon', 'MiniMapTracking', 'CartographerNotesPOI'}

    local function IsIgnored(name)
        if not name then return false end
        local lowerName = strlower(name)
        for _, prefix in ipairs(ignored) do
            if strfind(lowerName, strlower(prefix)) == 1 then
                return true
            end
        end
        return false
    end

    local function IsButton(frame, uiParentChild)
        if not frame or not frame.IsObjectType then return false end

        local width = frame:GetWidth() or 0
        local height = frame:GetHeight() or 0
        if width <= 0 or height <= 0 or width > 50 or height > 50 then return false end
        if not frame:IsVisible() then return false end

        local name = frame:GetName()
        if IsIgnored(name) then return false end

        local hasClick = frame:GetScript('OnClick') or frame:GetScript('OnMouseDown') or frame:GetScript('OnMouseUp')
        if not hasClick then return false end

        -- A few older addons parent their minimap button to UIParent and only
        -- anchor it to the minimap. Limit that broad scan to minimap/error
        -- button names so normal action and menu buttons are never collected.
        if uiParentChild then
            if not name then return false end
            local lowerName = strlower(name)
            if not strfind(lowerName, 'minimap') and
               not strfind(lowerName, 'improvederror') and
               not strfind(lowerName, 'interfaceerror') and
               not strfind(lowerName, 'ief') then
                return false
            end
        end

        if frame:IsObjectType('Button') then return true end
        if frame:IsObjectType('Frame') and name then
            local lowerName = strlower(name)
            return strfind(lowerName, 'icon') or strfind(lowerName, 'button')
        end
        return false
    end

    local function ScanForButtons()
        local buttons = {}
        local visited = {}

        local function AddButton(button)
            if button and not visited[button] then
                visited[button] = true
                if IsButton(button, false) then
                    table.insert(buttons, button)
                end
            end
        end

        local function ScanChildren(parent, depth)
            if not parent or depth > 4 then return end
            for _, child in ipairs({parent:GetChildren()}) do
                if not visited[child] then
                    visited[child] = true
                    if IsButton(child, false) then
                        table.insert(buttons, child)
                    end
                    if child:GetNumChildren() > 0 then
                        ScanChildren(child, depth + 1)
                    end
                end
            end
        end

        ScanChildren(Minimap, 1)
        ScanChildren(MinimapBackdrop, 1)

        -- Compatibility path for buttons anchored to, rather than parented by,
        -- the minimap (used by some ImprovedErrorFrame-era addons).
        for _, child in ipairs({UIParent:GetChildren()}) do
            if not visited[child] and IsButton(child, true) then
                visited[child] = true
                table.insert(buttons, child)
            end
        end

        -- These FuBar plugins expose the real minimap frame directly. This
        -- avoids relying on load order or on which embedded FuBarPlugin copy
        -- won library activation. IEF is hidden until it actually has an error.
        AddButton(NampowerOptions and NampowerOptions.minimapFrame)
        AddButton(SuperAPIOptions and SuperAPIOptions.minimapFrame)
        AddButton(IEFMinimapButton)

        return buttons
    end

    local function SkinButton(btn)
        local regions = {btn:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region:GetObjectType() == 'Texture' then
                local texture = region:GetTexture()
                if type(texture) == 'string' and strfind(strlower(texture), 'minimap%-trackingborder') then
                    region:SetTexture(nil)
                    region:Hide()
                end
            end
        end

        local bgframe = CreateFrame('Frame', nil, btn)
        bgframe:SetFrameStrata('BACKGROUND')
        bgframe:SetFrameLevel(0)
        bgframe:SetPoint('TOPLEFT', btn, 'TOPLEFT', 0, 0)
        bgframe:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', 0, 0)
        local bg = bgframe:CreateTexture(nil, 'BACKGROUND')
        bg:SetTexture(media['tex:generic:solid_small_round.blp'])
        bg:SetAllPoints(bgframe)

        local border = btn:CreateTexture(nil, 'OVERLAY')
        border:SetTexture(media['tex:generic:generic_round_border_shiny.blp'])
        border:SetPoint('TOPLEFT', btn, 'TOPLEFT', 2, -2)
        border:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', -2, 2)
    end

    local skinned = {}
    local function UpdateButtons()
        local changed = false
        for _, btn in ipairs(ScanForButtons()) do
            if not skinned[btn] then
                SkinButton(btn)
                skinned[btn] = btn
                changed = true
            end
        end
        if onChanged then
            -- Also refresh unchanged buttons. Some addons set their minimap
            -- point after our first scan, and the collector must reclaim it.
            onChanged(skinned, changed)
        end
    end

    UpdateButtons()
    -- Keep watching: FuBarPlugin-based addons may create or reveal their
    -- minimap buttons several seconds after login or after an addon reload.
    DF.timers.every(0.5, UpdateButtons)

    return skinned
end
