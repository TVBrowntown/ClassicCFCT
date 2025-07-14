local addonName, CFCT = ...
local tinsert, tremove, tsort, format, strlen, strsub, gsub, floor, sin, cos, asin, acos, random, select, pairs, ipairs, unpack, bitband = table.insert, table.remove, table.sort, string.format, string.len, string.sub, string.gsub, math.floor, math.sin, math.cos, math.asin, math.acos, math.random, select, pairs, ipairs, unpack, bit.band
local GetSpellInfo = GetSpellInfo
local IsRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local IsBCC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local DefaultPresets = CFCT:GetDefaultPresets()
local DefaultConfig = DefaultPresets["Classic"]
local DefaultVars = {
    enabled = true,
    hideBlizz = true,
    hideBlizzHeals = true,
    forceCVars = true,
    characterSpecificConfig = false,
    selectedPreset = "",
    lastVersion = ""
}
local DefaultCharVars = {
    enabled = true,
    hideBlizz = true,
    hideBlizzHeals = true,
    forceCVars = true,
    selectedPreset = "",
}
local DefaultTables = {
    mergeEventsIntervalOverrides = {},
    filterSpellBlacklist = {}
}
local ClassSpecificTables = {
    mergeEventsIntervalOverrides = true,
    filterSpellBlacklist = true
}

for i, class in ipairs(CLASS_SORT_ORDER) do
    if (class) then
        for k,v in pairs(ClassSpecificTables) do
            DefaultTables[k][class] = {}
        end
    end
end

local DefaultCharTables = {
    mergeEventsIntervalOverrides = {},
    filterSpellBlacklist = {}
}

local AnimationDefaults = {
    Pow = {
        enabled = false,
        initScale = 0.25,
        midScale = 1.55,
        endScale = 1,
        duration = 0.3,
        inOutRatio = 0.7
    },
    FadeIn = {
        enabled = false,
        duration = 0.07
    },
    FadeOut = {
        enabled = false,
        duration = 0.3
    },
    Scroll = {
        enabled = false,
        direction = "UP",
        distance = 32
    }
}

local function SetValue(path, value)
    local chain = { strsplit(".", path) }
    local depth = #chain
    local temp = CFCT

    for d, k in ipairs(chain) do
        if not temp[k] then
            return false
        end
        if (d == depth) then
            if (type(value) == 'table') then
                for key, val in pairs(value) do
                    temp[k][key] = val
                end
            else
                temp[k] = value
            end
            return true
        end
        temp = temp[k]
    end
    return false
end

local function GetValue(path)
    if not path or path == "" then
        return nil
    end

    local chain = { strsplit(".", path) }
    local depth = #chain
    local temp = CFCT

    for d, k in ipairs(chain) do
        if not temp then
            return nil
        end
        if (d == depth) then
            return temp[k]
        end
        temp = temp[k]
    end
    return nil
end

local function UpdateTable(dest, source, template, overwrite, debug)
    if type(dest) ~= 'table' then
        error("UpdateTable: dest is not a table, got " .. type(dest))
    end
    if type(source) ~= 'table' then
        if source == nil then
            source = {}
        else
            error("UpdateTable: source is not a table, got " .. type(source) .. " (value: " .. tostring(source) .. ")")
        end
    end
    if type(template) ~= 'table' then
        error("UpdateTable: template is not a table, got " .. type(template))
    end

    for k, t in pairs(template) do
        if (type(t) == 'table') then
            dest[k] = (type(dest[k]) == 'table') and dest[k] or {}
            UpdateTable(dest[k], source[k], t, overwrite, debug)
        elseif ((type(t) ~= type(dest[k])) or (dest[k] == nil) or (overwrite and (dest[k] ~= source[k]))) then
            dest[k] = (source[k] == nil) and t or source[k]
        end
    end
end

local function AttachTables(dest, source, template, debug)
    local class = UnitClassBase and UnitClassBase('player') or select(2, UnitClass('player'))
    
    for k, t in pairs(template) do
        if ClassSpecificTables and (ClassSpecificTables[k] == true) then
            if source[k] == nil then source[k] = {} end
            if source[k][class] == nil then source[k][class] = {} end
            dest[k] = source[k][class]
        else
            if source[k] == nil then source[k] = {} end
            dest[k] = source[k]
        end
    end
end

CFCT._log = {}
function CFCT:Log(msg)
    local msg = "|cffffff00ClassicFCT: |r|cffffff80"..(msg or "").."|r"
    print(msg)
    table.insert(self._log, "|cffffff00ClassicFCT: |r|cffffff80"..(msg or "").."|r")
end
function CFCT:DumpLog(n)
    local c = #self._log
    if not ((c > 0) and (c > n)) then return "Invalid Log Range" end
    return table.concat(self._log, "\n", c - n, n)
end

--Input Popup Box
StaticPopupDialogs["CLASSICFCT_POPUPDIALOG"] = {
    text = "POPUPDIALOG_TITLE",
    button1 = "OK",
    button2 = "Cancel",
    OnShow = function() end,
    OnAccept = function() end,
    EditBoxOnEnterPressed = function() end,
    hasEditBox = true,
    timeout = 0,
    exclusive = true,
    hideOnEscape = true
}

function CFCT:ShowInputBox(title, default, OnAccept)
    local pd = StaticPopupDialogs["CLASSICFCT_POPUPDIALOG"]
    pd.hasEditBox = true
    pd.text = title
    pd.OnShow = function(self) self.editBox:SetText(default) end
    pd.OnAccept = function(self) OnAccept(self.editBox:GetText()) end
    pd.EditBoxOnEnterPressed = function(self) OnAccept(self:GetText()) self:GetParent():Hide() end
    StaticPopup_Show("CLASSICFCT_POPUPDIALOG")
end

function CFCT:ConfirmAction(title, OnAccept)
    local pd = StaticPopupDialogs["CLASSICFCT_POPUPDIALOG"]
    pd.hasEditBox = false
    pd.text = title
    pd.OnShow = function() end
    pd.OnAccept = function(self) OnAccept() end
    pd.EditBoxOnEnterPressed = function() end
    StaticPopup_Show("CLASSICFCT_POPUPDIALOG")
end

CFCT.ConfigPanels = {}
CFCT.Presets = {}
-- Ensure CFCT.Config is properly initialized as a table
if not CFCT.Config then
    CFCT.Config = {}
end

