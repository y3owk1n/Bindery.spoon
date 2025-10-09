---@diagnostic disable: undefined-global

---@class Hs.Bindery
local M = {}

M.__index = M

M.name = "bindery"
M.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal modules
local Utils = {}

local log

local specialModifiers = {
	hyper = { "cmd", "alt", "ctrl", "shift" },
	meh = { "alt", "ctrl", "shift" },
}

-- ------------------------------------------------------------------
-- Types
-- ------------------------------------------------------------------

---@class Hs.Bindery.Config
---@field apps? Hs.Bindery.Config.Apps Apps configuration
---@field customBindings? table<string, Hs.Bindery.Config.CustomBindings> Custom bindings configuration
---@field contextualBindings? table<string,  Hs.Bindery.Config.ContextualBindings[]> Contextual bindings configuration
---@field watcher? Hs.Bindery.Config.Watcher Watcher configuration
---@field logLevel? string The log level to use

---@alias Hs.Bindery.Modifier "cmd"|"ctrl"|"alt"|"shift"|"fn"

---@class Hs.Bindery.Config.Apps
---@field modifier Hs.Bindery.Modifier|Hs.Bindery.Modifier[] Modifiers to use for the app launchers
---@field bindings table<string, string> App launchers

---@class Hs.Bindery.Config.CustomBindings
---@field modifier Hs.Bindery.Modifier|Hs.Bindery.Modifier[] Modifiers to use for the custom bindings
---@field key string Key to use for the custom bindings
---@field action function Action to perform for the custom bindings

---@class Hs.Bindery.Config.ContextualBindings
---@field modifier Hs.Bindery.Modifier|Hs.Bindery.Modifier[] Modifiers to use for the contextual bindings
---@field key string Key to use for the contextual bindings
---@field action function Action to perform for the contextual bindings

---@class Hs.Bindery.Config.Watcher
---@field hideAllWindowExceptFront Hs.Bindery.Config.Watcher.HideAllWindowExceptFront Whether to hide all windows except the frontmost one
---@field autoMaximizeWindow Hs.Bindery.Config.Watcher.AutoMaximizeWindow Whether to maximize the window when it is activated

---@class Hs.Bindery.Config.Watcher.Bindings
---@field modifier Hs.Bindery.Modifier|Hs.Bindery.Modifier[] Modifiers to use for the watcher bindings
---@field key string Key to use for the watcher bindings

---@class Hs.Bindery.Config.Watcher.HideAllWindowExceptFront
---@field enabled boolean Whether to hide all windows except the frontmost one
---@field bindings? Hs.Bindery.Config.Watcher.Bindings Bindings to use for the watcher hide all window except front bindings

---@class Hs.Bindery.Config.Watcher.AutoMaximizeWindow
---@field enabled boolean Whether to maximize the window when it is activated
---@field bindings? Hs.Bindery.Config.Watcher.Bindings Bindings to use for the watcher auto maximize window bindings

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

---Helper function to check if something is a "list-like" table
---@param t table
---@return boolean
function Utils.isList(t)
	if type(t) ~= "table" then
		return false
	end
	local count = 0
	for k, _ in pairs(t) do
		count = count + 1
		if type(k) ~= "number" or k <= 0 or k > count then
			return false
		end
	end
	return true
end

---Helper function to deep copy a value
---@param obj table
---@return table
function Utils.deepCopy(obj)
	if type(obj) ~= "table" then
		return obj
	end

	local copy = {}
	for k, v in pairs(obj) do
		copy[k] = Utils.deepCopy(v)
	end
	return copy
end

---Merges two tables with optional array extension
---@param base table Base table
---@param overlay table Table to merge into base
---@param extendArrays boolean If true, arrays are merged; if false, arrays are replaced
---@return table Merged result
function Utils.tblMerge(base, overlay, extendArrays)
	local result = Utils.deepCopy(base)

	for key, value in pairs(overlay) do
		local baseValue = result[key]
		local isOverlayArray = type(value) == "table" and Utils.isList(value)
		local isBaseArray = type(baseValue) == "table"
			and Utils.isList(baseValue)

		if extendArrays and isOverlayArray and isBaseArray then
			-- both are arrays: merge without duplicates
			for _, v in ipairs(value) do
				if not Utils.tblContains(baseValue, v) then
					table.insert(baseValue, v)
				end
			end
		elseif type(value) == "table" and type(baseValue) == "table" then
			-- both are tables (objects or mixed): recurse
			result[key] = Utils.tblMerge(baseValue, value, extendArrays)
		else
			-- plain value or type mismatch: replace
			result[key] = Utils.deepCopy(value)
		end
	end

	return result
