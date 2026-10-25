---------------------------------------------------------------
-- Crosshair.lua: Centre-screen reticle while mouselooking
---------------------------------------------------------------
-- Shows four short lines around the centre of the screen while
-- the camera is controlled with the stick (mouselook), so you can
-- see where you're aiming. Backport of the crosshair from modern
-- ConsolePort (seblindfors/ConsolePort, Artistic License 2.0).
-- Setting: crosshairEnable (off by default).

local _, db = ...
---------------------------------------------------------------
local IsMouselooking, min, max = IsMouselooking, math.min, math.max
---------------------------------------------------------------
local LINE_LENGTH = 10   -- length of each line, in UI units
local LINE_WIDTH  = 2    -- thickness of each line
local GAP         = 6    -- distance from the centre to each line
local FADE_SPEED  = 8    -- alpha change per second

local Crosshair = CreateFrame('Frame', 'ConsolePortCrosshair', UIParent)
Crosshair:SetFrameStrata('BACKGROUND')
Crosshair:SetSize(1, 1)
Crosshair:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
Crosshair:SetAlpha(0)
Crosshair:Hide()

local function CreateLine(dx, dy)
	local line = Crosshair:CreateTexture(nil, 'OVERLAY')
	line:SetTexture([[Interface\Buttons\WHITE8X8]])
	if dx ~= 0 then
		line:SetSize(LINE_LENGTH, LINE_WIDTH)
	else
		line:SetSize(LINE_WIDTH, LINE_LENGTH)
	end
	local offset = GAP + LINE_LENGTH / 2
	line:SetPoint('CENTER', Crosshair, 'CENTER', dx * offset, dy * offset)
	return line
end

Crosshair.Lines = {
	CreateLine( 0,  1),
	CreateLine( 0, -1),
	CreateLine(-1,  0),
	CreateLine( 1,  0),
}

function Crosshair:SetColor()
	local r, g, b = db.Atlas.GetNormalizedCC()
	for _, line in ipairs(self.Lines) do
		line:SetVertexColor(r or 1, g or 1, b or 1, 0.9)
	end
end

function Crosshair:OnUpdate(elapsed)
	local shouldDraw = IsMouselooking() and not UnitOnTaxi('player') and not SpellIsTargeting()
	local alpha = self:GetAlpha() + (shouldDraw and 1 or -1) * elapsed * FADE_SPEED
	self:SetAlpha(max(0, min(1, alpha)))
end

function Crosshair:Refresh()
	if db('crosshairEnable') then
		self:SetColor()
		self:SetAlpha(0)
		self:SetScript('OnUpdate', self.OnUpdate)
		self:Show()
	else
		self:SetScript('OnUpdate', nil)
		self:Hide()
	end
end

ConsolePort:RegisterVarCallback('crosshairEnable', Crosshair.Refresh, Crosshair)

-- Settings are loaded after this file; apply them once the player is in the world
Crosshair:RegisterEvent('PLAYER_ENTERING_WORLD')
Crosshair:SetScript('OnEvent', function(self)
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
	self:Refresh()
end)
