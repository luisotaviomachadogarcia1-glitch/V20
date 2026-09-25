-- ═══════════════════════════════════════════════════════════════════════
--   TORNADO ABSORVENTE v20.0  |  Delta Android
--   Todos os blocos do mapa voam para você em espiral (tornado)
--   Efeito visível para todos no servidor via NetworkOwnership
-- ═══════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ═══════════════════════ CONFIGURAÇÕES ═══════════════════════
local CONFIG = {
    Ativado = false,
    Raio = 150,              -- Alcance de sucção
    Velocidade = 80,         -- Velocidade de sucção
    AlturaTornado = 45,      -- Altura visual do tornado
    Rotacao = 6,             -- Força de rotação (rad/frame)
    AntiQueda = true,        -- Impede cair do mundo
    EfeitoVisual = true,     -- Cria tornado visual
    Som = true,              -- Som do tornado
}

local blocosControlados = {}    -- [parte] = {giro, velocidade, corOrig, matOrig}
local conexoes = {}
local partesTornado = {}        -- Partes visuais do tornado
local somTornado = nil
local efeitoParticulas = nil
local conexaoAntiQueda = nil
local ultimaPosicaoSegura = nil

-- ═══════════════════════ NETWORK OWNERSHIP ═══════════════════════
local function pegarOwnership(parte)
    pcall(function()
        parte:SetNetworkOwner(player)
    end)
end

-- ═══════════════════════ GUI ═══════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TornadoGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999

local Janela = Instance.new("Frame")
Janela.Name = "Janela"
Janela.Parent = ScreenGui
Janela.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
Janela.BorderSizePixel = 0
Janela.Position = UDim2.new(0.05, 0, 0.15, 0)
Janela.Size = UDim2.new(0, 290, 0, 480)
Janela.Active = true
Janela.ClipsDescendants = true

local Canto = Instance.new("UICorner")
Canto.CornerRadius = UDim.new(0, 10)
Canto.Parent = Janela

local Gradiente = Instance.new("UIGradient")
Gradiente.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
}
Gradiente.Rotation = 90
Gradiente.Parent = Janela

-- ─── Barra de título ───
local BarraTitulo = Instance.new("Frame")
BarraTitulo.Name = "BarraTitulo"
BarraTitulo.Parent = Janela
BarraTitulo.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
BarraTitulo.BorderSizePixel = 0
BarraTitulo.Size = UDim2.new(1, 0, 0, 38)

local CantoTitulo = Instance.new("UICorner")
CantoTitulo.CornerRadius = UDim.new(0, 10)
CantoTitulo.Parent = BarraTitulo

local Titulo = Instance.new("TextLabel")
Titulo.Parent = BarraTitulo
Titulo.BackgroundTransparency = 1
Titulo.Position = UDim2.new(0, 12, 0, 0)
Titulo.Size = UDim2.new(1, -85, 1, 0)
Titulo.Font = Enum.Font.GothamBold
Titulo.Text = "🌀 Tornado v20.0"
Titulo.TextColor3 = Color3.fromRGB(120, 200, 255)
Titulo.TextSize = 15
Titulo.TextXAlignment = Enum.TextXAlignment.Left

local BotaoMin = Instance.new("TextButton")
BotaoMin.Parent = BarraTitulo
BotaoMin.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
BotaoMin.BorderSizePixel = 0
BotaoMin.Position = UDim2.new(1, -70, 0, 6)
BotaoMin.Size = UDim2.new(0, 28, 0, 26)
BotaoMin.Font = Enum.Font.GothamBold
BotaoMin.Text = "—"
BotaoMin.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoMin.TextSize = 16

local CantoMin = Instance.new("UICorner")
CantoMin.CornerRadius = UDim.new(0, 5)
CantoMin.Parent = BotaoMin

local BotaoFechar = Instance.new("TextButton")
BotaoFechar.Parent = BarraTitulo
BotaoFechar.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
BotaoFechar.BorderSizePixel = 0
BotaoFechar.Position = UDim2.new(1, -36, 0, 6)
BotaoFechar.Size = UDim2.new(0, 28, 0, 26)
BotaoFechar.Font = Enum.Font.GothamBold
BotaoFechar.Text = "×"
BotaoFechar.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoFechar.TextSize = 18

