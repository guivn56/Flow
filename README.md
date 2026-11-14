# Flow

**AirflowUI** - menu de executor para Roblox em Luau, construido com a
**AirFlowLibrary** (neste repo), com o layout do **BBC Hub**: cada aba
tem DUAS COLUNAS lado a lado, cada secao tem o seu cabecalho e a logica
pesada fica em marcadores.

Corre em executores de **PC** (Synapse X, Fluxus, Script-Ware, AWP, Codex)
e de **mobile** (Delta, Arceus, Hydrogen, Solara).

---

## Link RAW (o artefacto)

```
https://raw.githubusercontent.com/guivn56/Flow/main/dist/airflowui.lua
```

Um ficheiro, sem `require`, sem a pasta `tabs/` no telemóvel: as 7 abas
vao embutidas. A biblioteca é buscada na internet com `game:HttpGet`
(da RAW do GitHub), por isso já não precisa do ficheiro
`/sdcard/Download/AirFlowLibrary.luau` no telemóvel:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/guivn56/Flow/main/AirFlowLibrary.luau"))()
```

| | |
|---|---|
| tamanho | 74 075 bytes |
| sha256 | `1cc9bcc688c7ccb97e28e5854ee114748da504891415a06c3e0083f6b3bf838a` |

---

## O visual (upgrade "premium", estilo BBC Hub)

| | |
|---|---|
| **Cartao por control** | cada toggle, slider, dropdown, input e keybind tem o **seu proprio fundo** (`Card`, `rgb(25,25,30)`), com **UICorner** e um **UIStroke** subtil. As colunas ficam transparentes: os controlos flutuam sobre o fundo da janela. |
| **Espacamento** | 6 px entre os cartoes de uma coluna (o `UIListLayout` do groupbox), para nada ficar grudado. |
| **Icono do toggle** | uma marca (o "☰" desenhado com formas, ou um icone lucide se passares `Icon = "..."`) do lado esquerdo do nome. Fica **roxa** com o toggle ligado e **cinzenta** com o toggle desligado. |
| **Watermark + timer** | uma caixa no **topo central da tela** com o nome do hub e o tempo que o script corre (`os.clock()`), em escuro, com cantos arredondados e contorno na cor do tema. |

A biblioteca ganhou uma cor nova no tema, `Card`. Se um tema nao a definir, ela
e derivada da propria `Surface2` do tema.

```lua
-- na biblioteca
window:CreateWatermark({ Name = "Airflow" })   -- marca + relogio no topo da tela
```

O `main.lua` cria a marca e o tema roxo completo (nao so a cor de destaque).

---

## O menu expansivel (sub menu do toggle)

O icone **"☰"** do lado esquerdo de um toggle pode ser um **botao**: ele
abre e fecha um **painel por baixo do toggle**, com as opcoes extras
dentro. E o mesmo para as colunas do BBC Hub: o painel e um cartao como
os outros, entalado, e os controlos de dentro ficam cartoes pequenos.

```lua
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
```

| | |
|---|---|
| **`SubElements`** | lista de specs. Cada spec e um `{ Type = "...", ... }` com as mesmas opcoes do control (o `Type` e `Slider`, `Dropdown`, `Toggle`, `Button`, `Input`, `Keybind`, `Label` ou `Paragraph`). Tambem aceita a forma mapa: `{ Slider = { { ... } }, Dropdown = { { ... } } }`. |
| **O icone** | com `SubElements`, o "☰" vira o botao que abre o painel (o clique no cartao continua a ligar/desligar o toggle). Fica com a cor do destaque enquanto o painel esta aberto. |
| **O painel** | abre como uma gaveta (0.26 s) por baixo do toggle, dentro da mesma coluna. Os controlos de dentro sao cartoes normais, com os mesmos flags e a mesma `Settings`. |
| **A rolagem** | o `CanvasSize` do `ScrollingFrame` da aba segue o conteudo: quando o painel abre ou fecha, a coluna cresce ou encolhe e a rolagem no telemóvel continua a apanhar o ultimo cartao. |
| **Fechar** | dobrar a coluna, esconder o toggle ou fechar o painel fecha tambem o que estiver aberto dentro dele (um dropdown, por exemplo). |

Na aba **COMBAT** ha dois exemplos: o **Silent Aim** (com `Hit Chance` e
`Target Part`) e o **Aimbot** (com `Smoothness` e `Prediction`).

---

## O que esta no repo

```
AirFlowLibrary.luau   a biblioteca do Airflow (o menu em si)
airflowui/
  main.lua            entrada: biblioteca, tema, janela, fundo hexagonal,
                      watermark, painel de keybinds, Settings e as 7 abas
  teste_misc.lua      teste da aba MISC sozinha
  build.py            junta as abas num unico ficheiro
  tabs/               uma aba por ficheiro
