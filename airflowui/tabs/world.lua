-- =====================================================================
-- tabs/world.lua - aba WORLD
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : ENVIRONMENT + PHYSICS
--   coluna direita  : WORLD + INTERACTION
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "WORLD" (icone "globe")
	-- -----------------------------------------------------------------
	local worldTab = window:CreateTab({ Name = "WORLD" }, "globe")

	local leftColumn = worldTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = worldTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "ENVIRONMENT" -------------------------------------------
	leftColumn:Section("ENVIRONMENT")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Time of Day",
		Flag = "WorldTimeOfDay",
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
	leftColumn:Dropdown({
		Name = "Weather",
		Flag = "WorldWeather",
		Options = { "Clear", "Rain", "Storm", "Snow" },
		Default = "Clear",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Brightness",
		Flag = "WorldBrightness",
		Min = 0,
		Max = 5,
		Step = 1,
		Default = 2,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Fog",
		Flag = "WorldFog",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Fog Density",
				Flag = "WorldFogDensity",
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
		Name = "Clouds",
		Flag = "WorldClouds",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Cloud Style",
				Flag = "WorldCloudsStyle",
				Options = { "Keep", "Light", "Heavy", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "PHYSICS" -----------------------------------------------
	leftColumn:Section("PHYSICS")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Gravity",
		Flag = "WorldGravity",
		Min = 0,
		Max = 500,
		Step = 5,
		Default = 196,
		Suffix = " studs/s",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Jump Power",
		Flag = "WorldJumpPower",
		Min = 0,
		Max = 200,
		Step = 1,
		Default = 50,
		Suffix = " studs",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Walk Speed",
		Flag = "WorldWalkSpeed",
		Min = 0,
		Max = 100,
		Step = 1,
		Default = 16,
		Suffix = " studs/s",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Bunny Hop",
		Flag = "WorldBunnyHop",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Hop Height",
				Flag = "WorldBunnyHopHeight",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 20,
				Suffix = " studs",
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

	-- SECCAO "WORLD" -------------------------------------------------
	rightColumn:Section("WORLD")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Doors",
		Flag = "WorldDoors",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Door State",
				Flag = "WorldDoorsState",
				Options = { "Keep", "Open", "Closed", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Windows",
		Flag = "WorldWindows",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Window State",
				Flag = "WorldWindowsState",
				Options = { "Keep", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Props",
		Flag = "WorldProps",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Prop State",
				Flag = "WorldPropsState",
				Options = { "Keep", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Vehicles",
		Flag = "WorldVehicles",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Name",
				Flag = "WorldVehiclesName",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "INTERACTION" -------------------------------------------
	rightColumn:Section("INTERACTION")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Auto Open",
		Flag = "WorldAutoOpen",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Open Delay",
				Flag = "WorldAutoOpenDelay",
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

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Auto Close",
		Flag = "WorldAutoClose",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Close Delay",
				Flag = "WorldAutoCloseDelay",
				Min = 0,
				Max = 5000,
				Step = 10,
				Default = 1000,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Slider({
		Name = "Interact Distance",
		Flag = "WorldInteractDistance",
		Min = 0,
		Max = 100,
		Step = 1,
		Default = 10,
		Suffix = " studs",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	return worldTab
end