local CantoFechar = Instance.new("UICorner")
CantoFechar.CornerRadius = UDim.new(0, 5)
CantoFechar.Parent = BotaoFechar

-- ─── Área de conteúdo ───
local Area = Instance.new("ScrollingFrame")
Area.Parent = Janela
Area.BackgroundTransparency = 1
Area.Position = UDim2.new(0, 10, 0, 48)
Area.Size = UDim2.new(1, -20, 1, -58)
Area.CanvasSize = UDim2.new(0, 0, 0, 520)
Area.ScrollBarThickness = 5
Area.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
Area.BorderSizePixel = 0

-- ─── Botão principal (LIGAR TORNADO) ───
local BotaoPrincipal = Instance.new("TextButton")
BotaoPrincipal.Parent = Area
BotaoPrincipal.BackgroundColor3 = Color3.fromRGB(70, 100, 180)
BotaoPrincipal.BorderSizePixel = 0
BotaoPrincipal.Position = UDim2.new(0, 0, 0, 0)
BotaoPrincipal.Size = UDim2.new(1, 0, 0, 55)
BotaoPrincipal.Font = Enum.Font.GothamBold
BotaoPrincipal.Text = "🌀 ATIVAR TORNADO"
BotaoPrincipal.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoPrincipal.TextSize = 16

local CantoPrincipal = Instance.new("UICorner")
CantoPrincipal.CornerRadius = UDim.new(0, 8)
CantoPrincipal.Parent = BotaoPrincipal

local GradienteBotao = Instance.new("UIGradient")
GradienteBotao.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 70, 160))
}
GradienteBotao.Parent = BotaoPrincipal

-- ─── Rótulo distância ───
local LabelRaio = Instance.new("TextLabel")
LabelRaio.Parent = Area
LabelRaio.BackgroundTransparency = 1
LabelRaio.Position = UDim2.new(0, 0, 0, 70)
LabelRaio.Size = UDim2.new(1, 0, 0, 20)
LabelRaio.Font = Enum.Font.GothamSemibold
LabelRaio.Text = "🎯 Raio do Tornado: 150"
LabelRaio.TextColor3 = Color3.fromRGB(180, 210, 255)
LabelRaio.TextSize = 13
LabelRaio.TextXAlignment = Enum.TextXAlignment.Left

local SliderRaio = Instance.new("Frame")
SliderRaio.Parent = Area
SliderRaio.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
SliderRaio.BorderSizePixel = 0
SliderRaio.Position = UDim2.new(0, 0, 0, 93)
SliderRaio.Size = UDim2.new(1, 0, 0, 10)

local CantoSliderR = Instance.new("UICorner")
CantoSliderR.CornerRadius = UDim.new(1, 0)
CantoSliderR.Parent = SliderRaio

local FillRaio = Instance.new("Frame")
FillRaio.Parent = SliderRaio
FillRaio.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
FillRaio.BorderSizePixel = 0
FillRaio.Size = UDim2.new(0.7, 0, 1, 0)

local CantoFillR = Instance.new("UICorner")
CantoFillR.CornerRadius = UDim.new(1, 0)
CantoFillR.Parent = FillRaio

local KnobRaio = Instance.new("Frame")
KnobRaio.Parent = SliderRaio
KnobRaio.BackgroundColor3 = Color3.fromRGB(200, 220, 255)
KnobRaio.BorderSizePixel = 0
KnobRaio.Size = UDim2.new(0, 18, 0, 18)
KnobRaio.Position = UDim2.new(0.7, -9, 0, -4)

local CantoKnobR = Instance.new("UICorner")
CantoKnobR.CornerRadius = UDim.new(1, 0)
CantoKnobR.Parent = KnobRaio

-- ─── Rótulo velocidade ───
local LabelVel = Instance.new("TextLabel")
LabelVel.Parent = Area
LabelVel.BackgroundTransparency = 1
LabelVel.Position = UDim2.new(0, 0, 0, 115)
LabelVel.Size = UDim2.new(1, 0, 0, 20)
LabelVel.Font = Enum.Font.GothamSemibold
LabelVel.Text = "💨 Velocidade de Sucção: 80"
LabelVel.TextColor3 = Color3.fromRGB(180, 255, 200)
LabelVel.TextSize = 13
LabelVel.TextXAlignment = Enum.TextXAlignment.Left

