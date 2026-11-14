# AirflowUI

Menu do **Airflow** (biblioteca `AirFlowLibrary.luau`) com o layout do
**BBC Hub**: cada aba tem duas colunas lado a lado, cada secao tem o seu
cabecalho e a logica pesada fica em marcadores.

## Ficheiros

```
AirflowUI/
  main.lua          entrada: biblioteca, tema, janela, fundo hexagonal,
                    watermark, painel de keybinds, tabela Settings
  build.py          junta as 7 abas num bundle (dist/airflowui.lua)
  teste_misc.lua    teste da aba MISC sozinha
  tabs/
    visuals.lua     aba VISUALS
    players.lua     aba PLAYER
    combat.lua      aba COMBAT
    world.lua       aba WORLD
    misc.lua        aba MISC
    lootfinder.lua  aba LOOTFINDER
    server.lua      aba SERVER
```

As abas aparecem na sidebar sempre por esta ordem: **VISUALS, PLAYER,
COMBAT, WORLD, MISC, LOOTFINDER, SERVER**.

A biblioteca é buscada na internet com `game:HttpGet`, a partir da RAW do
GitHub (`https://raw.githubusercontent.com/guivn56/Flow/main/AirFlowLibrary.luau`).
Se a rede falhar, há fallback para `/sdcard/Download/AirFlowLibrary.luau`.

## Como uma aba e feita

Cada ficheiro em `tabs/` devolve uma funcao que recebe o contexto e
constroi a aba:

```lua
return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	local tab = window:CreateTab({ Name = "COMBAT" }, "crosshair")
	local left = tab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local right = tab:Groupbox({ Name = "", Side = "Right", PopOut = false })
	ctx.plainColumn(left)
	ctx.plainColumn(right)

	left:Section("AIM")
	left:Toggle({
		Name = "Silent Aim",
		Flag = "CombatSilentAim",
		Callback = function(value)
			Settings.combat_silent_aim = value
		end,
	})
	return tab
end
```

O `ctx` leva quatro coisas:

| Campo | Para que serve |
|---|---|
| `Library` | a biblioteca AirFlow (tema, cores) |
| `window` | a janela onde criar o tab |
| `Settings` | a tabela de estado partilhada por todas as abas |
| `plainColumn` | esconde a barra do groupbox e o painel da coluna (as colunas do BBC Hub nao os usam: cada control e um cartao) |

## Regras

1. **Duas colunas** por aba: `Groupbox({ Side = "Left" })` e
   `Groupbox({ Side = "Right" })`, e `ctx.plainColumn` nas duas.
2. **Secoes** com o nome em maiusculas (`AIM`, `SOUNDS`, `DETECT`, ...).
3. **Logica em marcadores**: nenhum botao tem logica. Todos os callbacks
   fazem `print("Botão alterado")` e deixam o comentario
   `-- [INSERIR LOGICA AQUI]` onde a feature vai ser implementada.
4. **Flags** em todos os widgets: e o que permite guardar a config.
5. **Uma aba que falhe nao leva o menu abaixo**: o `main.lua` carrega
   cada aba num `pcall` e avisa no console.

## Sub menu de um toggle

Um toggle pode levar as opcoes extras dentro de um painel que abre por
baixo dele: o icone "☰" da esquerda passa a ser o botao que abre e fecha
o painel (o clique no cartao continua a ligar/desligar o toggle).

```lua
	left:Toggle({
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
```

| `Type` | control que aparece dentro do painel |
|---|---|
| `Slider` | `Min`, `Max`, `Step`, `Default`, `Suffix` |
| `Dropdown` | `Options`, `Default` |
| `Toggle` | `Default` (ligado/desligado) |
| `Button`, `Input`, `Keybind`, `Label`, `Paragraph` | as opcoes do control |

Cada spec aceita as mesmas opcoes do control normal (`Flag`, `Callback`,
`Desc`, ...). O painel vive na mesma coluna do toggle, por isso a coluna
cresce com ele e a rolagem no telemóvel continua a funcionar.

Na aba COMBAT ha dois exemplos: o **Silent Aim** (`Hit Chance`,
`Target Part`) e o **Aimbot** (`Smoothness`, `Prediction`).

## Correr

- Menu completo: cola o `main.lua` no executor (ele busca a biblioteca no
  GitHub com `game:HttpGet` e as abas de
  `/sdcard/Delta/Workspace/AirflowUI/tabs`).
- So a aba MISC: cola o `teste_misc.lua`.

## Visual

O `main.lua` monta:

1. **Tema cinza escuro** (`Background` 15,15,15 · `Surface` 22,22,22 ·
   `Surface2` 30,30,30 · `Stroke` 50,50,50) com o **roxo** (170,80,255)
   só nos botões e no texto branco.
2. **Janela** `AirflowUI` (760x520), que se ajusta ao ecra sozinha.
3. **Fundo hexagonal** em mosaico (`rbxassetid://12629542321`, tile 50x50,
   `ZIndex` -1, transparencia 0.8) por baixo do conteudo da janela.
4. **Watermark** no topo central da tela (0.5, 0, 10): o nome do hub e o
   relogio com o tempo que o script corre.
5. **Painel de keybinds** no canto superior direito: RShift (UI), LAlt
   (Cursor), Equals (Auto Run), G (Fly), X (Third Person), Z (Zoom), C
   (Lock), B (Activation), J (Aim Parts), MB3 (Add Friend), U
   (Underground). So e informativo: nenhuma tecla e lida aqui.
6. **Colunas do BBC Hub**: o painel da coluna fica transparente e cada
   control (toggle, slider, ...) vira um cartao com fundo, cantos e
   contorno proprios, com 6 px de espaco entre eles.
7. **Rolagem**: cada aba vive num `ScrollingFrame` com a barra de 4 px.

## Validar sem o jogo

O harness corre a biblioteca e o menu num mock do Roblox (headless) e
confere que as abas e os widgets aparecem:

```
/tmp/opencode/airflow_check/check.sh
```

`build_suite.py` embute os ficheiros do dispositivo no harness (o luau
CLI nao tem `io`) e o `mock_tmp/roblox.lua` e o mock do RoboX com os
patches necessarios (`mock_patches.patch` mostra o diff para o mock do
repo).
