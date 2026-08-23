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
local run = function(func)
	func()
end
local queue_on_teleport = queue_on_teleport or function() end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local proxService = cloneref(game:GetService('ProximityPromptService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local assetService = cloneref(game:GetService('AssetService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local stats = cloneref(game:GetService('Stats'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer

local fable = shared.fable
local tween = fable.Libraries.tween
local targetinfo = fable.Libraries.targetinfo
local getfontbounds = fable.Libraries.getfontbounds
local getfableasset = fable.Libraries.getfableasset

local TargetStrafeVector, SpiderShift, WaypointFolder
local Spider = {Enabled = false}
local Phase = {Enabled = false}

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getfableasset('FableV4/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

local function calculateMoveVector(vec)
	local c, s
	local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
	if R12 < 1 and R12 > -1 then
		c = R22
		s = R02
	else
		c = R00
		s = -R01 * math.sign(R12)
	end
	vec = Vector3.new((c * vec.X + s * vec.Z), 0, (c * vec.Z - s * vec.X)) / math.sqrt(c * c + s * s)
	return vec.Unit == vec.Unit and vec.Unit or Vector3.zero
end

local function isFriend(plr, recolor)
	if fable.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(fable.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and fable.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(fable.Categories.Targets.ListEnabled, plr.Name) and true
end

local function canClick()
	local mousepos = (inputService:GetMouseLocation() - guiService:GetGuiInset())
	for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	for _, v in coreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	return (not fable.gui.ScaledGui.ClickGui.Visible) and (not inputService:GetFocusedTextBox())
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do ind += 1 end
	return ind
end

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool', true) or nil
end

local function notif(...)
	return fable:CreateNotification(...)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local function rakNetCheck(module)
	if not (raknet and raknet.add_send_hook and pcall(raknet.add_send_hook, function() end)) then
		notif(module, 'This feature requires raknet! (risky feature, please do not use on mains.)', 10, 'warning')
		return false
	end

	return true
end

local visited, attempted, tpSwitch = {}, {}, false
local cacheExpire, cache = tick()
local function serverHop(pointer, filter)
	visited = shared.fableserverhoplist and shared.fableserverhoplist:split('/') or {}
	if not table.find(visited, game.JobId) then
		table.insert(visited, game.JobId)
	end
	if not pointer then
		notif('Fable', 'Searching for an available server.', 2)
	end

	local suc, httpdata = pcall(function()
		return cacheExpire < tick() and game:HttpGet('https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder='..(filter == 'Ascending' and 1 or 2)..'&excludeFullGames=true&limit=100'..(pointer and '&cursor='..pointer or '')) or cache
	end)
	local data = suc and httpService:JSONDecode(httpdata) or nil
	if data and data.data then
		for _, v in data.data do
			if tonumber(v.playing) < playersService.MaxPlayers and not table.find(visited, v.id) and not table.find(attempted, v.id) then
				cacheExpire, cache = tick() + 60, httpdata
				table.insert(attempted, v.id)

				notif('Fable', 'Found! Teleporting.', 5)
				teleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
				return
			end
		end

		if data.nextPageCursor then
			serverHop(data.nextPageCursor, filter)
		else
			notif('Fable', 'Failed to find an available server.', 5, 'warning')
		end
	else
		notif('Fable', 'Failed to grab servers. ('..(data and data.errors[1].message or 'no data')..')', 5, 'warning')
	end
end

fable:Clean(lplr.OnTeleport:Connect(function()
	if not tpSwitch then
		tpSwitch = true
		queue_on_teleport("shared.fableserverhoplist = '"..table.concat(visited, '/').."'\nshared.fableserverhopprevious = '"..game.JobId.."'")
	end
end))

local frictionTable, oldfrict, entitylib = {}, {}
local function updateVelocity()
	if getTableSize(frictionTable) > 0 then
		if entitylib.isAlive then
			for _, part in entitylib.character.Character:GetChildren() do
				if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' and not oldfrict[part] then
					oldfrict[part] = part.CustomPhysicalProperties or 'none'
					part.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
				end
			end
		end
	else
		for part, data in oldfrict do
			part.CustomPhysicalProperties = data ~= 'none' and data or nil
		end

		table.clear(oldfrict)
	end
end

local function motorMove(target, cf)
	local part = Instance.new('Part')
	part.Anchored = true
	part.Parent = workspace
	local motor = Instance.new('Motor6D')
	motor.Part0 = target
	motor.Part1 = part
	motor.C1 = cf
	motor.Parent = part
	task.delay(0, part.Destroy, part)
end

local hash = loadstring(downloadFile('FableV4/libraries/hash.lua'), 'hash')()
local prediction = loadstring(downloadFile('FableV4/libraries/prediction.lua'), 'prediction')()
entitylib = loadstring(downloadFile('FableV4/libraries/entity.lua'), 'entitylibrary')()
local whitelist = {
	alreadychecked = {},
	customtags = {},
	tagcallback = {},
	data = {WhitelistedUsers = {}},
	hashes = setmetatable({}, {
		__index = function(_, data)
			return hash and hash.sha512(data..'SelfReport') or ''
		end
	}),
	hooked = false,
	loaded = false,
	localprio = 0,
	said = {}
}
fable.Libraries.entity = entitylib
fable.Libraries.whitelist = whitelist
fable.Libraries.prediction = prediction
fable.Libraries.hash = hash
fable.Libraries.auraanims = {
	Normal = {
		{CFrame = CFrame.new(-0.17, -0.14, -0.12) * CFrame.Angles(math.rad(-53), math.rad(50), math.rad(-64)), Time = 0.1},
		{CFrame = CFrame.new(-0.55, -0.59, -0.1) * CFrame.Angles(math.rad(-161), math.rad(54), math.rad(-6)), Time = 0.08},
		{CFrame = CFrame.new(-0.62, -0.68, -0.07) * CFrame.Angles(math.rad(-167), math.rad(47), math.rad(-1)), Time = 0.03},
		{CFrame = CFrame.new(-0.56, -0.86, 0.23) * CFrame.Angles(math.rad(-167), math.rad(49), math.rad(-1)), Time = 0.03}
	},
	Random = {},
	['Horizontal Spin'] = {
		{CFrame = CFrame.Angles(math.rad(-10), math.rad(-90), math.rad(-80)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(-10), math.rad(180), math.rad(-80)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(-10), math.rad(90), math.rad(-80)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(-10), 0, math.rad(-80)), Time = 0.12}
	},
	['Vertical Spin'] = {
		{CFrame = CFrame.Angles(math.rad(-90), 0, math.rad(15)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(180), 0, math.rad(15)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(90), 0, math.rad(15)), Time = 0.12},
		{CFrame = CFrame.Angles(0, 0, math.rad(15)), Time = 0.12}
	},
	Exhibition = {
		{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.1},
		{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.2}
	},
	['Exhibition Old'] = {
		{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.15},
		{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.05},
		{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.1},
		{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.05},
		{CFrame = CFrame.new(0.63, -0.1, 1.37) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.15}
	}
}

local SpeedMethods
local SpeedMethodList = {'Velocity'}
SpeedMethods = {
	Velocity = function(options, moveDirection)
		local root = entitylib.character.RootPart
		root.AssemblyLinearVelocity = (moveDirection * options.Value.Value) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
	end,
	Impulse = function(options, moveDirection)
		local root = entitylib.character.RootPart
		local diff = ((moveDirection * options.Value.Value) - root.AssemblyLinearVelocity) * Vector3.new(1, 0, 1)
		if diff.Magnitude > (moveDirection == Vector3.zero and 10 or 2) then
			root:ApplyImpulse(diff * root.AssemblyMass)
		end
	end,
	CFrame = function(options, moveDirection, dt)
		local root = entitylib.character.RootPart
		local dest = (moveDirection * math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0) * dt)
		if options.WallCheck.Enabled then
			options.rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			options.rayCheck.CollisionGroup = root.CollisionGroup
			local ray = workspace:Raycast(root.Position, dest, options.rayCheck)
			if ray then
				dest = ((ray.Position + ray.Normal) - root.Position)
			end
		end
		root.CFrame += dest
	end,
	TP = function(options, moveDirection)
		if options.TPTiming < os.clock() then
			options.TPTiming = os.clock() + options.TPFrequency.Value
			SpeedMethods.CFrame(options, moveDirection, 1)
		end
	end,
	WalkSpeed = function(options)
		if not options.WalkSpeed then options.WalkSpeed = entitylib.character.Humanoid.WalkSpeed end
		entitylib.character.Humanoid.WalkSpeed = options.Value.Value
	end,
	Pulse = function(options, moveDirection)
		local root = entitylib.character.RootPart
		local dt = math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0)
		dt = dt * (1 - math.min((os.clock() % (options.PulseLength.Value + options.PulseDelay.Value)) / options.PulseLength.Value, 1))
		root.AssemblyLinearVelocity = (moveDirection * (entitylib.character.Humanoid.WalkSpeed + dt)) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
	end
}

for name in SpeedMethods do
	if not table.find(SpeedMethodList, name) then
		table.insert(SpeedMethodList, name)
	end
end

run(function()
	entitylib.getUpdateConnections = function(entity)
		local hum = entity.Humanoid
		return {
			hum:GetPropertyChangedSignal('Health'),
			hum:GetPropertyChangedSignal('MaxHealth'),
			{
				Connect = function()
					entity.Friend = entity.Player and isFriend(entity.Player) or nil
					entity.Target = entity.Player and isTarget(entity.Player) or nil
					return {
						Disconnect = function() end
					}
				end
			}
		}
	end

	entitylib.targetCheck = function(entity)
		if entity.TeamCheck then
			return entity:TeamCheck()
		end
		if entity.NPC then return true end
		if isFriend(entity.Player) then return false end
		if not select(2, whitelist:get(entity.Player)) then return false end
		if fable.Settings.Modules.Options['Teams by server'].Enabled then
			if not lplr.Team then return true end
			if not entity.Player.Team then return true end
			if entity.Player.Team ~= lplr.Team then return true end
			return #entity.Player.Team:GetPlayers() == #playersService:GetPlayers()
		end
		return true
	end

	entitylib.getEntityColor = function(entity)
		entity = entity.Player
		if not (entity and fable.Settings.Modules.Options['Use team color'].Enabled) then return end
		if isFriend(entity, true) then
			return Color3.fromHSV(fable.Categories.Friends.Options['Friends color'].Hue, fable.Categories.Friends.Options['Friends color'].Sat, fable.Categories.Friends.Options['Friends color'].Value)
		end
		return tostring(entity.TeamColor) ~= 'White' and entity.TeamColor.Color or nil
	end

	fable:Clean(function()
		entitylib.kill()
		entitylib = nil
	end)
	fable:Clean(fable.Categories.Friends.Update.Event:Connect(function() entitylib.refresh() end))
	fable:Clean(fable.Categories.Targets.Update.Event:Connect(function() entitylib.refresh() end))
	fable:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
	fable:Clean(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
		gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
	end))
end)

run(function()
	function whitelist:get(plr)
		local plrstr = self.hashes[plr.Name..plr.UserId]
		for _, v in self.data.WhitelistedUsers do
			if v.hash == plrstr then
				return v.level, v.attackable or whitelist.localprio >= v.level, v.tags
			end
		end

		return 0, true
	end

	function whitelist:isingame()
		for _, v in playersService:GetPlayers() do
			if self:get(v) ~= 0 then
				return true
			end
		end

		return false
	end

	function whitelist:tag(plr, text, rich)
		local plrtag, newtag = table.clone(select(3, self:get(plr)) or self.customtags[plr.Name] or {}), ''
		for _, v in self.tagcallback do
			v(plr, plrtag, rich)
		end

		if not text then
			return plrtag
		end

		for _, v in plrtag do
			newtag = newtag..(rich and v.color and '<font color="#'..v.color:ToHex()..'">['..v.text..']</font>' or '['..removeTags(v.text)..']')..' '
		end

		return newtag
	end

	function whitelist:getplayer(arg, plr)
		if arg == 'default' and self.localprio == 0 then
			return true
		end

		if arg == 'private' and self.localprio == 1 then
			return true
		end

		if arg == 'others' and plr ~= lplr then
			return true
		end

		if arg and lplr.Name:lower():sub(1, arg:len()) == arg:lower() then
			return true
		end

		return false
	end

	local olduninject
	function whitelist:playeradded(v, joined)
		if self:get(v) ~= 0 then
			if self.alreadychecked[v.UserId] then return end
			self.alreadychecked[v.UserId] = true
			self:hook()

			if self.localprio == 0 then
				olduninject = fable.Uninject
				fable.Uninject = function()
					notif('Fable', 'No escaping the private members :)', 10)
				end
			end
		end
	end

	function whitelist:process(msg, plr)
		if self.localprio < self:get(plr) or plr == lplr then
			local args = msg:split(' ')
			table.remove(args, 1)

			if self:getplayer(args[1], plr) then
				table.remove(args, 1)
				for cmd, func in self.commands do
					if msg:sub(1, cmd:len() + 1):lower() == ';'..cmd:lower() then
						func(args, plr)
						return true
					end
				end
			end
		end

		return false
	end

	function whitelist:newchat(obj, plr, skip)
		obj.PrefixText = self:tag(plr, true, true)..(obj.PrefixText or '')

		if not skip and self:process(obj.Text, plr) then
			obj.Visible = false
		end
	end

	function whitelist:oldchat(func)
		local msgtable, oldchat = debug.getupvalue(func, 3)
		if typeof(msgtable) == 'table' and msgtable.CurrentChannel then
			whitelist.oldchattable = msgtable
		end

		oldchat = hookfunction(func, function(data, ...)
			local plr = playersService:GetPlayerByUserId(data.SpeakerUserId)
			if plr then
				data.ExtraData.Tags = data.ExtraData.Tags or {}
				for _, v in self:tag(plr) do
					table.insert(data.ExtraData.Tags, {TagText = v.text, TagColor = v.color})
				end

				if data.Message and self:process(data.Message, plr) then
					data.Message = ''
				end
			end

			return oldchat(data, ...)
		end)

		fable:Clean(function()
			hookfunction(func, oldchat)
		end)
	end

	function whitelist:hook()
		if self.hooked then return end
		self.hooked = true

		if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			if getcallbackvalue and restorefunction and hookfunction then
				local old
				task.spawn(function()
					fable:Clean(function()
						if old then
							restorefunction(old)
							old = nil
						end
					end)

					repeat
						local current = getcallbackvalue(textChatService, 'OnIncomingMessage')

						if old ~= current and current then
							if old then
								restorefunction(old)
							end

							local hook
							hook = hookfunction(current, function(...)
								local msg = ...
								local data = hook(...)
								local plr = msg.TextSource and playersService:GetPlayerByUserId(msg.TextSource.UserId)

								if plr then
									if not (data and data:IsA('TextChatMessageProperties') and data.PrefixText ~= '') then
										data = Instance.new('TextChatMessageProperties')
										data.PrefixText = msg.PrefixText
										data.Text = msg.Text
									end

									self:newchat(data, plr, msg.Status ~= Enum.TextChatMessageStatus.Success)
								end

								return data
							end)

							old = current
						end

						task.wait(0.1)
					until fable.Loaded == nil
				end)
			end
		elseif replicatedStorage:FindFirstChild('DefaultChatSystemChatEvents') then
			pcall(function()
				for _, v in getconnections(replicatedStorage.DefaultChatSystemChatEvents.OnNewMessage.OnClientEvent) do
					if v.Function and table.find(debug.getconstants(v.Function), 'UpdateMessagePostedInChannel') then
						whitelist:oldchat(v.Function)
						break
					end
				end

				for _, v in getconnections(replicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent) do
					if v.Function and table.find(debug.getconstants(v.Function), 'UpdateMessageFiltered') then
						whitelist:oldchat(v.Function)
						break
					end
				end
			end)
		end
	end

	function whitelist:announce(text)
		local success, sendToast = pcall(function()
			local getAppIdHook = getrenv().require(game:GetService('CorePackages').Workspace.Packages._Workspace.AppCommonLib.AppCommonLib.Release.getNumericalApplicationId)
			local messageBusHook = getrenv().require(game:GetService('CorePackages').Workspace.Packages._Workspace.MessageBus.MessageBus.MessageBus)
			messageBusHook.getMessageId = function() end
			hookfunction(getAppIdHook, function()
				return 0
			end)

			local localizationService = game:GetService('LocalizationService')
			local root = game:GetService('CorePackages').Workspace.Packages._Index.NotificationModalsManager.NotificationModalsManager
			local reactBlox = getrenv().require(root.ReactRoblox)
			local react = getrenv().require(root.React)
			local UIBlox = getrenv().require(root.UIBlox)
			UIBlox.init(getrenv().require(game:GetService('CorePackages').Packages._Index.UIBlox.UIBlox.UIBloxDefaultConfig))
			local toastDialog = UIBlox.App.Dialog.Toast
			local localization = getrenv().require(root.InExperienceLocales).Localization
			local localProvider = getrenv().require(root.Localization).LocalizationProvider
			local defaultTheme = getrenv().require(root.Style).StyleProviderWithDefaultTheme
			local renderGui = nil

			local function createToast(content)
				return react.createElement(localProvider, {
					localization = localization.new(localizationService.RobloxLocaleId)
				}, {
					StyleProvider = react.createElement(defaultTheme, {}, {
						ToastWrapper = react.createElement('ScreenGui', {
							IgnoreGuiInset = true,
							ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
							ResetOnSpawn = false,
							DisplayOrder = 12
						}, {
							Toast = react.createElement(toastDialog, {
								duration = 20,
								toastContent = content
							})
						})
					})
				})
			end

			return function(content)
				if not renderGui then
					local folder = Instance.new('Folder')
					folder.Name = 'UIBloxToast'
					folder.Parent = game:GetService('CoreGui')
					folder.ChildRemoved:Once(function()
						folder:Destroy()
						renderGui = nil
					end)

					renderGui = reactBlox.createRoot(folder)
				end

				renderGui:render(react.createElement(createToast, content))
			end
		end)

		if success then
			return sendToast({
				toastTitle = text,
				iconImage = getfableasset('FableV4/assets/new/fable.png'),
				swipeUpDismiss = true,
				onActivated = function() end
			})
		end

		local container = Instance.new('TextButton')
		container.Size = UDim2.new(1, -24, 0, 60)
		container.Position = UDim2.new(0.5, 0, 0, -60)
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.BackgroundTransparency = 1
		container.Text = ''
		container.Parent = fable.gui
		local constraint = Instance.new('UISizeConstraint')
		constraint.MinSize = Vector2.new(24, 60)
		constraint.MaxSize = Vector2.new(600, math.huge)
		constraint.Parent = container
		local bkg = Instance.new('ImageLabel')
		bkg.Size = UDim2.fromScale(1, 1)
		bkg.Position = UDim2.fromScale(0.5, 0.5)
		bkg.AnchorPoint = Vector2.new(0.5, 0.5)
		bkg.BackgroundTransparency = 1
		bkg.Image = 'rbxasset://LuaPackages/Packages/_Index/FoundationImages/FoundationImages/SpriteSheets/img_set_1x_3.png'
		bkg.ImageRectOffset = Vector2.new(490, 196)
		bkg.ImageRectSize = Vector2.new(21, 21)
		bkg.ScaleType = Enum.ScaleType.Slice
		bkg.SliceCenter = Rect.new(10, 10, 11, 11)
		bkg.ImageColor3 = Color3.fromRGB(39, 41, 48)
		bkg.Parent = container
		local holder = Instance.new('Frame')
		holder.Size = UDim2.fromScale(1, 1)
		holder.BackgroundTransparency = 1
		holder.ClipsDescendants = true
		holder.Parent = bkg
		local listlayout = Instance.new('UIListLayout')
		listlayout.Padding = UDim.new(0, 12)
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.SortOrder = Enum.SortOrder.LayoutOrder
		listlayout.Parent = holder
		local padding = Instance.new('UIPadding')
		padding.PaddingBottom = UDim.new(0, 12)
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.PaddingTop = UDim.new(0, 12)
		padding.Parent = holder
		local mainframe = Instance.fromExisting(holder)
		mainframe.ClipsDescendants = false
		mainframe.Parent = holder
		local listlayout2 = Instance.fromExisting(listlayout)
		listlayout2.Parent = mainframe
		local textframe = Instance.new('Frame')
		textframe.Size = UDim2.new(1, -48, 0, 22)
		textframe.BackgroundTransparency = 1
		textframe.LayoutOrder = 2
		textframe.Parent = mainframe
		local textlabel = Instance.new('TextLabel')
		textlabel.Size = UDim2.new(1, 0, 0, 22)
		textlabel.BackgroundTransparency = 1
		textlabel.Text = text
		textlabel.TextSize = 20
		textlabel.TextColor3 = Color3.fromRGB(247, 247, 248)
		textlabel.TextXAlignment = Enum.TextXAlignment.Left
		textlabel.FontFace = Font.fromName('BuilderSans', Enum.FontWeight.Bold)
		textlabel.Parent = textframe
		local iconframe = Instance.new('Frame')
		iconframe.Size = UDim2.fromOffset(36, 36)
		iconframe.BackgroundTransparency = 1
		iconframe.Parent = mainframe
		local icon = Instance.new('ImageLabel')
		icon.Size = UDim2.fromOffset(36, 36)
		icon.Image = getfableasset('FableV4/assets/new/fable.png')
		icon.BackgroundTransparency = 1
		icon.Parent = iconframe
		constraint.MaxSize = Vector2.new(math.max(getfontbounds(text, 20, textlabel.FontFace).X + 80, 600), math.huge)

		tween:Tween(container, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 0, 20)
		})

		task.delay(20, function()
			if fable.Loaded ~= nil then
				tween:Tween(container, TweenInfo.new(0.3), {
					Position = UDim2.new(0.5, 0, 0, -60)
				})

				task.wait(0.3)
				container:Destroy()
			end
		end)
	end

	function whitelist:update(first)
		local suc = pcall(function()
			local _, subbed = pcall(function()
				return game:HttpGet('https://github.com/7GrandDadPGN/whitelists')
			end)
			local commit = subbed:find('currentOid')
			commit = commit and subbed:sub(commit + 13, commit + 52) or nil
			commit = commit and #commit == 40 and commit or 'main'
			whitelist.textdata = game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/whitelists/'..commit..'/PlayerWhitelist.json', true)
		end)
		if not suc or not hash or not whitelist.get then return true end
		whitelist.loaded = true

		if not first or whitelist.textdata ~= whitelist.olddata then
			if not first then
				whitelist.olddata = isfile('FableV4/profiles/whitelist.json') and readfile('FableV4/profiles/whitelist.json') or nil
			end

			local suc, res = pcall(function()
				return httpService:JSONDecode(whitelist.textdata)
			end)

			whitelist.data = suc and type(res) == 'table' and res or whitelist.data
			whitelist.localprio = whitelist:get(lplr)

			for _, v in whitelist.data.WhitelistedUsers do
				if v.tags then
					for _, tag in v.tags do
						tag.color = Color3.fromRGB(unpack(tag.color))
					end
				end
			end

			if not whitelist.connection then
				whitelist.connection = playersService.PlayerAdded:Connect(function(v)
					whitelist:playeradded(v, true)
				end)
				fable:Clean(whitelist.connection)
			end

			for _, v in playersService:GetPlayers() do
				whitelist:playeradded(v)
			end

			if entitylib.Running and fable.Loaded then
				entitylib.refresh()
			end

			if whitelist.textdata ~= whitelist.olddata then
				if whitelist.data.Announcement.expiretime > os.time() then
					local targets = whitelist.data.Announcement.targets
					targets = targets == 'all' and {tostring(lplr.UserId)} or targets:split(',')

					if table.find(targets, tostring(lplr.UserId)) then
						whitelist:announce(whitelist.data.Announcement.text)
					end
				end
				whitelist.olddata = whitelist.textdata
				pcall(function()
					writefile('FableV4/profiles/whitelist.json', whitelist.textdata)
				end)
			end

			if whitelist.data.KillFable then
				fable:Uninject()
				return true
			end

			if whitelist.data.BlacklistedUsers[tostring(lplr.UserId)] then
				task.spawn(lplr.kick, lplr, whitelist.data.BlacklistedUsers[tostring(lplr.UserId)])
				return true
			end
		end
	end

	whitelist.commands = {
		crash = function()
			task.spawn(function()
				repeat
					local part = Instance.new('Part')
					part.Size = Vector3.new(1e10, 1e10, 1e10)
					part.Parent = workspace
				until false
			end)
		end,
		deletemap = function()
			local terrain = workspace:FindFirstChildWhichIsA('Terrain')
			if terrain then
				terrain:Clear()
			end

			for _, obj in workspace:GetChildren() do
				if obj ~= terrain and not obj:IsDescendantOf(lplr.Character) and not obj:IsA('Camera') then
					obj:Destroy()
					obj:ClearAllChildren()
				end
			end
		end,
		framerate = function(args)
			if #args < 1 or not setfpscap then return end
			setfpscap(tonumber(args[1]) ~= '' and math.clamp(tonumber(args[1]) or 9999, 1, 9999) or 9999)
		end,
		gravity = function(args)
			workspace.Gravity = tonumber(args[1]) or workspace.Gravity
		end,
		jump = function()
			if entitylib.isAlive and entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end,
		kick = function(args)
			task.spawn(function()
				lplr:Kick(table.concat(args, ' '))
			end)
		end,
		kill = function()
			if entitylib.isAlive then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				entitylib.character.Humanoid.Health = 0
			end
		end,
		reveal = function()
			task.delay(0.1, function()
				if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
					textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync('I am using the inhaler client')
				else
					replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('I am using the inhaler client', 'All')
				end
			end)
		end,
		shutdown = function()
			game:Shutdown()
		end,
		toggle = function(args)
			if #args < 1 then return end
			if args[1]:lower() == 'all' then
				for i, v in fable.Modules do
					if i ~= 'Panic' and i ~= 'ServerHop' and i ~= 'Rejoin' then
						v:Toggle()
					end
				end
			else
				for i, v in fable.Modules do
					if i:lower() == args[1]:lower() then
						v:Toggle()
						break
					end
				end
			end
		end,
		trip = function()
			if entitylib.isAlive then
				if entitylib.character.RootPart.AssemblyLinearVelocity.Magnitude < 15 then
					entitylib.character.RootPart.AssemblyLinearVelocity = entitylib.character.RootPart.CFrame.LookVector * 15
				end

				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			end
		end,
		uninject = function()
			if olduninject then
				if fable.ThreadFix then
					setthreadidentity(8)
				end
				olduninject(fable)
			else
				fable:Uninject()
			end
		end,
		void = function()
			if entitylib.isAlive then
				entitylib.character.RootPart.CFrame += Vector3.new(0, -1000, 0)
			end
		end
	}

	task.spawn(function()
		repeat
			if whitelist:update(whitelist.loaded) then
				return
			end

			task.wait(10)
		until fable.Loaded == nil
	end)

	fable:Clean(function()
		table.clear(whitelist.commands)
		table.clear(whitelist.data)
		table.clear(whitelist)
	end)
end)
entitylib.start()

run(function()
	local HitSounds
	local Volume
	local Pitch
	local Range
	local cache = {}

	local sounds = {
		['Electronic Ping'] = 'rbxasset://sounds/electronicpingshort.wav',
		Snap = 'rbxasset://sounds/snap.mp3',
		Splash = 'rbxasset://sounds/impact_water.mp3',
		Oof = 'rbxasset://sounds/uuhhh.mp3'
	}

	local sound = Instance.new('Sound')
	sound.Name = 'FableHitSound'
	sound.SoundId = sounds['Electronic Ping']
	sound.Volume = 0.6
	sound.Parent = game:GetService('SoundService')

	HitSounds = fable.Categories.Combat:CreateModule({
		Name = 'Hit Sounds',
		Tooltip = 'Plays a sound when a nearby player takes damage.',
		Function = function() end
	})
	HitSounds:CreateDropdown({
		Name = 'Sound',
		List = { 'Electronic Ping', 'Snap', 'Splash', 'Oof' },
		Default = 'Electronic Ping',
		Tooltip = 'Which hit sound to play.',
		Function = function(val)
			sound.SoundId = sounds[val] or sound.SoundId
		end
	})
	Volume = HitSounds:CreateSlider({
		Name = 'Volume',
		Min = 0,
		Max = 100,
		Default = 60,
		Tooltip = 'Loudness of the hit sound.'
	})
	Pitch = HitSounds:CreateSlider({
		Name = 'Pitch',
		Min = 50,
		Max = 200,
		Default = 100,
		Tooltip = 'Playback pitch in percent.'
	})
	Range = HitSounds:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 250,
		Default = 75,
		Tooltip = 'Max distance to hear hits from.'
	})

	task.spawn(function()
		while fable.Loaded do
			local myhrp = lplr.Character and lplr.Character:FindFirstChild('HumanoidRootPart')
			for _, plr in playersService:GetPlayers() do
				if plr ~= lplr then
					local char = plr.Character
					local hum = char and char:FindFirstChildOfClass('Humanoid')
					local hrp = char and char:FindFirstChild('HumanoidRootPart')
					if hum and hrp then
						local old = cache[plr]
						cache[plr] = hum.Health
						if old and hum.Health < old and HitSounds.Enabled and myhrp and (myhrp.Position - hrp.Position).Magnitude <= Range.Value then
							sound.Volume = Volume.Value / 100
							sound.PlaybackSpeed = Pitch.Value / 100
							sound:Play()
						end
					elseif cache[plr] then
						cache[plr] = nil
					end
				end
			end
			task.wait(0.1)
		end
	end)
