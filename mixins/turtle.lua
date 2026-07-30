DRAGONFLIGHT()

function DF.mixins.HideMinimizeMaximizeButton()
    if DF.others.server ~= 'turtle' then return end

    local function DisableMapSizeButton(button)
        if not button then return end

        if button.SetScript then
            button:SetScript('OnClick', nil)
            button:SetScript('OnShow', function()
                this:Hide()
            end)
        end
        if button.Disable then
            button:Disable()
        end
        button:Hide()
        button.Show = function() end
    end

    DisableMapSizeButton(WorldMapFrameMinimizeButton)
    DisableMapSizeButton(WorldMapFrameMaximizeButton)

    if WorldMap_ToggleSizeDown then
        _G.WorldMap_ToggleSizeDown = function() end
    end
    if WorldMap_ToggleSizeUp then
        _G.WorldMap_ToggleSizeUp = function() end
    end
end

function DF.mixins.IsCollectorException(buttonName)
    if DF.others.server ~= 'turtle' then return false end
    return buttonName == 'EBC_Minimap' or buttonName == 'TWMiniMapBattlefieldFrame'
end

function DF.mixins.CleanTurtleTabName(name)
    if DF.others.server ~= 'turtle' or not name then return name end
    local cleaned = string.gsub(name, '^[Zz]+(%u)', '%1')
    return cleaned
end

function DF.mixins.AddInspectTalentTab(customBg)
    if DF.others.server ~= 'turtle' then return end

    if InspectFrameTab3 then
        InspectFrameTab3:Hide()
    end

    local talentTab = customBg:AddTab('Talent', function()
        InspectFrame_ShowSubFrame('InspectTalentFrame')
    end, 60)

    local function UpdateTalentTab()
        if InspectFrame.unit and UnitLevel(InspectFrame.unit) >= 10 then
            talentTab:Show()
        else
            talentTab:Hide()
        end
    end

    DF.hooks.HookScript(InspectFrame, 'OnShow', UpdateTalentTab, true)
    InspectFrame:RegisterEvent('UNIT_LEVEL')
    DF.hooks.HookScript(InspectFrame, 'OnEvent', function()
        if event == 'UNIT_LEVEL' and arg1 == InspectFrame.unit then
            UpdateTalentTab()
        end
    end, true)
end
