-- =====================================================================
-- tabs/server.lua - aba SERVER
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : SERVER (botoes e informacao do servidor)
--   coluna direita  : HOPPER (troca de servidor) + MISC (opcoes)
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "SERVER" (icone "server")
	-- -----------------------------------------------------------------
	local serverTab = window:CreateTab({ Name = "SERVER" }, "server")

	local leftColumn = serverTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = serverTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "SERVER" -------------------------------------------------
	leftColumn:Section("SERVER")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Button({
		Name = "Copy Server Link",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Button({
		Name = "Rejoin Server",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Auto Rejoin",
		Flag = "ServerAutoRejoin",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Delay",
				Flag = "ServerAutoRejoinDelay",
				Min = 0,
				Max = 10000,
				Step = 100,
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
	leftColumn:Toggle({
		Name = "Teleport To Spawn",
		Flag = "ServerTeleportSpawn",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Safe Spot",
				Flag = "ServerTeleportSpawnSafe",
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

	-- SECCAO "HOPPER" ------------------------------------------------
	rightColumn:Section("HOPPER")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Button({
		Name = "Server Hop",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Button({
		Name = "Random Server",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Input({
		Name = "Join Code",
		Placeholder = "Server code",
		Flag = "ServerJoinCode",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Low Ping Only",
		Flag = "ServerLowPing",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Max Ping",
				Flag = "ServerLowPingMax",
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

	-- SECCAO "MISC" ---------------------------------------------------
	rightColumn:Section("MISC")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Server Notifications",
		Flag = "ServerNotifications",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Sound",
				Flag = "ServerNotificationsSound",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Hide Server HUD",
		Flag = "ServerHideHud",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Hide Chat",
				Flag = "ServerHideHudChat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Hide Hotbar",
				Flag = "ServerHideHudHotbar",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	return serverTab
end