CFCT.Config = {
    OnLoad = function(self)
        -- Initialize saved variables
        ClassicFCTCustomPresets = ClassicFCTCustomPresets or {}
        ClassicFCTVars = ClassicFCTVars or {}
        ClassicFCTConfig = ClassicFCTConfig or {}
        ClassicFCTTables = ClassicFCTTables or {}
        
        -- Load presets
        CFCT.Presets = CFCT.Presets or {}
        UpdateTable(CFCT.Presets, ClassicFCTCustomPresets, ClassicFCTCustomPresets, true)
        UpdateTable(CFCT.Presets, DefaultPresets, DefaultPresets, true)
        
        -- Load variables
        UpdateTable(ClassicFCTVars, DefaultVars, DefaultVars)
        UpdateTable(CFCT, ClassicFCTVars, DefaultVars, true)
        
        -- Load configuration
        UpdateTable(ClassicFCTConfig, DefaultConfig, DefaultConfig)
        UpdateTable(CFCT.Config, ClassicFCTConfig, DefaultConfig, true)
        
        -- Load tables
        UpdateTable(ClassicFCTTables, DefaultTables, DefaultTables)
        AttachTables(CFCT.Config, ClassicFCTTables, DefaultTables)
        
        -- Ensure all category configs have required settings
        local categories = {"auto", "spell", "heal", "automiss", "autocrit", "petauto", "petautomiss", "petautocrit", "spellmiss", "spellcrit", "spelltick", "spelltickmiss", "spelltickcrit", "healmiss", "healcrit", "healtick", "healtickmiss", "healtickcrit", "petspell", "petspellmiss", "petspellcrit", "petspelltick", "petspelltickmiss", "petspelltickcrit", "petheal", "pethealmiss", "pethealcrit", "pethealtick", "pethealtickmiss", "pethealtickcrit"}
        for _, cat in ipairs(categories) do
            if CFCT.Config[cat] and type(CFCT.Config[cat]) == 'table' then
                if CFCT.Config[cat].showIcons == nil then
                    CFCT.Config[cat].showIcons = DefaultConfig[cat] and DefaultConfig[cat].showIcons or false
                end
            end
        end
        
        -- Refresh UI if config panel is visible
        if CFCT.ConfigPanel and CFCT.ConfigPanel:IsVisible() then
            C_Timer.After(0.1, function()
                CFCT.RefreshAllWidgets()
            end)
        end
    end,
    OnSave = function(self)
        -- Save presets
        if CFCT.Presets and type(CFCT.Presets) == 'table' then
            ClassicFCTCustomPresets = ClassicFCTCustomPresets or {}
            UpdateTable(ClassicFCTCustomPresets, CFCT.Presets, CFCT.Presets, true)
        end
        
        -- Save variables
        ClassicFCTVars = ClassicFCTVars or {}
        ClassicFCTVars.lastVersion = CFCT.lastVersion
        ClassicFCTVars.characterSpecificConfig = CFCT.characterSpecificConfig
        UpdateTable(ClassicFCTVars, CFCT, DefaultVars, true)
        
        -- Save configuration
        ClassicFCTConfig = ClassicFCTConfig or {}
        UpdateTable(ClassicFCTConfig, CFCT.Config, DefaultConfig, true)
        
        -- Save tables
        ClassicFCTTables = ClassicFCTTables or {}
        UpdateTable(ClassicFCTTables, CFCT.Config, DefaultTables, true)
    end,
    LoadPreset = function(self, presetName)
        CFCT:ConfirmAction("This will overwrite your current configuration. Are you sure?", function()
            if (CFCT.Presets and CFCT.Presets[presetName] ~= nil) then
                UpdateTable(CFCT.Config, CFCT.Presets[presetName], CFCT.Presets[presetName], true)
                CFCT:Log(presetName.." preset loaded.")
            elseif (DefaultPresets[presetName] ~= nil) then
                UpdateTable(CFCT.Config, DefaultPresets[presetName], DefaultPresets[presetName], true)
                CFCT:Log(presetName.." preset loaded.")
            end
            CFCT.ConfigPanel:refresh()
        end)
    end,
    SavePreset = function(self, presetName)
        CFCT:ConfirmAction("This will overwrite your the selected preset. Are you sure?", function()
            if (DefaultPresets[presetName] == nil) and (CFCT.Presets and CFCT.Presets[presetName] ~= nil) then
                UpdateTable(CFCT.Presets[presetName], CFCT.Config, CFCT.Config, true)
                CFCT:Log("Config saved to "..presetName.." preset.")
            end
        end)
    end,
    NewPresetName = function(self, baseName)
        for i=0, 10000, 1 do
            local name = format("%s%s", baseName, (i > 0) and tostring(i) or "")
            if (CFCT.Presets[name] == nil) then
                return name
            end
        end
    end,
    CreatePreset = function(self)
        local defaultName = self:NewPresetName("New preset")
        CFCT:ShowInputBox("Preset Name", defaultName, function(value)
            local value = ((strlen(value) > 0) and value or defaultName)
            if (CFCT.Presets and CFCT.Presets[value] == nil) then
                CFCT.Presets[value] = {}
                UpdateTable(CFCT.Presets[value], DefaultConfig, DefaultConfig)
                CFCT.selectedPreset = value
            else
                CFCT:Log("Preset "..value.." already exists")
            end
            CFCT.ConfigPanel:refresh()
        end)
    end,
    CreatePresetCopy = function(self, presetName)
        local defaultName = self:NewPresetName("Copy of "..presetName)
        CFCT:ShowInputBox("Preset Name", defaultName, function(value)
            local value = ((strlen(value) > 0) and value or defaultName)
            if (CFCT.Presets and CFCT.Presets[value] == nil) then
                CFCT.Presets[value] = {}
                UpdateTable(CFCT.Presets[value], CFCT.Presets[presetName], CFCT.Presets[presetName])
                CFCT.selectedPreset = value
            else
                CFCT:Log("Preset "..value.." already exists")
            end
            CFCT.ConfigPanel:refresh()
        end)
    end,
    RenamePreset = function(self, presetName)
        CFCT:ShowInputBox("Preset Name", presetName, function(value)
            local value = ((strlen(value) > 0) and value or presetName)
            if (CFCT.Presets and CFCT.Presets[value] == nil) then
                CFCT.Presets[value] = CFCT.Presets[presetName]
                CFCT.Presets[presetName] = nil
                CFCT.selectedPreset = value
            else
                CFCT:Log("Preset "..value.." already exists")
            end
            CFCT.ConfigPanel:refresh()
        end)
    end,
    DeletePreset = function(self, presetName)
        CFCT:ConfirmAction("This will delete the preset permanently. Are you sure?", function()
            if CFCT.Presets then
                CFCT.Presets[presetName] = nil
            end
            CFCT.ConfigPanel:refresh()
        end)
    end,
    RestoreDefaults = function(self)
        UpdateTable(CFCT.Config, DefaultConfig, DefaultConfig, true)
        UpdateTable(CFCT, DefaultVars, DefaultVars, true)
        CFCT.ConfigPanel:refresh()
        CFCT:Log("Defaults restored.")
    end,
    Show = function(self)
        InterfaceOptionsFrame_OpenToCategory(CFCT.ConfigPanels[1])
        InterfaceOptionsFrame_OpenToCategory(CFCT.ConfigPanels[1])
    end
}

SLASH_CLASSICFCT1 = '/cfct'
SlashCmdList['CLASSICFCT'] = function(msg)
    CFCT.Config:Show()
end
SLASH_CLASSICFCTFS1 = '/fs'
SlashCmdList['CLASSICFCTFS'] = function(msg)
    FrameStackTooltip_Toggle(0, 0, 0);
end

function CFCT.Color2RGBA(color)
    return tonumber("0x"..strsub(color, 3, 4))/255, tonumber("0x"..strsub(color, 5, 6))/255, tonumber("0x"..strsub(color, 7, 8))/255, tonumber("0x"..strsub(color, 1, 2))/255
end

function CFCT.RGBA2Color(r, g, b, a)
    return format("%02X%02X%02X%02X", floor(a*255+0.5), floor(r*255+0.5), floor(g*255+0.5), floor(b*255+0.5))
end

