DRAGONFLIGHT()

local textures = {
    background = media['tex:castbar:CastingBarBackground.blp'],
    bar = media['tex:castbar:CastingBarStandard3.tga'],
    reforgedBar = media['tex:castbar:CastingBarStandard3_Reforged.tga'],
    border = media['tex:castbar:CastingBarFrame.blp'],
    spark = media['tex:castbar:CastingBarSpark.blp'],
    flash = media['tex:castbar:CastingBarFrameFlash.tga'],
    dropshadow = media['tex:castbar:CastingBarFrameDropShadow.blp']
}

-- public
function DF.lib.CreateCastBar(unit)
    local cast = {}
    cast.unit = unit or 'player'

    cast.config = {
        width = 200,
        height = 16,
        barColor = {1, 0.82, 0},
        alphaSpeed = .9,
        fillDirection = 'left',
        sparkTrail = false,
        trailMaxCount = 15,
        trailSpawnDistance = 5,
        showLag = true,
        autoColorTime = true,
        timeFormatWhole = false,
        showIcon = true,
        showSpellName = true,
        showRank = true,
        showTime = true
    }

    cast.state = {
        fadeOut = false,
        lastCast = nil,
        lastEndTime = nil,
        interrupted = false,
        sparkPositions = {},
        calculatedFadeTime = 1,
        currentLag = 0,
        currentSpellId = nil,
        pushbackOffset = 0,
        channelPushbackOffset = 0,
        lastRawStartTime = nil,
        lastRawEndTime = nil,
        activeMode = nil,
        suppressFishing = false,
        suppressedFishingStart = nil
    }

    function cast:CreateCastFrame()
        local frameName = nil
        if self.unit == 'player' then
            frameName = 'DF_PlayerCastBar'
        elseif self.unit == 'target' then
            frameName = 'DF_TargetCastBar'
        end
        local frame = CreateFrame('Frame', frameName, UIParent)
        frame:SetWidth(self.config.width)
        frame:SetHeight(self.config.height)
        frame:SetAlpha(0)
        frame:Show()
        frame:SetFrameStrata('LOW')
        local dropshadow = frame:CreateTexture(nil, 'BACKGROUND', 1)
        dropshadow:SetWidth(self.config.width + 1)
        dropshadow:SetHeight(self.config.height + 9)
        dropshadow:SetPoint('TOP', frame, 'BOTTOM', 0, 5)
        dropshadow:SetTexture(textures.dropshadow)

        local bg = frame:CreateTexture(nil, 'BACKGROUND', 7)
        bg:SetAllPoints(frame)
        bg:SetTexture(textures.background)

        local icon = frame:CreateTexture(nil, 'BORDER')
        icon:SetWidth(self.config.height)
        icon:SetHeight(self.config.height)
        icon:SetPoint('RIGHT', frame, 'LEFT', -5, 0)
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

        local bar = frame:CreateTexture(nil, 'BORDER')
        bar:SetPoint('LEFT', frame, 'LEFT', 0, 0)
        bar:SetHeight(self.config.height)
        bar:SetWidth(0)
        local useReforgedSkin = DF.profile['gui-generator'] and DF.profile['gui-generator']['interfaceStyle'] == 'Simple Style'
        bar:SetTexture(useReforgedSkin and textures.reforgedBar or textures.bar)
        bar:SetVertexColor(self.config.barColor[1], self.config.barColor[2], self.config.barColor[3])

        local border = frame:CreateTexture(nil, 'ARTWORK')
        border:SetAllPoints(frame)
        border:SetTexture(textures.border)

        local spark = frame:CreateTexture(nil, 'OVERLAY')
        spark:SetHeight(self.config.height + 5)
        spark:SetWidth(25)
        spark:SetTexture(textures.spark)
        spark:SetBlendMode('ADD')
        spark:Hide()

        local spark2 = frame:CreateTexture(nil, 'OVERLAY')
        spark2:SetHeight(self.config.height + 5)
        spark2:SetWidth(25)
        spark2:SetTexture(textures.spark)
        spark2:SetBlendMode('ADD')
        spark2:Hide()

        local flash = frame:CreateTexture(nil, 'OVERLAY')
        flash:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 5)
        flash:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, -5)
        flash:SetTexture(textures.flash)
        flash:SetAlpha(0)
        flash:Hide()

        local text = frame:CreateFontString(nil, 'OVERLAY')
        text:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')
        text:SetPoint('LEFT', frame, 'LEFT', 5, -16)
        text:SetTextColor(1, 1, 1)

        local rankText = frame:CreateFontString(nil, 'OVERLAY')
        rankText:SetFont('Fonts\\FRIZQT__.TTF', 10, 'OUTLINE')
        rankText:SetPoint('LEFT', text, 'RIGHT', 3, 0)
        rankText:SetTextColor(0.9, 0.9, 0.9)

        local timeText = frame:CreateFontString(nil, 'OVERLAY')
        timeText:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')
        timeText:SetPoint('RIGHT', frame, 'RIGHT', -5, -16)
        timeText:SetTextColor(1, 1, 1)

        local sparkTrails = {}
        for i = 1, self.config.trailMaxCount do
            local trail = frame:CreateTexture(nil, 'OVERLAY')
            trail:SetHeight(self.config.height + 5)
            trail:SetWidth(25)
            trail:SetTexture(textures.spark)
            trail:SetBlendMode('ADD')
            trail:Hide()
            sparkTrails[i] = trail
        end

        local lagIndicator = frame:CreateTexture(nil, 'BORDER')
        lagIndicator:SetHeight(self.config.height)
        lagIndicator:SetWidth(0)
        lagIndicator:SetTexture('Interface\\Buttons\\WHITE8x8')
        lagIndicator:SetVertexColor(1, 0, 0)
        lagIndicator:SetAlpha(0.5)
        lagIndicator:Hide()

        local lagIndicator2 = frame:CreateTexture(nil, 'BORDER')
        lagIndicator2:SetHeight(self.config.height)
        lagIndicator2:SetWidth(0)
        lagIndicator2:SetTexture('Interface\\Buttons\\WHITE8x8')
        lagIndicator2:SetVertexColor(1, 0, 0)
        lagIndicator2:SetAlpha(0.5)
        lagIndicator2:Hide()

        self.frame = frame
        self.dropshadow = dropshadow
        self.bg = bg
        self.icon = icon
        self.bar = bar
        self.border = border
        self.spark = spark
        self.spark2 = spark2
        self.flash = flash
        self.text = text
        self.rankText = rankText
        self.timeText = timeText
        self.sparkTrails = sparkTrails
        self.lagIndicator = lagIndicator
        self.lagIndicator2 = lagIndicator2

        return frame
    end

    function cast:UpdateSparkHeights()
        local sparkHeight = self.config.height + 5
        self.spark:SetHeight(sparkHeight)
        self.spark2:SetHeight(sparkHeight)
        for i = 1, self.config.trailMaxCount do
            if self.sparkTrails[i] then
                self.sparkTrails[i]:SetHeight(sparkHeight)
            end
        end
    end

    function cast:UpdateProgress(progress, startTime, endTime)
        progress = DF.math.clamp(progress, 0, 1)
        local totalWidth = self.config.width
        local newWidth = progress * totalWidth
        if newWidth < 0.1 then newWidth = 0.1 end
        local fillDir = self.config.fillDirection

        if self.unit == 'player' and self.config.showLag and startTime and endTime then
            local duration = (endTime - startTime) / 1000
            local lagWidth = (totalWidth / duration) * (self.state.currentLag / 1000)
            lagWidth = math.min(totalWidth, lagWidth)

            if fillDir == 'left' then
                self.lagIndicator:ClearAllPoints()
                self.lagIndicator:SetPoint('RIGHT', self.frame, 'RIGHT', 0, 0)
                self.lagIndicator:SetWidth(lagWidth)
                self.lagIndicator:Show()
                self.lagIndicator2:Hide()
            elseif fillDir == 'right' then
                self.lagIndicator:ClearAllPoints()
                self.lagIndicator:SetPoint('LEFT', self.frame, 'LEFT', 0, 0)
                self.lagIndicator:SetWidth(lagWidth)
                self.lagIndicator:Show()
                self.lagIndicator2:Hide()
            elseif fillDir == 'center' or fillDir == 'centerreversed' then
                local halfLagWidth = lagWidth / 2
                self.lagIndicator:ClearAllPoints()
                self.lagIndicator:SetPoint('LEFT', self.frame, 'LEFT', 0, 0)
                self.lagIndicator:SetWidth(halfLagWidth)
                self.lagIndicator:Show()
                self.lagIndicator2:ClearAllPoints()
                self.lagIndicator2:SetPoint('RIGHT', self.frame, 'RIGHT', 0, 0)
                self.lagIndicator2:SetWidth(halfLagWidth)
                self.lagIndicator2:Show()
            end
        else
            self.lagIndicator:Hide()
            self.lagIndicator2:Hide()
        end

        if fillDir == 'left' then
            self.bar:ClearAllPoints()
            self.bar:SetPoint('LEFT', self.frame, 'LEFT', 0, 0)
            self.bar:SetWidth(newWidth)
            self.bar:SetTexCoord(0, progress, 0, 1)
        elseif fillDir == 'right' then
            local xOffset = totalWidth - newWidth
            self.bar:ClearAllPoints()
            self.bar:SetPoint('LEFT', self.frame, 'LEFT', xOffset, 0)
            self.bar:SetWidth(newWidth)
            self.bar:SetTexCoord(1 - progress, 1, 0, 1)
        elseif fillDir == 'center' then
            local halfWidth = newWidth / 2
            local xOffset = (totalWidth / 2) - halfWidth
            self.bar:ClearAllPoints()
            self.bar:SetPoint('LEFT', self.frame, 'LEFT', xOffset, 0)
            self.bar:SetWidth(newWidth)
            local halfProgress = progress / 2
            self.bar:SetTexCoord(0.5 - halfProgress, 0.5 + halfProgress, 0, 1)
        elseif fillDir == 'centerreversed' then
            local invertedProgress = 1 - progress
            local reversedWidth = invertedProgress * totalWidth
            if reversedWidth < 0.1 then reversedWidth = 0.1 end
            local halfWidth = reversedWidth / 2
            local xOffset = (totalWidth / 2) - halfWidth
            self.bar:ClearAllPoints()
            self.bar:SetPoint('LEFT', self.frame, 'LEFT', xOffset, 0)
            self.bar:SetWidth(reversedWidth)
            local halfProgress = invertedProgress / 2
            self.bar:SetTexCoord(0.5 - halfProgress, 0.5 + halfProgress, 0, 1)
        end

        if self.spark and progress > 0 and progress < 1 then
            local sparkX, sparkX2
            if fillDir == 'left' then
                sparkX = newWidth
                self.spark:SetPoint('CENTER', self.frame, 'LEFT', sparkX, 0)
                self.spark:Show()
                if self.spark2 then self.spark2:Hide() end
            elseif fillDir == 'right' then
                sparkX = totalWidth - newWidth
                self.spark:SetPoint('CENTER', self.frame, 'LEFT', sparkX, 0)
                self.spark:Show()
                if self.spark2 then self.spark2:Hide() end
            elseif fillDir == 'center' then
                local halfWidth = newWidth / 2
                local centerPoint = totalWidth / 2
                sparkX = centerPoint - halfWidth
                sparkX2 = centerPoint + halfWidth
                self.spark:SetPoint('CENTER', self.frame, 'LEFT', sparkX, 0)
                self.spark:Show()
                if self.spark2 then
                    self.spark2:SetPoint('CENTER', self.frame, 'LEFT', sparkX2, 0)
                    self.spark2:Show()
                end
            elseif fillDir == 'centerreversed' then
                local invertedProgress = 1 - progress
                local reversedWidth = invertedProgress * totalWidth
                if reversedWidth < 0.1 then reversedWidth = 0.1 end
                local halfWidth = reversedWidth / 2
                local centerPoint = totalWidth / 2
                sparkX = centerPoint - halfWidth
                sparkX2 = centerPoint + halfWidth
                self.spark:SetPoint('CENTER', self.frame, 'LEFT', sparkX, 0)
                self.spark:Show()
                if self.spark2 then
                    self.spark2:SetPoint('CENTER', self.frame, 'LEFT', sparkX2, 0)
                    self.spark2:Show()
                end
            end

            if self.config.sparkTrail and sparkX then
                local shouldAddPosition = false
                if table.getn(self.state.sparkPositions) == 0 then
                    shouldAddPosition = true
                else
                    local lastPos = self.state.sparkPositions[1]
                    local distance = math.abs(sparkX - lastPos.x1)
                    if distance > self.config.trailSpawnDistance then
                        shouldAddPosition = true
                    end
                end

                if shouldAddPosition then
                    table.insert(self.state.sparkPositions, 1, {x1 = sparkX, x2 = sparkX2, time = GetTime()})
                    if table.getn(self.state.sparkPositions) > self.config.trailMaxCount then
                        table.remove(self.state.sparkPositions)
                    end
                end

                local currentTime = GetTime()
                local fadeTime = self.state.calculatedFadeTime
                local trailIndex = 1
                for i = 1, table.getn(self.state.sparkPositions) do
                    local pos = self.state.sparkPositions[i]
                    if pos then
                        local age = currentTime - pos.time
                        if age < fadeTime then
                            local alpha = 1 - (age / fadeTime)
                            local trail = self.sparkTrails[trailIndex]
                            if trail then
                                trail:SetPoint('CENTER', self.frame, 'LEFT', pos.x1, 0)
                                trail:SetAlpha(alpha)
                                trail:Show()
                                trailIndex = trailIndex + 1
                            end
                            if pos.x2 and trailIndex <= self.config.trailMaxCount then
                                local trail2 = self.sparkTrails[trailIndex]
                                if trail2 then
                                    trail2:SetPoint('CENTER', self.frame, 'LEFT', pos.x2, 0)
                                    trail2:SetAlpha(alpha)
                                    trail2:Show()
                                    trailIndex = trailIndex + 1
                                end
                            end
                        end
                    end
                end
                for i = trailIndex, self.config.trailMaxCount do
                    if self.sparkTrails[i] then
                        self.sparkTrails[i]:Hide()
                    end
                end
            end
        elseif self.spark then
            self.spark:Hide()
            if self.spark2 then self.spark2:Hide() end
            for i = 1, self.config.trailMaxCount do
                if self.sparkTrails[i] then
                    self.sparkTrails[i]:Hide()
                end
            end
            self.state.sparkPositions = {}
        end
    end

    function cast:SetColors(r, g, b, rText, gText, bText)
        self.spark:SetVertexColor(r, g, b)
        if self.spark2 then self.spark2:SetVertexColor(r, g, b) end
        for i = 1, self.config.trailMaxCount do
            if self.sparkTrails[i] then self.sparkTrails[i]:SetVertexColor(r, g, b) end
        end
        self.text:SetTextColor(rText, gText, bText)
        self.rankText:SetTextColor(rText, gText, bText)
    end

    function cast:ResetTimingState(mode, startTime, endTime)
        self.state.pushbackOffset = 0
        self.state.channelPushbackOffset = 0
        self.state.lastRawStartTime = startTime
        self.state.lastRawEndTime = endTime
        self.state.activeMode = mode
    end

    function cast:ClearCastState(keepFishingSuppression)
        self.frame:SetAlpha(0)
        self.state.fadeOut = false
        self.state.lastCast = nil
        self.state.lastEndTime = nil
        self.state.interrupted = false
        self.state.currentSpellId = nil
        self.state.sparkPositions = {}
        self.state.pushbackOffset = 0
        self.state.channelPushbackOffset = 0
        self.state.lastRawStartTime = nil
        self.state.lastRawEndTime = nil
        self.state.activeMode = nil
        if not keepFishingSuppression then
            self.state.suppressFishing = false
            self.state.suppressedFishingStart = nil
        end
        self.bar:SetWidth(0.1)
        self.spark:Hide()
        if self.spark2 then self.spark2:Hide() end
        self.flash:Hide()
        self.icon:Hide()
        self.text:SetText('')
        self.rankText:SetText('')
        self.timeText:SetText('')
        self.lagIndicator:Hide()
        self.lagIndicator2:Hide()
        for i = 1, self.config.trailMaxCount do
            if self.sparkTrails[i] then
                self.sparkTrails[i]:Hide()
            end
        end
    end

    function cast:IsFishingName(name)
        if not name then return false end
        local fishingName = FISHING or PROFESSIONS_FISHING or 'Fishing'
        return string.find(string.lower(name), string.lower(fishingName), 1, true) and true or false
    end

    function cast:SuppressFishingCast()
        if self.unit ~= 'player' then return false end

        local castName, _, _, _, castStart = UnitCastingInfo(self.unit)
        local channelName, _, _, _, channelStart = UnitChannelInfo(self.unit)
        local activeName = channelName or castName or self.state.lastCast
        if not self:IsFishingName(activeName) then return false end

        self.state.suppressFishing = true
        self.state.suppressedFishingStart = channelStart or castStart or self.state.lastRawStartTime
        self:ClearCastState(true)
        return true
    end

    function cast:ApplyDelay(disruption)
        disruption = tonumber(disruption) or 0
        if disruption <= 0 then return end
        if self.unit ~= 'player' then return end
        if not self.state.activeMode then
            if UnitChannelInfo(self.unit) then
                self.state.activeMode = 'channel'
            elseif UnitCastingInfo(self.unit) then
                self.state.activeMode = 'cast'
            end
        end
        if self.state.activeMode == 'channel' then
            self.state.channelPushbackOffset = self.state.channelPushbackOffset + disruption
        elseif self.state.activeMode == 'cast' then
            self.state.pushbackOffset = self.state.pushbackOffset + disruption
        end
    end

    function cast:GetAdjustedCastEndTime(startTime, endTime)
        if self.state.lastRawEndTime and endTime ~= self.state.lastRawEndTime then
            -- If the client/API already reported the pushback-adjusted end time,
            -- trust that value and clear the manual offset to avoid double-counting.
            if endTime > self.state.lastRawEndTime then
                self.state.pushbackOffset = 0
            end
            self.state.lastRawEndTime = endTime
        end
        self.state.lastRawStartTime = startTime
        return endTime + (self.state.pushbackOffset or 0)
    end

    function cast:GetAdjustedChannelEndTime(startTime, endTime)
        if self.state.lastRawEndTime and endTime ~= self.state.lastRawEndTime then
            -- Channel pushback shortens remaining time. If the API already moved
            -- the end time for us, do not also apply the manual offset.
            if endTime < self.state.lastRawEndTime then
                self.state.channelPushbackOffset = 0
            end
            self.state.lastRawEndTime = endTime
        end
        self.state.lastRawStartTime = startTime
        return endTime - (self.state.channelPushbackOffset or 0)
    end

    function cast:UpdateFrame(elapsed)
        local castName, rank, text, icon, startTime, endTime = UnitCastingInfo(self.unit)
        local channelName, channelRank, channelText, channelIcon, channelStart, channelEnd = UnitChannelInfo(self.unit)

        if self.state.suppressFishing then
            local activeName = channelName or castName
            local activeStart = channelName and channelStart or startTime
            local sameFishingCast = self:IsFishingName(activeName) and
                (not self.state.suppressedFishingStart or activeStart == self.state.suppressedFishingStart)
            if sameFishingCast then
                self.frame:SetAlpha(0)
                return
            end
            self.state.suppressFishing = false
            self.state.suppressedFishingStart = nil
        end

        if castName then
            self.state.interrupted = false
            self.state.fadeOut = false
            if castName ~= self.state.lastCast or self.state.activeMode ~= 'cast' or startTime ~= self.state.lastRawStartTime then
                self.state.lastCast = castName
                self:ResetTimingState('cast', startTime, endTime)
                local castDuration = (endTime - startTime) / 1000
                local fadeTime = castDuration * 0.2
                self.state.calculatedFadeTime = DF.math.clamp(fadeTime, 0.3, 2.5)
                if self.unit == 'player' and self.config.showLag then
                    local _, _, lag = GetNetStats()
                    self.state.currentLag = lag or 0
                end
            end

            self.frame:SetAlpha(1)
            self.bar:SetVertexColor(self.config.barColor[1], self.config.barColor[2], self.config.barColor[3])
            self:SetColors(1, 1, 1, 1, 1, 1)
            self.rankText:SetTextColor(0.9, 0.9, 0.9)
            self.flash:Hide()

            local now = GetTime() * 1000
            local adjustedEndTime = self:GetAdjustedCastEndTime(startTime, endTime)
            self.state.lastEndTime = adjustedEndTime
            local progress = DF.math.normalize(now, startTime, adjustedEndTime)
            progress = DF.math.clamp(progress, 0, 1)
            self:UpdateProgress(progress, startTime, adjustedEndTime)

            local remaining = (adjustedEndTime - now) / 1000
            if self.config.showSpellName then
                local displayName = castName
                if string.find(castName, ' %- No Text') then
                    displayName = string.gsub(castName, ' %- No Text', '')
                end
                self.text:SetText(displayName)
            else
                self.text:SetText('')
            end
            if self.config.showRank then
                self.rankText:SetText(rank or '')
            else
                self.rankText:SetText('')
            end
            if self.config.showTime then
                local timeStr = self.config.timeFormatWhole and DF.data.formatTime(remaining, 0) or DF.data.formatTime(remaining)
                self.timeText:SetText(timeStr)
                if self.config.autoColorTime then
                    if remaining < 1 then
                        self.timeText:SetTextColor(1, remaining, remaining)
                    else
                        self.timeText:SetTextColor(1, 1, 1)
                    end
                else
                    self.timeText:SetTextColor(1, 1, 1)
                end
            else
                self.timeText:SetText('')
            end
            if icon and self.config.showIcon then self.icon:SetTexture(icon) self.icon:Show() else self.icon:Hide() end

        elseif channelName then
            self.state.interrupted = false
            self.state.fadeOut = false
            if channelName ~= self.state.lastCast or self.state.activeMode ~= 'channel' or channelStart ~= self.state.lastRawStartTime then
                self.state.lastCast = channelName
                self:ResetTimingState('channel', channelStart, channelEnd)
                local channelDuration = (channelEnd - channelStart) / 1000
                local fadeTime = channelDuration * 0.2
                self.state.calculatedFadeTime = DF.math.clamp(fadeTime, 0.3, 2.5)
                if self.unit == 'player' and self.config.showLag then
                    local _, _, lag = GetNetStats()
                    self.state.currentLag = lag or 0
                end
            end

            self.frame:SetAlpha(1)
            self.bar:SetVertexColor(self.config.barColor[1], self.config.barColor[2], self.config.barColor[3])
            self:SetColors(1, 1, 1, 1, 1, 1)
            self.rankText:SetTextColor(0.9, 0.9, 0.9)
            self.flash:Hide()

            local now = GetTime() * 1000
            local adjustedChannelEnd = self:GetAdjustedChannelEndTime(channelStart, channelEnd)
            self.state.lastEndTime = adjustedChannelEnd
            local timeLeft = adjustedChannelEnd - now
            local progress = DF.math.normalize(timeLeft, 0, adjustedChannelEnd - channelStart)
            progress = DF.math.clamp(progress, 0, 1)
            self:UpdateProgress(progress, channelStart, adjustedChannelEnd)

            if self.config.showSpellName then
                local displayName = channelName
                if string.find(channelName, ' %- No Text') then
                    displayName = string.gsub(channelName, ' %- No Text', '')
                end
                self.text:SetText(displayName)
            else
                self.text:SetText('')
            end
            if self.config.showRank then
                self.rankText:SetText(channelRank or '')
            else
                self.rankText:SetText('')
            end
            local channelRemaining = timeLeft / 1000
            if self.config.showTime then
                local timeStr = self.config.timeFormatWhole and DF.data.formatTime(channelRemaining, 0) or DF.data.formatTime(channelRemaining)
                self.timeText:SetText(timeStr)
                if self.config.autoColorTime then
                    if channelRemaining < 1 then
                        self.timeText:SetTextColor(1, channelRemaining, channelRemaining)
                    else
                        self.timeText:SetTextColor(1, 1, 1)
                    end
                else
                    self.timeText:SetTextColor(1, 1, 1)
                end
            else
                self.timeText:SetText('')
            end
            if channelIcon and self.config.showIcon then self.icon:SetTexture(channelIcon) self.icon:Show() else self.icon:Hide() end

        elseif self.state.lastCast then
            self.state.fadeOut = true
            if self.state.interrupted then
                self.bar:SetVertexColor(1, 0, 0)
                self.flash:SetVertexColor(1, 0, 0)
                self:SetColors(1, 0, 0, 1, 0, 0)
                self.timeText:SetTextColor(1, 0, 0)
            else
                self.flash:SetVertexColor(0, 1, 0)
                self:SetColors(0, 1, 0, 0, 1, 0)
                self.timeText:SetTextColor(0, 1, 0)
            end
            self.flash:SetAlpha(1)
            self.flash:Show()
        end

        if self.state.fadeOut and not castName and not channelName then
            local currentAlpha = self.frame:GetAlpha()
            local newAlpha = DF.math.clamp(currentAlpha - (self.config.alphaSpeed * elapsed), 0, 1)
            if newAlpha <= 0 then
                self.state.fadeOut = false
                self.state.lastCast = nil
                self.state.activeMode = nil
                self.state.pushbackOffset = 0
                self.state.channelPushbackOffset = 0
                self.frame:SetAlpha(0)
            else
                self.frame:SetAlpha(newAlpha)
            end
        end
    end

    cast:CreateCastFrame()
    cast.frame:SetScript('OnUpdate', function()
        cast:UpdateFrame(arg1)
    end)

    local castEventFrame = CreateFrame('Frame')
    castEventFrame:RegisterEvent('UNIT_CASTEVENT')
    if cast.unit == 'player' then
        castEventFrame:RegisterEvent('SPELLCAST_DELAYED')
        castEventFrame:RegisterEvent('LOOT_OPENED')
        castEventFrame:RegisterEvent('LOOT_CLOSED')
    end
    castEventFrame:SetScript('OnEvent', function()
        if event == 'SPELLCAST_DELAYED' then
            cast:ApplyDelay(arg1)
            return
        elseif event == 'LOOT_OPENED' or event == 'LOOT_CLOSED' then
            cast:SuppressFishingCast()
            return
        end

        local casterGUID = arg1
        local eventType = arg3
        local spellid = arg4
        local casterName = UnitName(casterGUID)
        local unitName = UnitName(cast.unit)
        if casterName == unitName then
            -- debugprint("[" .. cast.unit .. "] CASTEVENT: " .. eventType .. " | SpellID: " .. spellid .. " | CurrentID: " .. (cast.state.currentSpellId or "nil"))
            if eventType == 'START' then
                cast.state.currentSpellId = spellid
                cast.state.activeMode = 'cast'
                -- cast.state.interrupted = false
            elseif eventType == 'CHANNEL' then
                cast.state.currentSpellId = spellid
                cast.state.activeMode = 'channel'
                -- cast.state.interrupted = false
            elseif eventType == 'FAIL' then
                if spellid == cast.state.currentSpellId then
                    -- debugprint("[" .. cast.unit .. "] Setting interrupted = true for spell " .. spellid)
                    cast.state.interrupted = true
                    cast.state.currentSpellId = nil
                end
            elseif eventType == 'CAST' then
                if spellid == cast.state.currentSpellId then
                    -- debugprint("[" .. cast.unit .. "] Setting interrupted = false for spell " .. spellid)
                    cast.state.interrupted = false
                    cast.state.currentSpellId = nil
                end
            end
        end
    end)

    if cast.unit == 'target' then
        local eventFrame = CreateFrame('Frame')
        eventFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
        eventFrame:SetScript('OnEvent', function()
            cast:ClearCastState()
        end)
    end

    return cast
end
