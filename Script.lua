--= Конфигурация =--
local CONFIG = {
    targetPosition = Vector3.new(9602.7, 4086.2, -5357.8),
    safePosition = Vector3.new(8687.2, 4746.2, -6264),
    holdEKeyTime = 1,
    teleportDelay = 0.1,
    toolName = "Luminance",
    resetDelay = 0.5,
    respawnCheckInterval = 1,
    walkSpeed = 16,
    arrivalThreshold = 3,
    maxWalkTime = 2,
    maxDistance = 50,
    maxHeightDifference = 20,
    buttonColors = {
        start = Color3.fromRGB(60, 180, 60),
        pause = Color3.fromRGB(255, 255, 0),
        stop = Color3.fromRGB(255, 0, 0),
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
        "SubZero"
    },
    windowWidth = 380,
    windowHeightNormal = 340,
    windowHeightMobile = 370,
    buttonWidth = 0.9,
    titleHeight = 25,
    ignoreItem = "Luminance"
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
    unexpectedRareItem = nil,
    tooFarFromTarget = false,
    foundItemType = nil
}

--= Создание интерфейса =--
local player = game:GetService("Players").LocalPlayer

-- Проверка на античит
if not game:GetService("RunService"):IsStudio() then
    local antiCheat = player:FindFirstChild("AntiCheat")
    if antiCheat then
        warn("Обнаружен античит! Скрипт может не работать корректно.")
        return
    end
end

-- Удаляем старые версии GUI
if player:FindFirstChild("PlayerGui") then
    for _, oldGui in ipairs(player.PlayerGui:GetChildren()) do
        if oldGui:IsA("ScreenGui") and oldGui.Name:find("AutoFarmGUI") then
            oldGui:Destroy()
        end
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmGUI_"..tostring(math.random(10000,99999))
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function centerFrame()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    return UDim2.new(0.5, -CONFIG.windowWidth/2, 0.5, -(STATE.isMobile and CONFIG.windowHeightMobile or CONFIG.windowHeightNormal)/2)
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, CONFIG.windowWidth, 0, STATE.isMobile and CONFIG.windowHeightMobile or CONFIG.windowHeightNormal)
mainFrame.Position = centerFrame()
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = true
mainFrame.Parent = gui

-- Заголовок с кнопками управления
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, CONFIG.titleHeight)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.7, 0, 1, 0)
titleText.Position = UDim2.new(0, 5, 0, 0)
titleText.Text = "Luminance GUI (Cheat)"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.SourceSansSemibold
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Кнопка сворачивания
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, CONFIG.titleHeight, 0, CONFIG.titleHeight)
minimizeBtn.Position = UDim2.new(1, -CONFIG.titleHeight*2, 0, 0)
minimizeBtn.Text = "_"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 14
minimizeBtn.Parent = titleBar

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, CONFIG.titleHeight, 0, CONFIG.titleHeight)
closeBtn.Position = UDim2.new(1, -CONFIG.titleHeight, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.Parent = titleBar

-- Основной контент
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -CONFIG.titleHeight)
contentFrame.Position = UDim2.new(0, 0, 0, CONFIG.titleHeight)
contentFrame.BackgroundTransparency = 1
contentFrame.Visible = true
contentFrame.Parent = mainFrame

-- Фрейм для редких предметов
local rareItemsFrame = Instance.new("Frame")
rareItemsFrame.Size = UDim2.new(CONFIG.buttonWidth, 0, 0, 100)
rareItemsFrame.Position = UDim2.new((1 - CONFIG.buttonWidth)/2, 0, 0, 10)
rareItemsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
rareItemsFrame.BorderSizePixel = 0
rareItemsFrame.Parent = contentFrame

local rareItemsTitle = Instance.new("TextLabel")
rareItemsTitle.Size = UDim2.new(1, 0, 0, 20)
rareItemsTitle.Text = "Игнорируемые редкие вариации Luminance:"
rareItemsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
rareItemsTitle.BackgroundTransparency = 1
rareItemsTitle.Font = Enum.Font.SourceSansSemibold
rareItemsTitle.TextSize = 14
rareItemsTitle.Parent = rareItemsFrame

local rareItemsScrollingFrame = Instance.new("ScrollingFrame")
rareItemsScrollingFrame.Size = UDim2.new(1, 0, 1, -25)
rareItemsScrollingFrame.Position = UDim2.new(0, 0, 0, 20)
rareItemsScrollingFrame.BackgroundTransparency = 1
rareItemsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
rareItemsScrollingFrame.ScrollBarThickness = 5
rareItemsScrollingFrame.Parent = rareItemsFrame

