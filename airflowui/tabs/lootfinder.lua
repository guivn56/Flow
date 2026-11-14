-- =====================================================================
-- tabs/lootfinder.lua - aba LOOTFINDER
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : LOOT (toggles + slider de distancia)
--   coluna direita  : FILTERS (dropdowns) + NOTIFY (toggles)
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "LOOTFINDER" (icone "search")
	-- -----------------------------------------------------------------
	local lootTab = window:CreateTab({ Name = "LOOTFINDER" }, "search")

	local leftColumn = lootTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = lootTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "LOOT" ---------------------------------------------------
	leftColumn:Section("LOOT")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Loot ESP",
		Flag = "LootLootEsp",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Box",
				Flag = "LootLootEspBox",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Name",
				Flag = "LootLootEspName",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Distance",
				Flag = "LootLootEspDistance",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Loot Highlight",
		Flag = "LootHighlight",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Style",
				Flag = "LootHighlightStyle",
				Options = { "Outline", "Fill", "Text" },
				Default = "Outline",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Loot Range",
		Flag = "LootRange",
		Min = 0,
		Max = 500,
		Step = 5,
		Default = 100,
		Suffix = " studs",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Chests",
		Flag = "LootChests",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Opened",
				Flag = "LootChestsShowOpened",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Button({
		Name = "Refresh Loot",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "FILTERS" ------------------------------------------------
	rightColumn:Section("FILTERS")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Dropdown({
		Name = "Rarity",
		Flag = "LootFilterRarity",
		Options = { "All", "Common", "Rare", "Epic", "Legendary" },
		Default = "All",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Dropdown({
		Name = "Item Type",
		Flag = "LootFilterType",
		Options = { "All", "Weapons", "Armor", "Items", "Keys" },
		Default = "All",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Input({
		Name = "Item Name",
		Placeholder = "Search item",
		Flag = "LootFilterName",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Hide Empty",
		Flag = "LootHideEmpty",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Delay",
				Flag = "LootHideEmptyDelay",
				Min = 0,
				Max = 2000,
				Step = 10,
				Default = 100,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "NOTIFY" -------------------------------------------------
	rightColumn:Section("NOTIFY")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Rare Notify",
		Flag = "LootRareNotify",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "LootRareNotifyStyle",
				Options = { "Chat", "Window", "Both" },
				Default = "Chat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Loot Sound",
		Flag = "LootSound",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Volume",
				Flag = "LootSoundVolume",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	return lootTab
end
