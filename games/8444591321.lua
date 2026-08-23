local fable = shared.fable
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and fable then
		fable:CreateNotification('Fable', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
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

fable.Place = 6872274481
if isfile('FableV4/games/'..fable.Place..'.lua') then
	loadstring(readfile('FableV4/games/'..fable.Place..'.lua'), 'bedwars')()
else
	if not shared.FableDeveloper then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/exuric/Fable-V4/'..readfile('FableV4/profiles/commit.txt')..'/games/'..fable.Place..'.lua', true)
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile('FableV4/games/'..fable.Place..'.lua'), 'bedwars')()
		end
	end
end