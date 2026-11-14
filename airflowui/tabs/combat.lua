-- =====================================================================
-- tabs/combat.lua - aba COMBAT
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : AIM
--   coluna direita  : GUN + TRIGGERBOT + KILL AURA
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
--
-- O toggle traz um SUB MENU: o icone da esquerda (o "☰") vira um
-- botao que abre uma caixa por baixo do toggle, com as opcoes extras.
-- O painel cresce com a coluna, por isso a rolagem no telemóvel
-- continua a funcionar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

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

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Silent Aim",
		Flag = "CombatSilentAim",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Hit Chance",
				Flag = "CombatSilentAimHitChance",
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
			{
				Type = "Dropdown",
				Name = "Target Part",
				Flag = "CombatSilentAimTargetPart",
				Options = { "Head", "Torso", "Nearest" },
				Default = "Head",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Aim FOV",
		Flag = "CombatAimFov",
		Min = 0,
		Max = 720,
		Step = 5,
		Default = 120,
		Suffix = " px",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Aimbot",
		Flag = "CombatAimbot",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Smoothness",
				Flag = "CombatAimbotSmoothness",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 30,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Prediction",
				Flag = "CombatAimbotPrediction",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Auto Shoot",
		Flag = "CombatAutoShoot",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Delay",
				Flag = "CombatAutoShootDelay",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 50,
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
		Name = "Sticky Target",
		Flag = "CombatStickyTarget",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Stick Delay",
				Flag = "CombatStickyTargetDelay",
				Min = 0,
				Max = 500,
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
		Name = "Team Check",
		Flag = "CombatTeamCheck",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Team Mode",
				Flag = "CombatTeamCheckMode",
				Options = { "Skip", "Ignore", "Block" },
				Default = "Skip",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "FOV Circle",
		Flag = "CombatFovCircle",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Circle Size",
				Flag = "CombatFovCircleSize",
				Min = 10,
				Max = 720,
				Step = 5,
				Default = 120,
				Suffix = " px",
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

	-- SECCAO "GUN" ---------------------------------------------------
	rightColumn:Section("GUN")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "No Recoil",
		Flag = "CombatNoRecoil",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Recoil Power",
				Flag = "CombatNoRecoilPower",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 100,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Fire Rate",
		Flag = "CombatFireRate",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Rate",
				Flag = "CombatFireRateValue",
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
	rightColumn:Toggle({
		Name = "Auto Reload",
		Flag = "CombatAutoReload",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Reload Delay",
				Flag = "CombatAutoReloadDelay",
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
	rightColumn:Toggle({
		Name = "Fake Scope",
		Flag = "CombatFakeScope",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Zoom",
				Flag = "CombatFakeScopeZoom",
				Min = 1,
				Max = 10,
				Step = 1,
				Default = 3,
				Suffix = " x",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Grenade Prediction",
		Flag = "CombatGrenadePrediction",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Prediction Mode",
				Flag = "CombatGrenadePredictionMode",
				Options = { "Line", "Arc", "Both" },
				Default = "Line",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "TRIGGERBOT" -------------------------------------------
	rightColumn:Section("TRIGGERBOT")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Triggerbot",
		Flag = "CombatTriggerbot",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Only ADS",
				Flag = "CombatTriggerbotOnlyAds",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Slider",
				Name = "Trigger Delay",
				Flag = "CombatTriggerbotDelay",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 50,
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
		Name = "Triggerbot Distance",
		Flag = "CombatTriggerbotDistance",
		Min = 0,
		Max = 1000,
		Step = 10,
		Default = 50,
		Suffix = " px",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- SECCAO "KILL AURA" ---------------------------------------------
	rightColumn:Section("KILL AURA")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Kill Aura",
		Flag = "CombatKillAura",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Attack Type",
				Flag = "CombatKillAuraAttackType",
				Options = { "Power Attack", "Normal", "Heavy", "Light" },
				Default = "Power Attack",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Slider",
				Name = "Kill Aura Range",
				Flag = "CombatKillAuraRange",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 10,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Dropdown({
		Name = "Target Team",
		Flag = "CombatKillAuraTargetTeam",
		Options = { "Enemy", "Other", "All" },
		Default = "Enemy",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	return combatTab
end
