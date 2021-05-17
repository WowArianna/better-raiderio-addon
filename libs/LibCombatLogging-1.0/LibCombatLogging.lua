local MAJOR, MINOR = "LibCombatLogging-1.0", 1
assert(LibStub, MAJOR .. " requires LibStub")

---@class LibCombatLogging @The Public API this Library exports that you can use for autocompletion.
---@class LibCombatLogging_AddOn @`nil`, `true`, or `string` that is the addon name or unique handle. Both `nil` and `true` return the shared logging state where any code call that enabled logging, that could not be tracked to a specific addon, is also lumped in together.

---@type LibCombatLogging
local Lib = LibStub:NewLibrary(MAJOR, MINOR)
if not Lib then return end

local Logging = {} --- Internal `table` tracking combat logging handles.
local LoggingShared = setmetatable({}, { __metadata = false }) --- Shared `table` populated on-demand with handles that are keeping combat logging enabled.
local OrigLoggingCombat = rawget(_G, "LoggingCombat") --- Reference to the original global API to start, stop and get combat log state.

---@return number `arg1` is the amount of handles that are logging combat
local function CountLoggers()
	local c = 0
	for k, v in pairs(Logging) do
		c = c + 1
	end
	return c
end

---@param addon LibCombatLogging_AddOn
---@return boolean, number @`arg1` is the combat logging state for `addon`, and `arg2` returns the amount of addon handles logging combat.
local function StartLogging(addon)
	Logging[addon] = true
	local count = CountLoggers()
	if not OrigLoggingCombat() then
		return OrigLoggingCombat(true), count
	end
	return true, count
end

---@param addon LibCombatLogging_AddOn
---@return boolean, number @`arg1` is the combat logging state for `addon`, and `arg2` returns the amount of addon handles logging combat.
local function StopLogging(addon)
	Logging[addon] = nil
	local count = CountLoggers()
	if not next(Logging) and OrigLoggingCombat() then
		return OrigLoggingCombat(false), count
	end
	return false, count
end

---@param addon LibCombatLogging_AddOn
---@return boolean, number @`arg1` is the combat logging state for `addon`, and `arg2` returns the amount of addon handles logging combat.
local function GetLogging(addon)
	return Logging[addon], CountLoggers()
end

---@param addon LibCombatLogging_AddOn
---@param newstate nil|boolean @If `nil` it returns the current state for `addon`, otherwise it starts or stops combat logging.
---@return boolean, number @`arg1` is the combat logging state for `addon`, and `arg2` returns the amount of addon handles logging combat.
local function AddOnLoggingCombat(addon, newstate, ...)
	addon = addon or true
	if newstate then
		return StartLogging(addon, ...)
	elseif newstate ~= nil then
		return StopLogging(addon, ...)
	end
	return GetLogging(addon, ...)
end

---@param addon LibCombatLogging_AddOn
---@return boolean, number @`arg1` is the combat logging state for `addon`, but if `addon` was `nil` you will get a `table` containing all handles that are keeping the combat logged.
local function IsLoggingCombat(addon)
	if addon ~= nil then
		return Logging[addon]
	end
	if not next(Logging) then
		return
	end
	wipe(LoggingShared)
	for k, v in pairs(Logging) do
		LoggingShared[k] = v
	end
	return LoggingShared
end

---Wrapper for the native global API `LoggingCombat`. The `varargs` for this function are identical to the native `LoggingCombat` function. This function augments and tries to extract the calling code to use as handle so each call can have its separate handle, so combat logging is only disabled when all handles have said they don't need combat logging for themselves.
---@return boolean, number @`arg1` is the combat logging state for `addon`, and `arg2` returns the amount of addon handles logging combat.
local function LoggingCombat(...)
	local stack = debugstack(3)
	if stack then
		stack = {strsplit("[\r\n]", stack)}
		for i = #stack, 1, -1 do
			local text = stack[i]
			local addon = text:match("[\\/]-[Aa][Dd][Dd][Oo][Nn][Ss][\\/]-([^\\/]+)[\\/]-")
			if addon then
				return AddOnLoggingCombat(addon, ...)
			end
		end
	end
	return AddOnLoggingCombat(nil, ...)
end

-- Private API
---@type LibCombatLogging
local Private = {
	LoggingCombat = LoggingCombat,
	IsLoggingCombat = IsLoggingCombat,
	AddOnLoggingCombat = AddOnLoggingCombat,
}

-- Public API
---@type LibCombatLogging
setmetatable(Lib, {
	__metatable = false,
	__newindex = function()
	end,
	__index = function(self, key)
		return Private[key]
	end,
	__call = function(self, key, ...)
		local func = Private[key]
		if not func then
			return
		end
		return func(...)
	end,
})

--[[ EXAMPLE:
local LibCombatLogging = LibStub and LibStub("LibCombatLogging-1.0", true)
local LoggingCombat = LibCombatLogging and LibCombatLogging.LoggingCombat or _G.LoggingCombat
--]]

--[[ DEBUG:
rawset(_G, "LoggingCombat", LoggingCombat) -- forces everyone that calls the global API to go via our wrapper
-- /run local L=LibStub("LibCombatLogging-1.0")print(L.IsLoggingCombat(),L.AddOnLoggingCombat())
--]]