local SliderVel = Instance.new("Frame")
SliderVel.Parent = Area
SliderVel.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
SliderVel.BorderSizePixel = 0
SliderVel.Position = UDim2.new(0, 0, 0, 138)
SliderVel.Size = UDim2.new(1, 0, 0, 10)

local CantoSliderV = Instance.new("UICorner")
CantoSliderV.CornerRadius = UDim.new(1, 0)
CantoSliderV.Parent = SliderVel

local FillVel = Instance.new("Frame")
FillVel.Parent = SliderVel
FillVel.BackgroundColor3 = Color3.fromRGB(100, 220, 130)
FillVel.BorderSizePixel = 0
FillVel.Size = UDim2.new(0.35, 0, 1, 0)

local CantoFillV = Instance.new("UICorner")
CantoFillV.CornerRadius = UDim.new(1, 0)
CantoFillV.Parent = FillVel

local KnobVel = Instance.new("Frame")
KnobVel.Parent = SliderVel
KnobVel.BackgroundColor3 = Color3.fromRGB(200, 255, 220)
KnobVel.BorderSizePixel = 0
KnobVel.Size = UDim2.new(0, 18, 0, 18)
KnobVel.Position = UDim2.new(0.35, -9, 0, -4)

local CantoKnobV = Instance.new("UICorner")
CantoKnobV.CornerRadius = UDim.new(1, 0)
CantoKnobV.Parent = KnobVel

-- ─── Toggles ───
local function criarToggle(nome, texto, yPos, valorInicial, callback)
    local botao = Instance.new("TextButton")
    botao.Parent = Area
    botao.BackgroundColor3 = valorInicial and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(50, 50, 70)
    botao.BorderSizePixel = 0
    botao.Position = UDim2.new(0, 0, 0, yPos)
    botao.Size = UDim2.new(1, 0, 0, 36)
    botao.Font = Enum.Font.GothamSemibold
    botao.Text = texto .. (valorInicial and " ✓" or "")
    botao.TextColor3 = Color3.fromRGB(255, 255, 255)
    botao.TextSize = 13

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = botao

    local estado = valorInicial
    botao.MouseButton1Click:Connect(function()
        estado = not estado
        botao.BackgroundColor3 = estado and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(50, 50, 70)
        botao.Text = texto .. (estado and " ✓" or "")
        callback(estado)
    end)
    return botao
end

criarToggle("t1", "🎨 Efeito Visual do Tornado", 165, CONFIG.EfeitoVisual, function(v) CONFIG.EfeitoVisual = v end)
criarToggle("t2", "🔊 Som do Tornado", 207, CONFIG.Som, function(v) CONFIG.Som = v end)
criarToggle("t3", "🛡️ Anti-Queda (não cair do mundo)", 249, CONFIG.AntiQueda, function(v) CONFIG.AntiQueda = v end)

-- ─── Status ───
local LabelStatus = Instance.new("TextLabel")
LabelStatus.Parent = Area
LabelStatus.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
LabelStatus.BorderSizePixel = 0
LabelStatus.Position = UDim2.new(0, 0, 0, 295)
LabelStatus.Size = UDim2.new(1, 0, 0, 55)
LabelStatus.Font = Enum.Font.GothamSemibold
LabelStatus.Text = "Status: Parado"
LabelStatus.TextColor3 = Color3.fromRGB(140, 140, 160)
LabelStatus.TextSize = 12
LabelStatus.TextWrapped = true

local CantoStatus = Instance.new("UICorner")
CantoStatus.CornerRadius = UDim.new(0, 6)
CantoStatus.Parent = LabelStatus

-- ─── Contador de blocos ───
local LabelBlocos = Instance.new("TextLabel")
LabelBlocos.Parent = Area
LabelBlocos.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
LabelBlocos.BorderSizePixel = 0
LabelBlocos.Position = UDim2.new(0, 0, 0, 358)
LabelBlocos.Size = UDim2.new(1, 0, 0, 45)
LabelBlocos.Font = Enum.Font.GothamBold
LabelBlocos.Text = "🧲 Blocos no Tornado: 0"
LabelBlocos.TextColor3 = Color3.fromRGB(120, 200, 255)
LabelBlocos.TextSize = 14

