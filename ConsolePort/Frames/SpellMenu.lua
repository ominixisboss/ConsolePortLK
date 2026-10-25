---------------------------------------------------------------
-- SpellMenu.lua: Popup menu for spells in the spellbook
---------------------------------------------------------------
-- Selecting a spell with the interface cursor opens a small menu:
-- pick it up (to place on an action bar) or add it to a ring.
-- Inspired by modern ConsolePort's spell menu
-- (seblindfors/ConsolePort, Artistic License 2.0).
-- Setting: UIdisableSpellMenu (picks the spell up directly).

local _, db = ...
local CPAPI = db.CPAPI
---------------------------------------------------------------
local Menu = CreateFrame('Frame', 'ConsolePortSpellMenu', UIParent, 'UIDropDownMenuTemplate')

local function GetSpellIDFromBook(slot, bookType)
	local link = GetSpellLink(slot, bookType)
	local spellID = link and link:match('spell:(%d+)')
	return spellID
end

function ConsolePort:ShowSpellMenu(slot, bookType, anchor)
	local name, rank = GetSpellName(slot, bookType)
	if not name then return end
	local texture = GetSpellTexture(slot, bookType)
	local spellID = GetSpellIDFromBook(slot, bookType)

	local menu = {
		{ text = name .. ((rank and rank ~= '') and (' |cff999999(' .. rank .. ')|r') or ''),
		  icon = texture, isTitle = true, notCheckable = true },
		{ text = db.TUTORIAL.RING and db.TUTORIAL.RING.PICKUP_SPELL or 'Pick up (place on action bar)',
		  notCheckable = true,
		  func = function() PickupSpell(slot, bookType) end },
	}

	-- One entry per ring
	if spellID and bookType ~= BOOKTYPE_PET then
		for id, ring in ipairs(ConsolePortUtility or {}) do
			menu[#menu + 1] = {
				text = ('Add to %s'):format(ring.Name or ('Ring ' .. id)),
				icon = ring.Icon,
				notCheckable = true,
				func = function() ConsolePort:AddUtilityAction('spell', spellID, id) end,
			}
		end
	end

	menu[#menu + 1] = { text = CANCEL, notCheckable = true, func = function() CloseDropDownMenus() end }

	EasyMenu(menu, Menu, anchor or 'cursor', 0, 0, 'MENU')
end