end

---Checks if a table contains a value
---@param tbl table
---@param val any
---@return boolean
function Utils.tblContains(tbl, val)
	for _, v in ipairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

---@param mods "cmd"|"ctrl"|"alt"|"shift"|"fn"|("cmd"|"ctrl"|"alt"|"shift"|"fn")[]
---@param key string
---@param delay? number
---@param application? table
---@return nil
function Utils.keyStroke(mods, key, delay, application)
	if type(mods) == "string" then
		mods = { mods }
	end
	hs.eventtap.keyStroke(mods, key, delay or 0, application)
end

---@param items string[]
---@return nil
function Utils.safeSelectMenuItem(items)
	local app = hs.application.frontmostApplication()
	local success = app:selectMenuItem(items)
	if not success then
		hs.alert.show("Menu item not found")
		log.ef("Menu item not found")
	end
end

-- ------------------------------------------------------------------
-- Configuration
-- ------------------------------------------------------------------

---@type Hs.Bindery.Config
local DEFAULT_CONFIG = {
	logLevel = "warning",
	apps = {
		modifier = specialModifiers.hyper,
		bindings = {},
	},
	customBindings = {},
	contextualBindings = {},
	watcher = {
		hideAllWindowExceptFront = {
			enabled = false,
		},
		autoMaximizeWindow = {
			enabled = false,
		},
	},
}

-- ------------------------------------------------------------------
-- App Launchers
-- ------------------------------------------------------------------

local activeLauncherHotkeys = {}