end)

run(function()
	local uipallet = fable.Libraries.uipallet
	local color = fable.Libraries.color

	local ShowTime
	local MaxEntries
	local entries = {}
	local cache = {}
	local lastdamage = {}
	local watching = {}

	local holder = Instance.new('Frame')
	holder.Name = 'FableKillLog'
	holder.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	holder.BackgroundTransparency = 0.05
	holder.BorderSizePixel = 0
	holder.Position = UDim2.fromOffset(12, 60)
	holder.Size = UDim2.fromOffset(240, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Visible = false
	holder.Parent = fable.gui
	fable:Clean(holder)

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = holder

	local title = Instance.new('TextLabel')
	title.BackgroundTransparency = 1
	title.FontFace = uipallet.FontSemiBold
	title.Size = UDim2.new(1, -16, 0, 24)
	title.Position = UDim2.fromOffset(8, 0)
	title.Text = 'KILL LOG'
	title.TextColor3 = color.Light(uipallet.Text, 0.2)
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = holder

	local layout = Instance.new('UIListLayout')
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder

	local pad = Instance.new('UIPadding')
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 26)
	pad.Parent = holder

	local function rebuild()
		for _, v in holder:GetChildren() do
			if v.Name == 'Entry' then
				v:Destroy()
			end
		end
		local total = #entries
		for i = total, 1, -1 do
			local entry = entries[i]
			local label = Instance.new('TextLabel')
			label.Name = 'Entry'
			label.LayoutOrder = total - i + 1
			label.BackgroundTransparency = 1
			label.RichText = true
			label.FontFace = uipallet.Font
			label.TextSize = 13
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Size = UDim2.new(1, 0, 0, 0)
			label.TextColor3 = uipallet.Text
			label.Text = '<font color="#'..entry[2]..'">'..entry[1]..'</font>'
			label.Parent = holder
		end
	end

	local function addEntry(hex, msg)
		table.insert(entries, {(ShowTime.Enabled and os.date('[%H:%M:%S] ') or '')..msg, hex})
		while #entries > MaxEntries.Value do
			table.remove(entries, 1)
		end
		rebuild()
	end

	local KillLog = fable.Categories.Combat:CreateModule({
		Name = 'Kill Log',
		Tooltip = 'Logs knockouts and deaths of nearby players.',
		Function = function(callback)
			holder.Visible = callback
		end
	})
	ShowTime = KillLog:CreateToggle({
		Name = 'Show Time',
		Default = true,
		Tooltip = 'Adds a timestamp to entries.',
		Function = function()
			rebuild()
		end
	})
	MaxEntries = KillLog:CreateSlider({
		Name = 'Max Entries',
		Min = 5,
		Max = 20,
		Default = 8,
		Tooltip = 'How many entries to keep.',
		Function = function()
			rebuild()
		end
	})

	local function onDowned(plr)
		if os.clock() - (lastdamage[plr] or 0) < 4 then
			addEntry('9dff9d', 'You knocked '..removeTags(plr.DisplayName))
		else
			addEntry('c9c9c9', removeTags(plr.DisplayName)..' got knocked')
		end
	end

	local function onDeath(plr)
		if os.clock() - (lastdamage[plr] or 0) < 4 then
			addEntry('9dff9d', 'You killed '..removeTags(plr.DisplayName))
		else
			addEntry('ff8080', removeTags(plr.DisplayName)..' died')
		end
	end

	local function watch(plr)
		if plr == lplr or watching[plr] then return end
		watching[plr] = true
		local function bind(char)
			task.spawn(function()
				local hum = char:WaitForChild('Humanoid', 10)
				local effects = char:FindFirstChild('BodyEffects') or char:WaitForChild('BodyEffects', 10)
				local ko = effects and (effects:FindFirstChild('K.O') or effects:FindFirstChild('KO'))
				if ko and ko:IsA('BoolValue') then
					fable:Clean(ko:GetPropertyChangedSignal('Value'):Connect(function()
						if ko.Value and KillLog.Enabled then
							onDowned(plr)
						end
					end))
				end
				if hum then
					fable:Clean(hum.Died:Connect(function()
						if KillLog.Enabled then
							onDeath(plr)
						end
					end))
				end
			end)
		end
		if plr.Character then
			bind(plr.Character)
		end
		fable:Clean(plr.CharacterAdded:Connect(bind))
	end

	for _, plr in playersService:GetPlayers() do
		watch(plr)
	end
	fable:Clean(playersService.PlayerAdded:Connect(watch))
	fable:Clean(playersService.PlayerRemoving:Connect(function(plr)
		watching[plr] = nil
		cache[plr] = nil
		lastdamage[plr] = nil
	end))

	task.spawn(function()
		while fable.Loaded do
			for _, plr in playersService:GetPlayers() do
				if plr ~= lplr then
					local hum = plr.Character and plr.Character:FindFirstChildOfClass('Humanoid')
					if hum then
						local old = cache[plr]
						cache[plr] = hum.Health
						if old and hum.Health < old then
							lastdamage[plr] = os.clock()
						end
					elseif cache[plr] then
						cache[plr] = nil
					end
				end
			end
			task.wait(0.15)
		end
	end)
end)
