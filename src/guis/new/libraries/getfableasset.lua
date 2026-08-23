do
	local fableAssets = {
		['FableV4/assets/new/add.png'] = 'rbxassetid://121642387707174',
		['FableV4/assets/new/aim.png'] = 'rbxassetid://122207028123421',
		['FableV4/assets/new/allowedicon.png'] = 'rbxassetid://112336790299036',
		['FableV4/assets/new/allowediconmini.png'] = 'rbxassetid://90142384730147',
		['FableV4/assets/new/back.png'] = 'rbxassetid://80523803497740',
		['FableV4/assets/new/backmini.png'] = 'rbxassetid://85859225495272',
		['FableV4/assets/new/bind.png'] = 'rbxassetid://81399857677684',
		['FableV4/assets/new/bindbkg.png'] = 'rbxassetid://101996225428926',
		['FableV4/assets/new/blatant.png'] = 'rbxassetid://126929923309265',
		['FableV4/assets/new/blur.png'] = 'rbxassetid://79246816170155',
		['FableV4/assets/new/blurnoti.png'] = 'rbxassetid://124705876663719',
		['FableV4/assets/new/close.png'] = 'rbxassetid://121816018671466',
		['FableV4/assets/new/closemini.png'] = 'rbxassetid://108320409341289',
		['FableV4/assets/new/closetiny.png'] = 'rbxassetid://71393233149714',
		['FableV4/assets/new/colorpreview.png'] = 'rbxassetid://140438628568318',
		['FableV4/assets/new/combat.png'] = 'rbxassetid://94762732349053',
		['FableV4/assets/new/customtheme.png'] = 'rbxassetid://91756736022800',
		['FableV4/assets/new/discord.png'] = 'rbxassetid://99871463341003',
		['FableV4/assets/new/downexpand.png'] = 'rbxassetid://94197751291504',
		['FableV4/assets/new/downexpandslider.png'] = 'rbxassetid://90289944682645',
		['FableV4/assets/new/edit.png'] = 'rbxassetid://105801951237137',
		['FableV4/assets/new/editlarge.png'] = 'rbxassetid://119233876755282',
		['FableV4/assets/new/expandarrow.png'] = 'rbxassetid://86360332526471',
		['FableV4/assets/new/friends.png'] = 'rbxassetid://92957214042038',
		['FableV4/assets/new/inventory.png'] = 'rbxassetid://93264756888499',
		['FableV4/assets/new/legit_mode_icon.png'] = 'rbxassetid://102858626075156',
		['FableV4/assets/new/legit_switch.png'] = 'rbxassetid://127508881124779',
		['FableV4/assets/new/min.png'] = 'rbxassetid://82175054487146',
		['FableV4/assets/new/noti_alert.png'] = 'rbxassetid://82356478726846',
		['FableV4/assets/new/noti_info.png'] = 'rbxassetid://102614825645099',
		['FableV4/assets/new/noti_warning.png'] = 'rbxassetid://119631730212167',
		['FableV4/assets/new/notification.png'] = 'rbxassetid://90300780458781',
		['FableV4/assets/new/npcs.png'] = 'rbxassetid://104434365485227',
		['FableV4/assets/new/overlaydots.png'] = 'rbxassetid://78012624671930',
		['FableV4/assets/new/overlays.png'] = 'rbxassetid://136535637407545',
		['FableV4/assets/new/overlayslarge.png'] = 'rbxassetid://127574141208160',
		['FableV4/assets/new/pin.png'] = 'rbxassetid://92459145800579',
		['FableV4/assets/new/players.png'] = 'rbxassetid://105137446428129',
		['FableV4/assets/new/profiles.png'] = 'rbxassetid://126051451865127',
		['FableV4/assets/new/radar.png'] = 'rbxassetid://97983828696086',
		['FableV4/assets/new/rainbow_1.png'] = 'rbxassetid://101329996188554',
		['FableV4/assets/new/rainbow_2.png'] = 'rbxassetid://72739074644654',
		['FableV4/assets/new/rainbow_3.png'] = 'rbxassetid://100716555253397',
		['FableV4/assets/new/rainbow_4.png'] = 'rbxassetid://133424174227092',
		['FableV4/assets/new/range.png'] = 'rbxassetid://107794917650053',
		['FableV4/assets/new/rangeindicator.png'] = 'rbxassetid://107038094175283',
		['FableV4/assets/new/render.png'] = 'rbxassetid://125472576898654',
		['FableV4/assets/new/search.png'] = 'rbxassetid://115611852955611',
		['FableV4/assets/new/settingdots.png'] = 'rbxassetid://130896840048276',
		['FableV4/assets/new/settings.png'] = 'rbxassetid://73820177347303',
		['FableV4/assets/new/settingsmini.png'] = 'rbxassetid://115732118290997',
		['FableV4/assets/new/targetinfo.png'] = 'rbxassetid://121604266095276',
		['FableV4/assets/new/textgui.png'] = 'rbxassetid://99438663817412',
		['FableV4/assets/new/theme.png'] = 'rbxassetid://111525258317113',
		['FableV4/assets/new/utility.png'] = 'rbxassetid://108303206513893',
		['FableV4/assets/new/v4.png'] = 'rbxassetid://102549752760489',
		['FableV4/assets/new/v4mini.png'] = 'rbxassetid://115213099001611',
		['FableV4/assets/new/world.png'] = 'rbxassetid://118917453153459'
	}

	local function createDownloader(text)
		if fable.Loaded ~= true then
			local downloader = fable.Downloader
			if not downloader then
				downloader = Instance.new('TextLabel')
				downloader.BackgroundTransparency = 1
				downloader.FontFace = uipallet.Font
				downloader.Size = UDim2.new(1, 0, 0, 40)
				downloader.TextColor3 = Color3.new(1, 1, 1)
				downloader.TextSize = 20
				downloader.TextStrokeTransparency = 0
				downloader.Parent = fable.gui
				fable.Downloader = downloader
			end

			downloader.Text = 'Downloading '..text
		end
	end

	local function downloadFile(path, callback)
		if not isfile(path) then
			createDownloader(path)

			local success, data = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/exuric/Fable-V4/'..readfile('FableV4/profiles/commit.txt')..'/'..select(1, path:gsub('FableV4/', '')), true)
			end)

			if not success or data == '404: Not Found' then
				error(data)
			end

			if path:find('.lua') then
				data = '--This watermark is used to delete the file if its cached, remove it to make the file persist after fable updates.\n'..data
			end

			writefile(path, data)
		end

		return (callback or readfile)(path)
	end

	getfableasset = not inputService.TouchEnabled and getcustomasset and function(path)
		return downloadFile(path, getcustomasset)
	end or function(path)
		return fableAssets[path] or ''
	end
end