local function ValidateValue(rawVal, minVal, maxVal, step)
    local stepval = floor(rawVal / step) * step
    return min(max((((rawVal - stepval) >= (step / 2)) and stepval + step or stepval), minVal), maxVal)
end

-- Fixed widget config bridge functions with proper save triggering
local function WidgetConfigBridgeGet(self, default, ConfigPathOrFunc)
    if (type(ConfigPathOrFunc) == 'function') then
        return ConfigPathOrFunc(self, "Get", default)
    else
        if ConfigPathOrFunc:find("Config%.") then
            local configPath = ConfigPathOrFunc:gsub("Config%.", "")
            local chain = { strsplit(".", configPath) }
            local temp = CFCT.Config
            
            for d, k in ipairs(chain) do
                if not temp or not temp[k] then
                    return default
                end
                if d == #chain then
                    return temp[k]
                end
                temp = temp[k]
            end
            return default
        else
            local ret = GetValue(ConfigPathOrFunc)
            return (ret == nil) and default or ret
        end
    end
end

local function WidgetConfigBridgeSet(self, value, ConfigPathOrFunc)
    if (type(ConfigPathOrFunc) == 'function') then
        ConfigPathOrFunc(self, "Set", value)
    else
        local path = ConfigPathOrFunc
        if path:find("Config%.") then
            local configPath = path:gsub("Config%.", "")
            local chain = { strsplit(".", configPath) }
            local temp = CFCT.Config
            
            for d, k in ipairs(chain) do
                if d == #chain then
                    temp[k] = value
                    break
                end
                if not temp[k] then
                    temp[k] = {}
                end
                temp = temp[k]
            end
        else
            SetValue(ConfigPathOrFunc, value)
        end
        
        -- Immediately save configuration after any change
        CFCT.Config:OnSave()
        
        -- Trigger a refresh of the UI to show the changes immediately
        C_Timer.After(0.01, function()
            CFCT.RefreshAllWidgets()
        end)
    end
end

local AttachModesMenu = {
    {
        text = "Screen Center",
        value = "sc"
    },
    {
        text = "Target Nameplate",
        value = "tn"
    },
    {
        text = "Every Nameplate",
        value = "en"
    }
}
local MergeIntervalModeMenu = {
    {
        text = "First Event",
        value = "first"
    },
    {
        text = "Last Event",
        value = "last"
    }
}

local TextStrataMenu = {
    {
        text = "Background",
        value = "BACKGROUND"
    },
    {
        text = "Low",
        value = "LOW"
    },
    {
        text = "Medium",
        value = "MEDIUM"
    },
    {
        text = "High",
        value = "HIGH"
    },
    {
        text = "Dialog",
        value = "DIALOG"
    },
    {
        text = "Fullscreen",
        value = "FULLSCREEN"
    },
    {
        text = "Fullscreen Dialog",
        value = "FULLSCREEN_DIALOG"
    },
    {
        text = "Tooltip",
        value = "TOOLTIP"
    }
}

local AnimationsMenu = {
    Func = function(self, dropdown)
        
    end,
    {
        text = "Pow",
        value = "Pow"
    },
    {
        text = "Fade In",
        value = "FadeIn"
    },
    {
        text = "Fade Out",
        value = "FadeOut"
    },
    {
        text = "Scroll",
        value = "Scroll"
    },
}

local FontStylesMenu = {
    Func = function(self, dropdown)
        local ConfigPath = dropdown.configPath
        if (ConfigPath) then
            SetValue(ConfigPath, self.value)
        end
    end,
    {
        text = "No Outline",
        value = ""
    },
    {
        text = "No Outline Monochrome",
        value = "MONOCHROME"
    },
    {
        text = "Outline",
        value = "OUTLINE"
    },
    {
        text = "Outline Monochrome",
        value = "OUTLINE,MONOCHROME"
    },
    {
        text = "Thick Outline",
        value = "THICKOUTLINE"
    },
    {
        text = "Thick Outline Monochrome",
        value = "THICKOUTLINE,MONOCHROME"
    }
}

local SCHOOL_NAMES = {
    -- Single Schools
    [1] = STRING_SCHOOL_PHYSICAL,
    [2] = STRING_SCHOOL_HOLY,
    [4] = STRING_SCHOOL_FIRE,
    [8] = STRING_SCHOOL_NATURE,
    [16] = STRING_SCHOOL_FROST,
    [32] = STRING_SCHOOL_SHADOW,
    [64] = STRING_SCHOOL_ARCANE,
    -- Physical and a Magical
    [3] = STRING_SCHOOL_HOLYSTRIKE,
    [5] = STRING_SCHOOL_FLAMESTRIKE,
    [9] = STRING_SCHOOL_STORMSTRIKE,
    [17] = STRING_SCHOOL_FROSTSTRIKE,
    [33] = STRING_SCHOOL_SHADOWSTRIKE,
    [65] = STRING_SCHOOL_SPELLSTRIKE,
    -- Two Magical Schools
    [6] = STRING_SCHOOL_HOLYFIRE,
    [10] = STRING_SCHOOL_HOLYSTORM,
    [12] = STRING_SCHOOL_FIRESTORM,
    [18] = STRING_SCHOOL_HOLYFROST,
    [20] = STRING_SCHOOL_FROSTFIRE,
    [24] = STRING_SCHOOL_FROSTSTORM,
    [34] = STRING_SCHOOL_SHADOWHOLY,
    [36] = STRING_SCHOOL_SHADOWFLAME,
    [40] = STRING_SCHOOL_SHADOWSTORM,
    [48] = STRING_SCHOOL_SHADOWFROST,
    [66] = STRING_SCHOOL_DIVINE,
    [68] = STRING_SCHOOL_SPELLFIRE,
    [72] = STRING_SCHOOL_SPELLSTORM,
    [80] = STRING_SCHOOL_SPELLFROST,
    [96] = STRING_SCHOOL_SPELLSHADOW,
    -- Three or more schools
    [28] = STRING_SCHOOL_ELEMENTAL,
    [124] = STRING_SCHOOL_CHROMATIC,
    [126] = STRING_SCHOOL_MAGIC,
    [127] = STRING_SCHOOL_CHAOS
}

function ShowColorPicker(r, g, b, a, changedCallback)
    ColorPickerFrame:SetColorRGB(r,g,b);
    ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
    ColorPickerFrame.previousValues = {r,g,b,a};
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback;
    ColorPickerFrame:Hide();
    ColorPickerFrame:Show();
end

-- Widget creation functions...
local function CreateHeader(self, text, headerType, parent, point1, point2, x, y)
    local header = self:CreateFontString(nil, "ARTWORK", headerType)
    self:AddFrame(header)
    header:SetText(text)
    header:SetPoint(point1, parent, point2, x, y)
    return header
end

local function CreateCheckbox(self, label, tooltip, parent, point1, point2, x, y, defVal, ConfigPathOrFunc)
    local checkbox = CreateFrame("CheckButton", self:NewFrameID(), self, "InterfaceOptionsCheckButtonTemplate")
    self:AddFrame(checkbox)
    checkbox:SetPoint(point1, parent, point2, x, y)
    checkbox:SetScript("OnShow", function(self)
        local val = WidgetConfigBridgeGet(self, defVal, ConfigPathOrFunc)
        self:SetChecked(val)
    end)
    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        WidgetConfigBridgeSet(self, checked, ConfigPathOrFunc)
    end)
    
    checkbox.label = getglobal(checkbox:GetName() .. 'Text')
    checkbox.label:SetText(label)
    checkbox.tooltipText = tooltip
    checkbox.tooltipRequirement = "Default: " .. (tostring(defVal) ~= "nil" and tostring(defVal) or "")
    return checkbox
