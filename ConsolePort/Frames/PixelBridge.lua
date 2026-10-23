---------------------------------------------------------------
-- PixelBridge.lua: Data-to-Pixel Encoder (Experimental)
---------------------------------------------------------------
-- Encodes player state into pixels for external reading with WoWpadX.

local _, db = ...
local Bridge = CreateFrame('Frame', 'ConsolePortPixelBridge', WorldFrame)

-- Pixel Bridge Configuration
-- Sizes are in physical screen pixels (see UpdatePixelScale). Blocks are square
-- and big enough that WoWpadX can sample their centers, away from blended edges
-- caused by HD resolutions, UI scale, DPI scaling or post-processing.
local PIXEL_SIZE   = 6
local FRAME_WIDTH  = PIXEL_SIZE * 2
local FRAME_HEIGHT = PIXEL_SIZE

Bridge:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
Bridge:SetPoint('TOPLEFT', 0, 0)
Bridge:SetFrameStrata('TOOLTIP')
Bridge:SetFrameLevel(100)

-- Beacon (Left Block)
Bridge.Beacon = Bridge:CreateTexture(nil, 'OVERLAY')
Bridge.Beacon:SetSize(PIXEL_SIZE, FRAME_HEIGHT)
Bridge.Beacon:SetPoint('TOPLEFT')

-- Data (Right Block)
Bridge.Data = Bridge:CreateTexture(nil, 'OVERLAY')
Bridge.Data:SetSize(PIXEL_SIZE, FRAME_HEIGHT)
Bridge.Data:SetPoint('TOPLEFT', Bridge.Beacon, 'TOPRIGHT')

-- Make 1 frame unit == 1 physical pixel, regardless of resolution / UI scale.
function Bridge:UpdatePixelScale()
    local _, height = strmatch(GetCVar('gxResolution') or '', '(%d+)x(%d+)')
    height = tonumber(height)
    if not height or height <= 0 then
        height = 768
    end
    local parentScale = WorldFrame:GetEffectiveScale() or 1
    self:SetScale((768 / height) / parentScale)
end

Bridge:RegisterEvent('PLAYER_ENTERING_WORLD')
Bridge:RegisterEvent('DISPLAY_SIZE_CHANGED')
Bridge:RegisterEvent('UI_SCALE_CHANGED')
Bridge:SetScript('OnEvent', Bridge.UpdatePixelScale)
Bridge:UpdatePixelScale()

-- State tracking
local flashTimer = 0
local isMagenta  = true

---------------------------------------------------------------
-- Core Update Logic
---------------------------------------------------------------
function Bridge:OnUpdate(elapsed)
    -- 1. Blinking Logic (0.5s Toggle)
    flashTimer = flashTimer + elapsed
    if flashTimer >= 0.5 then
        isMagenta = not isMagenta
        flashTimer = 0
    end
    
    if isMagenta then
        Bridge.Beacon:SetTexture(1, 0, 1, 1) -- Magenta
    else
        Bridge.Beacon:SetTexture(0, 0, 0, 1) -- Black
    end

    -- 2. Data Encoding
    -- HP: Red Channel
    local maxHP = UnitHealthMax('player')
    local hp = (maxHP > 0) and (UnitHealth('player') / maxHP) or 1
    if hp < 0.01 then hp = 0.01 end
    
    -- State: Green Channel (Bitmask)
    local state = 0 
    local speed = GetUnitSpeed('player')
    local isWalking = (speed > 0 and speed < 4.5)

    if isWalking then state = state + 1 end
    if IsMouselooking() then state = state + 2 end
    if UnitAffectingCombat('player') then state = state + 4 end
    
    -- AOE: Blue Channel
    local isAOE = SpellIsTargeting() and 1 or 0

    -- Bits are packed into the top of the channel (state * 32 + 16) so small
    -- color shifts from gamma, dithering or shaders can't flip them.
    Bridge.Data:SetTexture(hp, (state * 32 + 16) / 255, isAOE, 1)
end

---------------------------------------------------------------
-- Toggle Management
---------------------------------------------------------------
function Bridge:Toggle(enabled)
    if enabled then
        self:Show()
        self:SetScript('OnUpdate', self.OnUpdate)
    else
        self:Hide()
        self:SetScript('OnUpdate', nil)
    end
end

function Bridge:OnVariableChanged(cvar, value)
    if (cvar == 'enablePixelBridge') then
        self:Toggle(value)
    end
end

-- Listen for the setting change via ConsolePort's callback system
ConsolePort:RegisterCallback('FireVarCallback', Bridge.OnVariableChanged, Bridge)

-- Initialize based on current setting
Bridge:Toggle(db('enablePixelBridge'))