local CantoBlocos = Instance.new("UICorner")
CantoBlocos.CornerRadius = UDim.new(0, 6)
CantoBlocos.Parent = LabelBlocos

-- ─── Info da versão ───
local InfoVersao = Instance.new("TextLabel")
InfoVersao.Parent = Area
InfoVersao.BackgroundTransparency = 1
InfoVersao.Position = UDim2.new(0, 0, 0, 410)
InfoVersao.Size = UDim2.new(1, 0, 0, 40)
InfoVersao.Font = Enum.Font.Gotham
InfoVersao.Text = "v20.0 • Tornado Absorvente\nTodos veem o efeito no servidor"
InfoVersao.TextColor3 = Color3.fromRGB(100, 100, 130)
InfoVersao.TextSize = 10
InfoVersao.TextWrapped = true

-- ═══════════════════════ ARRASTAR JANELA ═══════════════════════
local arrastando = false
local inicioArraste, posInicial

BarraTitulo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        arrastando = true
        inicioArraste = input.Position
        posInicial = Janela.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if arrastando and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - inicioArraste
        Janela.Position = UDim2.new(posInicial.X.Scale, posInicial.X.Offset + delta.X, posInicial.Y.Scale, posInicial.Y.Offset + delta.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        arrastando = false
    end
end)

-- ═══════════════════════ MINIMIZAR ═══════════════════════
local minimizado = false
local tamOriginal = UDim2.new(0, 290, 0, 480)
local tamMin = UDim2.new(0, 290, 0, 42)

BotaoMin.MouseButton1Click:Connect(function()
    minimizado = not minimizado
    local alvo = minimizado and tamMin or tamOriginal
    TweenService:Create(Janela, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = alvo}):Play()
    Area.Visible = not minimizado
    BotaoMin.Text = minimizado and "+" or "—"
end)

BotaoFechar.MouseButton1Click:Connect(function()
    CONFIG.Ativado = false
    limparTudo()
    ScreenGui:Destroy()
end)

-- ═══════════════════════ SLIDERS ═══════════════════════
local function configurarSlider(slider, fill, knob, minV, maxV, passo, callback)
    local arrastandoS = false
    local function atualizar(inputX)
        local relX = inputX - slider.AbsolutePosition.X
        local pct = math.clamp(relX / slider.AbsoluteSize.X, 0, 1)
        local valor = minV + (maxV - minV) * pct
        valor = math.floor(valor / passo) * passo
        valor = math.clamp(valor, minV, maxV)
        local novoPct = (valor - minV) / (maxV - minV)
        fill.Size = UDim2.new(novoPct, 0, 1, 0)
        knob.Position = UDim2.new(novoPct, -9, 0, -4)
        callback(valor)
    end
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastandoS = true
            atualizar(input.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if arrastandoS and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            atualizar(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastandoS = false
        end
    end)
end

configurarSlider(SliderRaio, FillRaio, KnobRaio, 50, 500, 10, function(v)
    CONFIG.Raio = v
    LabelRaio.Text = "🎯 Raio do Tornado: " .. v
end)

configurarSlider(SliderVel, FillVel, KnobVel, 20, 300, 10, function(v)
    CONFIG.Velocidade = v
    LabelVel.Text = "💨 Velocidade de Sucção: " .. v
end)

-- ═══════════════════════ FUNÇÕES BASE ═══════════════════════
local function obterPersonagem()
    local c = player.Character
    if c then return c:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function ehPersonagem(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

local function ehBlocoValido(obj)
    if not obj or not obj.Parent then return false end
    if not obj:IsA("BasePart") then return false end
    if obj:IsA("Terrain") then return false end
    if obj.Anchored then return false end   -- ⚠️ Anti-abismo: ignora ancorados
    if ehPersonagem(obj) then return false end
    if obj:FindFirstAncestorOfClass("Tool") then return false end
    if obj:FindFirstAncestorOfClass("Accessory") then return false end
    if obj.Locked then return false end

    -- Ignora partes gigantes (chão, paredes)
    local tam = obj.Size
    if tam.X > 250 or tam.Y > 250 or tam.Z > 250 then return false end

    return true
end

-- ═══════════════════════ TORNADO VISUAL ═══════════════════════
local function criarTornadoVisual()
    if not CONFIG.EfeitoVisual then return end
    
    -- Remove antigos
    for _, p in ipairs(partesTornado) do
        if p and p.Parent then p:Destroy() end
    end
    partesTornado = {}
    
    -- Cria 3 anéis de partes semi-transparentes que giram
    local numPartes = 24
    for i = 1, numPartes do
        local anguloBase = (i / numPartes) * math.pi * 2
        local altura = (i % 6) * 8
        
        local parte = Instance.new("Part")
        parte.Name = "TornadoVisual_" .. i
        parte.Shape = Enum.PartType.Ball
        parte.Size = Vector3.new(4, 4, 4)
        parte.Material = Enum.Material.Neon
        parte.Color = Color3.fromRGB(120, 200, 255)
        parte.Transparency = 0.4
        parte.Anchored = true
        parte.CanCollide = false
        parte.CanQuery = false
        parte.CanTouch = false
        parte.CastShadow = false
        parte.Parent = Workspace
        
        table.insert(partesTornado, parte)
    end
    
    -- Cria partículas ao redor do jogador
    local raiz = obterPersonagem()
    if raiz then
        local attachment = Instance.new("Attachment")
        attachment.Parent = raiz
        
        efeitoParticulas = Instance.new("ParticleEmitter")
        efeitoParticulas.Texture = "rbxassetid://243098098"
        efeitoParticulas.Rate = 80
        efeitoParticulas.Lifetime = NumberRange.new(0.8, 1.5)
        efeitoParticulas.Speed = NumberRange.new(15, 30)
        efeitoParticulas.SpreadAngle = Vector2.new(360, 360)
        efeitoParticulas.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 2),
            NumberSequenceKeypoint.new(1, 0)
        }
        efeitoParticulas.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }
        efeitoParticulas.Color = ColorSequence.new(Color3.fromRGB(120, 200, 255))
        efeitoParticulas.Parent = attachment
    end
