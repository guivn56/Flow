-- =====================================================================
-- tabs/players.lua - aba PLAYERS
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : PLAYERS ESP
--   coluna direita  : ITEMS ESP + RADAR
--
-- A logica pesada fica em marcadores.
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	-- -----------------------------------------------------------------
	-- ABA "PLAYERS" (icone "users")
	-- -----------------------------------------------------------------
	local playersTab = window:CreateTab({ Name = "PLAYERS" }, "users")

	local leftColumn = playersTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = playersTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "PLAYERS ESP" -------------------------------------------
	leftColumn:Section("PLAYERS ESP")

	-- [LOGICA DO ESP DE JOGADORES AQUI]
	leftColumn:Toggle({
		Name = "Master",
		Flag = "PlayersEspMaster",
		Callback = function(value)
			Settings.players_esp_master = value
		end,
	})

	-- [LOGICA DAS CAIXAS AQUI]
	leftColumn:Toggle({
		Name = "Boxes",
		Flag = "PlayersEspBoxes",
		Callback = function(value)
			Settings.players_esp_boxes = value
		end,
	})

	-- [LOGICA DAS NAME TAGS AQUI]
	leftColumn:Toggle({
		Name = "Name Tags",
		Flag = "PlayersEspNameTags",
		Callback = function(value)
			Settings.players_esp_name_tags = value
		end,
	})

	-- [LOGICA DAS DISTANCE TAGS AQUI]
	leftColumn:Toggle({
		Name = "Distance Tags",
		Flag = "PlayersEspDistanceTags",
		Callback = function(value)
			Settings.players_esp_distance_tags = value
		end,
	})

	-- [LOGICA DAS HEALTH BARS AQUI]
	leftColumn:Toggle({
		Name = "Health Bars",
		Flag = "PlayersEspHealthBars",
		Callback = function(value)
			Settings.players_esp_health_bars = value
		end,
	})

	-- [LOGICA DO SKELETON AQUI]
	leftColumn:Toggle({
		Name = "Skeleton",
		Flag = "PlayersEspSkeleton",
		Callback = function(value)
			Settings.players_esp_skeleton = value
		end,
	})

	-- [LOGICA DAS SETAS AQUI]
	leftColumn:Toggle({
		Name = "Arrows",
		Flag = "PlayersEspArrows",
		Callback = function(value)
			Settings.players_esp_arrows = value
		end,
	})

	-- [LOGICA DOS TRACERS AQUI]
	leftColumn:Toggle({
		Name = "Tracers",
		Flag = "PlayersEspTracers",
		Callback = function(value)
			Settings.players_esp_tracers = value
		end,
	})

	-- [LOGICA DOS HIGHLIGHTS AQUI]
	leftColumn:Toggle({
		Name = "Highlights",
		Flag = "PlayersEspHighlights",
		Callback = function(value)
			Settings.players_esp_highlights = value
		end,
	})

	-- [LOGICA DAS REPORTS TAGS AQUI]
	leftColumn:Toggle({
		Name = "Reports Tags",
		Flag = "PlayersEspReportsTags",
		Callback = function(value)
			Settings.players_esp_reports_tags = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "ITEMS ESP" ---------------------------------------------
	rightColumn:Section("ITEMS ESP")

	-- [LOGICA DO ESP DE NPCS AQUI]
	rightColumn:Toggle({
		Name = "NPCs ESP",
		Flag = "PlayersEspNpcs",
		Callback = function(value)
			Settings.players_esp_npcs = value
		end,
	})

	-- [LOGICA DO ESP DE CORPOS AQUI]
	rightColumn:Toggle({
		Name = "Corpses ESP",
		Flag = "PlayersEspCorpses",
		Callback = function(value)
			Settings.players_esp_corpses = value
		end,
	})

	-- [LOGICA DO ESP DE ITEMS LARADOS AQUI]
	rightColumn:Toggle({
		Name = "Dropped Items ESP",
		Flag = "PlayersEspDroppedItems",
		Callback = function(value)
			Settings.players_esp_dropped_items = value
		end,
	})

	-- [LOGICA DO ESP DE CONTAINERS (VAULTS) AQUI]
	rightColumn:Toggle({
		Name = "Containers ESP",
		Flag = "PlayersEspContainers",
		Callback = function(value)
			Settings.players_esp_containers = value
		end,
	})

	-- [LOGICA DO ESP DE QUESTS AQUI]
	rightColumn:Toggle({
		Name = "Quest Items ESP",
		Flag = "PlayersEspQuestItems",
		Callback = function(value)
			Settings.players_esp_quest_items = value
		end,
	})

	-- SECCAO "RADAR" -------------------------------------------------
	rightColumn:Section("RADAR")

	-- [LOGICA DO RADAR AQUI]
	rightColumn:Toggle({
		Name = "Radar",
		Flag = "PlayersRadarEnabled",
		Callback = function(value)
			Settings.players_radar_enabled = value
		end,
	})

	-- [LOGICA DO RADAR DE MAPA COMPLETO AQUI]
	rightColumn:Toggle({
		Name = "Full Map",
		Flag = "PlayersRadarFullMap",
		Callback = function(value)
			Settings.players_radar_full_map = value
		end,
	})

	-- [LOGICA DO RADAR SINCRONIZADO AQUI]
	rightColumn:Toggle({
		Name = "Sync Map",
		Flag = "PlayersRadarSyncMap",
		Callback = function(value)
			Settings.players_radar_sync_map = value
		end,
	})

	-- [LOGICA DA FORMA DO RADAR AQUI]
	rightColumn:Dropdown({
		Name = "Shape",
		Flag = "PlayersRadarShape",
		Options = { "Circle", "Square" },
		Default = "Circle",
		Callback = function(value)
			Settings.players_radar_shape = value
		end,
	})

	-- [LOGICA DO ZOOM DO RADAR AQUI]
	rightColumn:Slider({
		Name = "Zoom",
		Flag = "PlayersRadarZoom",
		Min = 1,
		Max = 10,
		Step = 1,
		Default = 4,
		Callback = function(value)
			Settings.players_radar_zoom = value
		end,
	})

	return playersTab
end
