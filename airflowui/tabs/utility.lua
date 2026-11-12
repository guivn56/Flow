-- =====================================================================
-- tabs/utility.lua - aba UTILITY
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : LOOT
--   coluna direita  : MOVEMENT + FREECAM + BOSS CHECKER
--
-- A logica pesada fica em marcadores.
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	-- -----------------------------------------------------------------
	-- ABA "UTILITY" (icone "wrench")
	-- -----------------------------------------------------------------
	local utilityTab = window:CreateTab({ Name = "UTILITY" }, "wrench")

	local leftColumn = utilityTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = utilityTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "LOOT" --------------------------------------------------
	leftColumn:Section("LOOT")

	-- [LOGICA DO AUTO LOOT AQUI]
	leftColumn:Toggle({
		Name = "Auto Loot",
		Flag = "UtilityAutoLoot",
		Callback = function(value)
			Settings.utility_auto_loot = value
		end,
	})

	-- [LOGICA DO INSTA LOOT AQUI]
	leftColumn:Toggle({
		Name = "Insta Loot",
		Flag = "UtilityInstaLoot",
		Callback = function(value)
			Settings.utility_insta_loot = value
		end,
	})

	-- [LOGICA DO LOOT FINDER AQUI]
	leftColumn:Toggle({
		Name = "Loot Finder",
		Flag = "UtilityLootFinder",
		Callback = function(value)
			Settings.utility_loot_finder = value
		end,
	})

	-- [LOGICA DO MAG FINDER AQUI]
	leftColumn:Toggle({
		Name = "Mag Finder",
		Flag = "UtilityMagFinder",
		Callback = function(value)
			Settings.utility_mag_finder = value
		end,
	})

	-- [LOGICA DE SUBSTITUIR POR MAIS BARATO AQUI]
	leftColumn:Toggle({
		Name = "Replace Cheaper",
		Flag = "UtilityReplaceCheaper",
		Callback = function(value)
			Settings.utility_replace_cheaper = value
		end,
	})

	-- [LOGICA DE PEGAR ITEMS LARADOS AQUI]
	leftColumn:Toggle({
		Name = "Pick Up Dropped",
		Flag = "UtilityPickUpDropped",
		Callback = function(value)
			Settings.utility_pick_up_dropped = value
		end,
	})

	-- SECCAO "LOOT RANGE" --------------------------------------------
	leftColumn:Section("LOOT RANGE")

	-- [LOGICA DO RAIO DO AUTO LOOT AQUI]
	leftColumn:Slider({
		Name = "Loot Radius",
		Flag = "UtilityLootRadius",
		Min = 0,
		Max = 100,
		Step = 1,
		Default = 10,
		Suffix = " studs",
		Callback = function(value)
			Settings.utility_loot_radius = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "MOVEMENT" ----------------------------------------------
	rightColumn:Section("MOVEMENT")

	-- [LOGICA DO ALWAYS SPRINT AQUI]
	rightColumn:Toggle({
		Name = "Always Sprint",
		Flag = "UtilityAlwaysSprint",
		Callback = function(value)
			Settings.utility_always_sprint = value
		end,
	})

	-- [LOGICA DO SPEEDHACK AQUI]
	rightColumn:Toggle({
		Name = "Speedhack",
		Flag = "UtilitySpeedhack",
		Callback = function(value)
			Settings.utility_speedhack = value
		end,
	})

	-- [LOGICA DO MULTIPLICADOR DO SPEEDHACK AQUI]
	rightColumn:Slider({
		Name = "Speed Multiplier",
		Flag = "UtilitySpeedMultiplier",
		Min = 1,
		Max = 5,
		Step = 0.1,
		Default = 1.3,
		Callback = function(value)
			Settings.utility_speed_multiplier = value
		end,
	})

	-- [LOGICA DO NO FALL AQUI]
	rightColumn:Toggle({
		Name = "No Fall",
		Flag = "UtilityNoFall",
		Callback = function(value)
			Settings.utility_no_fall = value
		end,
	})

	-- [LOGICA DO JESUS AQUI]
	rightColumn:Toggle({
		Name = "Jesus",
		Flag = "UtilityJesus",
		Callback = function(value)
			Settings.utility_jesus = value
		end,
	})

	-- SECCAO "FREECAM" -----------------------------------------------
	rightColumn:Section("FREECAM")

	-- [LOGICA DA FREECAM AQUI]
	rightColumn:Toggle({
		Name = "Freecam",
		Flag = "UtilityFreecam",
		Callback = function(value)
			Settings.utility_freecam = value
		end,
	})

	-- [LOGICA DA VELOCIDADE DA FREECAM AQUI]
	rightColumn:Slider({
		Name = "Freecam Speed",
		Flag = "UtilityFreecamSpeed",
		Min = 1,
		Max = 500,
		Step = 1,
		Default = 50,
		Callback = function(value)
			Settings.utility_freecam_speed = value
		end,
	})

	-- [LOGICA DO MODO CINEMATICO AQUI]
	rightColumn:Toggle({
		Name = "Cinematic",
		Flag = "UtilityFreecamCinematic",
		Callback = function(value)
			Settings.utility_freecam_cinematic = value
		end,
	})

	-- SECCAO "BOSS CHECKER" ------------------------------------------
	rightColumn:Section("BOSS CHECKER")

	-- [LOGICA DO BOSS CHECKER AQUI]
	rightColumn:Toggle({
		Name = "Boss Checker",
		Flag = "UtilityBossChecker",
		Callback = function(value)
			Settings.utility_boss_checker = value
		end,
	})

	-- [LOGICA DO INTERVALO DO BOSS CHECKER AQUI]
	rightColumn:Slider({
		Name = "Check Interval",
		Flag = "UtilityBossCheckerInterval",
		Min = 1,
		Max = 60,
		Step = 1,
		Default = 5,
		Suffix = " s",
		Callback = function(value)
			Settings.utility_boss_checker_interval = value
		end,
	})

	return utilityTab
end
