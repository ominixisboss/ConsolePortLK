local _, db = ...
---------------------------------------------------------------
-- ModernPresets.lua: Binding presets from modern ConsolePort
---------------------------------------------------------------
-- Ported from seblindfors/ConsolePort (Model/Gamepad/PlayStation5.lua
-- and Xbox.lua), Copyright (c) Sebastian Lindfors, Artistic License 2.0.
-- Modified for WotLK 3.3.5a:
--  * Button names translated to ConsolePortLK (PAD1 -> CP_R_DOWN, etc.).
--  * Shift/Ctrl are held on the modifier buttons (L1/L2 or the triggers,
--    set by calibration), so the two remaining shoulder buttons are
--    CP_T1 (modern R1 set) and CP_T2 (modern R2 set). Taps on the
--    modifier buttons themselves can't be bound in 3.3.5a.
--  * TARGETSCANENEMY -> TARGETNEARESTENEMY (not available in 3.3.5a).
--  * ConsolePortQuickMenu -> EXTRAACTIONBUTTON1 (no quick menu here).
--  * CAMERAZOOMIN/OUT -> CP_CAMZOOMIN/OUT (ConsolePortLK's smooth zoom).
--  * Grip buttons (touchpad halves, L3/R3 in AzerothPad HD) keep
--    ConsolePortLK's extra action bar bindings.
---------------------------------------------------------------
db.BindingPresets = db.BindingPresets or {}

local function Grips()
	return {
		['CP_T3'] = {
			['']		 	= 'MULTIACTIONBAR3BUTTON1',
			['SHIFT-'] 		= 'MULTIACTIONBAR3BUTTON2',
			['CTRL-'] 		= 'MULTIACTIONBAR3BUTTON3',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR3BUTTON4',
		},
		['CP_T4'] = {
			['']		 	= 'MULTIACTIONBAR3BUTTON5',
			['SHIFT-'] 		= 'MULTIACTIONBAR3BUTTON6',
			['CTRL-'] 		= 'MULTIACTIONBAR3BUTTON7',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR3BUTTON8',
		},
		['CP_T5'] = {
			['']		 	= 'MULTIACTIONBAR3BUTTON9',
			['SHIFT-'] 		= 'MULTIACTIONBAR3BUTTON10',
			['CTRL-'] 		= 'MULTIACTIONBAR3BUTTON11',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR3BUTTON12',
		},
		['CP_T6'] = {
			['']		 	= 'MULTIACTIONBAR4BUTTON1',
			['SHIFT-'] 		= 'MULTIACTIONBAR4BUTTON2',
			['CTRL-'] 		= 'MULTIACTIONBAR4BUTTON3',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR4BUTTON4',
		},
		['CP_T_R3'] = {},
		['CP_T_L3'] = {},
	}
end

local function DPad()
	return {
		['CP_L_UP'] = {
			[''] 			= 'ACTIONBUTTON10',
			['SHIFT-'] 		= 'MULTIACTIONBAR2BUTTON2',
			['CTRL-'] 		= 'MULTIACTIONBAR2BUTTON6',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR2BUTTON10',
		},
		['CP_L_DOWN'] = {
			[''] 			= 'ACTIONBUTTON12',
			['SHIFT-'] 		= 'MULTIACTIONBAR2BUTTON4',
			['CTRL-'] 		= 'MULTIACTIONBAR2BUTTON8',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR2BUTTON12',
		},
		['CP_L_LEFT'] = {
			[''] 			= 'ACTIONBUTTON9',
			['SHIFT-'] 		= 'MULTIACTIONBAR2BUTTON1',
			['CTRL-'] 		= 'MULTIACTIONBAR2BUTTON5',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR2BUTTON9',
		},
		['CP_L_RIGHT'] = {
			[''] 			= 'ACTIONBUTTON11',
			['SHIFT-'] 		= 'MULTIACTIONBAR2BUTTON3',
			['CTRL-'] 		= 'MULTIACTIONBAR2BUTTON7',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR2BUTTON11',
		},
	}
end

-- Face buttons shared by both layouts; downShift is the bottom face button's Shift binding.
local function Face(downShift)
	return {
		['CP_R_DOWN'] = {
			[''] 			= 'JUMP',
			['SHIFT-'] 		= downShift,
			['CTRL-'] 		= 'EXTRAACTIONBUTTON1',
			['CTRL-SHIFT-'] = 'CLICK ConsolePortUtilityToggle:LeftButton',
		},
		['CP_R_RIGHT'] = {
			[''] 			= 'ACTIONBUTTON5',
			['SHIFT-'] 		= 'ACTIONBUTTON8',
			['CTRL-'] 		= 'MULTIACTIONBAR1BUTTON5',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR1BUTTON8',
		},
		['CP_R_LEFT'] = {
			[''] 			= 'ACTIONBUTTON3',
			['SHIFT-'] 		= 'ACTIONBUTTON6',
			['CTRL-'] 		= 'MULTIACTIONBAR1BUTTON3',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR1BUTTON6',
		},
		['CP_R_UP'] = {
			[''] 			= 'ACTIONBUTTON4',
			['SHIFT-'] 		= 'ACTIONBUTTON7',
			['CTRL-'] 		= 'MULTIACTIONBAR1BUTTON4',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR1BUTTON7',
		},
	}
end

-- Shoulder buttons that are not modifiers (modern R1 / R2 sets)
local function Shoulders(t1Ctrl)
	return {
		['CP_T1'] = {
			[''] 			= 'ACTIONBUTTON1',
			['SHIFT-'] 		= 'TARGETNEARESTENEMY',
			['CTRL-'] 		= t1Ctrl,
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR1BUTTON11',
		},
		['CP_T2'] = {
			[''] 			= 'ACTIONBUTTON2',
			['SHIFT-'] 		= 'MULTIACTIONBAR1BUTTON2',
			['CTRL-'] 		= 'MULTIACTIONBAR1BUTTON10',
			['CTRL-SHIFT-'] = 'MULTIACTIONBAR1BUTTON12',
		},
	}
end

local function Merge(...)
	local result = {}
	for i = 1, select('#', ...) do
		for button, set in pairs(select(i, ...)) do
			result[button] = set
		end
	end
	return result
end

---------------------------------------------------------------
-- PlayStation 5
---------------------------------------------------------------
db.BindingPresets['PS5 (modern ConsolePort)'] = {
	Type = 'PS5',
	Bindings = Merge(Face('MULTIACTIONBAR1BUTTON1'), Shoulders('MULTIACTIONBAR1BUTTON9'), DPad(), Grips(), {
		-- Create (share) button
		['CP_X_LEFT'] = {
			[''] 			= 'OPENALLBAGS',
			['SHIFT-'] 		= 'TOGGLECHARACTER0',
			['CTRL-'] 		= 'TOGGLESPELLBOOK',
			['CTRL-SHIFT-'] = 'TOGGLETALENTS',
		},
		-- PS button
		['CP_X_CENTER'] = {
			[''] 			= 'TOGGLEGAMEMENU',
			['SHIFT-'] 		= 'CLICK ConsolePortRaidCursorToggle:LeftButton',
			['CTRL-'] 		= 'TOGGLEAUTORUN',
			['CTRL-SHIFT-'] = 'OPENCHAT',
		},
		-- Options button
		['CP_X_RIGHT'] = {
			[''] 			= 'TOGGLEWORLDMAP',
			['SHIFT-'] 		= 'CP_CAMZOOMOUT',
			['CTRL-'] 		= 'CP_CAMZOOMIN',
		},
	}),
}

---------------------------------------------------------------
-- Xbox
---------------------------------------------------------------
db.BindingPresets['Xbox (modern ConsolePort)'] = {
	Type = 'XBOX',
	Bindings = Merge(Face('MULTIACTIONBAR1BUTTON9'), Shoulders('MULTIACTIONBAR1BUTTON1'), DPad(), Grips(), {
		-- View button
		['CP_X_LEFT'] = {
			[''] 			= 'OPENALLBAGS',
			['SHIFT-'] 		= 'TOGGLECHARACTER0',
			['CTRL-'] 		= 'TOGGLEWORLDMAP',
			['CTRL-SHIFT-'] = 'TOGGLEAUTORUN',
		},
		-- Menu button
		['CP_X_RIGHT'] = {
			[''] 			= 'TOGGLEGAMEMENU',
			['SHIFT-'] 		= 'CLICK ConsolePortRaidCursorToggle:LeftButton',
			['CTRL-'] 		= 'CP_CAMZOOMOUT',
			['CTRL-SHIFT-'] = 'CP_CAMZOOMIN',
		},
		-- Xbox button: modern ConsolePort leaves it unbound, keep ConsolePortLK's
		['CP_X_CENTER'] = {
			['']		 	= 'TOGGLECHARACTER0',
			['SHIFT-'] 		= 'TOGGLESPELLBOOK',
			['CTRL-'] 		= 'TOGGLETALENTS',
		},
	}),
}
