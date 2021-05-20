local MAJOR, MINOR = "LibCombatLogging-1.0", 1
assert(LibStub, MAJOR .. " requires LibStub")

---@class LibCombatLogging @The core library table accessible by the library users to start, stop or get logging states. Add `---@type LibCombatLogging` where you import it to enable annotations.

---@class LibCombatLogging_AddOn @The addon handle can be anything unique to your addon or call path, most common cases are unique addon name, or your unique addon table, used for tracking purposes.

---@type LibCombatLogging
local Lib, PrevMinor = LibStub:NewLibrary(MAJOR, MINOR)
if not Lib then return end

Lib._Logging = Lib._Logging or {} --- Internal `table` tracking active combat logging handles.
Lib._OrigLoggingCombat = Lib._OrigLoggingCombat or _G.LoggingCombat --- Reference to the original global API to start, stop and get combat log state.

local Logging = Lib._Logging
local OrigLoggingCombat = Lib._OrigLoggingCombat

--- Checks if the addon handle has logging enabled.
---@return boolean isLogging @`true` if the addon handle is logging.
---@param addon LibCombatLogging_AddOn
local function IsLogging(addon)
	return Logging[addon]
end

--- Counts how many addon handles have logging enabled.
---@return number numLoggers @Number of logging handles.
local function GetNumLogging()
	local c = 0
	for k, v in pairs(Logging) do
		c = c + 1
	end
	return c
end

--- Returns a string of all the addon handles that are logging combat.
---@param excludeAddon LibCombatLogging_AddOn @Optional exception to exclude from the table, this would most likely be your own handle.
---@return string|nil @Example return could be `X`, or `X, Y and 2 undefined` or `nil` if nothing is currently logging combat.
local function GetLoggingAddOns(excludeAddon)
	local temp = {}
	local i = 0
	local undef = 0
	for k, _ in pairs(Logging) do
		if excludeAddon == nil or excludeAddon ~= k then
			if k == true then
				i = i + 1
				temp[i] = "/combatlog"
			elseif type(k) == "string" then
				i = i + 1
				temp[i] = k
			else
				undef = undef + 1
			end
		end
	end
	if i > 1 then
		table.sort(temp, function (a, b) return a > b end)
	end
	if undef > 0 then
		i = i + 1
		temp[i] = format("+%d undefined", undef)
	end
	if i > 0 then
		return table.concat(temp, ", ")
	end
end

--- Starts logging combat for the provided addon handle.
---@param addon LibCombatLogging_AddOn
local function StartLogging(addon)
	Logging[addon] = true
	if not OrigLoggingCombat() then
		OrigLoggingCombat(true)
	end
end

--- Stops logging combat for the provided addon handle.
---@param addon LibCombatLogging_AddOn
local function StopLogging(addon)
	Logging[addon] = nil
	if not next(Logging) and OrigLoggingCombat() then
		OrigLoggingCombat(false)
	end
end

--- Similar to the original API for LoggingCombat, but you must provide an addon handle, then you can provide a new state, or omit and return the status for the addon handle.
--- ```
--- local addonName = ...
--- local LibCombatLogging = LibStub("LibCombatLogging-1.0")
--- local LoggingCombat = function(...) return LibCombatLogging.LoggingCombat(addonName, ...) end
--- ```
---@param addon LibCombatLogging_AddOn
---@param newstate boolean|nil @`true` to enable logging, `false` to disable, and `nil` to not change the state and only return logging state for the addon handle.
---@return boolean isLogging @`true` if the addon handle is logging.
---@return number numLoggers @Number of logging handles.
local function LoggingCombat(addon, newstate)
	if addon == nil then
		addon = true
	end
	if newstate then
		StartLogging(addon)
	elseif newstate ~= nil then
		StopLogging(addon)
	end
	return IsLogging(addon), GetNumLogging()
end

--- A crude implementation, it's not recommended that you use this, instead please look at the `LoggingCombat` function with a more proper example how to implement this library in your addon. I'm adding this for completeness but please do not use this code:
--- ```
--- local LibCombatLogging = LibStub("LibCombatLogging-1.0")
--- local LoggingCombat = LibCombatLogging.WrapLoggingCombat
--- ```
local function WrapLoggingCombat(...)
	local addon
	local stack = debugstack(3)
	if stack then
		stack = {strsplit("[\r\n]", stack)}
		for i = #stack, 1, -1 do
			local text = stack[i]
			addon = text:match("[\\/]-[Aa][Dd][Dd][Oo][Nn][Ss][\\/]-([^\\/]+)[\\/]-")
			if addon then
				break
			end
		end
	end
	return LoggingCombat(addon, ...)
end

--- Wrap the /combatlog command with our library
function SlashCmdList.COMBATLOG(msg)
	local info = ChatTypeInfo.SYSTEM
	local addon = true
	if LoggingCombat(addon) then
		LoggingCombat(addon, false)
		DEFAULT_CHAT_FRAME:AddMessage(COMBATLOGDISABLED, info.r, info.g, info.b, info.id)
	else
		LoggingCombat(addon, true)
		DEFAULT_CHAT_FRAME:AddMessage(COMBATLOGENABLED, info.r, info.g, info.b, info.id)
	end
end

-- Public API
Lib.IsLogging = IsLogging
Lib.GetNumLogging = GetNumLogging
Lib.GetLoggingAddOns = GetLoggingAddOns
Lib.StartLogging = StartLogging
Lib.StopLogging = StopLogging
Lib.LoggingCombat = LoggingCombat
Lib.WrapLoggingCombat = WrapLoggingCombat

--[[ DEBUG:
_G.LoggingCombat = WrapLoggingCombat -- dangerous, it forces all the global API calls outside the library to go through the library forcefully for everyone
--]]