end

local function destruirTornadoVisual()
    for _, p in ipairs(partesTornado) do
        if p and p.Parent then p:Destroy() end
    end
    partesTornado = {}
    
    if efeitoParticulas and efeitoParticulas.Parent then
        efeitoParticulas:Destroy()
    end
    efeitoParticulas = nil
end

local function animarTornadoVisual(dt)
    if not CONFIG.EfeitoVisual then return end
    local raiz = obterPersonagem()
    if not raiz then return end
    
    local centro = raiz.Position
    local t = tick()
    
    for i, parte in ipairs(partesTornado) do
        if parte and parte.Parent then
            local idx = i - 1
            local pct = (idx % 8) / 8
            local altura = pct * CONFIG.AlturaTornado
            local raioAqui = (1 - pct * 0.5) * 12 + 4
            local angulo = t * CONFIG.Rotacao + (idx * math.pi * 2 / 8)
            
            local posX = centro.X + math.cos(angulo) * raioAqui
            local posZ = centro.Z + math.sin(angulo) * raioAqui
            local posY = centro.Y + altura
            
            parte.CFrame = CFrame.new(posX, posY, posZ)
            parte.Size = Vector3.new(3 + pct * 2, 3 + pct * 2, 3 + pct * 2)
            parte.Transparency = 0.3 + pct * 0.4
        end
    end
end

-- ═══════════════════════ SOM DO TORNADO ═══════════════════════
local function iniciarSom()
    if not CONFIG.Som then return end
    pcall(function()
        somTornado = Instance.new("Sound")
        somTornado.SoundId = "rbxassetid://9066773685" -- Som ambiente de vento
        somTornado.Volume = 2
        somTornado.Looped = true
        somTornado.Parent = Workspace
        somTornado:Play()
    end)
end

local function pararSom()
    if somTornado then
        pcall(function()
            somTornado:Stop()
            somTornado:Destroy()
        end)
        somTornado = nil
    end
end

-- ═══════════════════════ ANTI-QUEDA ═══════════════════════
local function iniciarAntiQueda()
    if conexaoAntiQueda then conexaoAntiQueda:Disconnect() end
    
    conexaoAntiQueda = RunService.Heartbeat:Connect(function()
        if not CONFIG.AntiQueda then return end
        local raiz = obterPersonagem()
        if not raiz then return end
        
        -- Se cair abaixo de -50 studs do último ponto seguro, teleporta de volta
        if raiz.Position.Y < -50 then
            if ultimaPosicaoSegura then
                raiz.CFrame = CFrame.new(ultimaPosicaoSegura + Vector3.new(0, 5, 0))
                raiz.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            else
                raiz.CFrame = CFrame.new(0, 50, 0)
            end
        end
        
        -- Atualiza posição segura se estiver acima do chão
        if raiz.Position.Y > 0 then
            ultimaPosicaoSegura = raiz.Position
        end
    end)
