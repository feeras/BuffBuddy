BuffsPlease = BuffsPlease or {}

BuffsPleaseDB_Defaults = {
    framePos     = { x = 300, y = 0 },
    enabledBuffs = {},   -- [spellId] = false to disable; absent/true means enabled
    whisperText  = "Could you please buff me with %s?",
    groupOnly    = true,
    maxButtons   = 5,
    minLevelDiff = 10,   -- don't request buffs from players more than this many levels below you
}

-- Deep-copy default values into db without overwriting keys already set by the user.
local function ApplyDefaults(db, defaults)
    for k, v in pairs(defaults) do
        if db[k] == nil then
            if type(v) == "table" then
                db[k] = {}
                ApplyDefaults(db[k], v)
            else
                db[k] = v
            end
        end
    end
end

-- ── Addon-loaded handler ──────────────────────────────────────────────────────

local configFrame = CreateFrame("Frame")
configFrame:RegisterEvent("ADDON_LOADED")

configFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "BuffsPlease" then return end
    self:UnregisterEvent("ADDON_LOADED")

    -- Initialise or upgrade the SavedVariables table
    if type(BuffsPleaseDB) ~= "table" then
        BuffsPleaseDB = {}
    end
    ApplyDefaults(BuffsPleaseDB, BuffsPleaseDB_Defaults)

    -- Strip legacy "[BuffsPlease] " prefix from saved whisper template
    if BuffsPleaseDB.whisperText then
        BuffsPleaseDB.whisperText = BuffsPleaseDB.whisperText:gsub("^%[BuffsPlease%]%s*", "")
    end

    -- Build the UI now that we have valid settings
    if BuffsPlease.UI and BuffsPlease.UI.Initialize then
        BuffsPlease.UI:Initialize()
    end

    -- Register the Interface Options panel
    BuffsPlease.CreateOptionsPanel()
end)

-- ── Interface Options panel ───────────────────────────────────────────────────