local function setupLaunchers()
	for appName, shortcut in pairs(M.config.apps.bindings) do
		local hotkey = hs.hotkey.bind(
			M.config.apps.modifier,
			shortcut,
			function()
				hs.application.launchOrFocus(appName)
			end
		)
		table.insert(activeLauncherHotkeys, hotkey)
	end
	log.df(
		string.format("Initialized launcher %s hotkeys", #activeLauncherHotkeys)
	)
end

local function clearLaunchers()
	for _, hotkey in ipairs(activeLauncherHotkeys) do
		if hotkey then
			hotkey:delete()
		end
	end
	log.df(string.format("Cleared %s launcher hotkeys", #activeLauncherHotkeys))
	activeLauncherHotkeys = {}
end

-- ------------------------------------------------------------------
-- Custom Bindings
-- ------------------------------------------------------------------

local activeCustomBindings = {}

local function setupCustomBindings()
	for _, customAction in pairs(M.config.customBindings) do
		local hotkey = hs.hotkey.bind(
			customAction.modifier,
			customAction.key,
			customAction.action
		)
		table.insert(activeCustomBindings, hotkey)
	end
	log.df(
		string.format("Initialized custom %s hotkeys", #activeCustomBindings)
	)
end

local function clearCustomBindings()
	for _, customAction in ipairs(activeCustomBindings) do
		if customAction then
			customAction:delete()
		end
	end

	log.df(string.format("Cleared %s custom hotkeys", #activeCustomBindings))
	activeCustomBindings = {}
end

-- ------------------------------------------------------------------
-- Contextual Bindings
-- ------------------------------------------------------------------

-- Store active contextual hotkeys for cleanup
local activeContextualHotkeys = {}

---Function to clear all contextual bindings
---@param appName? string
---@return nil
local function clearContextualBindings(appName)
	if not appName then
		for _, hotkeys in ipairs(activeContextualHotkeys) do
			for _, hotkey in ipairs(hotkeys) do
				if hotkey then
					hotkey:delete()
				end
			end
		end
		log.df(
			string.format(
				"Cleared %s contextual hotkeys",
				#activeContextualHotkeys
			)
		)
		activeContextualHotkeys = {}
	else
		if not activeContextualHotkeys[appName] then
			log.df(
				string.format("No contextual hotkeys defined for: %s", appName)
			)
			return
		end
		for _, hotkey in ipairs(activeContextualHotkeys[appName]) do
			if hotkey then
				hotkey:delete()
			end
		end
		log.df(
			string.format(
				"Cleared %s contextual hotkeys",
				#activeContextualHotkeys[appName]
			)
		)
		activeContextualHotkeys[appName] = {}
	end
end

---Function to activate contextual bindings for a specific app
---@param appName string
---@return nil
local function activateContextualBindings(appName)
	local bindings = M.config.contextualBindings[appName]
	if not bindings then
		log.df(string.format("No contextual bindings defined for: %s", appName))
		return
	end

	for _, binding in ipairs(bindings) do
		local hotkey =
			hs.hotkey.bind(binding.modifier, binding.key, binding.action)
		if not activeContextualHotkeys[appName] then
			activeContextualHotkeys[appName] = {}
		end
		table.insert(activeContextualHotkeys[appName], hotkey)
	end
	log.df(
		string.format(
			"Activated %s contextual hotkeys for: %s",
			#activeContextualHotkeys[appName],
			appName
		)
	)
end

-- ------------------------------------------------------------------
-- Window Watcher
-- ------------------------------------------------------------------

-- Global variable to track watcher
local _hideAllWindowExceptFrontStatus = false
local _autoMaximizeWindowStatus = false

local appWatcher = nil

local activeWatcherHotkeys = {}

local function setupWatcher()
	_hideAllWindowExceptFrontStatus = M.config.watcher.hideAllWindowExceptFront.enabled
		or false

	_autoMaximizeWindowStatus = M.config.watcher.autoMaximizeWindow.enabled
		or false

	if appWatcher then
		appWatcher:stop()
		appWatcher = nil
	end

	appWatcher = hs.application.watcher.new(function(appName, eventType)
		log.df(
			string.format("Watcher event: App=%s, Event=%s", appName, eventType)
		)

		if eventType == hs.application.watcher.activated and appName ~= nil then
			log.df(string.format("App activated: %s", appName))

			activateContextualBindings(appName)

			local activatedApp = hs.application.get(appName)

			if _hideAllWindowExceptFrontStatus then
				-- hide all windows except the frontmost one
				Utils.keyStroke({ "cmd", "alt" }, "h", 0, activatedApp)
				log.df("Hide all windows except the frontmost one")
			end

			if
				_hideAllWindowExceptFrontStatus and _autoMaximizeWindowStatus
			then
				-- maximize window
				Utils.keyStroke({ "fn", "ctrl" }, "f", 0, activatedApp)
				log.df("Maximize window")
			end
		end

		if
			eventType == hs.application.watcher.deactivated
			and appName ~= nil
		then
			log.df(string.format("App deactivated: %s", appName))
			clearContextualBindings(appName)
		end
	end)

	appWatcher:start()

	log.df("App watcher started")

	-- Bind `hideAllWindowExceptFront` toggle
	if M.config.watcher.hideAllWindowExceptFront.enabled then
		local bindings = M.config.watcher.hideAllWindowExceptFront.bindings
		if bindings and type(bindings) == "table" then
			local hotkey = hs.hotkey.bind(
				bindings.modifier,
				bindings.key,
				function()
					_hideAllWindowExceptFrontStatus =
						not _hideAllWindowExceptFrontStatus
					hs.alert.show(
						string.format(
							"hideAllWindowExceptFront: %s",
							_hideAllWindowExceptFrontStatus
						)
					)
					log.df(
						string.format(
							"hideAllWindowExceptFront: %s",
							_hideAllWindowExceptFrontStatus
						)
					)
				end
			)
			table.insert(activeWatcherHotkeys, hotkey)
			log.df(
				string.format(
					"Initialized watcher hideAllWindowExceptFront hotkey"
				)
			)
		else
			log.df("No watcher hideAllWindowExceptFront bindings defined")
		end
	end

	-- Bind `autoMaximizeWindow` toggle
	if M.config.watcher.autoMaximizeWindow.enabled then
		local bindings = M.config.watcher.autoMaximizeWindow.bindings
		if bindings and type(bindings) == "table" then
			local hotkey = hs.hotkey.bind(
				bindings.modifier,
				bindings.key,
				function()
					_autoMaximizeWindowStatus = not _autoMaximizeWindowStatus
					hs.alert.show(
						string.format(
							"autoMaximizeWindow: %s",
							_autoMaximizeWindowStatus
						)
					)
					log.df(
						string.format(
							"autoMaximizeWindow: %s",
							_autoMaximizeWindowStatus
						)
					)
				end
			)
			table.insert(activeWatcherHotkeys, hotkey)
			log.df(
				string.format("Initialized watcher autoMaximizeWindow hotkey")
			)
		else
			log.df("No watcher autoMaximizeWindow bindings defined")
		end
	end
end

local function clearWatcher()
	if appWatcher then
		appWatcher:stop()
		appWatcher = nil
		log.df("Stopped app watcher")
	end

	for _, hotkey in ipairs(activeWatcherHotkeys) do
		if hotkey then
			hotkey:delete()
		end
	end
	log.df(string.format("Cleared %s watcher hotkeys", #activeWatcherHotkeys))
	activeWatcherHotkeys = {}
end

-- ------------------------------------------------------------------
-- API
-- ------------------------------------------------------------------

---@type Hs.Bindery.Config
M.config = {}

-- Private state flag
M._running = false
M._initialized = false

---Initializes the module
---@return Hs.Bindery
function M:init()
	if self._initialized then
		return self
	end

	-- Initialize logger with default level
	log = hs.logger.new(M.name, "info")

	self._initialized = true
	log.i("Initialized")

	return self
end

---@class Hs.Bindery.Config.SetOpts
---@field extend? boolean Whether to extend the config or replace it, true = extend, false = replace

---Configures the module
---@param userConfig Hs.Bindery.Config
---@param opts? Hs.Bindery.Config.SetOpts
---@return Hs.Bindery
function M:configure(userConfig, opts)
	if not self._initialized then
		self:init()
	end

	opts = opts or {}
	local extend = opts.extend
	if extend == nil then
		extend = true
	end

	-- Start with defaults
	if not M.config or not next(M.config) then
		M.config = Utils.deepCopy(DEFAULT_CONFIG)
	end

	-- Merge user config
	if userConfig then
		M.config = Utils.tblMerge(M.config, userConfig, extend)
	end

	-- Reinitialize logger with configured level
	log = hs.logger.new(M.name, M.config.logLevel)

	log.i("Configured")

	return self
end

---Starts the module
---@return Hs.Bindery
function M:start()
	if self._running then
		log.w("Bindery already running")
		return self
	end

	if not M.config or not next(M.config) then
		self:configure({})
	end

	setupLaunchers()
	setupCustomBindings()
	setupWatcher()

	self._running = true
	log.i("Started")

	return self
end

---Stops the module
---@return Hs.Bindery
function M:stop()
	if not self._running then
		return self
	end

	log.i("-- Stopping Bindery...")

	clearLaunchers()
	clearCustomBindings()
	clearContextualBindings()
	clearWatcher()

	self._running = false
	log.i("Bindery stopped")

	return self
end

---Restarts the module
---@return Hs.Bindery
function M:restart()
	log.i("Restarting Bindery...")
	self:stop()
	self:start()
	return self
end

---Returns current running state
---@return boolean
function M:isRunning()
	return self._running
end

---Returns state and config information
---@return table
function M:debug()
	return {
		config = M.config,
		state = {
			activeLauncherHotkeys = activeLauncherHotkeys,
			activeCustomBindings = activeCustomBindings,
			activeContextualHotkeys = activeContextualHotkeys,
			_hideAllWindowExceptFrontStatus = _hideAllWindowExceptFrontStatus,
			_autoMaximizeWindowStatus = _autoMaximizeWindowStatus,
		},
	}
end

---Returns default config
---@return table
function M:getDefaultConfig()
	return Utils.deepCopy(DEFAULT_CONFIG)
end

M.keyStroke = Utils.keyStroke
M.safeSelectMenuItem = Utils.safeSelectMenuItem
M.specialModifiers = specialModifiers

return M