end

-- ═══════════════════════ NÚCLEO: SUCÇÃO EM ESPIRAL ═══════════════════════
local function controlarBloco(parte)
    if not parte or not parte.Parent or blocosControlados[parte] then return end
    if not ehBlocoValido(parte) then return end
    
    local raiz = obterPersonagem()
    if not raiz then return end
    
    pegarOwnership(parte)
    
    local ancoradoOrig = parte.Anchored
    local corOrig = parte.Color
    local matOrig = parte.Material
    
    parte.Anchored = false
    parte.CanCollide = false
    
    -- Aplica material neon para efeito visual
    pcall(function()
        parte.Material = Enum.Material.Neon
        parte.Color = Color3.fromRGB(120, 200, 255)
    end)
    
    -- Giro (para ficar rodando)
    local giro = Instance.new("BodyGyro")
    giro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    giro.P = 40000
    giro.D = 500
    giro.CFrame = parte.CFrame
    giro.Parent = parte
    
    -- Velocidade (para voar até você)
    local velocidade = Instance.new("BodyVelocity")
    velocidade.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    velocidade.Velocity = Vector3.new(0, 0, 0)
    velocidade.Parent = parte
    
    blocosControlados[parte] = {
        giro = giro,
        velocidade = velocidade,
        corOriginal = corOrig,
        materialOriginal = matOrig,
        ancoradoOriginal = ancoradoOrig,
    }
end

local function atualizarBlocos()
    local raiz = obterPersonagem()
    if not raiz then return end
    
    local centro = raiz.Position
    local t = tick()
    
    local paraRemover = {}
    
    for parte, dados in pairs(blocosControlados) do
        if not parte or not parte.Parent then
            paraRemover[parte] = true
        else
            local distancia = (parte.Position - centro).Magnitude
            
            -- Se muito longe, para de controlar
            if distancia > CONFIG.Raio * 1.8 then
                paraRemover[parte] = true
            else
                -- Movimento em espiral: combina direção radial + tangencial + subida
                local direcaoRadial = (centro - parte.Position)
                local distanciaRadial = direcaoRadial.Magnitude
                
                if distanciaRadial > 3 then
                    direcaoRadial = direcaoRadial.Unit
                else
                    direcaoRadial = Vector3.new(0, 0, 0)
                end
                
                -- Componente tangencial (rotação em espiral)
                local up = Vector3.new(0, 1, 0)
                local tangencial = direcaoRadial:Cross(up)
                if tangencial.Magnitude > 0 then
                    tangencial = tangencial.Unit
                end
                
                -- Sobe um pouco (efeito tornado)
                local subir = Vector3.new(0, 1, 0) * 5
                
                -- Velocidade final (espiral)
                local velFinal = (direcaoRadial * CONFIG.Velocidade) + (tangencial * CONFIG.Velocidade * 0.8) + subir
                dados.velocidade.Velocity = velFinal
                
                -- Giro contínuo
                dados.giro.CFrame = dados.giro.CFrame * CFrame.Angles(math.rad(15), math.rad(20), math.rad(10))
            end
        end
    end
    
    -- Remove blocos que sumiram
    for parte in pairs(paraRemover) do
        local dados = blocosControlados[parte]
        if dados then
            if dados.giro then pcall(function() dados.giro:Destroy() end) end
            if dados.velocidade then pcall(function() dados.velocidade:Destroy() end) end
            if parte and parte.Parent then
                pcall(function()
                    parte.Material = dados.materialOriginal
                    parte.Color = dados.corOriginal
                    parte:SetNetworkOwner(nil)
                end)
            end
            blocosControlados[parte] = nil
        end
    end
end

local function escanear()
    local raiz = obterPersonagem()
    if not raiz then return end
    local centro = raiz.Position
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if ehBlocoValido(obj) and not blocosControlados[obj] then
            local d = (obj.Position - centro).Magnitude
            if d <= CONFIG.Raio then
                controlarBloco(obj)
            end
        end
    end
