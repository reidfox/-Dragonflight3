DRAGONFLIGHT()

local setup = DF.setups.unitframes
DF:NewDefaults('unitframes', setup:GenerateDefaults())

DF:NewModule('unitframes', 1, 'PLAYER_LOGIN', function()
    local playerPortrait = setup:CreateUnitFrame('player', 195, 70)
    playerPortrait:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 45, -30)

    local targetPortrait = setup:CreateUnitFrame('target', 195, 70)
    targetPortrait:SetPoint('LEFT', playerPortrait, 'RIGHT', 50, 0)

    local totPortrait = setup:CreateUnitFrame('targettarget', 195, 70)
    totPortrait:SetPoint('TOPLEFT', targetPortrait, 'BOTTOMRIGHT', -10, -0)

    local petPortrait = setup:CreateUnitFrame('pet', 195, 70)
    petPortrait:SetPoint('TOPLEFT', playerPortrait, 'BOTTOMLEFT', 10, -20)

    local petTargetPortrait = setup:CreateUnitFrame('pettarget', 195, 70)
    petTargetPortrait:SetPoint('TOPLEFT', petPortrait, 'BOTTOMRIGHT', 10, 0)

    for i = 1, 4 do
        local partyFrame = setup:CreateUnitFrame('party'..i, 180, 70)
        if i == 1 then
            partyFrame:SetPoint('TOPLEFT', UIParent, 'LEFT', 10, 170)
        else
            partyFrame:SetPoint('TOPLEFT', setup.portraits[table.getn(setup.portraits)-1], 'BOTTOMLEFT', 0, -10)
        end
    end

    DF.common.KillFrame(PlayerFrame)
    DF.common.KillFrame(TargetFrame)
    DF.common.KillFrame(PetFrame)
    DF.common.KillFrame(PartyMemberFrame1)
    DF.common.KillFrame(PartyMemberFrame2)
    DF.common.KillFrame(PartyMemberFrame3)
    DF.common.KillFrame(PartyMemberFrame4)

    setup:OnUpdate()
    setup:OnEvent()

    playerPortrait.hpBar.max = UnitHealthMax('player')
    playerPortrait.hpBar:SetValue(UnitHealth('player'))
    playerPortrait.powerBar.max = UnitManaMax('player')
    playerPortrait.powerBar:SetValue(UnitMana('player'))
    setup:UpdateNameText(playerPortrait)
    setup:UpdateLevelColor(playerPortrait)

    local callbacks = setup:GenerateCallbacks()
    DF:NewCallbacks('unitframes', callbacks)

    -- Texture callbacks are normally change-driven. Reapply saved selections
    -- once at login so Simple Style's wrapper, crop and offsets do not require
    -- toggling the dropdown off and back on after a reload.
    local textureFrames = {'player', 'target', 'targettarget', 'pet', 'pettarget', 'party'}
    for i = 1, table.getn(textureFrames) do
        local key = textureFrames[i]
        callbacks[key..'HealthBarTexture'](DF.profile['unitframes'][key..'HealthBarTexture'])
        callbacks[key..'ManaBarTexture'](DF.profile['unitframes'][key..'ManaBarTexture'])
        callbacks[key..'PortraitBorderTexture'](DF.profile['unitframes'][key..'PortraitBorderTexture'])
        callbacks[key..'FlipPortraitBorder'](DF.profile['unitframes'][key..'FlipPortraitBorder'])
    end
end)
