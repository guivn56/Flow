-- =====================================================================
-- tabs/combat.lua - aba COMBAT
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : AIM
--   coluna direita  : GUN + TRIGGERBOT + KILL AURA
--
-- A logica pesada fica em marcadores: cada callback escreve o valor na
-- tabela Settings e onde estao os "-- [LOGICA ... AQUI]".
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	-- -----------------------------------------------------------------
	-- ABA "COMBAT" (icone "crosshair")
	-- -----------------------------------------------------------------
	local combatTab = window:CreateTab({ Name = "COMBAT" }, "crosshair")

	local leftColumn = combatTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = combatTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "AIM" ---------------------------------------------------
	leftColumn:Section("AIM")

	-- [LOGICA DO SILENT AIM AQUI]
	--
	-- O toggle traz um SUB MENU: o icone da esquerda (o "☰") vira um
	-- botao que abre uma caixa por baixo do toggle, com as opcoes extras.
	-- O painel cresce com a coluna, por isso a rolagem no telemóvel
	-- continua a funcionar.
	leftColumn:Toggle({
		Name = "Silent Aim",
		Flag = "CombatSilentAim",
		Callback = function(value)
			Settings.combat_silent_aim = value
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Hit Chance",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Slider alterado")
					-- [LOGICA AQUI]
				end,
			},
			{
				Type = "Dropdown",
				Name = "Target Part",
				Options = { "Head", "Torso", "Nearest" },
				Default = "Head",
				Callback = function(value)
					print("Dropdown alterado")
					-- [LOGICA AQUI]
				end,
			},
		},
	})

	-- [LOGICA DO FOV DA MIRA AQUI]
	leftColumn:Slider({
		Name = "Aim FOV",
		Flag = "CombatAimFov",
		Min = 0,
		Max = 720,
		Step = 5,
		Default = 120,
		Suffix = " px",
		Callback = function(value)
			Settings.combat_aim_fov = value
		end,
	})

	-- [LOGICA DO AIMBOT AQUI]
	--
	-- Segundo exemplo de sub menu: o Smoothness e o Prediction deixaram de
	-- ser cartoes soltos na coluna e passaram para dentro do painel do
	-- Aimbot (os flags continuam os mesmos).
	leftColumn:Toggle({
		Name = "Aimbot",
		Flag = "CombatAimbot",
		Callback = function(value)
			Settings.combat_aimbot = value
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Smoothness",
				Flag = "CombatSmoothing",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 30,
				Suffix = " %",
				Callback = function(value)
					Settings.combat_smoothing = value
					print("Slider alterado")
					-- [LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Prediction",
				Flag = "CombatPrediction",
				Callback = function(value)
					Settings.combat_prediction = value
					print("Toggle alterado")
					-- [LOGICA AQUI]
				end,
			},
		},
	})

	-- [LOGICA DO AUTO SHOOT AQUI]
	leftColumn:Toggle({
		Name = "Auto Shoot",
		Flag = "CombatAutoShoot",
		Callback = function(value)
			Settings.combat_auto_shoot = value
		end,
	})

	-- [LOGICA DO STICKY TARGET AQUI]
	leftColumn:Toggle({
		Name = "Sticky Target",
		Flag = "CombatStickyTarget",
		Callback = function(value)
			Settings.combat_sticky_target = value
		end,
	})

	-- [LOGICA DO TEAM CHECK AQUI]
	leftColumn:Toggle({
		Name = "Team Check",
		Flag = "CombatTeamCheck",
		Callback = function(value)
			Settings.combat_team_check = value
		end,
	})

	-- [LOGICA DO FOV CIRCLE AQUI]
	leftColumn:Toggle({
		Name = "FOV Circle",
		Flag = "CombatFovCircle",
		Callback = function(value)
			Settings.combat_fov_circle = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "GUN" ---------------------------------------------------
	rightColumn:Section("GUN")

	-- [LOGICA DO NO RECOIL AQUI]
	rightColumn:Toggle({
		Name = "No Recoil",
		Flag = "CombatNoRecoil",
		Callback = function(value)
			Settings.combat_no_recoil = value
		end,
	})

	-- [LOGICA DA FIRE RATE AQUI]
	rightColumn:Toggle({
		Name = "Fire Rate",
		Flag = "CombatFireRate",
		Callback = function(value)
			Settings.combat_fire_rate = value
		end,
	})

	-- [LOGICA DO AUTO RELOAD AQUI]
	rightColumn:Toggle({
		Name = "Auto Reload",
		Flag = "CombatAutoReload",
		Callback = function(value)
			Settings.combat_auto_reload = value
		end,
	})

	-- [LOGICA DO FAKE SCOPE AQUI]
	rightColumn:Toggle({
		Name = "Fake Scope",
		Flag = "CombatFakeScope",
		Callback = function(value)
			Settings.combat_fake_scope = value
		end,
	})

	-- [LOGICA DA GRENADE PREDICTION AQUI]
	rightColumn:Toggle({
		Name = "Grenade Prediction",
		Flag = "CombatGrenadePrediction",
		Callback = function(value)
			Settings.combat_grenade_prediction = value
		end,
	})

	-- SECCAO "TRIGGERBOT" -------------------------------------------
	rightColumn:Section("TRIGGERBOT")

	-- [LOGICA DO TRIGGERBOT AQUI]
	rightColumn:Toggle({
		Name = "Triggerbot",
		Flag = "CombatTriggerbot",
		Callback = function(value)
			Settings.combat_triggerbot = value
		end,
	})

	-- [LOGICA DA DISTANCIA DO TRIGGERBOT AQUI]
	rightColumn:Slider({
		Name = "Triggerbot Distance",
		Flag = "CombatTriggerbotDistance",
		Min = 0,
		Max = 1000,
		Step = 10,
		Default = 50,
		Suffix = " px",
		Callback = function(value)
			Settings.combat_triggerbot_distance = value
		end,
	})

	-- [LOGICA DO TRIGGERBOT SO EM ADS AQUI]
	rightColumn:Toggle({
		Name = "Only ADS",
		Flag = "CombatTriggerbotOnlyAds",
		Callback = function(value)
			Settings.combat_triggerbot_only_ads = value
		end,
	})

	-- SECCAO "KILL AURA" ---------------------------------------------
	rightColumn:Section("KILL AURA")

	-- [LOGICA DO KILL AURA AQUI]
	rightColumn:Toggle({
		Name = "Kill Aura",
		Flag = "CombatKillAura",
		Callback = function(value)
			Settings.combat_kill_aura = value
		end,
	})

	-- [LOGICA DO ALCANCE DO KILL AURA AQUI]
	rightColumn:Slider({
		Name = "Kill Aura Range",
		Flag = "CombatKillAuraRange",
		Min = 0,
		Max = 100,
		Step = 1,
		Default = 10,
		Suffix = " studs",
		Callback = function(value)
			Settings.combat_kill_aura_range = value
		end,
	})

	-- [LOGICA DO TIPO DE ATAQUE AQUI]
	rightColumn:Dropdown({
		Name = "Attack Type",
		Flag = "CombatKillAuraAttackType",
		Options = { "Power Attack", "Normal", "Heavy", "Light" },
		Default = "Power Attack",
		Callback = function(value)
			Settings.combat_kill_aura_attack = value
		end,
	})

	return combatTab
end