end

local function CreateButton(self, label, tooltip, parent, point1, point2, x, y, Func)
    local btn = CreateFrame("button", self:NewFrameID(), self, "UIPanelButtonTemplate")
    self:AddFrame(btn)
    btn:SetWidth(70)
    btn:SetPoint(point1, parent, point2, x, y)
    btn:SetText(label)
    btn:SetScript("OnClick", function(self, btn, down) if (btn == "LeftButton") and (type(Func) == 'function') then Func(self) end end)
    btn:Show()
    return btn
end

local function CreateSlider(self, label, tooltip, parent, point1, point2, x, y, minVal, maxVal, step, defVal, ConfigPathOrFunc)
    local slider = CreateFrame("Slider", self:NewFrameID(), self, "OptionsSliderTemplate")
    self:AddFrame(slider)
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint(point1, parent, point2, x, y)
    slider:SetWidth(270)
    slider.tooltipText = tooltip
    slider.tooltipRequirement = "Default: " .. (defVal or "") 
    getglobal(slider:GetName() .. 'Low'):SetText(tostring(minVal))
    getglobal(slider:GetName() .. 'High'):SetText(tostring(maxVal))
    getglobal(slider:GetName() .. 'Text'):SetText(label)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)

    slider:SetScript("OnShow", function(self)
        self:SetValue(WidgetConfigBridgeGet(self, defVal, ConfigPathOrFunc))
    end)
    slider:HookScript("OnValueChanged", function(self, val, isUserInput)
        WidgetConfigBridgeSet(self, val, ConfigPathOrFunc)
        
        -- Force test mode to update immediately for font size changes
        if ConfigPathOrFunc and type(ConfigPathOrFunc) == "string" and ConfigPathOrFunc:find("fontSize") then
            if CFCT._testMode then
                CFCT:Test(1)
            end
        end
    end)

    return slider
end

-- LSM integration for fonts
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local fontList = {[1]="Friz Quadrata TT"}
local fontPaths = {["Friz Quadrata TT"]="Fonts\\FRIZQT__.TTF"}
local fontObjects = {}
if LSM then
    local function updateFontList()
        for i, name in ipairs(LSM:List("font")) do
            local path = LSM:Fetch("font", name, true)
            if (path) then
                fontList[i] = name
                fontPaths[name] = path
                if (fontObjects[path] == nil) then
                    fontObjects[path] = CreateFont(name)
                    fontObjects[path]:SetFont(path, 14, "")
                end
            end
        end
    end
    updateFontList()
    function CFCT:UpdateUsedMedia(event, mediatype, key)
        if (mediatype == "font") then
            updateFontList()
        end
    end
    LSM.RegisterCallback(CFCT, "LibSharedMedia_Registered", "UpdateUsedMedia")
end

local function CreateFontDropdown(self, label, tooltip, parent, point1, point2, x, y, defVal, ConfigPath)
    local dropdown = CreateFrame('Frame', self:NewFrameID(), self, "UIDropDownMenuTemplate")
    self:AddFrame(dropdown)
    dropdown:SetPoint(point1, parent, point2, x, y)
    dropdown.left = getglobal(dropdown:GetName() .. "Left")
    dropdown.middle = getglobal(dropdown:GetName() .. "Middle")
    dropdown.middle:SetWidth(150)
    dropdown.right = getglobal(dropdown:GetName() .. "Right")
    local function itemOnClick(self)
        WidgetConfigBridgeSet(dropdown, self.value, ConfigPath)
        UIDropDownMenu_SetSelectedValue(dropdown, self.value)
    end
    dropdown.initialize = function(dd)
        local curValue = WidgetConfigBridgeGet(dd, defVal, ConfigPath)
        local info = UIDropDownMenu_CreateInfo()
        for i,name in ipairs(fontList) do
            wipe(info)
            info.text = name
            info.value = fontPaths[name]
            info.fontObject = fontObjects[info.value]
            info.checked = (curValue == info.value)
            info.func = itemOnClick
            UIDropDownMenu_AddButton(info)
        end
        UIDropDownMenu_SetSelectedValue(dd, curValue or defVal)
    end
    dropdown:HookScript("OnShow", function(self)
        DropDownList1:SetClampedToScreen(true)
        local curValue = WidgetConfigBridgeGet(self, defVal, ConfigPath)
        for name, path in pairs(fontPaths) do
            if (path == curValue) then
                getglobal(self:GetName().."Text"):SetText(name)
            end
        end
    end)
    return dropdown
end

local function CreateDropDownMenu(self, label, tooltip, parent, point1, point2, x, y, menuItems, ConfigPathOrFunc)
    local dropdown = CreateFrame('Frame', self:NewFrameID(), self, "UIDropDownMenuTemplate")
    self:AddFrame(dropdown)
    dropdown:SetPoint(point1, parent, point2, x, y)
    dropdown.left = getglobal(dropdown:GetName() .. "Left")
    dropdown.middle = getglobal(dropdown:GetName() .. "Middle")
    dropdown.middle:SetWidth(150)
    dropdown.right = getglobal(dropdown:GetName() .. "Right")
    dropdown.curValue = menuItems[1].value
    
    local function itemOnClick(self)
        for i, item in ipairs(menuItems) do
            if (item.value == self.value) then
                dropdown.curValue = item.value
                break
            end
        end
        WidgetConfigBridgeSet(dropdown, self.value, ConfigPathOrFunc)
        UIDropDownMenu_SetSelectedValue(dropdown, self.value)
    end
    dropdown.initialize = function(dd)
        local info = UIDropDownMenu_CreateInfo()
        for i,item in ipairs(menuItems) do
            wipe(info)
            info.text = item.text
            info.value = item.value
            info.checked = (info.value == dropdown.curValue)
            info.func = itemOnClick
            UIDropDownMenu_AddButton(info)
        end
        UIDropDownMenu_SetSelectedValue(dd, dd.curValue)
    end
    dropdown:HookScript("OnShow", function(self)
        self.curValue = WidgetConfigBridgeGet(self, self.curValue, ConfigPathOrFunc)
        for _,item in ipairs(menuItems) do
            if (item.value == self.curValue) then
                getglobal(self:GetName().."Text"):SetText(item.text)
            end
        end
    end)
    return dropdown
end

