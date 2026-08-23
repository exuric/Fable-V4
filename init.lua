local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
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

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after fable updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'FableV4', 'FableV4/games', 'FableV4/profiles', 'FableV4/assets', 'FableV4/libraries', 'FableV4/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.FableDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/exuric/Fable-V4')
	end)

	local assetVer = '1'
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'

	if commit == 'main' or (isfile('FableV4/profiles/commit.txt') and readfile('FableV4/profiles/commit.txt') or '') ~= commit then
		wipeFolder('FableV4')
		wipeFolder('FableV4/games')
		wipeFolder('FableV4/guis')
		wipeFolder('FableV4/libraries')
	end

	if (isfile('FableV4/profiles/asset.txt') and readfile('FableV4/profiles/asset.txt') or '') ~= assetVer then
		wipeFolder('FableV4/assets')
	end

	writefile('FableV4/profiles/asset.txt', assetVer)
	writefile('FableV4/profiles/commit.txt', commit)
end

return loadstring(downloadFile('FableV4/main.lua'), 'main')()