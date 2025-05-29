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
    }
}

--= Состояния скрипта =--
local STATE = {
    running = false,
    paused = false,
    stopped = true,
    attemptCount = 0,
    isDead = false,
    rareItemFound = false,
    ignoredRareItems = {},
    isMobile = game:GetService("UserInputService").TouchEnabled,
    isWalking = false,
    walkAttempts = 0,
    minimized = false,
    closed = false
}

--= Создание интерфейса =--
local player = game:GetService("Players").LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmGUI_"..tostring(math.random(10000,99999))
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, STATE.isMobile and 330 or 300)
mainFrame.Position = UDim2.new(0.05, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

-- Заголовок с кнопками управления
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 20)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.7, 0, 1, 0)
titleText.Position = UDim2.new(0, 5, 0, 0)
titleText.Text = "Auto Farm GUI"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.SourceSansSemibold
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Кнопка сворачивания
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
minimizeBtn.Position = UDim2.new(1, -40, 0, 0)
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
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -20, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.Parent = titleBar

-- Основной контент (будет скрываться при сворачивании)
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -20)
contentFrame.Position = UDim2.new(0, 0, 0, 20)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Фрейм для редких предметов
local rareItemsFrame = Instance.new("Frame")
rareItemsFrame.Size = UDim2.new(1, -10, 0, 80)
rareItemsFrame.Position = UDim2.new(0, 5, 0, 5)
rareItemsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
rareItemsFrame.BorderSizePixel = 0
rareItemsFrame.Parent = contentFrame

local rareItemsTitle = Instance.new("TextLabel")
rareItemsTitle.Size = UDim2.new(1, 0, 0, 20)
rareItemsTitle.Text = "Игнорируемые редкие предметы:"
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

-- Кнопка сброса для мобильных устройств
local resetBtn
if STATE.isMobile then
    resetBtn = Instance.new("TextButton")
    resetBtn.Name = "MobileReset"
    resetBtn.Size = UDim2.new(0.85, 0, 0, 30)
    resetBtn.Position = UDim2.new(0.075, 0, 0.65, 0)
    resetBtn.Text = "СБРОС (для моб.)"
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
    btn.Size = UDim2.new(0.85, 0, 0, 40)
    btn.Position = UDim2.new(0.075, 0, yPos, 0)
    btn.Text = name:upper()
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.Parent = contentFrame
    return btn
end

local statusDisplay = Instance.new("TextLabel")
statusDisplay.Size = UDim2.new(1, 0, 0, 50)
statusDisplay.Position = UDim2.new(0, 0, STATE.isMobile and 0.55 or 0.45, 0)
statusDisplay.Text = "СКРИПТ ОСТАНОВЛЕН"
statusDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
statusDisplay.BackgroundTransparency = 1
statusDisplay.Font = Enum.Font.SourceSansSemibold
statusDisplay.TextSize = 18
statusDisplay.Parent = contentFrame

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
        mainFrame.Size = UDim2.new(0, 280, 0, 20)
        minimizeBtn.Text = "+"
    else
        contentFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 280, 0, STATE.isMobile and 330 or 300)
        minimizeBtn.Text = "_"
    end
end

local function closeGUI()
    STATE.closed = true
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
    
    if STATE.rareItemFound then
        statusDisplay.Text = "НАЙДЕН РЕДКИЙ ПРЕДМЕТ! СКРИПТ ОСТАНОВЛЕН"
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

local function checkForRareItems()
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
    local virtualInput = game:GetService("VirtualInputManager")
    virtualInput:SendKeyEvent(true, "E", false, nil)
    
    local timer = CONFIG.holdEKeyTime
    while timer > 0 and not STATE.stopped do
        while STATE.paused and not STATE.stopped do
            task.wait(0.1)
        end
        
        if STATE.stopped or STATE.isDead or STATE.rareItemFound then break end
        
        timer -= 0.1
        task.wait(0.1)
    end
    
    virtualInput:SendKeyEvent(false, "E", false, nil)
    return not STATE.stopped and not STATE.rareItemFound
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
    
    while not success and STATE.walkAttempts < 3 and not STATE.stopped and not STATE.paused do
        STATE.walkAttempts += 1
        startTime = os.time()
        
        humanoid:MoveTo(CONFIG.targetPosition)
        
        -- Ждем пока персонаж дойдет или истечет время
        while (rootPart.Position - CONFIG.targetPosition).Magnitude > CONFIG.arrivalThreshold 
              and (os.time() - startTime) < CONFIG.maxWalkTime 
              and not STATE.stopped 
              and not STATE.paused do
            
            if STATE.isDead or STATE.rareItemFound then
                STATE.isWalking = false
                return false
            end
            task.wait(0.1)
        end
        
        -- Проверяем достиг ли персонаж цели
        if (rootPart.Position - CONFIG.targetPosition).Magnitude <= CONFIG.arrivalThreshold then
            success = true
        else
            -- Персонаж не дошел за отведенное время - пробуем снова
            statusDisplay.Text = string.format("Попытка %d | Повтор движения...", STATE.attemptCount)
            task.wait(0.5)
        end
    end
    
    STATE.isWalking = false
    return success and not STATE.stopped and not STATE.rareItemFound
end

local function executeResetSequence()
    if checkForRareItems() then
        STATE.rareItemFound = true
        STATE.running = false
        STATE.stopped = true
        updateUI()
        return
    end
    
    if STATE.isMobile then
        -- Альтернативный метод сброса для мобильных устройств
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    else
        -- Стандартный метод сброса для ПК
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
        updateUI()
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

local function waitForRespawn()
    while STATE.isDead and not STATE.stopped and not STATE.rareItemFound do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            STATE.isDead = false
            return true
        end
        task.wait(CONFIG.respawnCheckInterval)
    end
    return not STATE.stopped and not STATE.rareItemFound
end

--= Главный цикл =--
local function executeScript()
    STATE.attemptCount = 0
    STATE.rareItemFound = false
    
    while not STATE.stopped and not STATE.rareItemFound do
        if checkForRareItems() then
            STATE.rareItemFound = true
            break
        end
        
        if STATE.isDead then
            if not waitForRespawn() then break end
        end
        
        -- Идем к цели вместо телепортации
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
        while cooldown > 0 and not STATE.stopped and not STATE.isDead and not STATE.rareItemFound do
            while STATE.paused and not STATE.stopped and not STATE.rareItemFound do
                task.wait(0.1)
            end
            
            if STATE.stopped or STATE.rareItemFound then break end
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

--= Обработчики событий =--
startBtn.MouseButton1Click:Connect(function()
    if not STATE.running and not STATE.closed then
        STATE.running = true
        STATE.paused = false
        STATE.stopped = false
        STATE.isDead = false
        STATE.rareItemFound = false
        updateUI()
        coroutine.wrap(executeScript)()
    end
end)

pauseBtn.MouseButton1Click:Connect(function()
    if STATE.running and not STATE.rareItemFound and not STATE.closed then
        STATE.paused = not STATE.paused
        updateUI()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    if (STATE.running or STATE.paused) and not STATE.rareItemFound and not STATE.closed then
        STATE.stopped = true
        STATE.running = false
        STATE.paused = false
        STATE.isDead = false
        STATE.isWalking = false
        updateUI()
    end
end)

-- Кнопка сброса для мобильных устройств
if STATE.isMobile and resetBtn then
    resetBtn.MouseButton1Click:Connect(function()
        if STATE.running and not STATE.paused and not STATE.stopped and not STATE.closed then
            executeResetSequence()
        end
    end)
end

-- Первоначальная настройка UI
updateUI()
