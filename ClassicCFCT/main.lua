local addonName, CFCT = ...
_G[addonName] = CFCT
local tinsert, tremove, tsort, format, strlen, strsub, gsub, floor, sin, cos, asin, acos, random, select, pairs, ipairs, unpack, bitband, bitbor = table.insert, table.remove, table.sort, string.format, string.len, string.sub, string.gsub, math.floor, math.sin, math.cos, math.asin, math.acos, math.random, select, pairs, ipairs, unpack, bit.band, bit.bor
local InCombatLockdown = InCombatLockdown
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime

local function AbbreviateNumbers(value)
    local suffixes = {"", "K", "M", "B", "T"}
    local index = 1
    while value >= 1000 and index < #suffixes do
        value = value / 1000
        index = index + 1
    end
    return string.format("%.1f%s", value, suffixes[index])
end

CFCT.frame = CreateFrame("Frame", "ClassicFCT.frame", UIParent)
CFCT.Animating = {}
CFCT.fontStringCache = {}
CFCT.cachedNameplates = {}

local now = GetTime()
local f = CFCT.frame
f:SetSize(1,1)
f:SetPoint("CENTER", 0, 0)

local anim = CFCT.Animating
local fsc = CFCT.fontStringCache

local function round(n, d)
    local p = 10^d
    return math.floor(n * p) / p
end

local damageRollingAverage = 0
function CFCT:DamageRollingAverage()
    return damageRollingAverage
end

local ROLLING_AVERAGE_LENGTH = 10
local rollingAverageTimer = 0
local damageCache = {}
local function AddToAverage(value)
    if CFCT._testMode and not InCombatLockdown() then return end
    tinsert(damageCache, {
        value = value,
        time = now
    })
end

local ROLLINGAVERAGE_UPDATE_INTERVAL = 0.5
local function CalculateRollingAverage()
    local cacheSize = #damageCache
    local damage, count = 0, 0
    for k,v in ipairs(damageCache) do
        if (cacheSize > 200) and ((now - v.time) > ROLLING_AVERAGE_LENGTH) then
            tremove(damageCache, k)
        else
            damage = damage + v.value
            count = count + 1
        end
    end
    damageRollingAverage = count > 0 and damage / count or 0
end

local function FormatThousandSeparator(v)
    local s = format("%d", floor(v))
    local pos = strlen(s) % 3
    if pos == 0 then pos = 3 end
    return strsub(s, 1, pos)..gsub(strsub(s, pos+1), "(...)", ",%1")
end

-- Fixed InitFont function for WotLK 3.3.5a compatibility
local function InitFont(self, state)
    local fontOptions = state.fontOptions

    if not (fontOptions and fontOptions.fontPath and fontOptions.fontSize) then
        return self
    end

    -- Set font immediately
    self:SetFont(fontOptions.fontPath, fontOptions.fontSize, fontOptions.fontStyle)
    self:SetShadowOffset(fontOptions.fontSize / 14, fontOptions.fontSize / 14)
    self:SetDrawLayer("OVERLAY")
    self:SetJustifyH("CENTER")
    self:SetJustifyV("MIDDLE")
    
    -- Store state and original font info
    self.state = state
    self.state.originalFontSize = fontOptions.fontSize
    self.state.fontPath = fontOptions.fontPath
    self.state.fontStyle = fontOptions.fontStyle

    -- Set text
    if state.text then
        self:SetText(state.text)
    end

    -- Set colors (force alpha to 1)
    local r, g, b = fontOptions.fontColor[1], fontOptions.fontColor[2], fontOptions.fontColor[3]
    self:SetTextColor(r, g, b, 1)
    self:SetAlpha(fontOptions.fontAlpha)
    self:SetShadowColor(0, 0, 0, fontOptions.fontAlpha / 2)

    state.initialTime = now
    state.strHeight = self:GetStringHeight()
    state.strWidth = self:GetStringWidth()
    state.posX = 0
    state.posY = 0
    state.direction = 0

    self:Hide()
    return self
end

local function ReleaseFont(self)
    -- Clean up cached nameplate if this was the last text for this GUID
    if self.state and self.state.guid and CFCT.cachedNameplates then
        local guid = self.state.guid
        local hasOtherTexts = false
        
        for _, frame in ipairs(anim) do
            if frame.state and frame.state.guid == guid and frame ~= self then
                hasOtherTexts = true
                break
            end
        end
        
        if not hasOtherTexts then
            CFCT.cachedNameplates[guid] = nil
        end
    end
    
    self.state = nil
    self:Hide()
    tinsert(fsc, self)
end