local function CreateColorOption(self, label, tooltip, parent, point1, point2, x, y, defVal, ConfigPathOrFunc)
    local btn = CreateFrame("Button", self:NewFrameID(), self)
    if not btn then
        return nil
    end
    self:AddFrame(btn)

    if parent then
        btn:SetPoint(point1, parent, point2, x, y)
    else
        btn:SetPoint("TOPLEFT", 0, 0)
    end
    btn:SetSize(110, 24)
    btn:EnableMouse(true)

    if (ConfigPathOrFunc and (type(ConfigPathOrFunc) == 'function')) then
        btn.configFunc = ConfigPathOrFunc
    else
        btn.configPath = ConfigPathOrFunc
    end

    btn.SetColor = function(self, r, g, b, a)
        self.value = {a=a, r=r, g=g, b=b}
        if self.preview then
            self.preview:SetVertexColor(r, g, b, a)
        end
    end
    btn:SetScript("OnEnter", function(self)
        if self.preview and self.preview.bg then
            pcall(function()
                if self.preview.bg.SetColorTexture then
                    self.preview.bg:SetColorTexture(1, 1, 1)
                elseif self.preview.bg.SetVertexColor then
                    self.preview.bg:SetVertexColor(1, 1, 1)
                end
            end)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self.preview and self.preview.bg then
            pcall(function()
                if self.preview.bg.SetColorTexture then
                    self.preview.bg:SetColorTexture(0.5, 0.5, 0.5)
                elseif self.preview.bg.SetVertexColor then
                    self.preview.bg:SetVertexColor(0.5, 0.5, 0.5)
                end
            end)
        end
    end)
    btn:SetScript("OnClick", function(self)
        ColorPickerFrame:Hide()
        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        ColorPickerFrame:SetFrameLevel(self:GetFrameLevel() + 10)
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = 1 - OpacitySliderFrame:GetValue()
            WidgetConfigBridgeSet(self, CFCT.RGBA2Color(r, g, b, a), ConfigPathOrFunc)
            self:SetColor(r, g, b, a)
        end
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacityFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = 1 - OpacitySliderFrame:GetValue()
            WidgetConfigBridgeSet(self, CFCT.RGBA2Color(r, g, b, a), ConfigPathOrFunc)
            self:SetColor(r, g, b, a)
        end

        local a, r, g, b = self.value.a, self.value.r, self.value.g, self.value.b
        ColorPickerFrame.opacity = 1 - a
        ColorPickerFrame:SetColorRGB(r, g, b)

        ColorPickerFrame.cancelFunc = function()
            WidgetConfigBridgeSet(self, CFCT.RGBA2Color(r, g, b, a), ConfigPathOrFunc)
            self:SetColor(r, g, b, a)
        end

        ColorPickerFrame:Show()
    end)
    btn:SetScript("OnShow", function(self)
        local r, g, b, a = CFCT.Color2RGBA(WidgetConfigBridgeGet(self, defVal, ConfigPathOrFunc))
        self:SetColor(r, g, b, a)
    end)

    local preview = btn:CreateTexture(nil, "OVERLAY")
    if preview then
        btn.preview = preview
        preview:SetSize(22, 22)
        preview:SetTexture(130939)
        preview:SetPoint("LEFT")
    else
        btn.preview = nil
    end

    local tex = btn:CreateTexture(nil, "BACKGROUND")
    if tex and preview then
        preview.bg = tex
        tex:SetSize(18, 18)
        local success = pcall(function()
            if tex.SetColorTexture then
                tex:SetColorTexture(0.5, 0.5, 0.5)
            elseif tex.SetVertexColor then
                tex:SetVertexColor(0.5, 0.5, 0.5)
            end
        end)
        if not success then
            -- If color setting fails, just continue without color
        end
        tex:SetPoint("CENTER", preview)
        tex:Show()
    else
        if preview then
            preview.bg = nil
        end
    end

    -- checkerboard alpha background
    local ch = btn:CreateTexture(nil, "BACKGROUND")
    if ch and preview then
        preview.ch = ch
        ch:SetWidth(16)
        ch:SetHeight(16)
        ch:SetTexture(188523)
        ch:SetTexCoord(.25, 0, 0.5, .25)
        ch:SetDesaturated(true)
        ch:SetVertexColor(1, 1, 1, 0.75)
        ch:SetPoint("CENTER", preview)
        ch:Show()
    else
        if preview then
            preview.ch = nil
        end
    end

    local lbl = btn:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    btn.label = lbl
    lbl:SetHeight(24)
    lbl:SetJustifyH("LEFT")
    lbl:SetTextColor(1, 1, 1)
    if preview then
        lbl:SetPoint("LEFT", preview, "RIGHT", 2, 0)
    else
        lbl:SetPoint("LEFT", btn, "LEFT", 2, 0)
    end
    lbl:SetPoint("RIGHT")
    lbl:SetText(label)

    btn._Disable = btn.Disable
    btn.Disable = function(self)
        self:_Disable()
        lbl:SetTextColor(0.5, 0.5, 0.5)
    end
    btn._Enable = btn.Enable
    btn.Enable = function(self)
        self:_Enable()
        lbl:SetTextColor(1, 1, 1)
    end

    if not btn.preview then
        btn.preview = {}
    end

    return btn
end

local HEADER_TEXT = {
    auto = "Auto Hits",
    automiss = "Auto Misses",
    autocrit = "Auto Crits",
    petauto = "Pet Auto Hits",
    petautomiss = "Pet Auto Misses",
    petautocrit = "Pet Auto Crits",

    spell = "Spell Hits",
    spellmiss = "Spell Misses",
    spellcrit = "Spell Crits",
    spelltick = "DoT Ticks",
    spelltickmiss = "DoT Miss Ticks",
    spelltickcrit = "DoT Crit Ticks",

    petspell = "Pet Spell Hits",
    petspellmiss = "Pet Spell Misses",
    petspellcrit = "Pet Spell Crits",
    petspelltick = "Pet DoT Ticks",
    petspelltickmiss = "Pet DoT Miss Ticks",
    petspelltickcrit = "Pet DoT Crit Ticks",

    heal = "Heals",
    healmiss = "Heal Misses",
    healcrit = "Heal Crits",
    healtick = "HoT Ticks",
    healtickmiss = "HoT Miss Ticks",
    healtickcrit = "HoT Crit Ticks",

    petheal = "Pet Heals",
    pethealmiss = "Pet Heal Misses",
    pethealcrit = "Pet Heal Crits",
    pethealtick = "Pet HoT Ticks",
    pethealtickmiss = "Pet HoT Miss Ticks",
    pethealtickcrit = "Pet HoT Crit Ticks",
}

