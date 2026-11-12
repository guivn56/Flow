-- =====================================================================
-- tabs/visuals.lua - aba VISUALS
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : WORLD
--   coluna direita  : PLAYER + CROSSHAIR
--
-- A logica pesada fica em marcadores.
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	-- -----------------------------------------------------------------
	-- ABA "VISUALS" (icone "eye")
	-- -----------------------------------------------------------------
	local visualsTab = window:CreateTab({ Name = "VISUALS" }, "eye")

	local leftColumn = visualsTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = visualsTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "WORLD" -------------------------------------------------
	leftColumn:Section("WORLD")

	-- [LOGICA DO FULLBRIGHT AQUI]
	leftColumn:Toggle({
		Name = "Fullbright",
		Flag = "VisualsFullbright",
		Callback = function(value)
			Settings.visuals_fullbright = value
		end,
	})

	-- [LOGICA DO NO FOG AQUI]
	leftColumn:Toggle({
		Name = "No Fog",
		Flag = "VisualsNoFog",
		Callback = function(value)
			Settings.visuals_no_fog = value
		end,
	})

	-- [LOGICA DO BLOOM AQUI]
	leftColumn:Toggle({
		Name = "Bloom",
		Flag = "VisualsBloom",
		Callback = function(value)
			Settings.visuals_bloom = value
		end,
	})

	-- [LOGICA DA GRAMA AQUI]
	leftColumn:Toggle({
		Name = "Grass",
		Flag = "VisualsGrass",
		Callback = function(value)
			Settings.visuals_grass = value
		end,
	})

	-- [LOGICA DAS ARVORES AQUI]
	leftColumn:Toggle({
		Name = "Trees",
		Flag = "VisualsTrees",
		Callback = function(value)
			Settings.visuals_trees = value
		end,
	})

	-- [LOGICA DO TERRENO AQUI]
	leftColumn:Toggle({
		Name = "Terrain",
		Flag = "VisualsTerrain",
		Callback = function(value)
			Settings.visuals_terrain = value
		end,
	})

	-- [LOGICA DA AGUA AQUI]
	leftColumn:Toggle({
		Name = "Water",
		Flag = "VisualsWater",
		Callback = function(value)
			Settings.visuals_water = value
		end,
	})

	-- [LOGICA DA HORA DO DIA AQUI]
	leftColumn:Slider({
		Name = "Time of Day",
		Flag = "VisualsTimeOfDay",
		Min = 0,
		Max = 24,
		Step = 1,
		Default = 14,
		Callback = function(value)
			Settings.visuals_time_of_day = value
		end,
	})

	-- [LOGICA DO BRILHO AQUI]
	leftColumn:Slider({
		Name = "Brightness",
		Flag = "VisualsBrightness",
		Min = 0,
		Max = 5,
		Step = 1,
		Default = 2,
		Callback = function(value)
			Settings.visuals_brightness = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "PLAYER" ------------------------------------------------
	rightColumn:Section("PLAYER")

	-- [LOGICA DOS CHAMS AQUI]
	rightColumn:Toggle({
		Name = "Chams",
		Flag = "VisualsChams",
		Callback = function(value)
			Settings.visuals_chams = value
		end,
	})

	-- [LOGICA DO FORCE FIELD AQUI]
	rightColumn:Toggle({
		Name = "Force Field",
		Flag = "VisualsForceField",
		Callback = function(value)
			Settings.visuals_force_field = value
		end,
	})

	-- [LOGICA DO HALO AQUI]
	rightColumn:Toggle({
		Name = "Halo",
		Flag = "VisualsHalo",
		Callback = function(value)
			Settings.visuals_halo = value
		end,
	})

	-- [LOGICA DO TRAIL AQUI]
	rightColumn:Toggle({
		Name = "Trail",
		Flag = "VisualsTrail",
		Callback = function(value)
			Settings.visuals_trail = value
		end,
	})

	-- [LOGICA DO AURA AQUI]
	rightColumn:Toggle({
		Name = "Aura",
		Flag = "VisualsAura",
		Callback = function(value)
			Settings.visuals_aura = value
		end,
	})

	-- [LOGICA DO CHARACTER CHANGER AQUI]
	rightColumn:Toggle({
		Name = "Character Changer",
		Flag = "VisualsCharacterChanger",
		Callback = function(value)
			Settings.visuals_character_changer = value
		end,
	})

	-- SECCAO "CROSSHAIR" ---------------------------------------------
	rightColumn:Section("CROSSHAIR")

	-- [LOGICA DO CROSSHAIR AQUI]
	rightColumn:Toggle({
		Name = "Crosshair",
		Flag = "VisualsCrosshair",
		Callback = function(value)
			Settings.visuals_crosshair = value
		end,
	})

	-- [LOGICA DO TAMANHO DO CROSSHAIR AQUI]
	rightColumn:Slider({
		Name = "Size",
		Flag = "VisualsCrosshairSize",
		Min = 0,
		Max = 50,
		Step = 1,
		Default = 10,
		Callback = function(value)
			Settings.visuals_crosshair_size = value
		end,
	})

	-- [LOGICA DA ESPESSURA DO CROSSHAIR AQUI]
	rightColumn:Slider({
		Name = "Thickness",
		Flag = "VisualsCrosshairThickness",
		Min = 0,
		Max = 20,
		Step = 1,
		Default = 2,
		Callback = function(value)
			Settings.visuals_crosshair_thickness = value
		end,
	})

	-- [LOGICA DO PONTO DO CROSSHAIR AQUI]
	rightColumn:Toggle({
		Name = "Dot",
		Flag = "VisualsCrosshairDot",
		Callback = function(value)
			Settings.visuals_crosshair_dot = value
		end,
	})

	-- [LOGICA DE ESCONDER O HUD AQUI]
	rightColumn:Toggle({
		Name = "Hide HUD",
		Flag = "VisualsHideHud",
		Callback = function(value)
			Settings.visuals_hide_hud = value
		end,
	})

	return visualsTab
end