-- New grid position generator for square rings
local function get_square_grid_positions(n, gap)
    local positions = {}
    -- Center
    table.insert(positions, {x=0, y=0})
    if n == 1 then return positions end
    -- First ring (8 house spots)
    local d = gap
    local first_ring = {
        {x=0, y=d},         -- top
        {x=d, y=d},         -- top-right
        {x=d, y=0},         -- right
        {x=d, y=-d},        -- bottom-right
        {x=0, y=-d},        -- bottom
        {x=-d, y=-d},       -- bottom-left
        {x=-d, y=0},        -- left
        {x=-d, y=d},        -- top-left
    }
    for _, pos in ipairs(first_ring) do table.insert(positions, pos) end
    if n <= 9 then return positions end
    -- Second ring (12 grid spots)
    local d2 = 2 * gap
    local second_ring = {
        {x=0, y=d2}, {x=gap, y=d2}, {x=-gap, y=d2}, -- top 1, top 2
        {x=d2, y=0}, {x=d2, y=gap}, {x=d2, y=-gap}, -- right 1, right 2
        {x=0, y=-d2}, {x=gap, y=-d2}, {x=-gap, y=-d2}, -- bottom 1, bottom 2
        {x=-d2, y=0}, {x=-d2, y=gap}, {x=-d2, y=-gap}, -- left 1, left 2
    }
    for _, pos in ipairs(second_ring) do table.insert(positions, pos) end
    if n <= 21 then return positions end
    -- Further rings: expand in a square grid
    local ring = 3
    while #positions < n do
        local dist = ring * gap
        for dx = -ring, ring do
            for dy = -ring, ring do
                if math.abs(dx) == ring or math.abs(dy) == ring then
                    local px = dx * gap
                    local py = dy * gap
                    -- Avoid duplicates
                    local duplicate = false
                    for _, p in ipairs(positions) do
                        if p.x == px and p.y == py then duplicate = true break end
                    end
                    if not duplicate then
                        table.insert(positions, {x=px, y=py})
                        if #positions >= n then break end
                    end
                end
            end
            if #positions >= n then break end
        end
        ring = ring + 1
    end
    return positions
end

