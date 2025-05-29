--= Конфигурация =--
local CONFIG = {
    targetPosition = Vector3.new(9602.7, 4086.2, -5357.8),
    holdEKeyTime = 1,
    teleportDelay = 0.1,
    toolName = "Luminance",
    resetDelay = 0.5,
    respawnCheckInterval = 1,
    walkSpeed = 16,
    arrivalThreshold = 3,
    maxWalkTime = 2,
    buttonColors = {
        start = Color3.fromRGB(60, 180, 60),
        pause = Color3.fromRGB(200, 150, 0),
        stop = Color3.fromRGB(180, 60, 60),
        inactive = Color3.fromRGB(100, 100, 100)
    },
    rareItems = {
        "ElectroDarkness",
        "Star Seeker",
        "Melancholia",
        "Lunar Illusion",
        "NovaInterstellar",
        "Frost Stellar",
        "Frostelar",
        "Cosmical Aurora",
        "Colossal White",
        "Luminous Stellar",
        "Existential Conqueror",
        "TON-618"
    },
    windowWidth = 380,
    windowHeightNormal = 360,
    windowHeightMobile = 390,
    buttonWidth = 0.85,
    titleHeight = 30,
    ignoreItem = "Luminance",
    buttonSpacing = 5,
    borderColor = Color3.fromRGB(0, 162, 255),
    backgroundColor = Color3.fromRGB(30, 30, 30),
    titleColor = Color3.fromRGB(45, 45, 45)
}

--= Состояния скрипта =--
local STATE = {
    running = false,
    paused = false,
    stopped = true,
    attemptCount = 0,
    totalAttempts = 0,
    isDead = false,
    rareItemFound = false,
    ignoredRareItems = {},
    isMobile = game:GetService("UserInputService").TouchEnabled,
    isWalking = false,
    walkAttempts = 0,
    minimized = false,
    closed = false,
    unexpectedRareItem = nil
}

--= Создание интерфейса =--
local player = game:GetService("Players").LocalPlayer

-- Удаление старых версий GUI
pcall(function()
    for _, oldGui in ipairs(player.PlayerGui:GetChildren()) do
        if oldGui:IsA("ScreenGui") and oldGui.Name:find("AutoFarmGUI") then
            oldGui:Destroy()
        end
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmGUI_"..tostring(math.random(10000,99999))
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function centerFrame()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    return UDim2.new(0.5, -CONFIG.windowWidth/2, 0.5, -(STATE.isMobile and CONFIG.windowHeightMobile or CONFIG.windowHeightNormal)/2)
end

-- Основной контейнер с обводкой
local mainFrameContainer = Instance.new("Frame")
mainFrameContainer.Size = UDim2.new(0, CONFIG.windowWidth + 6, 0, (STATE.isMobile and CONFIG.windowHeightMobile or CONFIG.windowHeightNormal) + 6)
mainFrameContainer.Position = centerFrame()
mainFrameContainer.BackgroundColor3 = CONFIG.borderColor
mainFrameContainer.BorderSizePixel = 0
mainFrameContainer.Active = true
mainFrameContainer.Parent = gui

-- Основной фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, -4, 1, -4)
mainFrame.Position = UDim2.new(0, 2, 0, 2)
mainFrame.BackgroundColor3 = CONFIG.backgroundColor
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = true
mainFrame.Parent = mainFrameContainer

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, CONFIG.titleHeight)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = CONFIG.titleColor
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.7, 0, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.Text = "★ Auto Farm ★"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.SourceSansSemibold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Кнопки управления окном
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, CONFIG.titleHeight, 0, CONFIG.titleHeight)
minimizeBtn.Position = UDim2.new(1, -CONFIG.titleHeight*2 - 5, 0, 0)
minimizeBtn.Text = "_"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
minimizeBtn.BorderSizePixel = 1
minimizeBtn.BorderColor3 = Color3.fromRGB(100, 100, 100)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 16
minimizeBtn.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, CONFIG.titleHeight, 0, CONFIG.titleHeight)
closeBtn.Position = UDim2.new(1, -CONFIG.titleHeight - 5, 0, 0)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.BorderSizePixel = 1
closeBtn.BorderColor3 = Color3.fromRGB(200, 80, 80)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18
closeBtn.Parent = titleBar

-- Основное содержимое
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -CONFIG.titleHeight)
contentFrame.Position = UDim2.new(0, 0, 0, CONFIG.titleHeight)
contentFrame.BackgroundTransparency = 1
contentFrame.Visible = true
contentFrame.Parent = mainFrame

