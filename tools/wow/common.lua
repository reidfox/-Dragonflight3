DRAGONFLIGHT()

function DF.common.KillFrame(frame)
    if not frame then return end

    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end

    if frame.Hide then
        frame:Hide()
    end

    if frame.GetScript and frame.SetScript then
        local scriptTypes = {
            "OnShow", "OnHide", "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp",
            "OnClick", "OnDoubleClick", "OnDragStart", "OnDragStop", "OnUpdate",
            "OnEvent", "OnLoad", "OnSizeChanged", "OnValueChanged"
        }

        for _, scriptType in ipairs(scriptTypes) do
            local success = pcall(function() return frame:GetScript(scriptType) end)
            if success and frame:GetScript(scriptType) then
            frame:SetScript(scriptType, nil)
            end
        end
    end

    if frame.SetParent then
        frame:SetParent(UIParent)
    end

    if frame.ClearAllPoints then
        frame:ClearAllPoints()
    end

    if frame.SetAlpha then
        frame:SetAlpha(1)
    end

    if frame.Show then
        frame.Show = function() end
    end

    if frame.EnableMouse then
        frame:EnableMouse(false)
    end

    if frame.EnableKeyboard then
        frame:EnableKeyboard(false)
    end
end

function DF.common.MakeFrameResizable(targetFrame, minWidth, minHeight)
    targetFrame:SetResizable(true)
    if minWidth and minHeight then
        targetFrame:SetMinResize(minWidth, minHeight)
    end

    local corners = {'BOTTOMRIGHT', 'TOPRIGHT', 'TOPLEFT', 'BOTTOMLEFT'}

    for i, pointName in corners do
        local edge = CreateFrame('Frame', nil, targetFrame)
        edge:SetSize(10, 10)
        edge:SetPoint(pointName, targetFrame, pointName, 0, 0)
        edge:EnableMouse(true)
        edge:SetAlpha(0)

        local localPoint = pointName
        edge:SetScript('OnMouseDown', function()
            targetFrame:StartSizing(localPoint)
        end)

        edge:SetScript('OnMouseUp', function()
            targetFrame:StopMovingOrSizing()
        end)
    end
end

function DF.common.MakeFrameMovable(targetFrame)
    targetFrame:SetMovable(true)

    local moveHandle = CreateFrame('Frame', nil, targetFrame)
    moveHandle:SetAllPoints(targetFrame)
    moveHandle:EnableMouse(true)
    moveHandle:SetAlpha(0)

    moveHandle:SetScript('OnDragStart', function()
        targetFrame:StartMoving()
    end)

    moveHandle:SetScript('OnDragStop', function()
        targetFrame:StopMovingOrSizing()
    end)
end

function DF.common.CalculateLinearOffset(size, minSize, maxSize, minOffset, maxOffset)
    return minOffset + (size - minSize) * (maxOffset - minOffset) / (maxSize - minSize)
end

function DF.common.InsertChatLink(link, fallback)
    local text = link or fallback
    if not text then return false end

    local intellisense = getglobal('DF_IntelliSense')
    if intellisense and intellisense:IsShown() and intellisense.Insert then
        intellisense:Insert(text)
        return true
    end

    if link and ChatEdit_InsertLink and ChatEdit_InsertLink(link) then
        return true
    end

    if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
        ChatFrameEditBox:Insert(text)
        return true
    end

    return false
end

function DF.common.GetQuestLogLink(questIndex)
    if GetQuestLogQuestLink then
        local link = GetQuestLogQuestLink(questIndex)
        if link then return link end
    end
    if GetQuestLink then
        local link = GetQuestLink(questIndex)
        if link then return link end
    end
    return nil
end

function DF.common.GetSpellBookLink(spellIndex, bookType)
    if GetSpellLink then
        local link = GetSpellLink(spellIndex, bookType)
        if link then return link end
    end

    local name, rank = GetSpellName(spellIndex, bookType)
    if not name then return nil end
    if rank and rank ~= '' then return name .. ' (' .. rank .. ')' end
    return name
end

function DF.common.GetTalentLink(tabIndex, talentIndex)
    if GetTalentLink then
        local link = GetTalentLink(tabIndex, talentIndex)
        if link then return link end
    end

    local name = GetTalentInfo(tabIndex, talentIndex)
    return name
end

-- CreateGoldString: formats copper amount into colorized gold/silver/copper string
-- money (number) - amount in copper
-- returns: formatted string with gold/silver/copper values
function DF.common.CreateGoldString(money)
    if type(money) ~= 'number' then return '-' end
    local gold = floor(money / 100 / 100)
    local silver = floor(math.mod((money / 100), 100))
    local copper = floor(math.mod(money, 100))
    local string = ''
    if gold > 0 then string = string .. '|cffffffff' .. gold .. '|cffffd700g' end
    if silver > 0 or gold > 0 then
        if string ~= '' then string = string .. ' ' end
        string = string .. '|cffffffff' .. silver .. '|cffc7c7cfs'
    end
    if string ~= '' then string = string .. ' ' end
    string = string .. '|cffffffff' .. copper .. '|cffeda55fc'
    return string
end