local function GridLayout(unsortedFrames)
    local fctConfig = CFCT.Config
    local frames = {}
    if fctConfig.sortByDamage then
        local missPrio = fctConfig.sortMissPrio
        local count = 0
        for k,v in ipairs(unsortedFrames) do
            if (k == 1) then
                tinsert(frames, v)
                count = count + 1
            else
                local s1 = v.state
                for i,e in ipairs(frames) do
                    local s2 = e.state
                    if (not s2.miss and not s1.miss) and (s2.amount < s1.amount) then
                        tinsert(frames, i, v)
                        count = count + 1
                        break
                    elseif (s1.miss ~= s2.miss) and ((s1.miss and missPrio) or not s1.miss) then
                        tinsert(frames, i, v)
                        count = count + 1
                        break
                    elseif (i == count) then
                        tinsert(frames, i + 1, v)
                        count = count + 1
                        break
                    end
                end
            end
        end
    else
        frames = unsortedFrames
    end
    -- Calculate gap based on font size, icon, and padding
    local maxFontSize = 0
    local iconExtra = 0
    for _, e in ipairs(frames) do
        if e.state and e.state.fontOptions and e.state.fontOptions.fontSize then
            if e.state.fontOptions.fontSize > maxFontSize then
                maxFontSize = e.state.fontOptions.fontSize
            end
            if e.state.icon then
                iconExtra = 24 -- adjust if your icon is a different width
            end
        end
    end
    local padding = 8
    local gap = maxFontSize + iconExtra + padding
    -- Sort frames by creation time so oldest frames get center position
    local sortedFrames = {}
    for _, frame in ipairs(frames) do
        table.insert(sortedFrames, frame)
    end
    table.sort(sortedFrames, function(a, b)
        return (a.state.initialTime or 0) < (b.state.initialTime or 0)
    end)
    -- Generate enough grid positions
    local positions = get_square_grid_positions(#sortedFrames, gap)
    -- Build a set of used indices
    local used = {}
    for _, e in ipairs(sortedFrames) do
        if e.state.gridIdx then
            used[e.state.gridIdx] = true
        end
    end
    -- Assign gridIdx persistently
    local available = {}
    for i = 1, #positions do
        if not used[i] then table.insert(available, i) end
    end
    -- Guarantee: Once a frame is assigned a gridIdx, it is never changed for its lifetime.
    -- If a frame already has a gridIdx, we assert it does not change.
    for k, e in ipairs(sortedFrames) do
        if e.state.gridIdx then
            -- Assert that gridIdx is never reassigned
            assert(e.state._gridIdxAssigned == nil or e.state._gridIdxAssigned == e.state.gridIdx, "GridIdx for a frame was changed after assignment! This should never happen.")
            e.state._gridIdxAssigned = e.state.gridIdx
        end
        if not e.state.gridIdx then
            if k == 1 then
                e.state.gridIdx = 1
                used[1] = true
            else
                -- Randomly pick from available spots in the lowest ring
                local ringStart, ringEnd
                if k <= 9 then ringStart, ringEnd = 2, 9
                elseif k <= 21 then ringStart, ringEnd = 10, 21
                else ringStart, ringEnd = 22, #positions end
                -- Build a list of available spots in this ring
                local ringAvailable = {}
                for i = ringStart, ringEnd do
                    if not used[i] then table.insert(ringAvailable, i) end
                end
                if #ringAvailable > 0 then
                    local idx = ringAvailable[math.random(#ringAvailable)]
                    e.state.gridIdx = idx
                    used[idx] = true
                else
                    -- Fallback: pick any available
                    if #available > 0 then
                        local idx = table.remove(available, 1)
                        e.state.gridIdx = idx
                        used[idx] = true
                    else
                        -- Should not happen, but fallback to center
                        e.state.gridIdx = 1
                    end
                end
            end
            -- Mark that this frame has had its gridIdx assigned
            e.state._gridIdxAssigned = e.state.gridIdx
        end
        local pos = positions[e.state.gridIdx] or {x=0, y=0}
        local gridX = pos.x
        local gridY = pos.y
        e.state.posX = e.state.posX + gridX - (e.state.gridX or 0)
        e.state.posY = e.state.posY + gridY - (e.state.gridY or 0)
        e.state.gridX = gridX
        e.state.gridY = gridY
    end
    return frames
end

local function AnimateLinearAbsolute(startTime, duration, minval, maxval)
    local prog = min(max((now - startTime) / duration, 0), 1)
    return (maxval - minval) * prog + minval
end

-- Fixed animation system to use font size scaling instead of SetScale
local ANIMATIONS = {
    Pow = function(self, catConfig, animConfig)
        local duration = animConfig.duration * CFCT.Config.animDuration
        local midTime = self.state.initialTime + (duration * animConfig.inOutRatio)
        if (now < midTime) then
            self.state.powScale = AnimateLinearAbsolute(self.state.initialTime, midTime - self.state.initialTime, animConfig.initScale, animConfig.midScale)
        else
            self.state.powScale = AnimateLinearAbsolute(midTime, duration * (1 - animConfig.inOutRatio), animConfig.midScale, animConfig.endScale)
        end
    end,
    FadeIn = function(self, catConfig, animConfig)
        local duration = animConfig.duration * CFCT.Config.animDuration
        local endTime = self.state.initialTime + duration
        if (now <= endTime) then
            local fadeInAlpha = AnimateLinearAbsolute(self.state.initialTime, duration, 0, self.state.fontOptions.fontAlpha)
            self.state.fadeAlpha = (fadeInAlpha + (self.state.fadeOutAlpha or fadeInAlpha)) * 0.5
            self.state.fadeInAlpha = fadeInAlpha
        else
            self.state.fadeInAlpha = nil
        end
    end,
    FadeOut = function(self, catConfig, animConfig)
        local duration = animConfig.duration
        local startTime = self.state.initialTime + CFCT.Config.animDuration - duration
        if (now >= startTime) then
            local fadeOutAlpha = AnimateLinearAbsolute(startTime, duration, self.state.fontOptions.fontAlpha, 0)
            self.state.fadeAlpha = (fadeOutAlpha + (self.state.fadeInAlpha or fadeOutAlpha)) * 0.5
            self.state.fadeOutAlpha = fadeOutAlpha
        else
            self.state.fadeOutAlpha = nil
        end
    end,
    Scroll = function(self, catConfig, animConfig)
        local duration = CFCT.Config.animDuration
        local state, dir, dist, scrollX, scrollY = self.state, animConfig.direction, animConfig.distance, 0, 0

        if dir:find("RANDOM") then
            if (state.randomX == nil) and (state.randomY == nil) then
                local a = random(1,628) / 100
                local rx, ry = cos(a), sin(a)
                state.randomX, state.randomY =  rx * dist, ry * dist
            end
            scrollX = AnimateLinearAbsolute(state.initialTime, duration, 0, state.randomX)
            scrollY = AnimateLinearAbsolute(state.initialTime, duration, 0, state.randomY)
        elseif dir:find("RIGHT") then
            scrollX = AnimateLinearAbsolute(state.initialTime, duration, 0, dist)
        elseif dir:find("LEFT") then
            scrollX = AnimateLinearAbsolute(state.initialTime, duration, 0, -dist)
        end
        if dir:find("UP") then
            scrollY = AnimateLinearAbsolute(state.initialTime, duration, 0, dist)
        elseif dir:find("DOWN") then
            scrollY = AnimateLinearAbsolute(state.initialTime, duration, 0, -dist)
        end
        if state.scrollOriginX == nil then
            state.scrollOriginX = 0
            state.scrollOriginY = 0
        elseif state.scrollReset then
            state.scrollOriginX = -scrollX
            state.scrollOriginY = -scrollY
            state.scrollReset = nil
        end
        scrollX = scrollX + state.scrollOriginX
        scrollY = scrollY + state.scrollOriginY
        state.posX = state.posX + scrollX - (state.scrollX or 0)
        state.posY = state.posY + scrollY - (state.scrollY or 0)
        state.scrollX = scrollX
        state.scrollY = scrollY
    end,
}

local UIParent = UIParent
local WorldFrame = WorldFrame
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

local function UpdateFontParent(self)
    local fctConfig = CFCT.Config
    local nameplate = false
    local attach
    
    -- Handle different attach modes
    if fctConfig.attachMode == "en" then
        -- Every Nameplate mode: use the unit token from GUID
        local unit = CFCT:GetNamePlateUnitByGUID(self.state.guid)
        if unit then
            nameplate = GetNamePlateForUnit(unit)
        end
    elseif fctConfig.attachMode == "tn" then
        -- Target Nameplate mode: use the GUID to find nameplate for proper area of effect handling
        if self.state.guid then
            nameplate = CFCT.cachedNameplates[self.state.guid]
            if not nameplate then
                local unit = CFCT:GetNamePlateUnitByGUID(self.state.guid)
                if unit then
                    nameplate = GetNamePlateForUnit(unit)
                    CFCT.cachedNameplates[self.state.guid] = nameplate
                end
            end
        end
    end
    
    if nameplate then
        self.state.cachedNameplate = nameplate
    end
    
    if ((fctConfig.attachMode == "tn") or (fctConfig.attachMode == "en")) and nameplate then
        attach = nameplate
    elseif (fctConfig.attachMode == "sc") or (fctConfig.attachModeFallback == true) then
        attach = f
    else
        attach = false
    end
    
    local inheritNameplates = fctConfig.inheritNameplates
    if fctConfig.dontOverlapNameplates then
        self:SetParent(WorldFrame)
        self.state.baseScale = inheritNameplates and (attach and attach == nameplate) and attach:GetEffectiveScale() * UIParent:GetScale() or UIParent:GetScale()
    else
        self:SetParent(UIParent)
        self.state.baseScale = inheritNameplates and (attach and attach == nameplate) and attach:GetEffectiveScale() or 1
    end
    self.state.attach = attach
end

local function CalculateStringSize(self)
    -- Calculate size accounting for both UI scaling and animation scaling
    self.state.height = self.state.strHeight * self.state.baseScale * self.state.powScale
    self.state.width = self.state.strWidth * self.state.baseScale * self.state.powScale
end

local function ValidateFont(self)
    local fctConfig = CFCT.Config
    if ((now - self.state.initialTime) > fctConfig.animDuration) then
        return false
    end
    local catConfig = fctConfig[self.state.cat]
    if not (catConfig and catConfig.enabled) then
        return false
    end
    self.state.catConfig = catConfig
    return true
end

local function UpdateFontAnimations(self)
    local catConfig = self.state.catConfig
    CalculateStringSize(self)
    for animName, animFunc in pairs(ANIMATIONS) do
        local animConfig = catConfig[animName]
        if (animConfig and (type(animConfig) == 'table')) and animConfig.enabled then
            animFunc(self, catConfig, animConfig)
        end
    end
    CalculateStringSize(self)
end

local function UpdateFontPos(self)
    local fctConfig = CFCT.Config
    local attach = self.state.attach
    
    if attach then
        local isNamePlate = attach.namePlateUnitToken ~= nil
        local areaX = isNamePlate and fctConfig.areaNX or fctConfig.areaX
        local areaY = isNamePlate and fctConfig.areaNY or fctConfig.areaY
        self:SetPoint("CENTER", attach, "CENTER", areaX + self.state.posX, areaY + self.state.posY)
        self:Show()
    elseif self.state.cachedNameplate then
        local areaX = fctConfig.areaNX or fctConfig.areaX
        local areaY = fctConfig.areaNY or fctConfig.areaY
        self:SetPoint("CENTER", self.state.cachedNameplate, "CENTER", areaX + self.state.posX, areaY + self.state.posY)
        self:Show()
    else
        self:Hide()
    end
end

-- Fixed ApplyFontUpdate to use font size changes instead of SetScale
local function ApplyFontUpdate(self)
    local alpha = self.state.baseAlpha * self.state.fadeAlpha
    -- Clamp alpha to 1 (fully opaque) unless fading is intended
    if alpha > 1 then alpha = 1 end
    if alpha < 0 then alpha = 0 end
    self:SetAlpha(alpha)
    self:SetShadowColor(0, 0, 0, alpha / 2)
    
    -- Use font size scaling instead of SetScale for WotLK 3.3.5a compatibility
    if scale and scale ~= 1 and self.state.originalFontSize then
        local newFontSize = self.state.originalFontSize * scale
        self:SetFont(self.state.fontPath, newFontSize, self.state.fontStyle)
        self:SetShadowOffset(newFontSize / 14, newFontSize / 14)
    elseif scale == 1 and self.state.originalFontSize then
        self:SetFont(self.state.fontPath, self.state.originalFontSize, self.state.fontStyle)
        self:SetShadowOffset(self.state.originalFontSize / 14, self.state.originalFontSize / 14)
    end
end

local function GrabFontString()
    if (#fsc > 0) then 
        return tremove(fsc) 
    end
    local frame = f:CreateFontString()

    frame.Init = InitFont
    frame.UpdateParent = UpdateFontParent
    frame.UpdateAnimation = UpdateFontAnimations
    frame.UpdatePosition = UpdateFontPos
    frame.Validate = ValidateFont
    frame.Release = ReleaseFont
    frame.ApplyUpdate = ApplyFontUpdate

    return frame
end

local iconCache = {}
local function SpellIconText(spell)
    local fctConfig = CFCT.Config
    local tx = iconCache[spell] or select(3,GetSpellInfo(spell))
    if tx then
        iconCache[spell] = tx
        local aspectRatio = fctConfig.spellIconAspectRatio
        local zoom = fctConfig.spellIconZoom
        local offsetX, offsetY = fctConfig.spellIconOffsetX, fctConfig.spellIconOffsetY
        local height, width = 20 / aspectRatio, 20
        local txSize = zoom * 100
        local txMinX = (zoom - 1) * 100 / 2
        local txMaxX = (zoom + 1) * 100 / 2
        local txMinY = (zoom - (1 / aspectRatio)) * 100 / 2
        local txMaxY = (zoom + (1 / aspectRatio)) * 100 / 2
        return format("|T%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d|t",
            tx, height, width, offsetX, offsetY, txSize, txSize, txMinX, txMaxX, txMinY, txMaxY)
    end
    return false
end

local function GetDamageTypeColor(school)
    return CFCT.Config.colorTable[school]
end
local function GetDotTypeColor(school)
    return CFCT.Config.colorTableDot[school]
end

-- Add a global event counter for uniqueness
local globalEventCounter = 0
local function DispatchText(guid, event, text, amount, spellid, spellicon, periodic, crit, miss, pet, school, count)
    globalEventCounter = globalEventCounter + 1
    local cat = (pet and "pet" or "")..event..(periodic and "tick" or "")..(crit and "crit" or miss and "miss" or "")
    local fctConfig = CFCT.Config
    local catConfig = fctConfig[cat]
    text = text or tostring(amount)
    count = count or 1

    if not miss then
        if not crit then
            AddToAverage(amount / count)
        end
        if (fctConfig.filterAbsoluteEnabled and (fctConfig.filterAbsoluteThreshold > amount))
        or (fctConfig.filterRelativeEnabled and ((fctConfig.filterRelativeThreshold * 0.01 * CFCT:UnitHealthMax('player')) > amount))
        or (fctConfig.filterAverageEnabled and ((fctConfig.filterAverageThreshold * 0.01 * CFCT:DamageRollingAverage()) > amount)) then
            return false
        end

        if fctConfig.abbreviateNumbers then
            text = AbbreviateNumbers(amount)
        elseif fctConfig.kiloSeparator then
            text = FormatThousandSeparator(amount)
        end
    end
    
    if (count > 1) and fctConfig.mergeEventsCounter then
        text = text.." x"..tostring(count)
    end

    if spellicon and catConfig.showIcons then
        text = spellicon..text
    end

    local fontColor, fontAlpha
    local typeColor = periodic and fctConfig.colorTableDotEnabled and GetDotTypeColor(school) or GetDamageTypeColor(school)
    if (catConfig.colorByType == true) and typeColor then
        local r, g, b, a = CFCT.Color2RGBA((strlen(typeColor) == 6) and "FF"..typeColor or typeColor)
        a = min(a, select(4, CFCT.Color2RGBA(catConfig.fontColor)))
        fontColor = {r, g, b, a}
        fontAlpha = a
    else
        local r, g, b, a = CFCT.Color2RGBA(catConfig.fontColor)
        fontColor = {r, g, b, a}
        fontAlpha = a
    end

    tinsert(anim, 1, GrabFontString():Init({
        cat = cat,
        guid = guid,
        icon = spellicon,
        text = text,
        amount = amount,
        miss = miss,
        baseAlpha = 1, -- Always fully opaque unless fading
        baseScale = 1,
        fadeAlpha = 1, -- Always fully opaque unless fading
        powScale = 1,
        fontOptions = {
            fontPath = catConfig.fontPath,
            fontSize = catConfig.fontSize,
            fontStyle = catConfig.fontStyle,
            fontColor = {fontColor[1], fontColor[2], fontColor[3], 1}, -- force alpha to 1
            fontAlpha = 1
        },
        eventId = globalEventCounter
    }))
end

local spellIdCache = {}
CFCT.spellIdCache = spellIdCache
local eventCache = {}
CFCT.eventCache = eventCache

local function CacheEvent(guid, event, amount, text, spellid, spellicon, periodic, crit, miss, pet, school)
    globalEventCounter = globalEventCounter + 1
    if (spellid and not spellIdCache[spellid]) then
        spellIdCache[spellid] = true
        if CFCT.ConfigPanel and CFCT.ConfigPanel:IsVisible() then
            CFCT.ConfigPanel:refresh()
        end
    end

    local fctConfig = CFCT.Config
    if fctConfig.filterSpellBlacklist[spellid] == true
    or (fctConfig.filterMissesEnabled and miss) then
        return
    end

    local mergeConfig = {
        {fctConfig.mergeEventsByGuid, guid},
        {fctConfig.mergeEventsBySpellID, spellid},
        {fctConfig.mergeEventsBySpellIcon, spellicon},
        {fctConfig.mergeEventsBySchool, school}
    }
    local id = tostring(pet)
    for _, e in ipairs(mergeConfig) do
        if e[1] == true then id = id .. tostring(e[2]) end
    end
    
    local mergeTime = fctConfig.mergeEventsIntervalOverrides[spellid] or fctConfig.mergeEventsInterval
    local record = eventCache[id] or {
        events = {},
        expiry = nil
    }
    tinsert(record.events, {
        time = now,
        guid = guid,
        event = event,
        amount = amount,
        text = text,
        spellid = spellid,
        spellicon = spellicon,
        periodic = periodic,
        crit = crit,
        miss = miss,
        pet = pet,
        school = school,
        count = 1,
        eventId = globalEventCounter
    })
    if fctConfig.mergeEventsIntervalMode == "first" then
        if not record.expiry then
            record.expiry = now + mergeTime
        end
    elseif fctConfig.mergeEventsIntervalMode == "last" then
        record.expiry = now + mergeTime
    end
    eventCache[id] = record
end

local function ProcessCachedEvents()
    local mergingEnabled = CFCT.Config.mergeEvents
    local separateMisses = CFCT.Config.mergeEventsMisses

    for id, record in pairs(eventCache) do
        if mergingEnabled then
            if (now > record.expiry) then
                local merge
                for i = #record.events, 1, -1 do
                    local e = record.events[i]
                    if e.miss and separateMisses then
                        DispatchText(e.guid, e.event, e.text, e.amount, e.spellid, e.spellicon, e.periodic, e.crit, e.miss, e.pet, e.school)
                        tremove(record.events, i) -- Remove after dispatch
                    elseif not merge then
                        merge = e
                        tremove(record.events, i) -- Remove after merge
                    else
                        merge.amount = merge.amount + e.amount
                        merge.text = merge.text or e.text
                        merge.count = merge.count + 1
                        merge.miss = merge.miss == false and false or e.miss
                        merge.crit = merge.crit or e.crit
                        merge.periodic = merge.periodic and e.periodic
                        tremove(record.events, i)
                    end
                end
                if merge then
                    local text = (merge.amount ~= 0) and merge.amount or merge.text
                    DispatchText(merge.guid, merge.event, text, merge.amount, merge.spellid, merge.spellicon, merge.periodic, merge.crit, merge.miss, merge.pet, merge.school, merge.count)
                end
                eventCache[id] = nil -- Remove cache after processing
            end
        else
            for i = #record.events, 1, -1 do
                local e = record.events[i]
                local text = (e.amount ~= 0) and e.amount or e.text
                DispatchText(e.guid, e.event, text, e.amount, e.spellid, e.spellicon, e.periodic, e.crit, e.miss, e.pet, e.school)
                tremove(record.events, i) -- Remove after dispatch
            end
            eventCache[id] = nil -- Remove cache after processing
        end
        -- After this, no event should be dispatched twice.
    end
end

CFCT._testMode = false
local testModeTimer = 0
function CFCT:Test(n)
    local cats = {
        "auto",
        "spell",
        "heal"
    }

    local numplates = 0
    local it = (numplates > 0) and (n*numplates) or n
    for i = 1, it do
        local spellid
        repeat
            spellid = random(1,32767)
        until select(3,GetSpellInfo(spellid))

        local school = random(1,128)
        local pet = (random(1,3) == 1)
        local crit = (random(1,3) == 1)
        local miss = not crit and (random(1,2) == 1)
        local event = cats[random(1,#cats)]
        local text = miss and "Miss" or nil
        local periodic = (random(1,3) == 1) and event == "spell"
        local amount = crit and 2674 or miss and 0 or 1337
        local guid = UnitGUID("target") or UnitGUID("player")
        local spellicon = spellid and SpellIconText(spellid) or ""
        DispatchText(guid, event, text, amount, spellid, spellicon, periodic, crit, miss, pet, school)
    end
end

local CVAR_CHECK_INTERVAL = 5
local cvarTimer = 0
local function checkCvars()
    if (GetCVarDefault("CombatDamage")) then
        local varHideDamage = CFCT.hideBlizz and "0" or "1"
        local cvarHideDamage = GetCVar("CombatDamage")
        if not (cvarHideDamage == varHideDamage) then
            if CFCT.forceCVars then
                SetCVar("CombatDamage", varHideDamage)
            else
                CFCT.hideBlizz = (cvarHideDamage == "0")
            end
        end
    end
    if (GetCVarDefault("CombatHealing")) then
        local varHideHealing = CFCT.hideBlizzHeals and "0" or "1"
        local cvarHideHealing = GetCVar("CombatHealing")
        if not (cvarHideHealing == varHideHealing) then
            if CFCT.forceCVars then
                SetCVar("CombatHealing", varHideHealing)
            else
                CFCT.hideBlizzHeals = (cvarHideHealing == "0")
            end
        end
    end
end

local events = {
    COMBAT_LOG_EVENT_UNFILTERED = true,
    UNIT_MAXHEALTH = true,
    ADDON_LOADED = true,
    PLAYER_LOGOUT = true,
    PLAYER_ENTERING_WORLD = true,
    NAME_PLATE_UNIT_ADDED = true,
    NAME_PLATE_UNIT_REMOVED = true
}
for e,_ in pairs(events) do f:RegisterEvent(e) end
f:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

local function SortByUnit(allFrames)
    local fctConfig = CFCT.Config
    local animAreas = {}
    for k, frame in ipairs(allFrames) do
        local state = frame.state
        if (fctConfig.attachMode == "en") then
            -- Every Nameplate mode: group by unit token
            state.unit = CFCT:GetNamePlateUnitByGUID(state.guid) or ""
        else
            -- For "tn" and "sc" modes: group by individual GUIDs for proper area of effect handling
            -- This ensures area of effect damage appears on each affected target's nameplate
            state.unit = state.guid or "unknown"
        end
        animAreas[state.unit] = animAreas[state.unit] or {}
        tinsert(animAreas[state.unit], frame)
    end
    return animAreas
end

local function PrepareAnimatingFonts()
    local c = #anim
    local i = 1
    while (i <= c) do
        local frame = anim[i]
        if (frame:Validate() == false) then
            frame:Release()
            tremove(anim, i)
            c = c - 1
        else
            i = i + 1
        end
    end
end

local function UpdateAnimatingFonts()
    local animAreas = SortByUnit(anim)
    for k, animArea in pairs(animAreas) do
        for k, frame in ipairs(animArea) do
            frame:UpdateParent(animArea)
            frame:UpdateAnimation()
        end
        if CFCT.Config.preventOverlap then
            GridLayout(animArea)
        end
        for _, e in pairs(animArea) do
            e:UpdatePosition()
            e:ApplyUpdate()
        end
    end
end

f:SetScript("OnUpdate", function(self, elapsed)
    now = GetTime()
    if CFCT._testMode and (now > testModeTimer) and not InCombatLockdown() then
        CFCT:Test(2)
        testModeTimer = now + CFCT.Config.animDuration / 2
    end
    if (now > rollingAverageTimer) then
        CalculateRollingAverage()
        rollingAverageTimer = now + ROLLINGAVERAGE_UPDATE_INTERVAL
    end
    if (now > cvarTimer) then
        checkCvars()
        cvarTimer = now + CVAR_CHECK_INTERVAL
    end
    ProcessCachedEvents()
    PrepareAnimatingFonts()
    UpdateAnimatingFonts()
end)
f:Show()

function f:ADDON_LOADED(name)
    if (name == addonName) then
        CFCT.Config:OnLoad()
        local version = GetAddOnMetadata(addonName, "Version")
        if (version ~= CFCT.lastVersion) then
            C_Timer.After(5,function()
                CFCT:Log(GetAddOnMetadata(addonName, "Version").." - Fixed for WotLK 3.3.5a")
            end)
        end
        CFCT.lastVersion = version
        
        -- Register for interface options close event to save config
        if InterfaceOptionsFrame then
            InterfaceOptionsFrame:HookScript("OnHide", function()
                CFCT.Config:OnSave()
            end)
        end
    end
end

function f:PLAYER_LOGOUT()
    CFCT.Config:OnSave()
end

local playerGUID
function f:PLAYER_ENTERING_WORLD()
    playerGUID = UnitGUID("player")
end

local nameplates = {}
function f:NAME_PLATE_UNIT_ADDED(unit)
    local guid = UnitGUID(unit)
    nameplates[unit] = guid
    nameplates[guid] = unit 
end
function f:NAME_PLATE_UNIT_REMOVED(unit)
    local guid = nameplates[unit]
    nameplates[unit] = nil
    nameplates[guid] = nil
end
function CFCT:GetNamePlateUnitByGUID(guid)
    return nameplates[guid]
end

local unitHealthMax = {}
function f:UNIT_MAXHEALTH(unit)
    if (unit == 'player') then
        unitHealthMax[unit] = UnitHealthMax(unit)
    end
end
function CFCT:UnitHealthMax(unit)
    return unitHealthMax[unit] or UnitHealthMax(unit)
end

-- Combat log event parsing
local CLEU_SWING_EVENT = {
    SWING_DAMAGE = true,
    SWING_HEAL = true,
    SWING_LEECH = true,
    SWING_MISSED = true
}
local CLEU_SPELL_EVENT = {
    DAMAGE_SHIELD = true,
    DAMAGE_SPLIT = true,
    RANGE_DAMAGE = true,
    SPELL_DAMAGE = true,
    SPELL_BUILDING_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true,
    RANGE_MISSED = true,
    SPELL_MISSED = true,
    SPELL_PERIODIC_MISSED = true,
    SPELL_BUILDING_MISSED = true
}
local CLEU_MISS_EVENT = {
    SWING_MISSED = true,
    RANGE_MISSED = true,
    SPELL_MISSED = true,
    SPELL_PERIODIC_MISSED = true,
    SPELL_BUILDING_MISSED = true,
}
local CLEU_DAMAGE_EVENT = {
    SWING_DAMAGE = true,
    DAMAGE_SHIELD = true,
    DAMAGE_SPLIT = true,
    RANGE_DAMAGE = true,
    SPELL_DAMAGE = true,
    SPELL_BUILDING_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true
}
local CLEU_HEALING_EVENT = {
    SWING_HEAL = true,
    RANGE_HEAL = true,
    SPELL_HEAL = true,
    SPELL_BUILDING_HEAL = true,
    SPELL_PERIODIC_HEAL = true,
}

-- Bit flags for unit classification
local AFFILIATION_MINE = 0x00000001
local AFFILIATION_PARTY = 0X00000002
local AFFILIATION_RAID = 0X00000004
local AFFILIATION_OUTSIDER = 0X00000008
local REACTION_FRIENDLY = 0x00000010
local REACTION_NEUTRAL = 0x00000020
local REACTION_HOSTILE = 0x00000040
local CONTROL_HUMAN = 0x00000100
local CONTROL_SERVER = 0x00000200
local UNITTYPE_PLAYER = 0x00000400
local UNITTYPE_NPC = 0x00000800
local UNITTYPE_PET = 0x00001000
local UNITTYPE_GUARDIAN = 0x00002000
local UNITTYPE_OBJECT = 0x00004000
local TARGET_TARGET = 0x00010000
local TARGET_FOCUS = 0x00020000
local OBJECT_NONE = 0x80000000

local function TestFlagsAll(unitFlags, testFlags)
    if (bitband(unitFlags, testFlags) == testFlags) then return true end
end

local FLAGS_ME = bitbor(AFFILIATION_MINE, REACTION_FRIENDLY, CONTROL_HUMAN, UNITTYPE_PLAYER)
local FLAGS_MINE = bitbor(AFFILIATION_MINE, REACTION_FRIENDLY, CONTROL_HUMAN)
local FLAGS_MY_GUARDIAN = bitbor(AFFILIATION_MINE, REACTION_FRIENDLY, CONTROL_HUMAN, UNITTYPE_GUARDIAN)

function f:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, sourceGUID, sourceName, sourceFlags, recipientGUID, recipientName, recipientFlags, ...)
    if not CFCT.enabled then return end

    local playerEvent, petEvent = (playerGUID == sourceGUID), false
    if not playerEvent then 
        petEvent = (bitband(sourceFlags, UNITTYPE_GUARDIAN) > 0 or bitband(sourceFlags, UNITTYPE_PET) > 0) 
                   and (bitband(sourceFlags, AFFILIATION_MINE) > 0) 
    end
    if not (playerEvent or petEvent) or recipientGUID == playerGUID then return end

    local guid = recipientGUID
    if CLEU_DAMAGE_EVENT[event] then
        if CLEU_SWING_EVENT[event] then
            local amount, overkill, school, resist, block, absorb, crit, glancing, crushing, offhand = ...
            if amount then
                self:DamageEvent(guid, nil, amount, nil, crit, petEvent, school)
            end
        else
            local periodic = event:find("SPELL_PERIODIC", 1, true)
            local spellid, spellname, school, amount, overkill, school2, resist, block, absorb, crit, glancing, crushing, offhand = ...
            if amount then
                self:DamageEvent(guid, spellid, amount, periodic, crit, petEvent, school)
            end
        end
    elseif CLEU_MISS_EVENT[event] then
        if CLEU_SWING_EVENT[event] then
            local misstype, _, amount = ...
            self:MissEvent(guid, nil, amount, nil, misstype, petEvent, 1)
        else
            local periodic = event:find("SPELL_PERIODIC", 1, true)
            local spellid, spellname, school, misstype, _, amount = ...
            self:MissEvent(guid, spellid, amount, periodic, misstype, petEvent, school)
        end
    elseif CLEU_HEALING_EVENT[event] then
        if CLEU_SWING_EVENT[event] then
            local amount, overheal, absorb, crit = ...
            if amount then
                self:HealingEvent(guid, nil, amount, nil, crit, petEvent, nil)
            end
        else
            local periodic = event:find("SPELL_PERIODIC", 1, true)
            local spellid, spellname, school, amount, overheal, absorb, crit = ...
            if amount then
                self:HealingEvent(guid, spellid, amount, periodic, crit, petEvent, school)
            end
        end
    end
end

function f:DamageEvent(guid, spellid, amount, periodic, crit, pet, school, dot)
    spellid = spellid or 6603 -- 6603 = Auto Attack
    local event = ((spellid == 75) or (spellid == 6603)) and "auto" or "spell" -- 75 = autoshot
    local spellicon = spellid and SpellIconText(spellid) or ""
    
    -- Capture nameplate position immediately when event is received
    local unit = CFCT:GetNamePlateUnitByGUID(guid)
    if unit then
        local nameplate = GetNamePlateForUnit(unit)
        if nameplate then
            CFCT.cachedNameplates[guid] = nameplate
        end
    end
    
    CacheEvent(guid, event, amount, nil, spellid, spellicon, periodic, crit, false, pet, school)
end

function f:MissEvent(guid, spellid, amount, periodic, misstype, pet, school)
    spellid = spellid or 6603 -- 6603 = Auto Attack
    local event = ((spellid == 75) or (spellid == 6603)) and "auto" or "spell" -- 75 = autoshot
    local spellicon = spellid and SpellIconText(spellid) or ""
    
    -- Capture nameplate position immediately when event is received
    local unit = CFCT:GetNamePlateUnitByGUID(guid)
    if unit then
        local nameplate = GetNamePlateForUnit(unit)
        if nameplate then
            CFCT.cachedNameplates[guid] = nameplate
        end
    end
    
    CacheEvent(guid, event, 0, strlower(misstype):gsub("^%l", strupper), spellid or 6603, spellicon, periodic, false, true, pet, school)
end

function f:HealingEvent(guid, spellid, amount, periodic, crit, pet, school)
    local event = "heal"
    local spellicon = spellid and SpellIconText(spellid) or ""
    
    -- Capture nameplate position immediately when event is received
    local unit = CFCT:GetNamePlateUnitByGUID(guid)
    if unit then
        local nameplate = GetNamePlateForUnit(unit)
        if nameplate then
            CFCT.cachedNameplates[guid] = nameplate
        end
    end
    
    CacheEvent(guid, event, amount, nil, spellid, spellicon, periodic, crit, false, pet, school)
end