-- Animation panel creation functions with font size scaling instead of SetScale
local function CreatePowAnimationPanel(self, cat, anchor, point1, point2, x, y)
    local f = self:CreateChildFrame(point1, point2, anchor, x, y, 612, 90)
    f:Hide()
    DefaultConfig[cat].Pow = DefaultConfig[cat].Pow or {}
    UpdateTable(DefaultConfig[cat].Pow, AnimationDefaults.Pow, AnimationDefaults.Pow)
    local enabledCheckbox = f:CreateCheckbox("Enable Pow", "Enables/Disables this animation type", f, "TOPLEFT", "TOPLEFT", 170, -2, DefaultConfig[cat].Pow.enabled, "Config."..cat..".Pow.enabled")
    local c = f:CreateChildFrame(point1, point2, anchor, x, y, 612, 90)
    
    local duration = c:CreateSlider("Duration", "Animation duration relative to global duration", f, "TOPLEFT", "TOPLEFT", 310, -12, 0.01, 1, 0.01, DefaultConfig[cat].Pow.duration, "Config."..cat..".Pow.duration")
    duration:SetFrameLevel(enabledCheckbox:GetFrameLevel()+1)
    local inOutRatio = c:CreateSlider("Duration Ratio", "Duration ratio between time spent in Start to Mid phase and time spent in Mid to End phase.", f, "TOPLEFT", "TOPLEFT", 460, -12, 0.01, 1, 0.01, DefaultConfig[cat].Pow.inOutRatio, "Config."..cat..".Pow.inOutRatio")
    
    local initScale = c:CreateSlider("Start Scale", "Initial font size scale", f, "TOPLEFT", "TOPLEFT", 160, -58, 0.1, 5, 0.01, DefaultConfig[cat].Pow.initScale, "Config."..cat..".Pow.initScale")
    local midScale = c:CreateSlider("Mid Scale", "Mid point font size scale", f, "TOPLEFT", "TOPLEFT", 310, -58, 0.1, 5, 0.01, DefaultConfig[cat].Pow.midScale, "Config."..cat..".Pow.midScale")
    local endScale = c:CreateSlider("End Scale", "Final font size scale", f, "TOPLEFT", "TOPLEFT", 460, -58, 0.1, 5, 0.01, DefaultConfig[cat].Pow.endScale, "Config."..cat..".Pow.endScale")
    duration:SetWidth(140)
    inOutRatio:SetWidth(140)
    initScale:SetWidth(140)
    midScale:SetWidth(140)
    endScale:SetWidth(140)
    enabledCheckbox:HookScript("OnShow", function(self)
        if self:GetChecked() then c:Show() else c:Hide() end
    end)
    enabledCheckbox:HookScript("OnClick", function(self)
        if self:GetChecked() then c:Show() else c:Hide() end
    end)
    f.enabledCheckbox = enabledCheckbox
    return f
end    

local function CreateFadeInAnimationPanel(self, cat, anchor, point1, point2, x, y)
    local f = self:CreateChildFrame(point1, point2, anchor, x, y, 612, 90)
    f:Hide()
    DefaultConfig[cat].FadeIn = DefaultConfig[cat].FadeIn or {}
    UpdateTable(DefaultConfig[cat].FadeIn, AnimationDefaults.FadeIn, AnimationDefaults.FadeIn)
    local enabledCheckbox = f:CreateCheckbox("Enable Fade In", "Enables/Disables this animation type", f, "TOPLEFT", "TOPLEFT", 170, -2, DefaultConfig[cat].FadeIn.enabled, "Config."..cat..".FadeIn.enabled")
    local c = f:CreateChildFrame(point1, point2, anchor, x, y, 612, 90)
    
    local duration = c:CreateSlider("Duration", "Animation duration relative to global duration", f, "TOPLEFT", "TOPLEFT", 320, -12, 0.01, 1, 0.01, DefaultConfig[cat].FadeIn.duration, "Config."..cat..".FadeIn.duration")
    duration:SetFrameLevel(enabledCheckbox:GetFrameLevel()+1)
    duration:SetWidth(140)
    enabledCheckbox:HookScript("OnShow", function(self)
        if self:GetChecked() then c:Show() else c:Hide() end
    end)
    enabledCheckbox:HookScript("OnClick", function(self)
        if self:GetChecked() then c:Show() else c:Hide() end
    end)
    f.enabledCheckbox = enabledCheckbox
    return f
end   

local function CreateFadeOutAnimationPanel(self, cat, anchor, point1, point2, x, y)
    local f = self:CreateChildFrame(point1, point2, anchor, x, y, 612, 90)
    f:Hide()
    DefaultConfig[cat].FadeOut = DefaultConfig[cat].FadeOut or {}
    UpdateTable(DefaultConfig[cat].FadeOut, AnimationDefaults.FadeOut, AnimationDefaults.FadeOut)
    local enabledCheckbox = f:CreateCheckbox("Enable Fade Out", "Enables/Disables this animation type", f, "TOPLEFT", "TOPLEFT", 170, -2, DefaultConfig[cat].FadeOut.enabled, "Config."..cat..".FadeOut.enabled")
    local c = f:CreateChildFrame(point1, point2, anchor, x, y, 612, 90)
    
    local duration = c:CreateSlider("Duration", "Animation duration relative to global duration", f, "TOPLEFT", "TOPLEFT", 320, -12, 0.01, 1, 0.01, DefaultConfig[cat].FadeOut.duration, "Config."..cat..".FadeOut.duration")
    duration:SetFrameLevel(enabledCheckbox:GetFrameLevel()+1)
    duration:SetWidth(140)
    enabledCheckbox:HookScript("OnShow", function(self)
        if self:GetChecked() then c:Show() else c:Hide() end
    end)
    enabledCheckbox:HookScript("OnClick", function(self)
        if self:GetChecked() then c:Show() else c:Hide() end
    end)
    f.enabledCheckbox = enabledCheckbox
    return f
end

local ScrollDirectionsMenu = {
    {
        text = "Scroll Up",
        value = "UP"
    },
    {
        text = "Scroll Down",
        value = "DOWN"
    },
    {
        text = "Scroll Left",
        value = "LEFT"
    },
    {
        text = "Scroll Right",
        value = "RIGHT"
    },
    {
        text = "Scroll Up & Left",
        value = "UPLEFT"
    },
    {
        text = "Scroll Up & Right",
        value = "UPRIGHT"
    },
    {
        text = "Scroll Down & Left",
        value = "DOWNLEFT"
    },
    {
        text = "Scroll Down & Right",
        value = "DOWNRIGHT"
    },
    {
        text = "Random Direction",
        value = "RANDOM"
    },
}

local function CreateScrollAnimationPanel(self, cat, anchor, point1, point2, x, y)
    local f = self:CreateChildFrame(point1, point2, anchor, x, y, 612, 90)
    f:Hide()
    DefaultConfig[cat].Scroll = DefaultConfig[cat].Scroll or {}
    UpdateTable(DefaultConfig[cat].Scroll, AnimationDefaults.Scroll, AnimationDefaults.Scroll)
    local enabledCheckbox = f:CreateCheckbox("Enable Scroll", "Enables/Disables this animation type", f, "TOPLEFT", "TOPLEFT", 170, -2, DefaultConfig[cat].Scroll.enabled, "Config."..cat..".Scroll.enabled")
    local c = f:CreateChildFrame(point1, point2, anchor, x, y, 612, 90)
    
    local dirDropDown = c:CreateDropDownMenu("Direction", "Scroll direction", f, "TOPLEFT", "TOPLEFT", 320-16, 0, ScrollDirectionsMenu, "Config."..cat..".Scroll.direction")
    dirDropDown.middle:SetWidth(120)
    local distance = c:CreateSlider("Distance", "Scroll distance", f, "TOPLEFT", "TOPLEFT", 320, -40, 1, floor(WorldFrame:GetWidth()), 1, DefaultConfig[cat].Scroll.distance, "Config."..cat..".Scroll.distance")
    distance:SetFrameLevel(enabledCheckbox:GetFrameLevel()+1)
    distance:SetWidth(140)
    enabledCheckbox:HookScript("OnShow", function(self)
        if self:GetChecked() then c:Show() else c:Hide() end
    end)
    enabledCheckbox:HookScript("OnClick", function(self)
        if self:GetChecked() then c:Show() else c:Hide() end
    end)
    f.enabledCheckbox = enabledCheckbox
    return f
end    

