fable.Categories.Utility:CreateModule({
	Name = 'Panic',
	Function = function(callback)
		if callback then
			for _, module in fable.Modules do
				if module.Enabled then
					module:Toggle()
				end
			end
		end
	end,
	Tooltip = 'Disables all currently enabled modules'
})