end

function limparTudo()
    for parte, dados in pairs(blocosControlados) do
        if parte and parte.Parent then
            if dados.giro then pcall(function() dados.giro:Destroy() end) end
            if dados.velocidade then pcall(function() dados.velocidade:Destroy() end) end
            pcall(function()
                parte.Material = dados.materialOriginal
                parte.Color = dados.corOriginal
                parte:SetNetworkOwner(nil)
            end)
        end
    end    blocosControlados = {}
    
    for _, c in pairs(conexoes) do
        pcall(function() c:Disconnect() end)
    end
    conexoes = {}
end

-- ═══════════════════════ LOOP PRINCIPAL ═══════════════════════
local conexaoPrincipal = nil
local conexaoTornado = nil
local conexaoScan = nil

local function iniciarTornado()
    CONFIG.Ativado = true
    
    -- Anti-queda
    iniciarAntiQueda()
    
    -- Visual
    criarTornadoVisual()
    
    -- Som
    iniciarSom()
    
    -- Loop que atualiza posição dos blocos
    conexaoPrincipal = RunService.Heartbeat:Connect(function(dt)
        if not CONFIG.Ativado then return end
        atualizarBlocos()
    end)
    
    -- Loop que anima o tornado visual
    conexaoTornado = RunService.RenderStepped:Connect(function(dt)
        if not CONFIG.Ativado then return end
        animarTornadoVisual(dt)
    end)
    
    -- Loop de escaneamento
    conexaoScan = task.spawn(function()
        while CONFIG.Ativado and ScreenGui and ScreenGui.Parent do
            escanear()
            task.wait(0.5)
        end
    end)
end

local function pararTornado()
    CONFIG.Ativado = false
    
    if conexaoPrincipal then conexaoPrincipal:Disconnect() end
    if conexaoTornado then conexaoTornado:Disconnect() end
    conexaoPrincipal = nil
    conexaoTornado = nil
    
    destruirTornadoVisual()
    pararSom()
    limparTudo()
end

-- ═══════════════════════ BOTÃO PRINCIPAL ═══════════════════════
BotaoPrincipal.MouseButton1Click:Connect(function()
    if CONFIG.Ativado then
        pararTornado()
        BotaoPrincipal.Text = "🌀 ATIVAR TORNADO"
        Titulo.Text = "🌀 Tornado v20.0"
        Titulo.TextColor3 = Color3.fromRGB(120, 200, 255)
        LabelStatus.Text = "Status: Parado"
        LabelStatus.TextColor3 = Color3.fromRGB(140, 140, 160)
    else
        iniciarTornado()
        BotaoPrincipal.Text = "🌀 DESATIVAR TORNADO"
        Titulo.Text = "🌀 Tornado v20.0 [ATIVO]"
        Titulo.TextColor3 = Color3.fromRGB(100, 255, 150)
        LabelStatus.Text = "Status: SUGANDO BLOCOS! 🌪️"
        LabelStatus.TextColor3 = Color3.fromRGB(100, 255, 150)
    end
end)

-- ═══════════════════════ ATUALIZAÇÃO DE STATUS ═══════════════════════
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        task.wait(0.5)
        
        local count = 0
        for p in pairs(blocosControlados) do
            if p and p.Parent then count = count + 1 end
        end
        
        LabelBlocos.Text = "🧲 Blocos no Tornado: " .. count
        
        -- Cor do contador baseado na quantidade
        if count > 50 then
            LabelBlocos.TextColor3 = Color3.fromRGB(255, 100, 100)
        elseif count > 20 then
            LabelBlocos.TextColor3 = Color3.fromRGB(255, 200, 100)
        else
            LabelBlocos.TextColor3 = Color3.fromRGB(120, 200, 255)
        end
    end
end)

-- ═══════════════════════ AO RENASCER ═══════════════════════
player.CharacterAdded:Connect(function()
    task.wait(1)
    if CONFIG.Ativado then
        limparTudo()
        criarTornadoVisual()
    end
end)

print("╔════════════════════════════════════════╗")
print("║   🌀 TORNADO ABSORVENTE v20.0 🌀      ║")
print("║   GUI carregada com sucesso!          ║")
print("╚════════════════════════════════════════╝")