local function CreateCategoryPanel(self, cat, anchor, point1, point2, x, y)
    local f = self:CreateChildFrame(point1, point2, anchor, x, y, 612, 180)
    f:Show()
    
    local header = self:CreateHeader(HEADER_TEXT[cat], "GameFontNormalLarge", f, "TOPLEFT", "TOPLEFT", 4, -2)
    local enabledCheckbox = self:CreateCheckbox("Enabled", "Enables/Disables this event type", f, "TOPLEFT", "TOPLEFT", 143, 0, DefaultConfig[cat].enabled, "Config."..cat..".enabled")
    enabledCheckbox.label:SetWidth(80)
    enabledCheckbox:HookScript("OnShow", function(self)
        if (self:GetChecked()) then f:Show() else f:Hide() end
    end)
    enabledCheckbox:HookScript("OnClick", function(self)
        if (self:GetChecked()) then f:Show() else f:Hide() end
    end)
    local showIconsCheckbox = f:CreateCheckbox("Show Spell Icons", "Enables/Disables showing spell icons next to damage text", f, "TOPLEFT", "TOPLEFT", 250, 0, DefaultConfig[cat].showIcons, "Config."..cat..".showIcons")
    showIconsCheckbox:SetFrameLevel(enabledCheckbox:GetFrameLevel() + 1)

    local fontFaceDropDown = f:CreateFontDropdown("Font Face", "Font face used", f, "TOPLEFT", "TOPLEFT", -16, -28, DefaultConfig[cat].fontPath, "Config."..cat..".fontPath")
    local fontStyleDropDown = f:CreateDropDownMenu("Font Style", "Font style used", f, "TOPLEFT", "TOPLEFT", 154, -28, FontStylesMenu, "Config."..cat..".fontStyle")
    local fontSizeSlider = f:CreateSlider("Font Size", "Font Size", f, "TOPLEFT", "TOPLEFT", 170+180, -28, 10, 128, 1, DefaultConfig[cat].fontSize, "Config."..cat..".fontSize")
    fontSizeSlider:SetWidth(150)
    local colorWidget = f:CreateColorOption("Text Color", "Custom text color for this event", f, "TOPLEFT", "TOPLEFT", 170+180+160, -30, DefaultConfig[cat].fontColor, "Config."..cat..".fontColor")
    if (cat:find("heal") == nil) then
        local clrDmgTypeCheckbox = f:CreateCheckbox("Color By Type", "Enables/Disables coloring damage text based on its type (alpha still taken from the text color below)", f, "TOPLEFT", "TOPLEFT", 480, 0, DefaultConfig[cat].colorByType, "Config."..cat..".colorByType")
    end
    local animPanel = {}
    animPanel.Pow = CreatePowAnimationPanel(f, cat, f, "TOPLEFT", "TOPLEFT", 0, -70)
    animPanel.FadeIn = CreateFadeInAnimationPanel(f, cat, f, "TOPLEFT", "TOPLEFT", 0, -70)
    animPanel.FadeOut = CreateFadeOutAnimationPanel(f, cat, f, "TOPLEFT", "TOPLEFT", 0, -70)
    animPanel.Scroll = CreateScrollAnimationPanel(f, cat, f, "TOPLEFT", "TOPLEFT", 0, -70)
    local animStatus = "init"
    local animStatusHeader = f:CreateHeader("Animation Status:"..animStatus, "GameFontHighlightSmall", f, "TOPLEFT", "TOPLEFT", 4, -100)
    animStatusHeader:SetJustifyH("LEFT")

    local function updateStatus()
        animStatus = ""
        for i,a in ipairs(AnimationsMenu) do
            local k = a.text
            animStatus = animStatus..(CFCT.Config[cat][a.value].enabled and "\n|cff00ff00"..k or "\n|cffff0000"..k).."|r"
        end
        animStatusHeader:SetText("Animation Status:"..animStatus)
    end

    for k,v in pairs(animPanel) do
        v.enabledCheckbox:HookScript("OnClick", function(self)
            updateStatus()
        end)
    end
    
    local function show(val)
        for k,v in pairs(animPanel) do
            if (k == val) then v:Show() else v:Hide() end
        end
    end

    local animHeader = f:CreateHeader("Animation Settings", "GameFontHighlightSmall", f, "TOPLEFT", "TOPLEFT", 4, -60)

    local animDropDown = f:CreateDropDownMenu("Animations", "Animations", f, "TOPLEFT", "TOPLEFT", -16, -70, AnimationsMenu, function(self, e, value)
        if (e == "Get") then
            return value
        elseif (e == "Set") then
            show(value)
        end
        updateStatus()
    end)
    animDropDown:HookScript("OnShow", function(self)
        show(self.curValue)
        updateStatus()
    end)

    return f
end

-- Widget management functions
local function AddFrame(self, widget)
    local n = self.widgetCount + 1
    self.widgets[n] = widget
    self.widgetCount = n
end

local function NewFrameID(self)
    return self:GetName().."_Frame" .. tostring(self.widgetCount + 1)
end

local function Refresh(self)
    if (self:IsShown()) then
        self:Hide()
        self:Show()
    end
end

-- Function to refresh all UI widgets to reflect current config values
function CFCT.RefreshAllWidgets()
    if CFCT.ConfigPanel and CFCT.ConfigPanel.widgets then
        for _, widget in ipairs(CFCT.ConfigPanel.widgets) do
            if widget and widget:IsShown() then
                if widget.OnShow then
                    widget:OnShow()
                end
                if widget.widgets then
                    for _, childWidget in ipairs(widget.widgets) do
                        if childWidget and childWidget:IsShown() and childWidget.OnShow then
                            childWidget:OnShow()
                        end
                    end
                end
            end
        end
    end
end

local function EnableFrameTree(self)
    for _, e in ipairs(self.widgets) do
        if type(e.Enable) == 'function' then e:Enable() end
    end
end
local function DisableFrameTree(self)
    for _, e in ipairs(self.widgets) do
        if type(e.Disable) == 'function' then e:Disable() end
    end
end

local function CreateChildFrame(self, point1, point2, anchor, x, y, w, h)
    local f = CreateFrame("frame", self:NewFrameID(), self)
    self:AddFrame(f)
    f:SetPoint(point1, anchor, point2, x, y)
    f:SetSize(w,h)
    f:SetFrameLevel(1)
    f.widgets = {}
    f.widgetCount = 0
    f.CreateChildFrame = CreateChildFrame
    f.CreateHeader = CreateHeader
    f.CreateCheckbox = CreateCheckbox
    f.CreateButton = CreateButton
    f.CreateFontDropdown = CreateFontDropdown
    f.CreateDropDownMenu = CreateDropDownMenu
    f.CreateSlider = CreateSlider
    f.CreateColorOption = CreateColorOption
    f.AddFrame = AddFrame
    f.NewFrameID = NewFrameID
    f.Enable = EnableFrameTree
    f.Disable = DisableFrameTree
    f.Refresh = Refresh
    return f
end

