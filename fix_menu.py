import re

with open('airflowui/main.lua', 'r') as f:
    code = f.read()

# 1. Tema BBC Hub (Cinza Escuro)
code = re.sub(r'local\s+\w*THEME\w*\s*=\s*\{.*?\}', '''local DARK_THEME = {
    Accent = Color3.fromRGB(170, 80, 255),
    AccentDark = Color3.fromRGB(90, 40, 160),
    Background = Color3.fromRGB(15, 15, 15),
    Surface = Color3.fromRGB(22, 22, 22),
    Surface2 = Color3.fromRGB(30, 30, 30),
    Surface3 = Color3.fromRGB(40, 40, 40),
    Stroke = Color3.fromRGB(50, 50, 50),
    Text = Color3.fromRGB(255, 255, 255),
    Muted = Color3.fromRGB(160, 160, 160)
}''', code, flags=re.DOTALL)

# 2. Trocar as Abas
code = re.sub(r'local\s+Tab\w+\s*=\s*Window:Tab\(.*?\)', '''local TabVisuals = Window:Tab({ Title = "VISUALS", Icon = "eye" })
local TabPlayer = Window:Tab({ Title = "PLAYER", Icon = "user" })
local TabCombat = Window:Tab({ Title = "COMBAT", Icon = "target" })
local TabWorld = Window:Tab({ Title = "WORLD", Icon = "globe" })
local TabMisc = Window:Tab({ Title = "MISC", Icon = "grid" })
local TabLoot = Window:Tab({ Title = "LOOTFINDER", Icon = "search" })
local TabServer = Window:Tab({ Title = "SERVER", Icon = "server" })''', code, count=1)

# 3. Adicionar Fundo Hexagonal
hex = '''
-- Fundo Hexagonal
task.spawn(function()
    task.wait(1)
    if Window and Window.Main then
        local HexBg = Instance.new("ImageLabel")
        HexBg.Parent = Window.Main
        HexBg.Size = UDim2.new(1, 0, 1, 0)
        HexBg.BackgroundTransparency = 1
        HexBg.Image = "rbxassetid://12629542321"
        HexBg.ScaleType = Enum.ScaleType.Tile
        HexBg.TileSize = UDim2.new(0, 50, 0, 50)
        HexBg.ImageColor3 = Color3.fromRGB(20, 20, 20)
        HexBg.ImageTransparency = 0.8
        HexBg.ZIndex = -1
    end
end)
'''
if "Fundo Hexagonal" not in code:
    code += hex

with open('airflowui/main.lua', 'w') as f:
    f.write(code)
print("SUCESSO! main.lua modificado com as cores e abas do BBC Hub.")
