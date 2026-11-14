-- =====================================================================
-- tabs/players.lua - aba PLAYER
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : PLAYERS ESP
--   coluna direita  : ITEMS ESP + RADAR
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "PLAYER" (icone "user")
	-- -----------------------------------------------------------------
	local playersTab = window:CreateTab({ Name = "PLAYER" }, "user")

	local leftColumn = playersTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = playersTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "PLAYERS ESP" -------------------------------------------
	leftColumn:Section("PLAYERS ESP")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Master",
		Flag = "PlayerEspMaster",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Max Distance",
				Flag = "PlayerEspMaxDistance",
				Min = 0,
				Max = 2000,
				Step = 10,
				Default = 500,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Dropdown",
				Name = "Team Filter",
				Flag = "PlayerEspTeamFilter",
				Options = { "All", "Team", "Enemy", "Other" },
				Default = "All",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Boxes",
		Flag = "PlayerEspBoxes",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Box Style",
				Flag = "PlayerEspBoxStyle",
				Options = { "Outline", "Corner", "Full" },
				Default = "Outline",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Name Tags",
		Flag = "PlayerEspNameTags",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Tag Size",
				Flag = "PlayerEspNameTagSize",
				Min = 8,
				Max = 32,
				Step = 1,
				Default = 14,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Distance Tags",
		Flag = "PlayerEspDistanceTags",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Tag Offset",
				Flag = "PlayerEspDistanceTagOffset",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 20,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Health Bars",
		Flag = "PlayerEspHealthBars",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Bar Style",
				Flag = "PlayerEspHealthBarStyle",
				Options = { "Left", "Right", "Bottom" },
				Default = "Left",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Skeleton",
		Flag = "PlayerEspSkeleton",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Head",
				Flag = "PlayerEspSkeletonHead",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Arrows",
		Flag = "PlayerEspArrows",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Arrow Position",
				Flag = "PlayerEspArrowPosition",
				Options = { "Above", "Below", "Side" },
				Default = "Above",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Tracers",
		Flag = "PlayerEspTracers",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Tracer Thickness",
				Flag = "PlayerEspTracerThickness",
				Min = 1,
				Max = 10,
				Step = 1,
				Default = 2,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Highlights",
		Flag = "PlayerEspHighlights",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Highlight Style",
				Flag = "PlayerEspHighlightStyle",
				Options = { "Outline", "Fill", "Both" },
				Default = "Outline",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Reports Tags",
		Flag = "PlayerEspReportsTags",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Report Count",
				Flag = "PlayerEspReportsCount",
				Min = 1,
				Max = 20,
				Step = 1,
				Default = 3,
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "ITEMS ESP" ---------------------------------------------
	rightColumn:Section("ITEMS ESP")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "NPCs ESP",
		Flag = "PlayerEspNpcs",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "NPC Distance",
				Flag = "PlayerEspNpcsDistance",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 100,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Corpses ESP",
		Flag = "PlayerEspCorpses",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Name",
				Flag = "PlayerEspCorpsesName",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Dropped Items ESP",
		Flag = "PlayerEspDroppedItems",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Item Distance",
				Flag = "PlayerEspDroppedItemsDistance",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 100,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Containers ESP",
		Flag = "PlayerEspContainers",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Loot",
				Flag = "PlayerEspContainersLoot",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Quest Items ESP",
		Flag = "PlayerEspQuestItems",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Quest Type",
				Flag = "PlayerEspQuestItemsType",
				Options = { "All", "Active", "Daily", "Event" },
				Default = "All",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "RADAR" -------------------------------------------------
	rightColumn:Section("RADAR")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Radar",
		Flag = "PlayerRadarEnabled",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Radar Size",
				Flag = "PlayerRadarSize",
				Min = 100,
				Max = 600,
				Step = 10,
				Default = 240,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Full Map",
		Flag = "PlayerRadarFullMap",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Grid",
				Flag = "PlayerRadarFullMapGrid",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Sync Map",
		Flag = "PlayerRadarSyncMap",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Sync Delay",
				Flag = "PlayerRadarSyncMapDelay",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 10,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Dropdown({
		Name = "Shape",
		Flag = "PlayerRadarShape",
		Options = { "Circle", "Square" },
		Default = "Circle",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Slider({
		Name = "Zoom",
		Flag = "PlayerRadarZoom",
		Min = 1,
		Max = 10,
		Step = 1,
		Default = 4,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	return playersTab
end