local function CreateConfigPanel(name, parent, height)
    local Container = CreateFrame('frame', "ClassicFCTConfigPanel_"..gsub(name, " ", ""), UIParent)
    local sf = CreateFrame('ScrollFrame', Container:GetName().."_ScrollFrame", Container, "UIPanelScrollFrameTemplate")
    local sfname = sf:GetName()
    sf.scrollbar = getglobal(sfname.."ScrollBar")
    sf.scrollupbutton = getglobal(sfname.."ScrollBarScrollUpButton")
    sf.scrolldownbutton = getglobal(sfname.."ScrollBarScrollDownButton")

    sf.scrollupbutton:ClearAllPoints();
    sf.scrollupbutton:SetPoint("TOPLEFT", sf, "TOPRIGHT", -6, -2);
    
    sf.scrolldownbutton:ClearAllPoints();
    sf.scrolldownbutton:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", -6, 2);
    
    sf.scrollbar:ClearAllPoints();
    sf.scrollbar:SetPoint("TOP", sf.scrollupbutton, "BOTTOM", 0, -2);
    sf.scrollbar:SetPoint("BOTTOM", sf.scrolldownbutton, "TOP", 0, 2);

    Container.name = name
    Container.parent = parent
    Container.refresh = Refresh
    Container.okay = function(self)
        CFCT._testMode = false
        CFCT.Config:OnSave()
    end
    Container.cancel = function(self)
        CFCT._testMode = false
        CFCT.Config:OnSave()
    end
    InterfaceOptions_AddCategory(Container)
    CFCT.ConfigPanels[#CFCT.ConfigPanels + 1] = Container
    Container:SetAllPoints()
    Container:Hide()

    local p = CreateFrame("Frame", Container:GetName().."_ScrollChild")
    p.refresh = function(self) Container:refresh() end 
    p.widgets = {}
    p.widgetCount = 0
    p.CreateSubPanel = function(self, name, height)
        return CreateConfigPanel(name, Container.name, height)
    end
    p.CreateChildFrame = CreateChildFrame
    p.CreateCategoryPanel = CreateCategoryPanel
    p.CreateHeader = CreateHeader
    p.CreateCheckbox = CreateCheckbox
    p.CreateButton = CreateButton
    p.CreateFontDropdown = CreateFontDropdown
    p.CreateDropDownMenu = CreateDropDownMenu
    p.CreateSlider = CreateSlider
    p.CreateColorOption = CreateColorOption
    p.AddFrame = AddFrame
    p.NewFrameID = NewFrameID
    Container.panel = p
    p.Container = Container
    sf:SetScrollChild(p)
    sf:SetAllPoints()
    p:HookScript("OnShow", function(self) self:SetSize(sf:GetWidth(), height or sf:GetHeight()) end)
    return p
end

-- ConfigPanel Layout
local ConfigPanel = CreateConfigPanel("ClassicFCT", nil, 800)

ConfigPanel:HookScript("OnShow", function(self) 
    CFCT._testMode = true
    C_Timer.After(0.1, function()
        CFCT.RefreshAllWidgets()
    end)
end)

CFCT.ConfigPanel = ConfigPanel
local headerGlobal = ConfigPanel:CreateHeader("ClassicFCT Configuration", "GameFontNormalLarge", ConfigPanel, "TOPLEFT", "TOPLEFT", 16, -16)
local charSpecificCheckbox = ConfigPanel:CreateCheckbox("Character Specific Config", "Settings are saved per character. Presets stay global.", headerGlobal, "LEFT", "LEFT", 0, -2, DefaultVars.characterSpecificConfig, function(self, e, value)
    if (e == "Get") then
        return CFCT.characterSpecificConfig == nil and value or CFCT.characterSpecificConfig
    elseif (e == "Set") then
        CFCT.Config:OnSave()
        CFCT.characterSpecificConfig = value
        ClassicFCTVars.characterSpecificConfig = value
        CFCT.Config:OnLoad()
        ConfigPanel:refresh()
    end
end)
local enabledCheckbox = ConfigPanel:CreateCheckbox("Enable ClassicFCT", "Enables/Disables the addon", charSpecificCheckbox, "TOPLEFT", "BOTTOMLEFT", 0, -2, DefaultVars.enabled, "enabled")

local hideBlizzDamageCheckbox = ConfigPanel:CreateCheckbox("Hide Blizzard Damage", "Enables/Disables the default Blizzard Floating Damage Text", enabledCheckbox, "LEFT", "RIGHT", 150, 0, DefaultVars.hideBlizz, "hideBlizz")
hideBlizzDamageCheckbox:HookScript("OnClick", function(self)
    SetCVar("CombatDamage", self:GetChecked() and "0" or "1")
end)
if (GetCVarDefault("CombatDamage") == nil) then hideBlizzDamageCheckbox:Hide() end

local hideBlizzHealingCheckbox = ConfigPanel:CreateCheckbox("Hide Blizzard Healing", "Enables/Disables the default Blizzard Floating Healing Text", hideBlizzDamageCheckbox, "LEFT", "RIGHT", 150, 0, DefaultVars.hideBlizzHeals, "hideBlizzHeals")
hideBlizzHealingCheckbox:HookScript("OnClick", function(self)
    SetCVar("CombatHealing", self:GetChecked() and "0" or "1")
end)
if (GetCVarDefault("CombatHealing") == nil) then hideBlizzHealingCheckbox:Hide() end

local headerPresets = ConfigPanel:CreateHeader("Config Presets", "GameFontNormalLarge", headerGlobal, "TOPLEFT", "BOTTOMLEFT", 0, -46)

-- Create a minimal config interface due to space constraints
local CONFIG_LAYOUT = {
    {
        catname = "Auto Attacks",
        subcatlist = {
            "auto",
            "autocrit",
            "automiss"
        }
    },
    {
        catname = "Special Attacks",
        subcatlist = {
            "spell",
            "spellcrit",
            "spellmiss"
        }
    },
    {
        catname = "Damage Over Time",
        subcatlist = {
            "spelltick",
            "spelltickcrit",
            "spelltickmiss"
        }
    },
    {
        catname = "Heals",
        subcatlist = {
            "heal",
            "healcrit",
            "healmiss"
        }
    },
    {
        catname = "Heals Over Time",
        subcatlist = {
            "healtick",
            "healtickcrit",
            "healtickmiss"
        }
    },
    {
        catname = "Pet Auto Attacks",
        subcatlist = {
            "petauto",
            "petautocrit",
            "petautomiss"
        }
    },
    {
        catname = "Pet Special Attacks",
        subcatlist = {
            "petspell",
            "petspellcrit",
            "petspellmiss"
        }
    },
    {
        catname = "Pet Damage Over Time",
        subcatlist = {
            "petspelltick",
            "petspelltickcrit",
            "petspelltickmiss"
        }
    },
    {
        catname = "Pet Heals",
        subcatlist = {
            "petheal",
            "pethealcrit",
            "pethealmiss"
        }
    },
    {
        catname = "Pet Heals Over Time",
        subcatlist = {
            "pethealtick",
            "pethealtickcrit",
            "pethealtickmiss"
        }
    }
}

for _, cat in ipairs(CONFIG_LAYOUT) do
    local subpanel = ConfigPanel:CreateSubPanel(cat.catname)
    subpanel:HookScript("OnShow", function(self) CFCT._testMode = true end)
    subpanel:HookScript("OnHide", function(self) CFCT._testMode = false end)
    local parent = nil
    for _, subcat in ipairs(cat.subcatlist) do
        if not parent then
            parent = subpanel:CreateCategoryPanel(subcat, subpanel, "TOPLEFT", "TOPLEFT", 6, -6)
        else
            parent = subpanel:CreateCategoryPanel(subcat, parent, "TOPLEFT", "BOTTOMLEFT", 0, -6)
        end
    end
end