function BuffsPlease.CreateOptionsPanel()
    local panel = CreateFrame("Frame", "BuffsPleaseOptionsPanel")
    panel.name = "BuffsPlease"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffffcc00BuffsPlease|r Settings")

    -- ── Min Level Difference ──────────────────────────────────────────────────
    local sectionLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sectionLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    sectionLabel:SetText("Buff Request Level Filter")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", sectionLabel, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(380)
    desc:SetJustifyH("LEFT")
    desc:SetText("Don't suggest requesting buffs from players more than this many levels below you. Set to 0 to disable the filter.")
    desc:SetTextColor(0.7, 0.7, 0.7)

    local slider = CreateFrame("Slider", "BuffsPleaseMinLevelDiffSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 2, -20)
    slider:SetWidth(220)
    slider:SetMinMaxValues(0, 60)
    slider:SetValueStep(1)
    _G[slider:GetName() .. "Low"]:SetText("0")
    _G[slider:GetName() .. "High"]:SetText("60")
    _G[slider:GetName() .. "Text"]:SetText("Min Level Difference")

    local valueDisplay = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    valueDisplay:SetPoint("LEFT", slider, "RIGHT", 14, 0)
    valueDisplay:SetText("10")

    slider:SetScript("OnValueChanged", function(self, value)
        valueDisplay:SetText(math.floor(value))
    end)

    -- Sync slider from saved DB each time the panel is opened
    panel:SetScript("OnShow", function()
        local v = (BuffsPleaseDB and BuffsPleaseDB.minLevelDiff ~= nil) and BuffsPleaseDB.minLevelDiff or 10
        slider:SetValue(v)
        valueDisplay:SetText(v)
    end)

    -- Called when the user clicks "Okay"
    panel.okay = function()
        if BuffsPleaseDB then
            BuffsPleaseDB.minLevelDiff = math.floor(slider:GetValue())
        end
        if BuffsPlease.Core then BuffsPlease.Core:Refresh() end
    end

    -- Called when the user clicks "Cancel" – nothing to revert since we only write on okay
    panel.cancel = function() end

    -- Called when the user clicks "Defaults"
    panel.default = function()
        slider:SetValue(10)
        valueDisplay:SetText("10")
    end

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        panel.category = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

-- ── Slash commands ────────────────────────────────────────────────────────────

SLASH_BUFFSPLEASE1 = "/buffsplease"
SLASH_BUFFSPLEASE2 = "/bp"

SlashCmdList["BUFFSPLEASE"] = function(msg)
    local cmd = string.lower(string.match(msg, "^%s*(%S*)") or "")

    if cmd == "" then
        -- Toggle the main frame
        if BuffsPlease.UI and BuffsPlease.UI.Toggle then
            BuffsPlease.UI:Toggle()
        end

    elseif cmd == "reset" then
        if BuffsPlease.UI and BuffsPlease.UI.ResetPosition then
            BuffsPlease.UI:ResetPosition()
            print("|cffffcc00BuffsPlease:|r Frame position reset.")
        end

    elseif cmd == "debugcast" then
        BuffsPlease.debugCast = not BuffsPlease.debugCast
        print("|cffffcc00BuffsPlease:|r Cast debug logging " .. (BuffsPlease.debugCast and "|cff00ff00ON|r" or "|cffff4040OFF|r"))
        if BuffsPlease.debugCast then
            print("  Triggers on next UI refresh. Move your mouse or wait up to 5s.")
        end

    elseif cmd == "debugsmart" then
        BuffsPlease.debugSmart = not BuffsPlease.debugSmart
        print("|cffffcc00BuffsPlease:|r Smart buff debug " .. (BuffsPlease.debugSmart and "|cff00ff00ON|r" or "|cffff4040OFF|r"))
        if BuffsPlease.debugSmart then
            print("  Shows cast scan results on each refresh. Toggle off when done.")
            BuffsPlease.Core:Refresh()
        end

    elseif cmd == "test" then
        local testSpellId = 21562  -- Power Word: Fortitude (rank 4)
        local link = "[Power Word: Fortitude]"
        local template = (BuffsPleaseDB and BuffsPleaseDB.whisperText)
            or "Could you please buff me with %s?"
        local msg = string.format(template, link)
        local playerName = UnitName("player")
        SendChatMessage(msg, "WHISPER", nil, playerName)
        print("|cffffcc00BuffsPlease:|r Sent test whisper to yourself: " .. msg)

    elseif cmd == "minleveldiff" then
        local val = tonumber(string.match(msg, "%S+%s+(%S+)"))
        if val then
            BuffsPleaseDB.minLevelDiff = math.max(0, math.floor(val))
            print(string.format("|cffffcc00BuffsPlease:|r Min level diff set to %d. Players more than %d levels below you won't be suggested for buff requests.",
                BuffsPleaseDB.minLevelDiff, BuffsPleaseDB.minLevelDiff))
            if BuffsPlease.Core then BuffsPlease.Core:Refresh() end
        else
            print(string.format("|cffffcc00BuffsPlease:|r Current minLevelDiff = %d. Usage: |cffffff00/bb minleveldiff <number>|r",
                (BuffsPleaseDB and BuffsPleaseDB.minLevelDiff) or 10))
        end

    elseif cmd == "debug" then
        print("|cffffcc00BuffsPlease Debug:|r Scanning group buff status...")
        local units = BuffsPlease.Core:GetGroupUnits()
        if #units == 1 then
            print("  Not in a group (showing local player only).")
        end
        for _, unit in ipairs(units) do
            if UnitIsConnected(unit) then
                local name = UnitName(unit) or unit
                local _, classFile = UnitClass(unit)
                print(string.format("|cffa0a0ff%s|r [%s]", name, classFile or "?"))
                local lvl = UnitLevel(unit)
                local targetLvl = (lvl and lvl > 0) and lvl or 60
                for _, buffDef in ipairs(BuffsPlease.BUFF_DEFINITIONS) do
                    local hasBuff, remaining = BuffsPlease.Core:UnitHasBuff(unit, buffDef)
                    local status
                    if hasBuff then
                        if buffDef.maxDuration == 0 then
                            status = "|cff00ff00Active (permanent)|r"
                        else
                            status = string.format("|cff00ff00Active (%.0fs)|r", remaining)
                        end
                    else
                        status = "|cffff4040Missing|r"
                    end
                    -- Show which rank would be cast on this target
                    local rankNote = ""
                    if BuffsPlease.playerClass == buffDef.class then
                        local bestId = BuffsPlease.Core:GetBestKnownSpellId(buffDef, targetLvl)
                        if bestId then
                            local _, rankStr = GetSpellInfo(bestId)
                            rankNote = " → " .. (rankStr or "?")
                        else
                            rankNote = " → |cffff4040no usable rank|r"
                        end
                    end
                    print(string.format("    %-30s %s%s", buffDef.label, status, rankNote))
                end
            end
        end

    else
        print("|cffffcc00BuffsPlease|r commands:")
        print("  |cffffff00/buffsplease|r (or |cffffff00/bp|r) — toggle window")
        print("  |cffffff00/buffsplease reset|r              — reset frame position")
        print("  |cffffff00/buffsplease minleveldiff <n>|r  — min level gap for buff requests (default 10)")
        print("  |cffffff00/buffsplease debugcast|r           — toggle verbose rank-selection logging")
        print("  |cffffff00/buffsplease debugsmart|r         — toggle smart buff scan debug output")
        print("  |cffffff00/buffsplease test|r               — whisper yourself to verify spell link format")
        print("  |cffffff00/buffsplease debug|r              — print group buff status")
    end
end
