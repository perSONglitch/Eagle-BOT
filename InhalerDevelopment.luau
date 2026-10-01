--[[
	Inhaler — Night5449791 Vape V4 native build of EagleScript.luau's Vape layer.

	EagleScript.luau drives Vape through three things stock Vape V4 never provides:
		1. shared.VapeBotCommand   - function(raw) that parses ".name args" commands
		2. getgenv().vapeEvents    - bus exposing PlayerKill.Event (used by ".sb on")
		3. F6 into Vape's ChatCommand TextBox - JARVIS types text and presses Return

	Inhaler implements all three against the real Vape API (shared.vape,
	vape.Categories.<Cat>.Modules.<Name>, Module:Toggle(), Module.Options.<Name>,
	vape.Libraries.entity, vape:CreateNotification, vape:Clean) instead of UI typing.
	It is a bridge, not a rewrite: EagleScript works unmodified, with no F6 and no
	patched Vape build.

	Load order
		shared.VapeDeveloper = true   -- optional, dev only
		-- (a) Vape, or let Inhaler auto-load it (see Inhaler.AutoLoad)
		loadstring(game:HttpGet('https://raw.githubusercontent.com/Night5449791/VapeV4ForRoblox/main/NewMainScript.lua', true))()
		-- (b) this file
		-- (c) EagleScript.luau (optional)

	(b) and (c) are interchangeable: otherCmd() re-reads
	getgenv().JARVIS_VAPE_COMMAND_BOX on every call while its capture is dead, so
	executing this file after EagleScript still wires it up (as long as F6 was never
	pressed — F6 overwrites the capture with Vape's real TextBox).

	Installed globals
		getgenv().Inhaler / shared.Inhaler   - the API below
		shared.VapeBotCommand                - command parser (EagleScript's fallthrough)
		getgenv().vapeEvents                 - { PlayerKill = {Event, Fire} }
		getgenv().JARVIS_VAPE_COMMAND_BOX    - always-alive command sink (no F6 required)

	API
		Inhaler:Command('.esp on')            -> accepted, message
		Inhaler:Send('kill bob')              -> same, through the command box
		Inhaler:Set('Noclip', true)           -> enable/disable any module by name
		Inhaler:Option('KillAura', 'Mode', 'Single')
		Inhaler:Targets('KillAura', {'bob'})  -> write a module's Targets/TextList
		Inhaler:Kill('bob')                   -> KillAura-style module, targeted
		Inhaler:Whitelist('bob', true)        -> mirror into Vape's Friends list
		Inhaler:WhitelistAll()
		Inhaler:Save()                        -> vape:Save()
		Inhaler:Modules()                     -> dump every registered module name
]]

local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(obj) return obj end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function() return false end
local loadstr = loadstring :: any
local shared = shared or getgenv()
-- Executor-only, so read them off the global env instead of naming them.
local setidentity = rawget(getgenv(), 'setthreadidentity')
local getidentity = rawget(getgenv(), 'getthreadidentity')

local Players = cloneref(game:GetService('Players'))
local lplr = Players.LocalPlayer

local Inhaler = {
	Version = '1.0',
	AutoLoad = true,      -- load Vape ourselves when shared.vape is missing
	AutoWhitelist = true, -- mirror every joined player into Vape's Friends list
	KillRadius = 16,      -- studs used to attribute a death to a killer
	KillWindow = 8,       -- seconds a recorded attacker stays valid
	KillTimeout = 0,      -- >0 auto-disables the kill module after N seconds
	TrackDeaths = true,   -- feed vapeEvents.PlayerKill from Humanoid deaths
	Debug = false,
	-- filled in by start(): the command box, the vape module, the kill signal
	Box = nil :: any,
	Module = nil :: any,
	KillEvent = nil :: any,
	VapeURL = 'https://raw.githubusercontent.com/Night5449791/VapeV4ForRoblox/main/NewMainScript.lua'
}

-- Command aliases inherited from EagleScript.luau (lines 961-967 / 2512-2518).
Inhaler.Aliases = {
	diedtp = 'diedtp', deathtp = 'diedtp', dtp = 'diedtp',
	autore = 'autoreload', ar = 'autoreload', reloadauto = 'autoreload',
	notaze = 'antitaze', notaser = 'antitaze', antitazer = 'antitaze', at = 'antitaze',
	af = 'antifling', nofling = 'antifling',
	sa = 'silentaim', rb = 'ragebot', ta = 'toolaura', esp = 'esp',
	ka = 'killaura', aura = 'killaura', kill = 'killaura',
	vanish = 'invisibility', invis = 'invisibility',
	clip = 'noclip', tp = 'teleport', tpplayer = 'teleport'
}

-- Modules Inhaler:Kill() will try, in order, before giving up.
Inhaler.KillModules = {'KillAura', 'Aura', 'Kill', 'Killaura'}

local vape = nil
local maid = {}
local moduleIndex = {}
local cleanup = nil -- assigned at the bottom; referenced by Inhaler:Destroy()

local function clean(item)
	if not item then return end
	table.insert(maid, item)
	if vape and vape.Clean then
		pcall(function() vape:Clean(item) end)
	end
end

local function notif(text, duration, kind)
	if not vape or not vape.CreateNotification then return end
	pcall(function()
		vape:CreateNotification('Inhaler', text, duration or 5, kind or 'info')
	end)
end

local function log(text)
	if Inhaler.Debug then
		print('[Inhaler] '..tostring(text))
	end
end

local function findVape()
	return (shared and shared.vape) or rawget(getgenv(), 'vape')
end

-- vape.Loaded: false -> truthy after Load -> nil on Uninject.
local function waitForVape(timeout)
	local deadline = os.clock() + (timeout or 30)
	while os.clock() < deadline do
		local v = findVape()
		if v then
			if v.Loaded == nil then return nil end
			if v.Loaded ~= false then return v end
		end
		task.wait(0.25)
	end
	return nil
end

--[[ ---------------------------- module lookup ---------------------------- ]]

local function rebuildIndex()
	table.clear(moduleIndex)
	if not vape then return end

	if type(vape.Modules) == 'table' then
		for name, mod in pairs(vape.Modules) do
			if type(mod) == 'table' then
				moduleIndex[tostring(name):lower()] = mod
			end
		end
	end

	if type(vape.Categories) == 'table' then
		for _, category in pairs(vape.Categories) do
			if type(category) == 'table' and type(category.Modules) == 'table' then
				for name, mod in pairs(category.Modules) do
					if type(mod) == 'table' then
						local key = tostring(name):lower()
						if not moduleIndex[key] then
							moduleIndex[key] = mod
						end
					end
				end
			end
		end
	end
end

local function findModule(name)
	name = tostring(name or ''):lower()
	if name == '' then return nil end

	local mod = moduleIndex[name]
	if mod then return mod end

	rebuildIndex()
	mod = moduleIndex[name]
	if mod then return mod end

	local partial
	for key, candidate in pairs(moduleIndex) do
		if key:sub(1, #name) == name then
			return candidate
		elseif not partial and key:find(name, 1, true) then
			partial = candidate
		end
	end
	return partial
end

local function isKillModule(mod)
	if not mod then return false end
	local name = tostring(mod.Name or ''):lower()
	for _, candidate in ipairs(Inhaler.KillModules) do
		if name == tostring(candidate):lower() then return true end
	end
	return false
end

-- Game chunks load after the GUI, so a module can be missing for a few seconds.
local function waitForModule(name, timeout)
	local deadline = os.clock() + (timeout or 10)
	local mod
	repeat
		mod = findModule(name)
		if mod then break end
		task.wait(0.5)
	until os.clock() > deadline
	return mod
end

local function setState(mod, enabled)
	if not mod or mod.Enabled == enabled then return true end
	local ok = pcall(function() mod:Toggle() end)
	if Inhaler.Debug then
		log(('toggle %s -> %s (%s)'):format(tostring(mod.Name), tostring(enabled), tostring(ok)))
	end
	return ok and mod.Enabled == enabled
end

local function findOption(mod, name)
	if not mod or type(mod.Options) ~= 'table' then return nil end
	local opt = mod.Options[name]
	if opt then return opt end
	local lower = tostring(name):lower()
	for key, candidate in pairs(mod.Options) do
		if tostring(key):lower() == lower then return candidate end
	end
	for key, candidate in pairs(mod.Options) do
		if tostring(key):lower():find(lower, 1, true) then return candidate end
	end
	return nil
end

local function listContents(opt)
	if type(opt) ~= 'table' then return nil end
	return opt.ListEnabled or opt.List
end

local function listHas(opt, name)
	local list = listContents(opt)
	if type(list) ~= 'table' then return false end
	return table.find(list, name) ~= nil
end

-- ChangeValue() is a toggle, so membership has to be re-checked on every step.
local function listToggle(opt, name)
	if type(opt) ~= 'table' or type(opt.ChangeValue) ~= 'function' then return false end
	local ok = pcall(function() opt:ChangeValue(name) end)
	return ok
end

local function setList(opt, names)
	if type(opt) ~= 'table' then return false end

	local current = listContents(opt)
	if type(current) == 'table' then
		local guard = 0
		while guard < 200 do
			guard = guard + 1
			local victim
			for _, existing in ipairs(current) do
				if not table.find(names, existing) then
					victim = existing
					break
				end
			end
			if not victim then break end
			if not listToggle(opt, victim) then break end
			if listHas(opt, victim) then break end
		end
	end

	for _, name in ipairs(names) do
		if not listHas(opt, name) then
			listToggle(opt, name)
		end
	end
	return true
end

local function toBool(value)
	local v = tostring(value or ''):lower():gsub('%s+$', '')
	if v == 'on' or v == 'true' or v == '1' or v == 'enable' or v == 'enabled' then return true end
	if v == 'off' or v == 'false' or v == '0' or v == 'disable' or v == 'disabled' then return false end
	return nil
end

local function parseValue(value)
	local bool = toBool(value)
	if bool ~= nil then return bool end
	local num = tonumber(value)
	if num then return num end
	return value
end

local function setOptionValue(opt, value)
	if type(opt) ~= 'table' then return false end
	if type(opt.SetValue) ~= 'function' then return false end
	return select(1, pcall(function() opt:SetValue(value) end))
end

--[[ ------------------------------ commands ------------------------------ ]]

function Inhaler:Command(raw)
	if not vape then return false, 'vape not loaded' end

	local text = tostring(raw or ''):gsub('^%s+', ''):gsub('%s+$', '')
	text = text:gsub('^[%.;\' ]+', '')
	if text == '' then return false, 'empty command' end

	local name, args = text:match('^(%S+)%s*(.*)$')
	if not name then return false, 'unparsed command' end
	name = name:lower()
	args = (args or ''):gsub('%s+$', '')
	name = Inhaler.Aliases[name] or name

	local mod = findModule(name)
	if not mod then
		local late = waitForModule(name, 5)
		if not late then
			return false, ('no module "%s"'):format(name)
		end
		mod = late
	end

	if args == '' then
		setState(mod, not mod.Enabled)
		return true, ('%s %s'):format(tostring(mod.Name), mod.Enabled and 'on' or 'off')
	end

	local flag = toBool(args)
	if flag ~= nil then
		setState(mod, flag)
		return true, ('%s %s'):format(tostring(mod.Name), mod.Enabled and 'on' or 'off')
	end

	if args:find('=', 1, true) then
		local failed
		local count = 0
		for pair in args:gmatch('[^,%s]+') do
			local key, value = pair:match('^([%w_]+)=(.+)$')
			if key then
				local opt = findOption(mod, key) or findOption(mod, (key:gsub('_', ' ')))
				if opt and setOptionValue(opt, parseValue(value)) then
					count = count + 1
				else
					failed = key
				end
			end
		end
		if failed then
			return false, ('no option "%s" on %s'):format(failed, tostring(mod.Name))
		end
		return true, ('%s: %d option(s) set'):format(tostring(mod.Name), count)
	end

	-- Bare words: player targets if the module has a Targets/TextList option,
	-- otherwise treat them as a Dropdown value (Mode/Team/...).
	local names = {}
	for word in args:gmatch('%S+') do
		table.insert(names, word)
	end

	local targets = findOption(mod, 'Targets')
	if targets then
		setList(targets, names)
		setState(mod, true)
		if Inhaler.KillTimeout > 0 and isKillModule(mod) then
			task.delay(Inhaler.KillTimeout, function()
				if vape and vape.Loaded ~= nil then
					setState(mod, false)
				end
			end)
		end
		return true, ('%s -> %s'):format(tostring(mod.Name), table.concat(names, ', '))
	end

	local dropdown = findOption(mod, 'Mode') or findOption(mod, 'Team')
	if dropdown and dropdown.Value ~= nil then
		setOptionValue(dropdown, args)
		return true, ('%s = %s'):format(tostring(mod.Name), args)
	end

	return false, ('%s takes no arguments'):format(tostring(mod.Name))
end

function Inhaler:Send(text)
	local box = Inhaler.Box
	if box then
		box.Text = tostring(text or '')
	end
	return Inhaler:Command(text)
end

function Inhaler:Set(name, enabled)
	local mod = waitForModule(name, 5)
	if not mod then return false, 'no module' end
	return setState(mod, enabled == true)
end

function Inhaler:Option(module, option, value)
	local mod = waitForModule(module, 5)
	local opt = mod and findOption(mod, option)
	if not opt then return false, 'no option' end
	return setOptionValue(opt, value)
end

function Inhaler:Targets(module, names)
	local mod = waitForModule(module, 5)
	local opt = mod and findOption(mod, 'Targets')
	if not opt then return false, 'no targets option' end
	return setList(opt, names or {})
end

function Inhaler:Kill(name)
	for _, candidate in ipairs(Inhaler.KillModules) do
		local mod = findModule(candidate)
		if mod then
			local opt = findOption(mod, 'Targets')
			if opt then setList(opt, {name}) end
			setState(mod, true)
			return true, ('%s -> %s'):format(tostring(mod.Name), tostring(name))
		end
	end
	return false, 'no kill module (set Inhaler.KillModules)'
end

local function friendsCategory()
	if not vape or type(vape.Categories) ~= 'table' then return nil end
	return vape.Categories.Friends
end

function Inhaler:Whitelist(name, enabled)
	local friends = friendsCategory()
	if not friends then return false, 'no friends list' end
	if listHas(friends, name) == (enabled == true) then return true end
	return listToggle(friends, name)
end

function Inhaler:WhitelistAll()
	local count = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lplr then
			local ok = select(1, Inhaler:Whitelist(plr.Name, true))
			if ok then count = count + 1 end
		end
	end
	return count
end

function Inhaler:Save()
	if not vape then return false end
	return pcall(function() vape:Save() end)
end

function Inhaler:Destroy()
	cleanup(true)
end

function Inhaler:Modules()
	rebuildIndex()
	local names = {}
	for name in pairs(moduleIndex) do
		table.insert(names, name)
	end
	table.sort(names)
	print('[Inhaler] modules ('..#names..'): '..table.concat(names, ', '))
	return names
end

--[[ --------------------------- vapeEvents bus --------------------------- ]]

local killEvent = Instance.new('BindableEvent')
clean(killEvent)
Inhaler.KillEvent = killEvent

local vapeEvents = {}
vapeEvents.PlayerKill = {
	Event = killEvent.Event,
	Fire = function(_, killer, victim)
		killEvent:Fire(killer, victim)
	end
}
rawset(getgenv(), 'vapeEvents', vapeEvents)
shared.vapeEvents = vapeEvents

local lastAttacker = {}

local function rootOf(plr)
	local char = plr and plr.Character
	return char and char:FindFirstChild('HumanoidRootPart')
end

local function holdsTool(plr)
	local char = plr and plr.Character
	if not char then return false end
	return char:FindFirstChildOfClass('Tool') ~= nil
end

-- Two passes: an armed player wins over a merely close one.
local ARMED_PASSES = {true, false}

local function nearestSuspected(victim)
	local vroot = rootOf(victim)
	if not vroot then return nil end

	for _, armedOnly in ipairs(ARMED_PASSES) do
		local best, bestDist = nil, Inhaler.KillRadius
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= victim then
				local hum = plr.Character and plr.Character:FindFirstChildOfClass('Humanoid')
				if hum and hum.Health > 0 and (not armedOnly or holdsTool(plr)) then
					local r = rootOf(plr)
					if r then
						local dist = (r.Position - vroot.Position).Magnitude
						if dist < bestDist then
							best, bestDist = plr, dist
						end
					end
				end
			end
		end
		if best then return best end
	end
	return nil
end

local function watchPlayer(plr)
	if not Inhaler.TrackDeaths then return end
	clean(plr.CharacterAdded:Connect(function(char)
		local hum = char:FindFirstChildOfClass('Humanoid') or char:WaitForChild('Humanoid', 5)
		if not hum then return end

		local last = hum.Health
		clean(hum.HealthChanged:Connect(function(health)
			if health < last then
				local attacker = nearestSuspected(plr)
				if attacker then
					lastAttacker[plr.Name] = {name = attacker.Name, at = os.clock()}
				end
			end
			last = health
		end))

		clean(hum.Died:Connect(function()
			local record = lastAttacker[plr.Name]
			local killer
			if record and (os.clock() - record.at) <= Inhaler.KillWindow then
				killer = record.name
			else
				local near = nearestSuspected(plr)
				killer = near and near.Name
			end
			lastAttacker[plr.Name] = nil
			if killer then
				log(('PlayerKill %s -> %s'):format(killer, plr.Name))
				killEvent:Fire(killer, plr.Name)
			end
		end))
	end))

	clean(plr.CharacterRemoving:Connect(function()
		lastAttacker[plr.Name] = nil
	end))
end

--[[ --------------------------- command box --------------------------- ]]

local function createCommandBox()
	local pg = lplr:FindFirstChild('PlayerGui') or lplr:WaitForChild('PlayerGui', 10)
	if not pg then return nil end

	local old = pg:FindFirstChild('InhalerCommandBox')
	if old then old:Destroy() end

	-- vape.ThreadFix means core-GUI creation requires identity 8.
	local restoreIdentity
	if vape and vape.ThreadFix and setidentity and getidentity then
		restoreIdentity = getidentity()
		pcall(setidentity, 8)
	end

	local gui = Instance.new('ScreenGui')
	gui.Name = 'InhalerCommandBox'
	gui.ResetOnSpawn = false
	gui.Enabled = true
	gui.Parent = pg
	clean(gui)

	-- Offscreen on purpose: EagleScript's F6 transport focuses this box, writes
	-- the command and presses Return, which fires FocusLost(enter == true).
	local box = Instance.new('TextBox')
	box.Name = 'Box'
	box.Size = UDim2.fromOffset(1, 1)
	box.Position = UDim2.new(0, -200, 0, -200)
	box.BackgroundTransparency = 1
	box.TextTransparency = 1
	box.ClearTextOnFocus = false
	box.Active = false
	box.Parent = gui

	if restoreIdentity then
		pcall(setidentity, restoreIdentity)
	end

	clean(box.FocusLost:Connect(function(enter)
		if not enter then return end
		local text = box.Text
		box.Text = ''
		if text == '' then return end
		local ok, accepted, message = pcall(Inhaler.Command, Inhaler, text)
		if not ok then
			notif('command error: '..tostring(accepted), 8, 'alert')
		elseif not accepted and message then
			notif(tostring(message), 5, 'warning')
		end
	end))

	return box
end

--[[ ------------------------- optional vape module ------------------------- ]]

local function registerVapeModule()
	if not vape or type(vape.Categories) ~= 'table' then return end
	local category = vape.Categories.Utility or vape.Categories.World
	if not category or type(category.CreateModule) ~= 'function' then return end
	if not vape.gui then return end

	local ok, mod = pcall(function()
		return category:CreateModule({
			Name = 'Inhaler',
			Tooltip = 'Native command bridge for the Inhaler layer',
			Function = function(callback)
				if not callback then return end
				repeat
					task.wait()
				until Inhaler.Module == nil or not Inhaler.Module.Enabled
			end
		})
	end)
	if not ok or type(mod) ~= 'table' then return end

	Inhaler.Module = mod
	pcall(function()
		mod:CreateTextBox({
			Name = 'Command',
			Placeholder = 'kill bob / esp on',
			Default = '',
			Function = function(enter)
				if not enter then return end
				local opt = mod.Options and mod.Options.Command
				local text = opt and opt.Value
				if text and text ~= '' then
					local ok2, accepted, message = pcall(Inhaler.Command, Inhaler, text)
					if ok2 and not accepted then
						notif(tostring(message), 5, 'warning')
					end
				end
			end
		})
	end)
end

--[[ -------------------------------- boot -------------------------------- ]]

-- Tears the whole bridge down: connections, command box, vape module, globals.
-- A re-executed chunk gets fresh locals, so this only ever cleans its own run.
cleanup = function(silent)
	for _, item in ipairs(maid) do
		if typeof(item) == 'RBXScriptConnection' then
			pcall(function() item:Disconnect() end)
		elseif typeof(item) == 'Instance' then
			pcall(function() item:Destroy() end)
		elseif type(item) == 'function' then
			pcall(item)
		end
	end
	table.clear(maid)
	table.clear(moduleIndex)
	table.clear(lastAttacker)
	Inhaler.Module = nil
	Inhaler.Box = nil

	if vape and vape.Remove then
		pcall(function() vape:Remove('Inhaler') end)
	end

	shared.VapeBotCommand = nil
	shared.Inhaler = nil
	shared.vapeEvents = nil
	rawset(getgenv(), 'vapeEvents', nil)
	rawset(getgenv(), 'Inhaler', nil)
	rawset(getgenv(), 'JARVIS_VAPE_COMMAND_BOX', nil)

	if not silent then
		log('uninjected')
	end
end

local function start(v)
	vape = v

	-- shared.VapeBotCommand: EagleScript's fallthrough (submit(), line 1017).
	shared.VapeBotCommand = function(raw)
		return Inhaler:Command(raw)
	end

	Inhaler.Box = createCommandBox()
	if Inhaler.Box then
		rawset(getgenv(), 'JARVIS_VAPE_COMMAND_BOX', Inhaler.Box)
		shared.JARVIS_VAPE_COMMAND_BOX = Inhaler.Box
	end

	if Inhaler.AutoWhitelist then
		clean(Players.PlayerAdded:Connect(function(plr)
			task.defer(function()
				for _ = 1, 20 do
					if not plr.Parent then return end
					if select(1, Inhaler:Whitelist(plr.Name, true)) then return end
					task.wait(0.5)
				end
			end)
		end))
		task.spawn(function()
			for _ = 1, 20 do
				if friendsCategory() then
					Inhaler:WhitelistAll()
					return
				end
				task.wait(0.5)
			end
			notif('Friends list unavailable; whitelist sync skipped', 8, 'warning')
		end)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		watchPlayer(plr)
	end
	clean(Players.PlayerAdded:Connect(watchPlayer))
	clean(Players.PlayerRemoving:Connect(function(plr)
		lastAttacker[plr.Name] = nil
	end))

	registerVapeModule()
	rebuildIndex()

	-- Uninject sentinel: vape.Loaded goes nil, never back.
	task.spawn(function()
		local tracked = vape
		repeat
			task.wait(1)
		until tracked.Loaded == nil
		if vape == tracked then
			cleanup()
		end
	end)

	rawset(getgenv(), 'Inhaler', Inhaler)
	shared.Inhaler = Inhaler
	notif(('ready (v%s, %d modules)'):format(Inhaler.Version, (function()
		local n = 0
		for _ in pairs(moduleIndex) do n = n + 1 end
		return n
	end)()), 6)
end

if Inhaler.AutoLoad and not findVape() and not shared.InhalerSkipVapeLoad then
	task.spawn(function()
		local ok, err = pcall(function()
			local source = (game :: any):HttpGet(Inhaler.VapeURL, true)
			local chunk = loadstr(source, 'vape')
			if chunk then chunk() end
		end)
		if not ok then
			warn('[Inhaler] vape auto-load failed: '..tostring(err))
		end
	end)
end

local found = waitForVape(30)
if not found then
	warn('[Inhaler] shared.vape never appeared; load Vape V4 first')
	notif('shared.vape not found — load Vape V4 first', 15, 'alert')
	return
end

start(found)
