-- =====================================================================
-- tabs/misc.lua - aba MISC
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : MISC (6 toggles) + SOUNDS (input + 2 toggles)
--   coluna direita  : DETECT (4 toggles) + VAULT SORT (3 toggles)
--                      + INVENTORY VIEWER (1 botao)
--
-- O modulo devolve uma funcao que recebe o contexto (ctx) e constroi a
-- aba. A logica pesada fica em marcadores.
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	-- -----------------------------------------------------------------
	-- ABA "MISC" (icone "settings")
	-- -----------------------------------------------------------------
	local miscTab = window:CreateTab({ Name = "MISC" }, "settings")

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

	-- [LOGICA FAST TRADE AQUI]
	leftColumn:Toggle({
		Name = "Fast Trade",
		Flag = "MiscFastTrade",
		Callback = function(value)
			Settings.misc_fast_trade = value
		end,
	})

	-- [LOGICA PANIC MODE AQUI]
	leftColumn:Toggle({
		Name = "Panic Mode",
		Flag = "MiscPanicMode",
		Callback = function(value)
			Settings.misc_panic_mode = value
		end,
	})

	-- [LOGICA PASS DOOR AQUI]
	leftColumn:Toggle({
		Name = "Pass Door",
		Flag = "MiscPassDoor",
		Callback = function(value)
			Settings.misc_pass_door = value
		end,
	})

	-- [LOGICA SCREEN EFFECTS AQUI]
	leftColumn:Toggle({
		Name = "Screen Effects",
		Flag = "MiscScreenEffects",
		Callback = function(value)
			Settings.misc_screen_effects = value
		end,
	})

	-- [LOGICA REPORT NOTIFY AQUI]
	leftColumn:Toggle({
		Name = "Report Notify",
		Flag = "MiscReportNotify",
		Callback = function(value)
			Settings.misc_report_notify = value
		end,
	})

	-- [LOGICA JOIN NOTIFY AQUI]
	leftColumn:Toggle({
		Name = "Join Notify",
		Flag = "MiscJoinNotify",
		Callback = function(value)
			Settings.misc_join_notify = value
		end,
	})

	-- SECCAO "SOUNDS" ------------------------------------------------
	leftColumn:Section("SOUNDS")

	-- [LOGICA DO SOUND ID AQUI]
	local soundId = leftColumn:Input({
		Name = "Add Sound ID",
		Placeholder = "Sound ID",
		Flag = "MiscSoundId",
		Callback = function(value)
			Settings.misc_sound_id = value
		end,
	})

	-- [LOGICA DO SOM DE PULO AQUI]
	leftColumn:Toggle({
		Name = "Jump",
		Flag = "MiscJumpSound",
		Callback = function(value)
			Settings.misc_jump_sound = value
		end,
	})

	-- [LOGICA DOS PASSOS AQUI]
	leftColumn:Toggle({
		Name = "Footsteps",
		Flag = "MiscFootstepsSound",
		Callback = function(value)
			Settings.misc_footsteps_sound = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "DETECT" ------------------------------------------------
	rightColumn:Section("DETECT")

	-- [LOGICA DE DETECTAR CONTENT CREATOR AQUI]
	rightColumn:Toggle({
		Name = "Content Creator",
		Flag = "MiscDetectContentCreator",
		Callback = function(value)
			Settings.misc_detect_content_creator = value
		end,
	})

	-- [LOGICA DE DETECTAR TESTER AQUI]
	rightColumn:Toggle({
		Name = "Tester",
		Flag = "MiscDetectTester",
		Callback = function(value)
			Settings.misc_detect_tester = value
		end,
	})

	-- [LOGICA DE DETECTAR MODERADOR AQUI]
	rightColumn:Toggle({
		Name = "Moderator",
		Flag = "MiscDetectModerator",
		Callback = function(value)
			Settings.misc_detect_moderator = value
		end,
	})

	-- [LOGICA DE DETECTAR CHEATER AQUI]
	rightColumn:Toggle({
		Name = "Cheater",
		Flag = "MiscDetectCheater",
		Callback = function(value)
			Settings.misc_detect_cheater = value
		end,
	})

	-- SECCAO "VAULT SORT" --------------------------------------------
	rightColumn:Section("VAULT SORT")

	-- [LOGICA DE ORDENAR POR VALOR AQUI]
	rightColumn:Toggle({
		Name = "Sort By Value",
		Flag = "MiscSortByValue",
		Callback = function(value)
			Settings.misc_sort_by_value = value
		end,
	})

	-- [LOGICA DE ORDENAR POR TIPO AQUI]
	rightColumn:Toggle({
		Name = "Sort By Type",
		Flag = "MiscSortByType",
		Callback = function(value)
			Settings.misc_sort_by_type = value
		end,
	})

	-- [LOGICA DE ORDENAR POR NOME AQUI]
	rightColumn:Toggle({
		Name = "Sort By Name",
		Flag = "MiscSortByName",
		Callback = function(value)
			Settings.misc_sort_by_name = value
		end,
	})

	-- SECCAO "INVENTORY VIEWER" -------------------------------------
	rightColumn:Section("INVENTORY VIEWER")

	-- [LOGICA DO INVENTORY VIEWER AQUI]
	rightColumn:Button({
		Name = "Show Inventory",
		Callback = function()
			print("[Airflow] Show Inventory")
		end,
	})

	return miscTab
end
