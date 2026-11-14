-- =====================================================================
-- tabs/misc.lua - aba MISC
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : MISC (6 toggles) + SOUNDS (input + 2 toggles)
--   coluna direita  : DETECT (4 toggles) + VAULT SORT (3 toggles)
--                      + INVENTORY VIEWER (1 botao)
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "MISC" (icone "grid")
	-- -----------------------------------------------------------------
	local miscTab = window:CreateTab({ Name = "MISC" }, "grid")

	-- DUAS COLUNAS LADO A LADO
	local leftColumn = miscTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = miscTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "MISC" --------------------------------------------------
	leftColumn:Section("MISC")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Fast Trade",
		Flag = "MiscFastTrade",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Trade Delay",
				Flag = "MiscFastTradeDelay",
				Min = 0,
				Max = 1000,
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
	leftColumn:Toggle({
		Name = "Panic Mode",
		Flag = "MiscPanicMode",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Panic Action",
				Flag = "MiscPanicModeAction",
				Options = { "Close Menu", "Hide HUD", "Reset" },
				Default = "Close Menu",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Pass Door",
		Flag = "MiscPassDoor",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Auto Open",
				Flag = "MiscPassDoorAutoOpen",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Screen Effects",
		Flag = "MiscScreenEffects",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Effect",
				Flag = "MiscScreenEffectsType",
				Options = { "None", "Blur", "Vignette", "Flash" },
				Default = "None",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Report Notify",
		Flag = "MiscReportNotify",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Sound",
				Flag = "MiscReportNotifySound",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Join Notify",
		Flag = "MiscJoinNotify",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Sound",
				Flag = "MiscJoinNotifySound",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "SOUNDS" ------------------------------------------------
	leftColumn:Section("SOUNDS")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Input({
		Name = "Add Sound ID",
		Placeholder = "Sound ID",
		Flag = "MiscSoundId",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Jump",
		Flag = "MiscJumpSound",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Volume",
				Flag = "MiscJumpSoundVolume",
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
		Name = "Footsteps",
		Flag = "MiscFootstepsSound",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Volume",
				Flag = "MiscFootstepsSoundVolume",
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

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "DETECT" ------------------------------------------------
	rightColumn:Section("DETECT")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Content Creator",
		Flag = "MiscDetectContentCreator",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "MiscDetectContentCreatorStyle",
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
		Name = "Tester",
		Flag = "MiscDetectTester",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "MiscDetectTesterStyle",
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
		Name = "Moderator",
		Flag = "MiscDetectModerator",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "MiscDetectModeratorStyle",
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
		Name = "Cheater",
		Flag = "MiscDetectCheater",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "MiscDetectCheaterStyle",
				Options = { "Chat", "Window", "Both" },
				Default = "Chat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "VAULT SORT" --------------------------------------------
	rightColumn:Section("VAULT SORT")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Sort By Value",
		Flag = "MiscSortByValue",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Order",
				Flag = "MiscSortByValueOrder",
				Options = { "High to Low", "Low to High" },
				Default = "High to Low",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Sort By Type",
		Flag = "MiscSortByType",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Order",
				Flag = "MiscSortByTypeOrder",
				Options = { "A to Z", "Z to A" },
				Default = "A to Z",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Sort By Name",
		Flag = "MiscSortByName",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Order",
				Flag = "MiscSortByNameOrder",
				Options = { "A to Z", "Z to A" },
				Default = "A to Z",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "INVENTORY VIEWER" -------------------------------------
	rightColumn:Section("INVENTORY VIEWER")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Button({
		Name = "Show Inventory",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	return miscTab
end