-- Кнопка смерти для мобильных устройств
local resetBtn
if STATE.isMobile then
    resetBtn = Instance.new("TextButton")
    resetBtn.Name = "MobileReset"
    resetBtn.Size = UDim2.new(CONFIG.buttonWidth, 0, 0, 30)
    resetBtn.Position = UDim2.new((1 - CONFIG.buttonWidth)/2, 0, 0.65, 0)
    resetBtn.Text = "Смерть (для моб.)"
    resetBtn.Font = Enum.Font.SourceSansBold
    resetBtn.TextSize = 14
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    resetBtn.Visible = false
    resetBtn.Parent = contentFrame
end

local function createControlButton(name, yPos, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(CONFIG.buttonWidth, 0, 0, 40)
    btn.Position = UDim2.new((1 - CONFIG.buttonWidth)/2, 0, yPos, 0)
    btn.Text = name:upper()
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.Parent = contentFrame
    return btn
end

local statusDisplay = Instance.new("TextLabel")
statusDisplay.Size = UDim2.new(CONFIG.buttonWidth, 0, 0, 60)
statusDisplay.Position = UDim2.new((1 - CONFIG.buttonWidth)/2, 0, STATE.isMobile and 0.55 or 0.45, 0)
statusDisplay.Text = "СКРИПТ ОСТАНОВЛЕН"
statusDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
statusDisplay.BackgroundTransparency = 1
statusDisplay.Font = Enum.Font.SourceSansSemibold
statusDisplay.TextSize = 18
statusDisplay.TextWrapped = true
statusDisplay.Parent = contentFrame

local attemptsDisplay = Instance.new("TextLabel")
attemptsDisplay.Size = UDim2.new(CONFIG.buttonWidth, 0, 0, 20)
attemptsDisplay.Position = UDim2.new((1 - CONFIG.buttonWidth)/2, 0, STATE.isMobile and 0.75 or 0.65, 0)
attemptsDisplay.Text = "Всего попыток: 0"
attemptsDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
attemptsDisplay.BackgroundTransparency = 1
attemptsDisplay.Font = Enum.Font.SourceSans
attemptsDisplay.TextSize = 14
attemptsDisplay.Parent = contentFrame

local startBtn = createControlButton("Старт", STATE.isMobile and 0.85 or 0.75, CONFIG.buttonColors.start)
local pauseBtn = createControlButton("Пауза", STATE.isMobile and 0.95 or 0.85, CONFIG.buttonColors.inactive)
local stopBtn = createControlButton("Стоп", STATE.isMobile and 1.05 or 0.95, CONFIG.buttonColors.inactive)

-- Создаем кнопки для редких предметов
local function createRareItemButton(itemName, index)
    local btn = Instance.new("TextButton")
    btn.Name = itemName
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.Position = UDim2.new(0, 5, 0, (index-1)*25)
    btn.Text = itemName
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = STATE.ignoredRareItems[itemName] and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(180, 60, 60)
    btn.Parent = rareItemsScrollingFrame
    
    btn.MouseButton1Click:Connect(function()
        STATE.ignoredRareItems[itemName] = not STATE.ignoredRareItems[itemName]
        btn.BackgroundColor3 = STATE.ignoredRareItems[itemName] and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(180, 60, 60)
    end)
    
    rareItemsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #CONFIG.rareItems * 25)
end

-- Инициализация кнопок редких предметов
for i, itemName in ipairs(CONFIG.rareItems) do
    createRareItemButton(itemName, i)
end

-- Функции для управления окном
local function toggleMinimize()
    STATE.minimized = not STATE.minimized
    if STATE.minimized then
        contentFrame.Visible = false
        mainFrame.Size = UDim2.new(0, CONFIG.windowWidth, 0, CONFIG.titleHeight)
        minimizeBtn.Text = "+"
    else
        contentFrame.Visible = true
        mainFrame.Size = UDim2.new(0, CONFIG.windowWidth, 0, STATE.isMobile and CONFIG.windowHeightMobile or CONFIG.windowHeightNormal)
        minimizeBtn.Text = "_"
    end
    mainFrame.Position = centerFrame()
end

local function closeGUI()
    STATE.closed = true
    STATE.running = false
    STATE.paused = false
    STATE.stopped = true
    gui:Destroy()
end

minimizeBtn.MouseButton1Click:Connect(toggleMinimize)
closeBtn.MouseButton1Click:Connect(closeGUI)

--= Основные функции =--
local function teleportToSafePosition()
    local character = player.Character
    if not character then 
        statusDisplay.Text = "Ошибка телепортации: нет персонажа"
        return false 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        statusDisplay.Text = "Ошибка телепортации: нет HumanoidRootPart"
        return false 
    end
    
    -- Проверяем, не находимся ли уже в безопасной точке
    if (humanoidRootPart.Position - CONFIG.safePosition).Magnitude < 10 then
        statusDisplay.Text = "Уже в безопасной точке"
        return true
    end
    
    -- Убедимся, что персонаж жив
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        statusDisplay.Text = "Нельзя телепортировать мертвого персонажа"
        return false
    end
    
    -- Выполняем телепортацию
    local success = pcall(function()
        humanoidRootPart.CFrame = CFrame.new(CONFIG.safePosition)
    end)
    
    if success then
        statusDisplay.Text = "Успешная телепортация!"
        task.wait(1) -- Даем время на завершение телепортации
        return true
    else
        statusDisplay.Text = "Ошибка при телепортации!"
        return false
    end
end

local function hasAnyValuableItems()
    STATE.foundItemType = nil
    STATE.unexpectedRareItem = nil
    
    -- Проверяем наличие любых ценных предметов (из списка или неизвестных)
    for _, item in ipairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name ~= CONFIG.ignoreItem then
            local isKnown = false
            -- Проверяем, есть ли предмет в списке редких
            for _, knownItem in ipairs(CONFIG.rareItems) do
                if item.Name == knownItem then
                    isKnown = true
                    break
                end
            end
            
            -- Если предмет не известен и не игнорируется
            if not isKnown and not STATE.ignoredRareItems[item.Name] then
                STATE.unexpectedRareItem = item.Name
                STATE.foundItemType = "unknown"
                return true, "unknown"
            end
            
            -- Если предмет известен и не игнорируется
            if isKnown and not STATE.ignoredRareItems[item.Name] then
                STATE.rareItemFound = true
                STATE.foundItemType = "rare"
                return true, "rare"
            end
        end
    end
    
    -- Проверяем инструменты в руках персонажа
    if player.Character then
        for _, item in ipairs(player.Character:GetChildren()) do
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
                    STATE.foundItemType = "unknown"
                    return true, "unknown"
                end
                
                if isKnown and not STATE.ignoredRareItems[item.Name] then
                    STATE.rareItemFound = true
                    STATE.foundItemType = "rare"
                    return true, "rare"
                end
            end
        end
    end
    
    return false, nil
end

local function updateUI()
    startBtn.BackgroundColor3 = STATE.running and CONFIG.buttonColors.inactive or CONFIG.buttonColors.start
    pauseBtn.BackgroundColor3 = STATE.running and (STATE.paused and CONFIG.buttonColors.pause or CONFIG.buttonColors.inactive) or CONFIG.buttonColors.inactive
    stopBtn.BackgroundColor3 = STATE.running and CONFIG.buttonColors.stop or CONFIG.buttonColors.inactive
    
    pauseBtn.Text = STATE.paused and "Продолжить" or "Пауза"
    attemptsDisplay.Text = "Всего попыток: "..tostring(STATE.totalAttempts)
    
    if STATE.unexpectedRareItem then
        statusDisplay.Text = string.format("НАЙДЕН НЕИЗВЕСТНЫЙ ПРЕДМЕТ: %s!\nТЕЛЕПОРТАЦИЯ И ОСТАНОВ", STATE.unexpectedRareItem)
    elseif STATE.rareItemFound then
        statusDisplay.Text = "НАЙДЕН РЕДКИЙ ПРЕДМЕТ! ТЕЛЕПОРТАЦИЯ И ОСТАНОВКА СКРИПТА"
    elseif STATE.stopped then
        statusDisplay.Text = string.format("ОСТАНОВЛЕНО | Попыток: %d", STATE.attemptCount)
    elseif STATE.paused then
        statusDisplay.Text = string.format("ПАУЗА | Попытка %d", STATE.attemptCount)
    elseif STATE.isDead then
        statusDisplay.Text = "ПЕРСОНАЖ УМЕР | Ожидание возрождения..."
    elseif STATE.isWalking then
        statusDisplay.Text = string.format("ИДЕТ К ЦЕЛИ | Попытка %d", STATE.attemptCount)
    else
        statusDisplay.Text = string.format("РАБОТАЕТ | Попытка %d", STATE.attemptCount)
    end
    
    if STATE.isMobile and resetBtn then
        resetBtn.Visible = STATE.running and not STATE.paused and not STATE.stopped
    end
end

local function isTooFarFromTarget(position)
    local horizontalDistance = (Vector3.new(position.X, 0, position.Z) - Vector3.new(CONFIG.targetPosition.X, 0, CONFIG.targetPosition.Z)).Magnitude
    local heightDifference = math.abs(position.Y - CONFIG.targetPosition.Y)
    return horizontalDistance > CONFIG.maxDistance or heightDifference > CONFIG.maxHeightDifference
end

local function holdEKey()
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
            
            if isTooFarFromTarget(rootPart.Position) then
                humanoid.Health = 0
                statusDisplay.Text = "СЛИШКОМ ДАЛЕКО | Персонаж умирает..."
                STATE.isWalking = false
                return false
            end
            
            if STATE.isDead or STATE.rareItemFound or STATE.unexpectedRareItem or STATE.closed then
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

local function killCharacter()
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
            return true
        end
    end
    return false
end

local function executeResetSequence()
    local hasItems, itemType = hasAnyValuableItems()
    if hasItems then
        if itemType == "unknown" then
            STATE.unexpectedRareItem = STATE.unexpectedRareItem or "Неизвестный предмет"
        elseif itemType == "rare" then
            STATE.rareItemFound = true
        end
        STATE.running = false
        STATE.stopped = true
        updateUI()
        return
    end
    
    killCharacter()
    task.wait(CONFIG.resetDelay)
end

local function useTool()
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

--= Функции для обработки смерти =--
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
    -- Проверяем наличие любых ценных предметов перед запуском
    local hasItems, itemType = hasAnyValuableItems()
    if hasItems then
        if itemType == "unknown" then
            STATE.unexpectedRareItem = STATE.unexpectedRareItem or "Неизвестный предмет"
            if teleportToSafePosition() then
                task.wait(1)
            end
        elseif itemType == "rare" then
            STATE.rareItemFound = true
            if teleportToSafePosition() then
                task.wait(1)
            end
        end
        STATE.running = false
        STATE.stopped = true
        updateUI()
        return
    end
    
    STATE.attemptCount = 0
    STATE.rareItemFound = false
    STATE.unexpectedRareItem = nil
    
    while not STATE.stopped and not STATE.rareItemFound and not STATE.unexpectedRareItem and not STATE.closed do
        -- Проверяем наличие предметов в начале каждой итерации
        local hasItems, itemType = hasAnyValuableItems()
        if hasItems then
            if itemType == "unknown" then
                STATE.unexpectedRareItem = STATE.unexpectedRareItem or "Неизвестный предмет"
                if teleportToSafePosition() then
                    task.wait(1)
                end
            elseif itemType == "rare" then
                STATE.rareItemFound = true
                if teleportToSafePosition() then
                    task.wait(1)
                end
            end
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
            
            local hasItems, itemType = hasAnyValuableItems()
            if hasItems then
                if itemType == "unknown" then
                    STATE.unexpectedRareItem = STATE.unexpectedRareItem or "Неизвестный предмет"
                    if teleportToSafePosition() then
                        task.wait(1)
                    end
                elseif itemType == "rare" then
                    STATE.rareItemFound = true
                    if teleportToSafePosition() then
                        task.wait(1)
                    end
                end
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
    end
    
    STATE.running = false
    STATE.stopped = true
    STATE.isDead = false
    STATE.isWalking = false
    updateUI()
end

--= Обработчики кнопок =--
startBtn.MouseButton1Click:Connect(function()
    if not STATE.running and STATE.stopped then
        local hasItems, itemType = hasAnyValuableItems()
        if hasItems then
            if itemType == "unknown" then
                STATE.unexpectedRareItem = STATE.unexpectedRareItem or "Неизвестный предмет"
                if teleportToSafePosition() then
                    task.wait(1)
                end
            elseif itemType == "rare" then
                STATE.rareItemFound = true
                if teleportToSafePosition() then
                    task.wait(1)
                end
            end
            STATE.running = false
            STATE.stopped = true
            updateUI()
            return
        end
        
        STATE.running = true
        STATE.stopped = false
        STATE.paused = false
        STATE.attemptCount = 0
        STATE.rareItemFound = false
        STATE.unexpectedRareItem = nil
        updateUI()
        coroutine.wrap(executeScript)()
    end
end)

pauseBtn.MouseButton1Click:Connect(function()
    if STATE.running and not STATE.stopped then
        STATE.paused = not STATE.paused
        updateUI()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    if STATE.running and not STATE.stopped then
        STATE.running = false
        STATE.stopped = true
        STATE.paused = false
        updateUI()
    end
end)

if STATE.isMobile and resetBtn then
    resetBtn.MouseButton1Click:Connect(function()
        if STATE.running and not STATE.stopped and not STATE.paused then
            executeResetSequence()
        end
    end)
end

-- Инициализация интерфейса
updateUI()