dist/
  airflowui.lua       o bundle (o que se cola no executor)
  airflowui.lua.map.json   sha256 por modulo e do bundle
```

## Abas

| Aba | Coluna esquerda | Coluna direita |
|---|---|---|
| **VISUALS** | WORLD | PLAYER · CROSSHAIR |
| **PLAYER** | PLAYERS ESP | ITEMS ESP · RADAR |
| **COMBAT** | AIM | GUN · TRIGGERBOT · KILL AURA |
| **WORLD** | ENVIRONMENT · PHYSICS | WORLD · INTERACTION |
| **MISC** | MISC · SOUNDS | DETECT · VAULT SORT · INVENTORY VIEWER |
| **LOOTFINDER** | LOOT | FILTERS · NOTIFY |
| **SERVER** | SERVER | HOPPER · MISC |

A ordem da sidebar e exactamente esta: VISUALS, PLAYER, COMBAT, WORLD,
MISC, LOOTFINDER, SERVER.

---

## O tema (BBC Hub)

| Cor | Valor |
|---|---|
| `Background` | `rgb(15, 15, 15)` |
| `Surface` | `rgb(22, 22, 22)` |
| `Surface2` | `rgb(30, 30, 30)` |
| `Stroke` | `rgb(50, 50, 50)` |
| `Accent` | `rgb(170, 80, 255)` (so nos botoes) |
| `Text` | branco |

O tema e aplicado **antes** da janela, para tudo ja nascer com as cores
certas.

---

## O fundo hexagonal

Um `ImageLabel` com o padrao hexagonal em mosaico (`rbxassetid://12629542321`,
`TileSize` 50x50, `ImageTransparency` 0.8, `ZIndex` -1) vive dentro do
`Body` da janela: fica por baixo de tudo e desaparece com ela.

---

## O painel de keybinds (canto superior direito)

Uma lista com os atalhos do hub, so informativa (nenhuma tecla e lida
pelo menu):

```
RShift (UI) · LAlt (Cursor) · Equals (Auto Run) · G (Fly) ·
X (Third Person) · Z (Zoom) · C (Lock) · B (Activation) ·
J (Aim Parts) · MB3 (Add Friend) · U (Underground)
```

## Como uma aba e feita

Cada ficheiro em `airflowui/tabs/` devolve `function(ctx)` e recebe:

| Campo | Para que serve |
|---|---|
| `Library` | a biblioteca AirFlow (tema, cores) |
| `window` | a janela onde criar o tab |
| `Settings` | a tabela de estado partilhada por todas as abas |
| `plainColumn` | esconde a barra do groupbox (as colunas do BBC Hub nao a usam) |

Regras:

1. **Duas colunas** por aba: `Groupbox({ Side = "Left" })` e
   `Groupbox({ Side = "Right" })`, com `ctx.plainColumn` nas duas.
2. **Secoes** com o nome em maiusculas (`AIM`, `SOUNDS`, `DETECT`, ...).
3. **Logica em marcadores**: cada callback faz `print("Botão alterado")`
   e fica com o marcador `-- [INSERIR LOGICA AQUI]`.
4. **Flags** em todos os widgets (e o que permite guardar a config).
5. **Uma aba que falhe nao leva o menu abaixo**: o `main.lua` carrega
   cada aba num `pcall` e avisa no console.

Exemplo:

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

## Build

```
python3 airflowui/build.py
```

Escreve `dist/airflowui.lua` (o bundle), `dist/airflowui.lua.map.json` e
`dist/airflowui.lua.source.lua` (a fonte em claro, para os testes
correrem os mesmos bytes). O build e determinista: os mesmos ficheiros
dao sempre o mesmo bundle.

O `main.lua` tem a tabela `EMBEDDED`: o build troca a linha
`local EMBEDDED = {}` pela tabela com as abas embutidas. Por isso o
mesmo ficheiro serve para as duas formas - com bundle (as abas vem de
dentro) e sem bundle (as abas vem do disco).

## Correr

- **Menu completo**: cola o `dist/airflowui.lua` no executor.
- **So a aba MISC**: cola o `airflowui/teste_misc.lua`.

---

Uso interno. Nao redistribuir sem autorizacao.
