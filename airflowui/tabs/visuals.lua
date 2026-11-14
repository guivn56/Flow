-- =====================================================================
-- tabs/visuals.lua - aba VISUALS
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : WORLD
--   coluna direita  : PLAYER + CROSSHAIR
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

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

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Fullbright",
		Flag = "VisualsFullbright",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Intensity",
				Flag = "VisualsFullbrightIntensity",
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

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "No Fog",
		Flag = "VisualsNoFog",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Fog End",
				Flag = "VisualsNoFogEnd",
				Min = 0,
				Max = 1000,
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
	leftColumn:Toggle({
		Name = "Bloom",
		Flag = "VisualsBloom",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Bloom Intensity",
				Flag = "VisualsBloomIntensity",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 20,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Grass",
		Flag = "VisualsGrass",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Grass State",
				Flag = "VisualsGrassState",
				Options = { "Keep", "Low", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Trees",
		Flag = "VisualsTrees",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Tree State",
				Flag = "VisualsTreesState",
				Options = { "Keep", "Low", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Terrain",
		Flag = "VisualsTerrain",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Detail",
				Flag = "VisualsTerrainDetail",
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

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Water",
		Flag = "VisualsWater",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Water Style",
				Flag = "VisualsWaterStyle",
				Options = { "Keep", "Clear", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Time of Day",
		Flag = "VisualsTimeOfDay",
		Min = 0,
		Max = 24,
		Step = 1,
		Default = 14,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Brightness",
		Flag = "VisualsBrightness",
		Min = 0,
		Max = 5,
		Step = 1,
		Default = 2,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "PLAYER" ------------------------------------------------
	rightColumn:Section("PLAYER")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Chams",
		Flag = "VisualsChams",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Chams Style",
				Flag = "VisualsChamsStyle",
				Options = { "Outline", "Fill", "Both" },
				Default = "Outline",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Slider",
				Name = "Chams Size",
				Flag = "VisualsChamsSize",
				Min = 0,
				Max = 20,
				Step = 1,
				Default = 4,
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
		Name = "Force Field",
		Flag = "VisualsForceField",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Hide Others",
				Flag = "VisualsForceFieldHideOthers",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Halo",
		Flag = "VisualsHalo",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Halo Size",
				Flag = "VisualsHaloSize",
				Min = 0,
				Max = 20,
				Step = 1,
				Default = 6,
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
		Name = "Trail",
		Flag = "VisualsTrail",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Trail Style",
				Flag = "VisualsTrailStyle",
				Options = { "Line", "Particle", "Both" },
				Default = "Line",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Aura",
		Flag = "VisualsAura",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Aura Size",
				Flag = "VisualsAuraSize",
				Min = 0,
				Max = 20,
				Step = 1,
				Default = 4,
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
		Name = "Character Changer",
		Flag = "VisualsCharacterChanger",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Body",
				Flag = "VisualsCharacterBody",
				Options = { "Default", "Blocky", "Pro", "Slim" },
				Default = "Default",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "CROSSHAIR" ---------------------------------------------
	rightColumn:Section("CROSSHAIR")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Crosshair",
		Flag = "VisualsCrosshair",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Style",
				Flag = "VisualsCrosshairStyle",
				Options = { "Cross", "Dot", "Circle", "T" },
				Default = "Cross",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Slider({
		Name = "Size",
		Flag = "VisualsCrosshairSize",
		Min = 0,
		Max = 50,
		Step = 1,
		Default = 10,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Slider({
		Name = "Thickness",
		Flag = "VisualsCrosshairThickness",
		Min = 0,
		Max = 20,
		Step = 1,
		Default = 2,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Dot",
		Flag = "VisualsCrosshairDot",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Dot Size",
				Flag = "VisualsCrosshairDotSize",
				Min = 0,
				Max = 20,
				Step = 1,
				Default = 3,
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
		Name = "Hide HUD",
		Flag = "VisualsHideHud",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Hide Chat",
				Flag = "VisualsHideHudChat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Hide Hotbar",
				Flag = "VisualsHideHudHotbar",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	return visualsTab
end
