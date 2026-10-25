---------------------------------------------------------------
-- ControllerTest.lua: Shows which controller button was pressed
---------------------------------------------------------------
-- Type /cptest. Every button you press shows its ConsolePort
-- icon, its name and the key it arrived as, so you can check
-- your mapping (AzerothPad HD, calibration, modifiers).
-- Escape closes the window. Inspired by modern ConsolePort's
-- controller test (seblindfors/ConsolePort, Artistic License 2.0).

local _, db = ...
local CPAPI = db.CPAPI
---------------------------------------------------------------
local MAX_LINES = 8

local Test = CreateFrame('Frame', 'ConsolePortControllerTest', UIParent)
Test:SetSize(380, 300)
Test:SetPoint('CENTER')
Test:SetFrameStrata('DIALOG')
Test:SetBackdrop({
	bgFile   = [[Interface\DialogFrame\UI-DialogBox-Background]],
	edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
	tile = true, tileSize = 32, edgeSize = 32,
	insets = {left = 11, right = 12, top = 12, bottom = 11},
})
Test:EnableKeyboard(true)
Test:EnableMouse(true)
Test:Hide()
tinsert(UISpecialFrames, Test:GetName())

Test.Title = Test:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
Test.Title:SetPoint('TOP', 0, -20)
Test.Title:SetText('Controller Test')

Test.Help = Test:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
Test.Help:SetPoint('TOP', Test.Title, 'BOTTOM', 0, -6)
Test.Help:SetText('Press buttons on your controller. Escape to close.')

Test.Lines = {}
for i = 1, MAX_LINES do
	local line = CreateFrame('Frame', nil, Test)
	line:SetSize(340, 26)
	line:SetPoint('TOP', 0, -50 - (i - 1) * 28)
	line.Icon = line:CreateTexture(nil, 'ARTWORK')
	line.Icon:SetSize(24, 24)
	line.Icon:SetPoint('LEFT')
	line.Text = line:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	line.Text:SetPoint('LEFT', line.Icon, 'RIGHT', 8, 0)
	line.Text:SetJustifyH('LEFT')
	line:SetAlpha(1 - (i - 1) / MAX_LINES)
	Test.Lines[i] = line
end

local history = {}

local function GetModifierPrefix()
	return (IsAltKeyDown() and 'ALT-' or '') .. (IsControlKeyDown() and 'CTRL-' or '') .. (IsShiftKeyDown() and 'SHIFT-' or '')
end

local function Describe(key)
	local modifier = GetModifierPrefix()
	local action = GetBindingAction(modifier .. key) 
	if (not action or action == '') and modifier ~= '' then
		action = GetBindingAction(key)
	end
	-- Modifier buttons arrive as the modifier keys themselves
	if key:match('SHIFT$') then return db.TEXTURE and db.TEXTURE.CP_M1, 'Modifier: Shift', key end
	if key:match('CTRL$')  then return db.TEXTURE and db.TEXTURE.CP_M2, 'Modifier: Ctrl', key end

	local button = action and action:match('^(CP_[%u%d_]+)')
	if button then
		local icon = db.TEXTURE and db.TEXTURE[button]
		local name = _G['BINDING_NAME_' .. button] or button
		if name:find('|T') then name = button end -- some names are icon strings
		return icon, (modifier ~= '' and (modifier .. name) or name), key
	end
	return nil, (action and action ~= '') and action or 'Not bound to a ConsolePort button', key
end

function Test:Push(icon, text, key)
	tinsert(history, 1, {icon = icon, text = text, key = key})
	history[MAX_LINES + 1] = nil
	for i, line in ipairs(self.Lines) do
		local entry = history[i]
		if entry then
			line.Icon:SetTexture(entry.icon or [[Interface\Icons\INV_Misc_QuestionMark]])
			line.Text:SetText(('%s |cff888888(%s)|r'):format(entry.text, entry.key))
			line:Show()
		else
			line:Hide()
		end
	end
end

Test:SetScript('OnKeyDown', function(self, key)
	if key == 'ESCAPE' then
		self:Hide()
		return
	end
	self:Push(Describe(key))
end)

-- L3 / R3 arrive as mouse clicks
Test:SetScript('OnMouseDown', function(self, button)
	local map = { LeftButton = 'CP_T_L3', RightButton = 'CP_T_R3' }
	local cp = map[button]
	self:Push(cp and db.TEXTURE and db.TEXTURE[cp], cp and (cp == 'CP_T_L3' and 'Left stick click (L3)' or 'Right stick click (R3)') or button, button)
end)

Test:SetScript('OnShow', function(self)
	wipe(history)
	for _, line in ipairs(self.Lines) do line:Hide() end
end)

SLASH_CONSOLEPORTTEST1 = '/cptest'
SlashCmdList['CONSOLEPORTTEST'] = function()
	if InCombatLockdown() then return end
	if Test:IsShown() then Test:Hide() else Test:Show() end
end