-- Фрейм редких предметов
local rareItemsFrame = Instance.new("Frame")
rareItemsFrame.Size = UDim2.new(CONFIG.buttonWidth, 0, 0, 120)
rareItemsFrame.Position = UDim2.new((1 - CONFIG.buttonWidth)/2, 0, 0, 10)
rareItemsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
rareItemsFrame.BorderSizePixel = 1
rareItemsFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
rareItemsFrame.Parent = contentFrame

local rareItemsTitle = Instance.new("TextLabel")
rareItemsTitle.Size = UDim2.new(1, 0, 0, 25)
rareItemsTitle.Text = "Игнорируемые редкие предметы:"
rareItemsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
rareItemsTitle.BackgroundTransparency = 1
rareItemsTitle.Font = Enum.Font.SourceSansSemibold
rareItemsTitle.TextSize = 14
rareItemsTitle.Parent = rareItemsFrame

local rareItemsScrollingFrame = Instance.new("ScrollingFrame")
rareItemsScrollingFrame.Size = UDim2.new(1, -5, 1, -30)
rareItemsScrollingFrame.Position = UDim2.new(0, 5, 0, 25)
rareItemsScrollingFrame.BackgroundTransparency = 1
rareItemsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
rareItemsScrollingFrame.ScrollBarThickness = 5
rareItemsScrollingFrame.Parent = rareItemsFrame

-- Кнопки управления
local function createControlButton(name, yPos, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(CONFIG.buttonWidth, 0, 0, 38)
    btn.Position = UDim2.new((1 - CONFIG.buttonWidth)/2, 0, yPos, 0)
    btn.Text = name:upper()
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(
        math.min(255, color.R * 255 + 30),
        math.min(255, color.G * 255 + 30),
        math.min(255, color.B * 255 + 30)
    )
    btn.Parent = contentFrame
    return btn
end

local startBtn = createControlButton("Старт", 0.15, CONFIG.buttonColors.start)
local pauseBtn = createControlButton("Пауза", 0.15 + 0.1 + CONFIG.buttonSpacing/360, CONFIG.buttonColors.inactive)
local stopBtn = createControlButton("Стоп", 0.15 + 0.2 + (CONFIG.buttonSpacing*2)/360, CONFIG.buttonColors.inactive)

-- Статусная панель
local statusDisplay = Instance.new("TextLabel")
statusDisplay.Size = UDim2.new(CONFIG.buttonWidth, 0, 0, 70)
statusDisplay.Position = UDim2.new((1 - CONFIG.buttonWidth)/2, 0, STATE.isMobile and 0.58 or 0.48, 0)
statusDisplay.Text = "СКРИПТ ОСТАНОВЛЕН\nВсего попыток: 0"
statusDisplay.TextColor3 = Color3.fromRGB(220, 220, 220)
statusDisplay.BackgroundTransparency = 1
statusDisplay.Font = Enum.Font.SourceSansSemibold
statusDisplay.TextSize = 16
statusDisplay.TextWrapped = true
statusDisplay.Parent = contentFrame

-- Кнопки редких предметов
for i, itemName in ipairs(CONFIG.rareItems) do
    local btn = Instance.new("TextButton")
    btn.Name = itemName
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.Position = UDim2.new(0, 5, 0, (i-1)*28)
    btn.Text = " "..itemName
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BackgroundColor3 = STATE.ignoredRareItems[itemName] and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(180, 60, 60)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(100, 100, 100)
    btn.Parent = rareItemsScrollingFrame
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 20, 1, 0)
    icon.Position = UDim2.new(1, -25, 0, 0)
    icon.Text = STATE.ignoredRareItems[itemName] and "✓" or "✗"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.SourceSansBold
    icon.TextSize = 14
    icon.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        STATE.ignoredRareItems[itemName] = not STATE.ignoredRareItems[itemName]
        btn.BackgroundColor3 = STATE.ignoredRareItems[itemName] and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(180, 60, 60)
        icon.Text = STATE.ignoredRareItems[itemName] and "✓" or "✗"
    end)
    
    rareItemsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #CONFIG.rareItems * 28)
end

--= Функции управления =--
local function toggleMinimize()
    STATE.minimized = not STATE.minimized
    if STATE.minimized then
        contentFrame.Visible = false
        mainFrameContainer.Size = UDim2.new(0, CONFIG.windowWidth + 6, 0, CONFIG.titleHeight + 6)
        minimizeBtn.Text = "+"
    else
        contentFrame.Visible = true
        mainFrameContainer.Size = UDim2.new(0, CONFIG.windowWidth + 6, 0, (STATE.isMobile and CONFIG.windowHeightMobile or CONFIG.windowHeightNormal) + 6)
        minimizeBtn.Text = "_"
    end
    mainFrameContainer.Position = centerFrame()
end

local function closeGUI()
    STATE.closed = true
    STATE.running = false
    STATE.stopped = true
    gui:Destroy()
end

