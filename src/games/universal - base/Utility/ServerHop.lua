local ServerHop
local Sort

ServerHop = fable.Categories.Utility:CreateModule({
	Name = 'ServerHop',
	Function = function(callback)
		if callback then
			ServerHop:Toggle()
			serverHop(nil, Sort.Value)
		end
	end,
	Tooltip = 'Teleports into a unique server'
})
Sort = ServerHop:CreateDropdown({
	Name = 'Sort',
	List = {'Descending', 'Ascending'},
	Tooltip = 'Descending - Prefers full servers\nAscending - Prefers empty servers'
})
ServerHop:CreateButton({
	Name = 'Rejoin Previous Server',
	Function = function()
		notif('ServerHop', shared.fableserverhopprevious and 'Rejoining previous server...' or 'Cannot find previous server', 5)

		if shared.fableserverhopprevious then
			teleportService:TeleportToPlaceInstance(game.PlaceId, shared.fableserverhopprevious)
		end
	end
})