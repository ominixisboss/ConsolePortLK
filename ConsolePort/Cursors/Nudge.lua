---------------------------------------------------------------
-- Cursors\Nudge.lua: Free movement for the interface cursor.
---------------------------------------------------------------
-- Hold CTRL (your CTRL modifier button) and use the D-pad to
-- slide the interface cursor freely across the screen. When
-- CTRL is released, the cursor snaps to the closest element.
-- Backport of the Nudge controller from modern ConsolePort.
-- Disabled by default (setting: UIenableNudge).

local _, db = ...
---------------------------------------------------------------
local ConsolePort, Cursor = ConsolePort, ConsolePortCursor
local Node = ConsolePortUI:GetNodeDriver()
local InCombat, IsControlKeyDown, sqrt = InCombatLockdown, IsControlKeyDown, math.sqrt
---------------------------------------------------------------
local MODIFIER = 'CTRL-'
local SPEED = 0.6       -- fraction of screen height per second at full speed
local ACCEL_TIME = 0.35 -- seconds to reach full speed

local Nudge = CreateFrame('Frame', 'ConsolePortCursorNudge')
Nudge.input = {}
Nudge.Buttons = {}

-- Direction vectors for each D-pad binding
local Directions = {
	CP_L_UP    = { 0,  1},
	CP_L_DOWN  = { 0, -1},
	CP_L_LEFT  = {-1,  0},
	CP_L_RIGHT = { 1,  0},
}

---------------------------------------------------------------
-- Input buttons (fired by override bindings while the cursor is active)
---------------------------------------------------------------
for binding, vector in pairs(Directions) do
	local button = CreateFrame('Button', 'ConsolePortCursorNudge'..binding, Nudge)
	button:SetScript('OnMouseDown', function() Nudge:SetInput(binding, vector) end)
	button:SetScript('OnMouseUp', function() Nudge:SetInput(binding, nil) end)
	Nudge.Buttons[binding] = button
end

function Nudge:SetInput(binding, vector)
	if InCombat() or not Cursor:IsVisible() then
		return self:Reset()
	end
	self.input[binding] = vector
	if vector and not self.active then
		self:Begin()
	end
end

function Nudge:GetDirection()
	local x, y = 0, 0
	for _, vector in pairs(self.input) do
		x, y = x + vector[1], y + vector[2]
	end
	if x ~= 0 and y ~= 0 then
		local len = sqrt(x * x + y * y)
		x, y = x / len, y / len
	end
	return x, y
end

---------------------------------------------------------------
-- Movement
---------------------------------------------------------------
function Nudge:Begin()
	local scale = Cursor:GetEffectiveScale()
	local left, top = Cursor:GetLeft(), Cursor:GetTop()
	if not left or not top then return end

	self.active = true
	self.held = 0
	-- Track the pointer tip in screen pixels so scale changes can't skew it
	self.x, self.y = left * scale, top * scale

	if Cursor.MoveAndScale:IsPlaying() then
		Cursor.MoveAndScale:Stop()
	end
	Cursor:ClearHighlight()
	self:SetScript('OnUpdate', self.OnUpdate)
end

function Nudge:OnUpdate(elapsed)
	if InCombat() or not Cursor:IsVisible() then
		return self:Reset()
	end
	-- Modifier released: snap to the closest element
	if not IsControlKeyDown() then
		return self:Snap()
	end

	local dx, dy = self:GetDirection()
	if dx == 0 and dy == 0 then
		self.held = 0
		return
	end

	self.held = self.held + elapsed
	local ramp = self.held < ACCEL_TIME and (0.25 + 0.75 * self.held / ACCEL_TIME) or 1
	local screenW = UIParent:GetWidth() * UIParent:GetEffectiveScale()
	local screenH = UIParent:GetHeight() * UIParent:GetEffectiveScale()
	local step = screenH * SPEED * ramp * elapsed

	self.x = math.max(0, math.min(screenW, self.x + dx * step))
	self.y = math.max(0, math.min(screenH, self.y + dy * step))

	local scale = Cursor:GetEffectiveScale()
	Cursor:ClearAllPoints()
	Cursor:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', self.x / scale, self.y / scale)
end

function Nudge:Snap()
	local x, y = self.x, self.y
	self:Reset()
	if not x or InCombat() then return end

	Node:ClearCache()
	Node:RunScan(ConsolePort:GetVisibleCursorFrames())

	local best, bestDist
	for _, item in Node:IterateCache() do
		local node = item.node
		local cx, cy = node:GetCenter()
		if cx and cy then
			local s = node:GetEffectiveScale()
			local dist = Node:GetDistanceSum(x, y, cx * s, cy * s)
			if not bestDist or dist < bestDist then
				best, bestDist = node, dist
			end
		end
	end

	if best then
		ConsolePort:SetCurrentNode(best)
	else
		ConsolePort:UIControl()
	end
end

function Nudge:Reset()
	wipe(self.input)
	self.active = nil
	self.x, self.y = nil, nil
	self:SetScript('OnUpdate', nil)
end

---------------------------------------------------------------
-- Bindings: added on top of the cursor's own D-pad overrides,
-- owned by ConsolePort so they are cleared together with them.
---------------------------------------------------------------
function Nudge:Bind(owner)
	for binding, button in pairs(self.Buttons) do
		for i = 1, select('#', GetBindingKey(binding)) do
			local key = select(i, GetBindingKey(binding))
			SetOverrideBindingClick(owner, true, MODIFIER..key, button:GetName(), 'LeftButton')
		end
	end
end

local UIOverrideButtons = ConsolePort.UIOverrideButtons
function ConsolePort:UIOverrideButtons(enabled)
	local result = UIOverrideButtons(self, enabled)
	if enabled and db('UIenableNudge') and not InCombat() then
		Nudge:Bind(self)
	elseif not enabled then
		Nudge:Reset()
	end
	return result
end