minimizeBtn.MouseButton1Click:Connect(toggleMinimize)
closeBtn.MouseButton1Click:Connect(closeGUI)

--= Основные функции =--
local function updateUI()
    startBtn.BackgroundColor3 = STATE.running and CONFIG.buttonColors.inactive or CONFIG.buttonColors.start
    pauseBtn.BackgroundColor3 = STATE.running and (STATE.paused and CONFIG.buttonColors.pause or CONFIG.buttonColors.inactive) or CONFIG.buttonColors.inactive
    stopBtn.BackgroundColor3 = STATE.running and CONFIG.buttonColors.stop or CONFIG.buttonColors.inactive
    
    pauseBtn.Text = STATE.paused and "ПРОДОЛЖИТЬ" or "ПАУЗА"
    
    local statusText = ""
    if STATE.unexpectedRareItem then
        statusText = string.format("НАЙДЕН НЕИЗВЕСТНЫЙ ЦЕННЫЙ ПРЕДМЕТ: %s!\nСКРИПТ ОСТАНОВЛЕН", STATE.unexpectedRareItem)
    elseif STATE.rareItemFound then
        statusText = "НАЙДЕН РЕДКИЙ ПРЕДМЕТ! СКРИПТ ОСТАНОВЛЕН"
    elseif STATE.stopped then
        statusText = string.format("ОСТАНОВЛЕНО | Текущая попытка: %d", STATE.attemptCount)
    elseif STATE.paused then
        statusText = string.format("ПАУЗА | Текущая попытка: %d", STATE.attemptCount)
    elseif STATE.isDead then
        statusText = "ПЕРСОНАЖ УМЕР | Ожидание возрождения..."
    elseif STATE.isWalking then
        statusText = string.format("ИДЕТ К ЦЕЛИ | Попытка %d", STATE.attemptCount)
    else
        statusText = string.format("РАБОТАЕТ | Попытка %d", STATE.attemptCount)
    end
    
    statusDisplay.Text = statusText..string.format("\nВсего попыток: %d", STATE.totalAttempts)
end

local function checkForRareItems()
    for _, item in ipairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name ~= CONFIG.ignoreItem then
            local isKnown = false
            for _, knownItem in ipairs(CONFIG.rareItems) do
                if item.Name == knownItem then
                    isKnown = true
                    break
                end
            end
            
            if not isKnown and not STATE.ignoredRareItems[item.Name] then
                STATE.unexpectedRareItem = item.Name
                return true
            end
        end
    end
    
    for _, itemName in ipairs(CONFIG.rareItems) do
        if not STATE.ignoredRareItems[itemName] then
            for _, item in ipairs(player.Backpack:GetChildren()) do
                if item.Name == itemName then
                    return true
                end
            end
            
            if player.Character then
                for _, item in ipairs(player.Character:GetChildren()) do
                    if item:IsA("Tool") and item.Name == itemName then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function holdEKey()
    if STATE.closed then return false end
    local virtualInput = game:GetService("VirtualInputManager")
    virtualInput:SendKeyEvent(true, "E", false, nil)
    
    local timer = CONFIG.holdEKeyTime
    while timer > 0 and not STATE.stopped and not STATE.closed do
        while STATE.paused and not STATE.stopped and not STATE.closed do
            task.wait(0.1)
        end
        
        if STATE.stopped or STATE.isDead or STATE.rareItemFound or STATE.unexpectedRareItem or STATE.closed then break end
        
        timer -= 0.1
        task.wait(0.1)
    end
    
    virtualInput:SendKeyEvent(false, "E", false, nil)
    return not STATE.stopped and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed
end

local function walkToTarget()
    if STATE.closed then return false end
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    STATE.isWalking = true
    STATE.walkAttempts = 0
    updateUI()
    
    local success = false
    local startTime = os.time()
    
    while not success and STATE.walkAttempts < 3 and not STATE.stopped and not STATE.paused and not STATE.closed do
        STATE.walkAttempts += 1
        startTime = os.time()
        
        humanoid:MoveTo(CONFIG.targetPosition)
        
        while (rootPart.Position - CONFIG.targetPosition).Magnitude > CONFIG.arrivalThreshold 
              and (os.time() - startTime) < CONFIG.maxWalkTime 
              and not STATE.stopped 
              and not STATE.paused 
              and not STATE.closed do
            
            if STATE.isDead or STATE.rareItemFound or STATE.unexpectedRareItem then
                STATE.isWalking = false
                return false
            end
            task.wait(0.1)
        end
        
        if (rootPart.Position - CONFIG.targetPosition).Magnitude <= CONFIG.arrivalThreshold then
            success = true
        else
            statusDisplay.Text = string.format("Попытка %d | Повтор движения...", STATE.attemptCount)
            task.wait(0.5)
        end
    end
    
    STATE.isWalking = false
    return success and not STATE.stopped and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed
