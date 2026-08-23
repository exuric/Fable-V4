repeat task.wait() until game:IsLoaded()
if shared.fable then shared.fable:Uninject() end

local fable
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and fable then
		fable:CreateNotification('Fable', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/exuric/Fable-V4/'..readfile('FableV4/profiles/commit.txt')..'/'..select(1, path:gsub('FableV4/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after fable updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	fable.Init = nil
	fable:Load()
	task.spawn(function()
		repeat
			fable:Save()
			task.wait(10)
		until not fable.Loaded
	end)

	local teleportedServers
	fable:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.FableIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.fablereload = true
				if shared.FableDeveloper then
					loadstring(readfile('FableV4/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/exuric/Fable-V4/'..readfile('FableV4/profiles/commit.txt')..'/loader.lua', true), 'loader')()
				end
			]]
			if shared.FableDeveloper then
				teleportScript = 'shared.FableDeveloper = true\n'..teleportScript
			end
			if shared.FableCustomProfile then
				teleportScript = 'shared.FableCustomProfile = "'..shared.FableCustomProfile..'"\n'..teleportScript
			end
			fable:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.fablereload then
		if not fable.Categories then return end
		if fable.Settings.GUI.Options['GUI bind indicator'].Enabled then
			fable:CreateNotification('Finished Loading', fable.FableButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(fable.GUIBind.Keys, ' + '):upper()..' to open GUI', 5)
		end
	end
end

if not isfile('FableV4/profiles/gui.txt') then
	writefile('FableV4/profiles/gui.txt', 'new')
end
local gui = 'new'--readfile('FableV4/profiles/gui.txt')

if not isfolder('FableV4/assets/'..gui) then
	makefolder('FableV4/assets/'..gui)
end
fable = loadstring(downloadFile('FableV4/guis/'..gui..'.lua'), 'gui')()
shared.fable = fable

if not shared.FableIndependent then
	loadstring(downloadFile('FableV4/games/universal.lua'), 'universal')()
	if isfile('FableV4/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('FableV4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.FableDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/exuric/Fable-V4/'..readfile('FableV4/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('FableV4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
			end
		end
	end
	finishLoading()
else
	fable.Init = finishLoading
	return fable
end