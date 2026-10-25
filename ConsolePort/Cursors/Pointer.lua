---------------------------------------------------------------
-- Cursors\Pointer.lua: Rotating pointer arrow for the interface cursor.
---------------------------------------------------------------
-- The arrow turns toward the direction the cursor is travelling,
-- then eases back to the normal up-left pointer angle once it
-- arrives. Backport of the cursor arrow from modern ConsolePort
-- (seblindfors/ConsolePort, Artistic License 2.0).
-- Setting: UIpointerAnimation (off = classic static pointer).

local _, db = ...
local CPAPI = db.CPAPI
---------------------------------------------------------------
local Cursor = ConsolePortCursor
local atan2, pi, rad, min, abs = math.atan2, math.pi, math.rad, math.min, math.abs
---------------------------------------------------------------
local REST_ANGLE  = rad(45)  -- up-left, like a regular mouse pointer
local TURN_SPEED  = 14       -- how fast the arrow turns toward its target
local HOLD_TIME   = 0.25     -- seconds to keep pointing along the travel direction
local ARROW_SIZE  = 32
local ARROW_SHIFT = 10       -- moves the arrow so its tip sits near the selected element
local TWO_PI = 2 * pi

local Pointer = CreateFrame('Frame', nil, Cursor)
Pointer:Hide()

local Arrow = Cursor:CreateTexture(nil, 'OVERLAY', nil, 7)
Arrow:SetTexture([[Interface\WorldMap\WorldMapArrow]])
Arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
Arrow:SetPoint('CENTER', Cursor, 'TOPLEFT', ARROW_SHIFT, -ARROW_SHIFT)
Arrow:Hide()

Pointer.current = REST_ANGLE
Pointer.target  = REST_ANGLE
Pointer.hold    = 0
Arrow:SetRotation(REST_ANGLE)

---------------------------------------------------------------
-- Rotation
---------------------------------------------------------------
local function ShortestDelta(from, to)
	return ((to - from + pi) % TWO_PI) - pi
end

function Pointer:OnUpdate(elapsed)
	if self.hold > 0 then
		self.hold = self.hold - elapsed
		if self.hold <= 0 then
			self.target = REST_ANGLE
		end
	end

	local delta = ShortestDelta(self.current, self.target)
	if abs(delta) < 0.001 then
		self.current = self.target
		Arrow:SetRotation(self.current)
		if self.hold <= 0 then
			self:Hide() -- settled at rest, stop updating
		end
		return
	end

	self.current = (self.current + delta * min(1, elapsed * TURN_SPEED)) % TWO_PI
	Arrow:SetRotation(self.current)
end

Pointer:SetScript('OnUpdate', Pointer.OnUpdate)

-- Point along the line from (x1, y1) to (x2, y2), in screen pixels
function Pointer:Travel(x1, y1, x2, y2)
	local dx, dy = x2 - x1, y2 - y1
	if (dx * dx + dy * dy) < 4 then return end
	-- The map arrow points up at rotation 0
	self.target = (atan2(dy, dx) - pi / 2) % TWO_PI
	self.hold = HOLD_TIME
	self:Show()
end

---------------------------------------------------------------
-- Enable / disable
---------------------------------------------------------------
function Pointer:SetEnabled(enabled)
	self.enabled = enabled
	CPAPI.SetShown(Arrow, enabled)
	if Cursor.Tip then CPAPI.SetShown(Cursor.Tip, not enabled) end
	if not enabled then
		self:Hide()
		self.current, self.target = REST_ANGLE, REST_ANGLE
		Arrow:SetRotation(REST_ANGLE)
	end
end

---------------------------------------------------------------
-- Hook cursor movement
---------------------------------------------------------------
local function Refresh()
	Pointer:SetEnabled(db('UIpointerAnimation') and true or false)
end

local Move = Cursor.Move
function Cursor:Move(...)
	-- Settings aren't guaranteed to be loaded when this file runs
	if Pointer.enabled == nil then Refresh() end

	local oldX, oldY = self:GetCenter()
	local oldScale = self:GetEffectiveScale()
	Move(self, ...)

	if not Pointer.enabled or not oldX then return end
	local pointer = self.Pointer
	local newX, newY = pointer and pointer:GetCenter()
	if newX then
		local newScale = pointer:GetEffectiveScale()
		Pointer:Travel(oldX * oldScale, oldY * oldScale, newX * newScale, newY * newScale)
	end
end

ConsolePort:RegisterVarCallback('UIpointerAnimation', Refresh)