end

local function executeResetSequence()
    if STATE.closed then return end
    if checkForRareItems() then
        STATE.rareItemFound = true
        STATE.running = false
        STATE.stopped = true
        updateUI()
        return
    end
    
    if STATE.isMobile then
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    else
        local virtualInput = game:GetService("VirtualInputManager")
        virtualInput:SendKeyEvent(true, "Escape", false, nil)
        task.wait(0.05)
        virtualInput:SendKeyEvent(false, "Escape", false, nil)
        task.wait(CONFIG.resetDelay)
        virtualInput:SendKeyEvent(true, "R", false, nil)
        task.wait(0.05)
        virtualInput:SendKeyEvent(false, "R", false, nil)
        task.wait(CONFIG.resetDelay)
        virtualInput:SendKeyEvent(true, "Return", false, nil)
        task.wait(0.05)
        virtualInput:SendKeyEvent(false, "Return", false, nil)
    end
end

local function useTool()
    if STATE.closed then return false end
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool.Name == CONFIG.toolName and tool:IsA("Tool") then
            humanoid:EquipTool(tool)
            task.wait(0.3)
            
            local success = pcall(function()
                if tool:FindFirstChild("RemoteEvent") then
                    tool.RemoteEvent:FireServer()
                elseif tool:FindFirstChild("RemoteFunction") then
                    tool.RemoteFunction:InvokeServer()
                end
            end)
            
            return success
        end
    end
    return false
end

--= Обработка смерти =--
local function onCharacterAdded(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        STATE.isDead = true
        STATE.attemptCount += 1
        STATE.totalAttempts += 1
        updateUI()
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

local function waitForRespawn()
    while STATE.isDead and not STATE.stopped and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            STATE.isDead = false
            return true
        end
        task.wait(CONFIG.respawnCheckInterval)
    end
    return not STATE.stopped and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed
end

--= Главный цикл =--
local function executeScript()
    if STATE.closed then return end
    STATE.attemptCount = 0
    STATE.rareItemFound = false
    STATE.unexpectedRareItem = nil
    STATE.totalAttempts += 1
    
    while not STATE.stopped and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed do
        if checkForRareItems() then
            STATE.rareItemFound = true
            break
        end
        
        if STATE.isDead then
            if not waitForRespawn() then break end
        end
        
        if not walkToTarget() then break end
        
        statusDisplay.Text = string.format("Попытка %d | Зажатие E", STATE.attemptCount)
        
        if not holdEKey() then break end
        
        statusDisplay.Text = string.format("Попытка %d | Поиск %s", STATE.attemptCount, CONFIG.toolName)
        local toolFound = useTool()
        
        if toolFound then
            statusDisplay.Text = string.format("Попытка %d | Проверка предметов...", STATE.attemptCount)
            task.wait(0.5)
            
            if checkForRareItems() then
                STATE.rareItemFound = true
                break
            end
            
            statusDisplay.Text = string.format("Попытка %d | Сброс...", STATE.attemptCount)
            executeResetSequence()
            task.wait(1)
        end
        
        local cooldown = 1
        while cooldown > 0 and not STATE.stopped and not STATE.isDead and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed do
            while STATE.paused and not STATE.stopped and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed do
                task.wait(0.1)
            end
            
            if STATE.stopped or STATE.rareItemFound or STATE.unexpectedRareItem or STATE.closed then break end
            cooldown -= 0.1
            task.wait(0.1)
        end
        
        STATE.attemptCount += 1
    end
    
    STATE.running = false
    STATE.stopped = true
    STATE.isDead = false
    STATE.isWalking = false
    updateUI()
end

--= Обработчики событий =--
startBtn.MouseButton1Click:Connect(function()
    if not STATE.running and not STATE.closed then
        STATE.running = true
        STATE.paused = false
        STATE.stopped = false
        STATE.isDead = false
        STATE.rareItemFound = false
        STATE.unexpectedRareItem = nil
        updateUI()
        coroutine.wrap(executeScript)()
    end
end)

pauseBtn.MouseButton1Click:Connect(function()
    if STATE.running and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed then
        STATE.paused = not STATE.paused
        updateUI()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    if (STATE.running or STATE.paused) and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed then
        STATE.stopped = true
        STATE.running = false
        STATE.paused = false
        STATE.isDead = false
        STATE.isWalking = false
        updateUI()
    end
end)

--= Инициализация =--
updateUI()

-- Дополнительная проверка GUI
delay(2, function()
    if not gui or not gui.Parent or not mainFrameContainer or not mainFrameContainer.Visible then
        warn("GUI не отображается, скрипт остановлен")
        STATE.closed = true
        STATE.running = false
        STATE.stopped = true
    end
end)
