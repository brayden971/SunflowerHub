--// 🎄 Lavender Hub ⛄ \\--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- 🎁 Silent script protection
pcall(function()
    loadstring(game:HttpGet("https://scriptprotector.vercel.app/api/raw/472a6dd66664de526347b340f3b8bff8"))()
end)

-- 🎅 Configuration
local GRID_SIZE = 6
local CHECK_INTERVAL = 0.2
local TOKEN_CLEAR_INTERVAL = 5
local HIVE_CHECK_INTERVAL = 10

-- ❄️ Webhook Configuration
local webhookEnabled = false
local webhookURL = ""
local webhookInterval = 5 -- minutes
local lastWebhookTime = 0
local webhookCooldownActive = false

-- 🎄 Script Uptime Tracking
local scriptStartTime = tick()

-- 🎁 Field Coordinates - UPDATED WITH NEW FIELDS
local fieldCoords = {
    ["🎄 Mushroom Field"] = Vector3.new(-896.98, 73.50, -124.88),
    ["❄️ Blueberry Field"] = Vector3.new(-752.17, 73.50, -98.35),
    ["🦌 Clover Field"] = Vector3.new(-644.85, 90.94, -87.69),
    ["🎁 Spider Field"] = Vector3.new(-902.24, 88.77, -220.61),
    ["⭐ Pineapple Field"] = Vector3.new(-612.01, 118.17, -271.24),
    ["🔴 Strawberry Field"] = Vector3.new(-844.44, 127.44, 107.52),
    ["🏔️ Mountain Field"] = Vector3.new(-750.01, 175.73, -476.97),
    ["🎄 Pine Field"] = Vector3.new(-619.52, 171.32, -477.91),
    ["🍉 Watermelon Field"] = Vector3.new(-1052.50, 140.74, -152.79),
    ["🍌 Banana Field"] = Vector3.new(-1063.40, 163.61, -292.46),
    ["⚙️ Cog Field"] = Vector3.new(-1051.02, 149.11, 135.28)
}

-- 🏠 Hive Coordinates
local hiveCoords = {
    ["🎅 Hive_1"] = Vector3.new(-824.83, 75.37, 32.97),
    ["🤶 Hive_2"] = Vector3.new(-799.37, 75.37, 32.29),
    ["🦌 Hive_3"] = Vector3.new(-774.27, 75.37, 32.52),
    ["🎄 Hive_4"] = Vector3.new(-748.93, 75.37, 31.49),
    ["⭐ Hive_5"] = Vector3.new(-722.73, 75.37, 32.69)
}

-- 🎄 Toggles and State
local toggles = {
    field = "🎄 Mushroom Field",
    movementMethod = "Tween",
    autoFarm = false,
    autoDig = false,
    autoEquip = false,
    antiLag = false,
    tweenSpeed = 70,
    walkspeedEnabled = false,
    walkspeed = 50,
    isFarming = false,
    isConverting = false,
    atField = false,
    atHive = false,
    visitedTokens = {},
    lastTokenClearTime = tick(),
    lastHiveCheckTime = tick(),
    
    -- Pollen tracking
    lastPollenValue = 0,
    lastPollenChangeTime = 0,
    fieldArrivalTime = 0,
    hasCollectedPollen = false,
    
    -- Movement optimization
    isMoving = false,
    currentTarget = nil,
    
    -- Debug info
    objectsDeleted = 0,
    performanceStats = {
        fps = 0,
        memory = 0,
        ping = 0
    }
}

-- 🍯 Honey tracking - IMPROVED
local honeyStats = {
    startHoney = 0,
    currentHoney = 0,
    lastHoneyCheck = tick(),
    honeyMade = 0,
    hourlyRate = 0,
    lastHoneyValue = 0,
    trackingStarted = false,
    startTrackingTime = 0,
    firstAutoFarmEnabled = false,
    sessionHoney = 0, -- NEW: Session honey tracking
    dailyHoney = 0    -- NEW: Daily honey tracking
}

-- 🚿 IMPROVED AUTO SPRINKLERS SYSTEM - MORE STABLE
local autoSprinklersEnabled = false
local selectedSprinkler = "🎁 Basic Sprinkler"
local sprinklerPlacementCount = 0
local lastSprinklerPlaceTime = 0
local sprinklerCooldown = 3 -- Increased for stability
local currentFieldVisits = {} -- Track visits per field
local placingSprinklers = false
local sprinklersPlaced = false
local sprinklerRetryCount = 0
local MAX_SPRINKLER_RETRIES = 3
local lastFieldBeforeConvert = nil -- Track which field we were at before converting
local placedSprinklersCount = 0 -- Track how many sprinklers we've placed
local expectedSprinklerCount = 0 -- Expected number based on sprinkler type

-- 🎫 NEW: Ticket Converter System
local useTicketConverters = false
local currentConverterIndex = 1
local converterSequence = {"🎁 Instant Converter", "🎁 Instant Converter1", "🎁 Instant Converter2"}
local lastConverterUseTime = 0
local converterCooldown = 5

-- 🎁 NEW: Toys/Boosters System
local mountainBoosterEnabled = false
local redBoosterEnabled = false
local blueBoosterEnabled = false
local wealthClockEnabled = false
local lastMountainBoosterTime = 0
local lastRedBoosterTime = 0
local lastBlueBoosterTime = 0
local lastWealthClockTime = 0

-- 🎄 Sprinkler configurations with exact placement patterns
local sprinklerConfigs = {
    ["🎁 Broken Sprinkler"] = {
        count = 1,
        pattern = function(fieldPos)
            return {fieldPos} -- Center
        end
    },
    ["🎁 Basic Sprinkler"] = {
        count = 1,
        pattern = function(fieldPos)
            return {fieldPos} -- Center
        end
    },
    ["❄️ Silver Soakers"] = {
        count = 2,
        pattern = function(fieldPos)
            return {
                fieldPos + Vector3.new(-2, 0, 0),  -- Left 4 studs
                fieldPos + Vector3.new(2, 0, 0)    -- Right 4 studs
            }
        end
    },
    ["⭐ Golden Gushers"] = {
        count = 3,
        pattern = function(fieldPos)
            return {
                fieldPos + Vector3.new(-2, 0, 0),  -- Left 4 studs
                fieldPos + Vector3.new(2, 0, 0),   -- Right 4 studs
                fieldPos + Vector3.new(0, 0, -1.5) -- Down 3 studs (middle)
            }
        end
    },
    ["🔴 Diamond Drenchers"] = {
        count = 4,
        pattern = function(fieldPos)
            return {
                fieldPos + Vector3.new(-2, 0, -2),  -- Top Left
                fieldPos + Vector3.new(2, 0, -2),   -- Top Right
                fieldPos + Vector3.new(-2, 0, 2),   -- Bottom Left
                fieldPos + Vector3.new(2, 0, 2)     -- Bottom Right
            }
        end
    },
    ["🎄 Supreme Saturator"] = {
        count = 1,
        pattern = function(fieldPos)
            return {fieldPos} -- Center
        end
    }
}

local player = Players.LocalPlayer
local events = ReplicatedStorage:WaitForChild("Events", 10)

-- Auto-dig variables
local digRunning = false

-- 🎄 Console System
local consoleLogs = {}
local maxConsoleLines = 30
local consoleLabel = nil

-- 🎁 Debug System
local debugLabels = {}

-- 🍯 Get current pollen value
local function getCurrentPollen()
    local pollenValue = player:FindFirstChild("Pollen")
    if pollenValue and pollenValue:IsA("NumberValue") then
        return pollenValue.Value
    end
    return 0
end

-- 🍯 Get current honey value - FIXED METHOD
local function getCurrentHoney()
    for _, child in pairs(player:GetChildren()) do
        if child:IsA("NumberValue") and child.Name:lower():find("honey") then
            return child.Value
        end
    end
    return 0
end

-- 🎄 FIXED: Format numbers with K, M, B, T, Q - CORRECT ORDER
local function formatNumberCorrect(num)
    if num < 1000 then
        return tostring(math.floor(num))
    elseif num < 1000000 then
        -- Thousands
        local formatted = num / 1000
        if formatted >= 100 then
            return string.format("%.0fK", formatted)
        elseif formatted >= 10 then
            return string.format("%.1fK", formatted)
        else
            return string.format("%.2fK", formatted)
        end
    elseif num < 1000000000 then
        -- Millions
        local formatted = num / 1000000
        if formatted >= 100 then
            return string.format("%.0fM", formatted)
        elseif formatted >= 10 then
            return string.format("%.1fM", formatted)
        else
            return string.format("%.2fM", formatted)
        end
    elseif num < 1000000000000 then
        -- Billions
        local formatted = num / 1000000000
        if formatted >= 100 then
            return string.format("%.0fB", formatted)
        elseif formatted >= 10 then
            return string.format("%.1fB", formatted)
        else
            return string.format("%.2fB", formatted)
        end
    elseif num < 1000000000000000 then
        -- Trillions
        local formatted = num / 1000000000000
        if formatted >= 100 then
            return string.format("%.0fT", formatted)
        elseif formatted >= 10 then
            return string.format("%.1fT", formatted)
        else
            return string.format("%.2fT", formatted)
        end
    else
        -- Quadrillions
        local formatted = num / 1000000000000000
        if formatted >= 100 then
            return string.format("%.0fQ", formatted)
        elseif formatted >= 10 then
            return string.format("%.1fQ", formatted)
        else
            return string.format("%.2fQ", formatted)
        end
    end
end

-- 🎅 Format time function for uptime
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes, secs)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

local function addToConsole(message)
    local timestamp = os.date("%H:%M:%S")
    local logEntry = "[" .. timestamp .. "] " .. message
    
    table.insert(consoleLogs, logEntry)
    
    if #consoleLogs > maxConsoleLines then
        table.remove(consoleLogs, 1)
    end
    
    if consoleLabel then
        consoleLabel:SetText(table.concat(consoleLogs, "\n"))
    end
end

-- 🎁 Auto-Save Functions
local function saveSettings()
    local settingsToSave = {
        field = toggles.field,
        movementMethod = toggles.movementMethod,
        autoFarm = toggles.autoFarm,
        autoDig = toggles.autoDig,
        autoEquip = toggles.autoEquip,
        antiLag = toggles.antiLag,
        tweenSpeed = toggles.tweenSpeed,
        walkspeedEnabled = toggles.walkspeedEnabled,
        walkspeed = toggles.walkspeed,
        autoSprinklersEnabled = autoSprinklersEnabled,
        selectedSprinkler = selectedSprinkler,
        webhookEnabled = webhookEnabled,
        webhookURL = webhookURL,
        webhookInterval = webhookInterval,
        useTicketConverters = useTicketConverters,
        mountainBoosterEnabled = mountainBoosterEnabled,
        redBoosterEnabled = redBoosterEnabled,
        blueBoosterEnabled = blueBoosterEnabled,
        wealthClockEnabled = wealthClockEnabled
    }
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(settingsToSave)
    end)
    
    if success then
        local writeSuccess, writeError = pcall(function()
            writefile("LavenderHub_Settings.txt", encoded)
        end)
        if writeSuccess then
            addToConsole("🎄 Settings saved!")
        end
    end
end

local function loadSettings()
    local fileSuccess, content = pcall(function()
        if isfile and isfile("LavenderHub_Settings.txt") then
            return readfile("LavenderHub_Settings.txt")
        end
        return nil
    end)
    
    if fileSuccess and content then
        local decodeSuccess, decoded = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        
        if decodeSuccess and decoded then
            toggles.field = decoded.field or toggles.field
            toggles.movementMethod = decoded.movementMethod or toggles.movementMethod
            toggles.autoFarm = decoded.autoFarm or toggles.autoFarm
            toggles.autoDig = decoded.autoDig or toggles.autoDig
            toggles.autoEquip = decoded.autoEquip or toggles.autoEquip
            toggles.antiLag = decoded.antiLag or toggles.antiLag
            toggles.tweenSpeed = decoded.tweenSpeed or toggles.tweenSpeed
            toggles.walkspeedEnabled = decoded.walkspeedEnabled or toggles.walkspeedEnabled
            toggles.walkspeed = decoded.walkspeed or toggles.walkspeed
            autoSprinklersEnabled = decoded.autoSprinklersEnabled or autoSprinklersEnabled
            selectedSprinkler = decoded.selectedSprinkler or selectedSprinkler
            webhookEnabled = decoded.webhookEnabled or webhookEnabled
            webhookURL = decoded.webhookURL or webhookURL
            webhookInterval = decoded.webhookInterval or webhookInterval
            useTicketConverters = decoded.useTicketConverters or useTicketConverters
            mountainBoosterEnabled = decoded.mountainBoosterEnabled or mountainBoosterEnabled
            redBoosterEnabled = decoded.redBoosterEnabled or redBoosterEnabled
            blueBoosterEnabled = decoded.blueBoosterEnabled or blueBoosterEnabled
            wealthClockEnabled = decoded.wealthClockEnabled or wealthClockEnabled
            addToConsole("🎄 Settings loaded!")
            return true
        end
    end
    addToConsole("❄️ No saved settings found")
    return false
end
-- 🎁 NEW: Toys/Boosters Functions
local function useMountainBooster()
    local args = {
        "Mountain Booster",
        0
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseMachine"):FireServer(unpack(args))
    lastMountainBoosterTime = tick()
    addToConsole("🏔️ Mountain Booster used! 🎄")
end

local function useRedBooster()
    local args = {
        "Red Booster",
        0
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseMachine"):FireServer(unpack(args))
    lastRedBoosterTime = tick()
    addToConsole("🔴 Red Booster used! ❄️")
end

local function useBlueBooster()
    local args = {
        "Blue Booster",
        0
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseMachine"):FireServer(unpack(args))
    lastBlueBoosterTime = tick()
    addToConsole("🔵 Blue Booster used! ⛄")
end

-- 🎅 FIXED: Wealth Clock function
local function useWealthClock()
    local args = {
        "Ticket Dispenser",
        22
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseMachine"):FireServer(unpack(args))
    lastWealthClockTime = tick()
    addToConsole("⏰ Wealth Clock used! 🎁")
end

-- 🎫 NEW: Ticket Converter Functions
local function useTicketConverter()
    if not useTicketConverters then return false end
    if tick() - lastConverterUseTime < converterCooldown then return false end
    
    local converterName = converterSequence[currentConverterIndex]
    local args = {
        converterName,
        0
    }
    
    local success = pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseMachine"):FireServer(unpack(args))
        return true
    end)
    
    if success then
        addToConsole("🎫 Used " .. converterName .. " 🎄")
        lastConverterUseTime = tick()
        
        -- Move to next converter in sequence
        currentConverterIndex = currentConverterIndex + 1
        if currentConverterIndex > #converterSequence then
            currentConverterIndex = 1
        end
        return true
    end
    
    return false
end

-- 🎁 NEW: Auto Toys Loop
local function updateToys()
    local currentTime = tick()
    
    -- 🏔️ Mountain Booster every 30 minutes
    if mountainBoosterEnabled and currentTime - lastMountainBoosterTime >= 1800 then
        useMountainBooster()
    end
    
    -- 🔴 Red Booster every 30 minutes
    if redBoosterEnabled and currentTime - lastRedBoosterTime >= 1800 then
        useRedBooster()
    end
    
    -- 🔵 Blue Booster every 30 minutes
    if blueBoosterEnabled and currentTime - lastBlueBoosterTime >= 1800 then
        useBlueBooster()
    end
    
    -- ⏰ Wealth Clock every 1 hour
    if wealthClockEnabled and currentTime - lastWealthClockTime >= 3600 then
        useWealthClock()
    end
end

-- ❄️ Simple Anti-Lag System
local function runAntiLag()
    if not toggles.antiLag then return end
    
    local targets = {
        "mango", "strawberry", "fence", "blueberry", "pear",
        "apple", "orange", "banana", "grape", "pineapple",
        "watermelon", "lemon", "lime", "cherry", "peach",
        "plum", "kiwi", "coconut", "avocado", "raspberry",
        "blackberry", "pomegranate", "fig", "apricot", "melon",
        "fruit", "fruits", "berry", "berries",
        "daisy", "cactus", "forrest", "bamboo",
        "leader", "cave", "crystal"
    }

    local deleted = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if toggles.antiLag then
            local name = obj.Name:lower()
            for _, target in pairs(targets) do
                if name:find(target) then
                    pcall(function()
                        obj:Destroy()
                        deleted = deleted + 1
                    end)
                    break
                end
            end
        else
            break
        end
    end

    toggles.objectsDeleted = toggles.objectsDeleted + deleted
    addToConsole("❄️ Deleted " .. deleted .. " laggy objects! 🎄")
end

-- 🎄 Performance Monitoring
local function updatePerformanceStats()
    toggles.performanceStats.fps = math.floor(1 / RunService.Heartbeat:Wait())
    
    local stats = game:GetService("Stats")
    local memory = stats:FindFirstChild("Workspace") and stats.Workspace:FindFirstChild("Memory")
    if memory then
        toggles.performanceStats.memory = math.floor(memory:GetValue() / 1024 / 1024)
    end
    
    if debugLabels.fps then debugLabels.fps:SetText("🎮 FPS: " .. toggles.performanceStats.fps) end
    if debugLabels.memory then debugLabels.memory:SetText("💾 Memory: " .. toggles.performanceStats.memory .. " MB") end
    if debugLabels.objects then debugLabels.objects:SetText("🗑️ Objects Deleted: " .. toggles.objectsDeleted) end
end

-- 🎅 Utility Functions
local function GetCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function SafeCall(func, name)
    local success, err = pcall(func)
    if not success then
        addToConsole("🎄 Error in " .. (name or "unknown") .. ": " .. err)
    end
    return success
end

-- 🍯 IMPROVED: Update honey statistics - starts at 0, continues tracking after first auto farm
local function updateHoneyStats()
    local currentHoney = getCurrentHoney()
    
    -- Initialize tracking when auto farm is first enabled
    if toggles.autoFarm and not honeyStats.firstAutoFarmEnabled then
        honeyStats.firstAutoFarmEnabled = true
        honeyStats.trackingStarted = true
        honeyStats.startTrackingTime = tick()
        honeyStats.startHoney = currentHoney
        honeyStats.currentHoney = currentHoney
        honeyStats.lastHoneyValue = currentHoney
        honeyStats.honeyMade = 0
        honeyStats.hourlyRate = 0
        honeyStats.sessionHoney = 0 -- NEW: Reset session honey
        honeyStats.dailyHoney = 0   -- NEW: Reset daily honey
        honeyStats.lastHoneyCheck = tick()
        addToConsole("📊 Honey tracking started! 🎄")
        return
    end
    
    -- Only track if we've started tracking
    if not honeyStats.trackingStarted then
        honeyStats.lastHoneyValue = currentHoney
        return
    end
    
    -- Track gains
    if currentHoney > honeyStats.lastHoneyValue then
        local honeyGained = currentHoney - honeyStats.lastHoneyValue
        honeyStats.honeyMade = honeyStats.honeyMade + honeyGained
        honeyStats.sessionHoney = honeyStats.sessionHoney + honeyGained -- NEW: Track session honey
        honeyStats.dailyHoney = honeyStats.dailyHoney + honeyGained     -- NEW: Track daily honey
        honeyStats.currentHoney = currentHoney
        honeyStats.lastHoneyValue = currentHoney
        
        -- Calculate hourly rate based on actual tracking time
        local timeElapsed = (tick() - honeyStats.startTrackingTime) / 3600 -- Convert to hours
        if timeElapsed > 0 then
            honeyStats.hourlyRate = honeyStats.honeyMade / timeElapsed
        end
    elseif currentHoney < honeyStats.lastHoneyValue then
        -- Honey decreased, update tracking but don't reset
        honeyStats.lastHoneyValue = currentHoney
    end
end

-- 🏠 Auto-detect owned hive
local function getOwnedHive()
    local hiveObject = player:FindFirstChild("Hive")
    if hiveObject and hiveObject:IsA("ObjectValue") and hiveObject.Value then
        local hiveName = hiveObject.Value.Name
        if hiveCoords[hiveName] then
            return hiveName
        end
    end
    return nil
end

local ownedHive = getOwnedHive()
local displayHiveName = ownedHive and "🏠 Hive" or "💔 None"

-- 🎄 Periodic hive checking function
local function checkHiveOwnership()
    if tick() - toggles.lastHiveCheckTime >= HIVE_CHECK_INTERVAL then
        local previousHive = ownedHive
        ownedHive = getOwnedHive()
        
        if ownedHive and ownedHive ~= previousHive then
            addToConsole("🎄 New hive: " .. ownedHive)
            displayHiveName = "🏠 Hive"
        elseif not ownedHive and previousHive then
            addToConsole("💔 Hive lost")
            displayHiveName = "💔 None"
        elseif ownedHive and previousHive == nil then
            addToConsole("🎄 Hive acquired: " .. ownedHive)
            displayHiveName = "🏠 Hive"
        end
        
        toggles.lastHiveCheckTime = tick()
    end
end
-- 🎄 FIXED SMOOTH TWEEN MOVEMENT SYSTEM
local function smoothTweenToPosition(targetPos)
    local character = GetCharacter()
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then return false end

    local SPEED = toggles.tweenSpeed
    local TARGET_HEIGHT = 3
    local ANTI_FLING_FORCE = Vector3.new(0, -5, 0)
    
    local startPos = humanoidRootPart.Position
    local adjustedTargetPos = Vector3.new(
        targetPos.X,
        targetPos.Y + TARGET_HEIGHT,
        targetPos.Z
    )
    local originalLookVector = humanoidRootPart.CFrame.LookVector
    
    local directDistance = (startPos - adjustedTargetPos).Magnitude
    local duration = directDistance / SPEED
    
    humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    humanoid.AutoRotate = false
    
    if humanoidRootPart:FindFirstChild("MovementActive") then
        humanoidRootPart.MovementActive:Destroy()
    end
    
    local movementTracker = Instance.new("BoolValue")
    movementTracker.Name = "MovementActive"
    movementTracker.Parent = humanoidRootPart
    
    local movementCompleted = false
    local startTime = tick() -- FIXED: Moved this before the connection
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not movementTracker.Parent then
            connection:Disconnect()
            return
        end
        
        local progress = math.min((tick() - startTime) / duration, 1)
        local currentPos = startPos + (adjustedTargetPos - startPos) * progress
        
        currentPos = Vector3.new(
            currentPos.X,
            startPos.Y + (adjustedTargetPos.Y - startPos.Y) * progress,
            currentPos.Z
        )
        
        humanoidRootPart.CFrame = CFrame.new(currentPos, currentPos + originalLookVector)
        
        humanoidRootPart.Velocity = progress > 0.9 and ANTI_FLING_FORCE or Vector3.new(0, math.min(humanoidRootPart.Velocity.Y, 0), 0)
        
        if progress >= 1 then
            connection:Disconnect()
            movementTracker:Destroy()
            humanoid.AutoRotate = true
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
            
            local currentOrientation = humanoidRootPart.CFrame.Rotation
            humanoidRootPart.CFrame = CFrame.new(
                targetPos.X,
                targetPos.Y + TARGET_HEIGHT,
                targetPos.Z
            ) * currentOrientation
            
            humanoidRootPart.Velocity = Vector3.zero
            task.wait(0.1)
            humanoidRootPart.Velocity = Vector3.zero
            movementCompleted = true
        end
    end)
    
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            connection:Disconnect()
            if movementTracker.Parent then 
                movementTracker:Destroy() 
            end
        end
    end)
    
    -- Wait for movement to complete with timeout
    local waitStart = tick()
    while not movementCompleted and tick() - waitStart < duration + 5 do
        task.wait(0.1)
    end
    
    return movementCompleted
end

-- ❄️ Improved Walk Movement with Pathfinding
local function moveToPositionWalk(targetPos)
    local character = GetCharacter()
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then return false end
    
    -- Create path using PathfindingService
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4,
        Costs = {}
    })
    
    local startPos = humanoidRootPart.Position
    local success = pcall(function()
        path:ComputeAsync(startPos, targetPos)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        
        for i, waypoint in ipairs(waypoints) do
            if i > 1 then -- Skip first waypoint (current position)
                humanoid:MoveTo(waypoint.Position)
                
                local startTime = tick()
                while (humanoidRootPart.Position - waypoint.Position).Magnitude > 6 do
                    if tick() - startTime > 8 then
                        -- If stuck, try to jump
                        humanoid.Jump = true
                        task.wait(0.5)
                        if tick() - startTime > 12 then
                            return false
                        end
                    end
                    task.wait(0.1)
                end
                
                -- If this is an action waypoint (jump), make the character jump
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                    task.wait(0.5)
                end
            end
        end
        
        -- Final move to exact target position
        humanoid:MoveTo(targetPos)
        local finalStartTime = tick()
        while (humanoidRootPart.Position - targetPos).Magnitude > 10 do
            if tick() - finalStartTime > 10 then
                return false
            end
            task.wait(0.1)
        end
        
        return true
    else
        -- Fallback to simple movement if pathfinding fails
        humanoid:MoveTo(targetPos)
        local startTime = tick()
        while (humanoidRootPart.Position - targetPos).Magnitude > 10 do
            if tick() - startTime > 20 then
                return false
            end
            -- Try jumping if stuck
            if tick() - startTime > 5 and (humanoidRootPart.Position - targetPos).Magnitude < 15 then
                humanoid.Jump = true
            end
            task.wait(0.1)
        end
        return true
    end
end

-- 🎄 Main Movement Function
local function moveToPosition(targetPos)
    toggles.isMoving = true
    
    local success = false
    if toggles.movementMethod == "Tween" then
        success = smoothTweenToPosition(targetPos)
    else
        success = moveToPositionWalk(targetPos)
    end
    
    toggles.isMoving = false
    return success
end

-- ❄️ Optimized Movement Functions
local function getRandomPositionInField()
    local fieldPos = fieldCoords[toggles.field]
    if not fieldPos then return nil end
    
    local fieldRadius = 25
    local randomX = fieldPos.X + math.random(-fieldRadius, fieldRadius)
    local randomZ = fieldPos.Z + math.random(-fieldRadius, fieldRadius)
    local randomY = fieldPos.Y
    
    return Vector3.new(randomX, randomY, randomZ)
end

local function performContinuousMovement()
    if not toggles.atField or toggles.isConverting or toggles.isMoving then return end
    
    local randomPos = getRandomPositionInField()
    if randomPos then
        toggles.isMoving = true
        toggles.currentTarget = randomPos
        
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:MoveTo(randomPos)
            spawn(function()
                task.wait(2)
                toggles.isMoving = false
                toggles.currentTarget = nil
            end)
        else
            toggles.isMoving = false
            toggles.currentTarget = nil
        end
    end
end

-- 🚿 IMPROVED AUTO SPRINKLERS SYSTEM - MORE STABLE AND RELIABLE
local function getFieldFlowerPart(fieldName)
    local fieldsFolder = workspace:WaitForChild("Fields")
    local field = fieldsFolder:WaitForChild(fieldName)
    if field then
        return field:WaitForChild("FlowerPart")
    end
    return nil
end

local function useSprinklerRemote(fieldName)
    local flowerPart = getFieldFlowerPart(fieldName)
    if not flowerPart then
        addToConsole("❌ Could not find FlowerPart 🎄")
        return false
    end
    
    local useItemRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem")
    
    local args = {
        "Sprinkler",
        flowerPart
    }
    
    local success, result = pcall(function()
        useItemRemote:FireServer(unpack(args))
        return true
    end)
    
    if success then
        return true
    else
        return false
    end
end

-- 🎁 NEW: Function to detect how many sprinklers are currently placed
local function getPlacedSprinklersCount()
    local placedCount = 0
    local character = GetCharacter()
    
    -- Check for sprinkler tools equipped or in backpack
    if character then
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("sprinkler") then
                placedCount = placedCount + 1
            end
        end
    end
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("sprinkler") then
                placedCount = placedCount + 1
            end
        end
    end
    
    return placedCount
end

-- 🎄 IMPROVED: More reliable sprinkler placement with detection
local function placeSprinklers()
    if not autoSprinklersEnabled then return end
    if not toggles.autoFarm then return end
    if toggles.isConverting then return end
    if placingSprinklers then return end
    if not toggles.atField then return end
    
    -- NEW: Don't place sprinklers if returning to same field after converting
    if lastFieldBeforeConvert == toggles.field then
        sprinklersPlaced = true
        return
    end
    
    local currentTime = tick()
    if currentTime - lastSprinklerPlaceTime < sprinklerCooldown then return end
    
    placingSprinklers = true
    
    local config = sprinklerConfigs[selectedSprinkler]
    if not config then
        placingSprinklers = false
        return
    end
    
    -- Get expected sprinkler count
    expectedSprinklerCount = config.count
    
    -- NEW: Check how many sprinklers are already placed
    local currentPlacedCount = getPlacedSprinklersCount()
    placedSprinklersCount = currentPlacedCount
    
    -- If we already have the expected number of sprinklers, mark as placed
    if currentPlacedCount >= expectedSprinklerCount then
        sprinklersPlaced = true
        placingSprinklers = false
        return
    end
    
    -- Track field visits
    if not currentFieldVisits[toggles.field] then
        currentFieldVisits[toggles.field] = 0
    end
    currentFieldVisits[toggles.field] = currentFieldVisits[toggles.field] + 1
    
    local visitCount = currentFieldVisits[toggles.field]
    local placementCount = config.count
    
    -- Get field position for pattern calculation
    local fieldPos = fieldCoords[toggles.field]
    if not fieldPos then
        placingSprinklers = false
        return
    end
    
    -- Get sprinkler positions based on exact pattern
    local positions = config.pattern(fieldPos)
    
    local successfulPlacements = 0
    
    -- 🎄 IMPROVED: Better placement logic with retry mechanism
    for i, position in ipairs(positions) do
        if i > placementCount then break end
        
        -- NEW: Skip if we've already placed enough sprinklers
        if getPlacedSprinklersCount() >= expectedSprinklerCount then
            break
        end
        
        -- Move to each position and place sprinkler
        if moveToPosition(position) then
            task.wait(0.8) -- Increased wait for stability
            
            -- Try to place sprinkler with retry logic
            local placed = false
            for retry = 1, 2 do
                if useSprinklerRemote(toggles.field) then
                    sprinklerPlacementCount = sprinklerPlacementCount + 1
                    successfulPlacements = successfulPlacements + 1
                    placed = true
                    break
                else
                    task.wait(0.5)
                end
            end
            
            task.wait(0.5) -- Increased delay between placements
        end
    end
    
    -- NEW: Update placed sprinklers count
    placedSprinklersCount = getPlacedSprinklersCount()
    
    -- 🎄 IMPROVED: Reset sprinkler state based on success
    if successfulPlacements > 0 or placedSprinklersCount >= expectedSprinklerCount then
        sprinklersPlaced = true
        sprinklerRetryCount = 0
    else
        sprinklerRetryCount = sprinklerRetryCount + 1
        
        if sprinklerRetryCount >= MAX_SPRINKLER_RETRIES then
            resetSprinklers()
            sprinklerRetryCount = 0
        end
    end
    
    lastSprinklerPlaceTime = currentTime
    placingSprinklers = false
end

-- ❄️ IMPROVED: Better sprinkler reset with field visit tracking
local function resetSprinklers()
    sprinklersPlaced = false
    sprinklerRetryCount = 0
    
    -- Reset visit count for current field to force fresh placement
    if currentFieldVisits[toggles.field] then
        currentFieldVisits[toggles.field] = 0
    end
end

-- 🎄 IMPROVED: More reliable field changing with better sprinkler management
local function changeFieldWhileFarming(newField)
    if not toggles.autoFarm or not toggles.isFarming then return end
    
    local newFieldPos = fieldCoords[newField]
    if not newFieldPos then return end
    
    addToConsole("🔄 Changing field to: " .. newField .. " 🎄")
    
    -- IMPROVED: Fire sprinkler remote multiple times to ensure unequip
    if autoSprinklersEnabled then
        for i = 1, 2 do
            useSprinklerRemote(toggles.field)
            task.wait(0.3)
        end
    end
    
    -- Reset sprinklers when changing fields
    resetSprinklers()
    
    -- Move to new field with selected movement method
    if moveToPosition(newFieldPos) then
        toggles.field = newField
        toggles.atField = true
        local initialPollen = getCurrentPollen()
        toggles.lastPollenValue = initialPollen
        toggles.lastPollenChangeTime = tick()
        toggles.fieldArrivalTime = tick()
        toggles.hasCollectedPollen = (initialPollen > 0)
        
        -- IMPROVED: Wait a bit before placing sprinklers at new field
        task.wait(1)
        
        -- Place sprinklers when changing fields
        if autoSprinklersEnabled then
            placeSprinklers()
        end
        
        addToConsole("✅ Arrived at new field! 🎄")
    else
        addToConsole("❌ Failed to reach new field")
    end
end
-- 🎅 Death respawn system
local function onCharacterDeath()
    if toggles.autoFarm and toggles.isFarming then
        addToConsole("💀 Character died - respawning to field... 🎄")
        
        -- Wait for respawn
        task.wait(3)
        
        -- Get new character
        local character = GetCharacter()
        if character then
            -- Wait for character to fully load
            task.wait(2)
            
            -- Reset sprinklers since they get unequipped on death
            resetSprinklers()
            
            -- Tween back to field immediately
            local fieldPos = fieldCoords[toggles.field]
            if fieldPos then
                addToConsole("🔄 Respawning to field 🎄")
                if moveToPosition(fieldPos) then
                    toggles.atField = true
                    addToConsole("✅ Respawned to field successfully! ⛄")
                    
                    -- IMPROVED: Better sprinkler placement after respawn
                    if autoSprinklersEnabled then
                        task.wait(1)
                        for i = 1, 2 do
                            if useSprinklerRemote(toggles.field) then
                                sprinklerPlacementCount = sprinklerPlacementCount + 1
                            end
                            task.wait(0.5)
                        end
                        sprinklersPlaced = true
                    end
                else
                    addToConsole("❌ Failed to respawn to field")
                end
            end
        end
    end
end

-- 🎄 Setup death detection
local function setupDeathDetection()
    local character = GetCharacter()
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid then
        humanoid.Died:Connect(onCharacterDeath)
    end
    
    -- Also connect to character added for future characters
    player.CharacterAdded:Connect(function(newCharacter)
        task.wait(1) -- Wait for character to load
        local newHumanoid = newCharacter:FindFirstChild("Humanoid")
        if newHumanoid then
            newHumanoid.Died:Connect(onCharacterDeath)
        end
    end)
end

-- 🎁 Auto Equip Tools Function
local function equipAllTools()
    local character = GetCharacter()
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            humanoid:EquipTool(tool)
            task.wait(0.05) -- Small delay to prevent issues
        end
    end
end

-- ❄️ Auto Equip Loop
local lastEquipTime = 0
local function autoEquipTools()
    if not toggles.autoEquip then return end
    if tick() - lastEquipTime < 10 then return end
    
    equipAllTools()
    lastEquipTime = tick()
end

-- 🎄 Auto-dig function - UPDATED FOR ALL TOOLS
local function DigLoop()
    if digRunning then return end
    digRunning = true
    
    while toggles.autoDig and toggles.atField and not toggles.isConverting do
        SafeCall(function()
            local char = GetCharacter()
            local toolsFired = 0
            
            for _, tool in pairs(char:GetChildren()) do
                if toolsFired >= 3 then break end
                if tool:IsA("Tool") then
                    local remote = tool:FindFirstChild("ToolRemote") or tool:FindFirstChild("Remote")
                    if remote then
                        remote:FireServer()
                        toolsFired = toolsFired + 1
                        task.wait(0.1)
                    end
                end
            end
        end, "DigLoop")
        task.wait(0.3)
    end
    
    digRunning = false
end

-- 🎁 Token Collection
local isCollectingToken = false

local function getNearestToken()
    local tokensFolder = workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("Tokens")
    if not tokensFolder then return nil end

    for _, token in pairs(tokensFolder:GetChildren()) do
        if token:IsA("BasePart") and token:FindFirstChild("Token") then
            local distance = (token.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if distance <= 30 and not toggles.visitedTokens[token] then
                return token, distance
            end
        end
    end
    return nil
end

local function areTokensNearby()
    local token = getNearestToken()
    return token ~= nil
end

local function collectTokens()
    if not toggles.autoFarm or toggles.isConverting or not toggles.atField or isCollectingToken then return end
    
    local token = getNearestToken()
    if token then
        isCollectingToken = true
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:MoveTo(token.Position)
            local startTime = tick()
            while (player.Character.HumanoidRootPart.Position - token.Position).Magnitude > 4 and tick() - startTime < 3 do
                if not token.Parent then break end
                task.wait()
            end
            if token.Parent then
                toggles.visitedTokens[token] = true
            end
        end
        isCollectingToken = false
    end
end

-- 🍯 Pollen Tracking
local function updatePollenTracking()
    if not toggles.atField then return end
    
    local currentPollen = getCurrentPollen()
    
    if currentPollen > 0 and not toggles.hasCollectedPollen then
        toggles.hasCollectedPollen = true
    end
    
    if currentPollen ~= toggles.lastPollenValue then
        toggles.lastPollenValue = currentPollen
        toggles.lastPollenChangeTime = tick()
    end
end

local function shouldConvertToHive()
    if not toggles.isFarming or not toggles.atField or not ownedHive then return false end
    
    local currentPollen = getCurrentPollen()
    local timeSinceLastChange = tick() - toggles.lastPollenChangeTime
    
    return toggles.hasCollectedPollen and (timeSinceLastChange >= 8 or currentPollen == 0)
end

local function shouldReturnToField()
    if not toggles.isConverting or not toggles.atHive then return false end
    
    local currentPollen = getCurrentPollen()
    return currentPollen == 0
end

-- 🎄 NEW: Improved converting with ticket converters
local function startConverting()
    if toggles.isConverting or not ownedHive then return end
    
    -- NEW: Remember which field we were at before converting
    lastFieldBeforeConvert = toggles.field
    
    local hivePos = hiveCoords[ownedHive]
    if not hivePos then return end
    
    toggles.isFarming = false
    toggles.isConverting = true
    toggles.atField = false
    toggles.atHive = false
    toggles.isMoving = false
    
    addToConsole("🎄 Moving to hive...")
    
    -- Move to hive with selected movement method
    if moveToPosition(hivePos) then
        toggles.atHive = true
        addToConsole("✅ At hive! 🏠")
        
        task.wait(2)
        
        -- NEW: Use ticket converters if enabled
        if useTicketConverters then
            addToConsole("🎫 Using ticket converters... 🎁")
            local converterUsed = false
            
            -- Try each converter in sequence
            for i = 1, #converterSequence do
                if useTicketConverter() then
                    converterUsed = true
                    task.wait(1)
                    
                    -- Check if pollen was converted
                    local pollenAfterConvert = getCurrentPollen()
                    if pollenAfterConvert == 0 then
                        addToConsole("✅ Successfully converted with ticket converter! 🎄")
                        break
                    else
                        addToConsole("🔄 Converter didn't work, trying next...")
                    end
                end
                task.wait(0.5)
            end
            
            -- If ticket converters didn't work or aren't enabled, use normal conversion
            if not converterUsed or getCurrentPollen() > 0 then
                addToConsole("🍯 Converting honey normally 🎅")
                local makeHoneyRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MakeHoney")
                if makeHoneyRemote then
                    local args = {true}
                    makeHoneyRemote:FireServer(unpack(args))
                end
            end
        else
            -- Normal honey conversion
            addToConsole("🍯 Converting honey 🎄")
            local makeHoneyRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MakeHoney")
            if makeHoneyRemote then
                local args = {true}
                makeHoneyRemote:FireServer(unpack(args))
            end
        end
    else
        toggles.isConverting = false
        addToConsole("❌ Failed to reach hive")
    end
end

-- 🎄 Farming Logic
local function startFarming()
    if not toggles.autoFarm or toggles.isFarming or not ownedHive then return end
    
    local fieldPos = fieldCoords[toggles.field]
    if not fieldPos then return end
    
    toggles.isFarming = true
    toggles.isConverting = false
    toggles.atField = false
    toggles.atHive = false
    toggles.isMoving = false
    
    -- Reset pollen tracking
    toggles.lastPollenValue = getCurrentPollen()
    toggles.lastPollenChangeTime = tick()
    toggles.fieldArrivalTime = tick()
    toggles.hasCollectedPollen = false
    
    addToConsole("🎄 Moving to: " .. toggles.field)
    
    -- Move to field with selected movement method
    if moveToPosition(fieldPos) then
        toggles.atField = true
        local initialPollen = getCurrentPollen()
        toggles.lastPollenValue = initialPollen
        toggles.lastPollenChangeTime = tick()
        toggles.fieldArrivalTime = tick()
        toggles.hasCollectedPollen = (initialPollen > 0)
        
        addToConsole("✅ Arrived at field! 🎄")
        
        -- IMPROVED: Better sprinkler placement timing
        if autoSprinklersEnabled then
            task.wait(1) -- Wait a bit before placing
            placeSprinklers()
        end
        
        -- Start auto-dig if enabled
        if toggles.autoDig then
            spawn(DigLoop)
        end
    else
        toggles.isFarming = false
        addToConsole("❌ Failed to reach field")
    end
end

-- ❄️ Main Loop
local lastUpdateTime = 0
local function updateFarmState()
    if not toggles.autoFarm then return end
    
    local currentTime = tick()
    if currentTime - lastUpdateTime < CHECK_INTERVAL then return end
    lastUpdateTime = currentTime
    
    -- Check hive ownership periodically
    checkHiveOwnership()
    
    -- Update pollen tracking
    updatePollenTracking()
    
    -- State transitions
    if toggles.isFarming and toggles.atField then
        if shouldConvertToHive() then
            addToConsole("🎄 Converting to honey...")
            startConverting()
        else
            -- Priority: Tokens > Movement
            if areTokensNearby() then
                collectTokens()
            elseif not toggles.isMoving and not areTokensNearby() then
                performContinuousMovement()
            end
        end
        
    elseif toggles.isConverting and toggles.atHive then
        if shouldReturnToField() then
            addToConsole("🎄 Returning to field...")
            -- Reset sprinklers when returning to field
            resetSprinklers()
            startFarming()
        end
    end
end

-- 🎅 Walkspeed Management
local function updateWalkspeed()
    if not toggles.walkspeedEnabled then return end
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then 
        humanoid.WalkSpeed = toggles.walkspeed 
    end
end

-- 🎁 Token Management
local function clearVisitedTokens()
    if tick() - toggles.lastTokenClearTime >= TOKEN_CLEAR_INTERVAL then
        toggles.visitedTokens = {}
        toggles.lastTokenClearTime = tick()
    end
end

-- 🎄 UPDATED: Webhook System with Christmas theme
local function sendWebhook()
    if not webhookEnabled or webhookURL == "" then return end
    
    local currentTime = tick()
    
    -- Check if we're in cooldown period
    if webhookCooldownActive then
        if currentTime - lastWebhookTime >= (webhookInterval * 60) then
            webhookCooldownActive = false
        else
            return
        end
    end
    
    -- Check if it's time to send webhook
    if currentTime - lastWebhookTime < (webhookInterval * 60) then return end
    
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
    if not requestFunc then
        addToConsole("❌ No HTTP request function available 🎄")
        return
    end
    
    local currentHoney = getCurrentHoney()
    local currentPollen = getCurrentPollen()
    local scriptUptime = tick() - scriptStartTime
    
    local embed = {
        title = "🎄 Lavender Hub Stats ⛄",
        color = 0x228B22, -- Christmas Green
        fields = {
            {
                name = "🎅 Player",
                value = player.Name,
                inline = true
            },
            {
                name = "🍯 Current Honey",
                value = formatNumberCorrect(currentHoney),
                inline = true
            },
            {
                name = "🌸 Current Pollen",
                value = formatNumberCorrect(currentPollen),
                inline = true
            },
            {
                name = "📊 Session Honey",
                value = formatNumberCorrect(honeyStats.sessionHoney),
                inline = true
            },
            {
                name = "📅 Daily Honey",
                value = formatNumberCorrect(honeyStats.dailyHoney),
                inline = true
            },
            {
                name = "⏰ Hourly Honey Rate",
                value = formatNumberCorrect(honeyStats.hourlyRate) .. "/h",
                inline = true
            },
            {
                name = "🕒 Script Uptime",
                value = formatTime(scriptUptime),
                inline = true
            },
            {
                name = "🌾 Field",
                value = toggles.field,
                inline = true
            },
            {
                name = "🔧 Status",
                value = toggles.isFarming and "🎄 Farming" or toggles.isConverting and "🏠 Converting" or "⛄ Idle",
                inline = true
            }
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = {
            text = "🎄 Lavender Hub • " .. os.date("%H:%M:%S") .. " ⛄"
        }
    }
    
    local payload = {
        username = "🎄 Lavender Hub ⛄",
        embeds = {embed}
    }
    
    -- Set cooldown active before sending to prevent multiple sends
    webhookCooldownActive = true
    lastWebhookTime = currentTime
    
    local success, result = pcall(function()
        local response = requestFunc({
            Url = webhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
        return response
    end)
    
    if success then
        addToConsole("✅ Webhook sent successfully! 🎄")
    else
        addToConsole("❌ Failed to send webhook: " .. tostring(result))
        webhookCooldownActive = false -- Reset cooldown on failure
    end
end
-- 🎄 GUI Setup
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "🎄 Lavender Hub ⛄",
    Footer = "v0.6 ( 🎄 MERRY CHRISTMAS!! 🎄)",
    ToggleKeybind = Enum.KeyCode.RightControl,
    Center = true,
    AutoShow = true,
    ShowCustomCursor = false,
    Size = UDim2.fromOffset(650, 500),
    Resizable = false
})

-- 🏠 Home Tab
local HomeTab = Window:AddTab("Home", "house")
local HomeLeftGroupbox = HomeTab:AddLeftGroupbox("🎄 Stats")
local WrappedLabel = HomeLeftGroupbox:AddLabel({ Text = "Loading... 🎄", DoesWrap = true })

-- 🌾 Farming Tab
local MainTab = Window:AddTab("Farming", "shovel")

-- 🎄 Farming Settings
local FarmingGroupbox = MainTab:AddLeftGroupbox("🎄 Farming")
local FieldDropdown = FarmingGroupbox:AddDropdown("FieldDropdown", {
    Values = {"🎄 Mushroom Field", "❄️ Blueberry Field", "🦌 Clover Field", "🎁 Spider Field", "⭐ Pineapple Field", "🔴 Strawberry Field", "🏔️ Mountain Field", "🎄 Pine Field", "🍉 Watermelon Field", "🍌 Banana Field", "⚙️ Cog Field"},
    Default = 1,
    Multi = false,
    Text = "🌾 Field",
    Callback = function(Value)
        local oldField = toggles.field
        toggles.field = Value
        saveSettings()
        
        -- If farming and field changed, move to new field
        if toggles.autoFarm and toggles.isFarming and oldField ~= Value then
            changeFieldWhileFarming(Value)
        end
    end
})

local AutoFarmToggle = FarmingGroupbox:AddToggle("AutoFarmToggle", {
    Text = "🎄 Auto Farm",
    Default = false,
    Callback = function(Value)
        toggles.autoFarm = Value
        saveSettings()
        if Value then
            startFarming()
        else
            toggles.isFarming = false
            toggles.isConverting = false
            toggles.atField = false
            toggles.atHive = false
            toggles.isMoving = false
        end
    end
})

local AutoDigToggle = FarmingGroupbox:AddToggle("AutoDigToggle", {
    Text = "⛄ Auto Dig",
    Default = false,
    Callback = function(Value)
        toggles.autoDig = Value
        saveSettings()
    end
})

local AutoEquipToggle = FarmingGroupbox:AddToggle("AutoEquipToggle", {
    Text = "🎁 Auto Equip Tools",
    Default = false,
    Callback = function(Value)
        toggles.autoEquip = Value
        saveSettings()
        if Value then
            addToConsole("🎄 Auto Equip Tools enabled!")
            equipAllTools()
        else
            addToConsole("🎄 Auto Equip Tools disabled")
        end
    end
})

-- 🎫 NEW: Ticket Converters Toggle
local TicketConvertersToggle = FarmingGroupbox:AddToggle("TicketConvertersToggle", {
    Text = "🎫 Use Ticket Converters",
    Default = false,
    Callback = function(Value)
        useTicketConverters = Value
        saveSettings()
        if Value then
            addToConsole("🎫 Ticket Converters enabled! 🎄")
        else
            addToConsole("🎫 Ticket Converters disabled")
        end
    end
})

-- 🚿 IMPROVED AUTO SPRINKLERS - MORE STABLE
local AutoSprinklersToggle = FarmingGroupbox:AddToggle("AutoSprinklersToggle", {
    Text = "🚿 Auto Sprinklers",
    Default = false,
    Callback = function(Value)
        autoSprinklersEnabled = Value
        saveSettings()
        if Value then
            addToConsole("🚿 Auto Sprinklers enabled! 🎄")
            sprinklerPlacementCount = 0
            sprinklerRetryCount = 0
            currentFieldVisits = {} -- Reset visits when enabling
            resetSprinklers()
        else
            addToConsole("🚿 Auto Sprinklers disabled")
        end
    end
})

local SprinklerDropdown = FarmingGroupbox:AddDropdown("SprinklerDropdown", {
    Values = {"🎁 Broken Sprinkler", "🎁 Basic Sprinkler", "❄️ Silver Soakers", "⭐ Golden Gushers", "🔴 Diamond Drenchers", "🎄 Supreme Saturator"},
    Default = 2,
    Multi = false,
    Text = "🚿 Sprinkler Type",
    Callback = function(Value)
        selectedSprinkler = Value
        saveSettings()
        addToConsole("🚿 Sprinkler type set to: " .. Value .. " 🎄")
        resetSprinklers() -- Reset when changing sprinkler type
    end
})

-- 🎄 Movement Settings
local MovementGroupbox = MainTab:AddRightGroupbox("🎄 Movement")
local MovementMethodDropdown = MovementGroupbox:AddDropdown("MovementMethod", {
    Values = {"⛄ Walk", "🎄 Tween"},
    Default = 1,
    Multi = false,
    Text = "🚶 Method",
    Callback = function(Value)
        toggles.movementMethod = Value
        saveSettings()
    end
})

local TweenSpeedSlider = MovementGroupbox:AddSlider("TweenSpeed", {
    Text = "🎄 Tween Speed",
    Default = 70,
    Min = 30,
    Max = 150,
    Rounding = 1,
    Compact = true,
    Callback = function(Value)
        toggles.tweenSpeed = Value
        saveSettings()
    end
})

-- 🎅 Player Settings
local PlayerGroupbox = MainTab:AddLeftGroupbox("🎅 Player")
local WalkspeedToggle = PlayerGroupbox:AddToggle("WalkspeedToggle", {
    Text = "⛄ Walkspeed",
    Default = false,
    Callback = function(Value)
        toggles.walkspeedEnabled = Value
        saveSettings()
        if not Value and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid then humanoid.WalkSpeed = 16 end
        end
    end
})

local WalkspeedSlider = PlayerGroupbox:AddSlider("WalkspeedSlider", {
    Text = "🎄 Speed",
    Default = 50,
    Min = 16,
    Max = 100,
    Rounding = 1,
    Compact = true,
    Callback = function(Value)
        toggles.walkspeed = Value
        saveSettings()
    end
})

-- ❄️ Anti-Lag Settings
local AntiLagGroupbox = MainTab:AddRightGroupbox("❄️ Performance")
local AntiLagToggle = AntiLagGroupbox:AddToggle("AntiLagToggle", {
    Text = "🎄 Anti Lag",
    Default = false,
    Tooltip = "Delete fruits and nature objects to reduce lag",
    Callback = function(Value)
        toggles.antiLag = Value
        saveSettings()
        if Value then
            addToConsole("🎄 Anti-Lag enabled - cleaning objects...")
            runAntiLag()
        else
            addToConsole("🎄 Anti-Lag disabled")
        end
    end
})

-- 🎁 NEW: Toys Tab
local ToysTab = Window:AddTab("Toys", "gift")

-- 🏔️ Mountain Booster
local MountainBoosterGroupbox = ToysTab:AddLeftGroupbox("🏔️ Mountain Booster")
local MountainBoosterToggle = MountainBoosterGroupbox:AddToggle("MountainBoosterToggle", {
    Text = "🎄 Auto Mountain Booster (30 min)",
    Default = false,
    Callback = function(Value)
        mountainBoosterEnabled = Value
        saveSettings()
        if Value then
            useMountainBooster()
            addToConsole("🏔️ Auto Mountain Booster enabled! 🎄")
        else
            addToConsole("🏔️ Auto Mountain Booster disabled")
        end
    end
})

-- 🔴 Red Booster
local RedBoosterGroupbox = ToysTab:AddLeftGroupbox("🔴 Red Booster")
local RedBoosterToggle = RedBoosterGroupbox:AddToggle("RedBoosterToggle", {
    Text = "🎄 Auto Red Booster (30 min)",
    Default = false,
    Callback = function(Value)
        redBoosterEnabled = Value
        saveSettings()
        if Value then
            useRedBooster()
            addToConsole("🔴 Auto Red Booster enabled! 🎄")
        else
            addToConsole("🔴 Auto Red Booster disabled")
        end
    end
})

-- 🔵 Blue Booster
local BlueBoosterGroupbox = ToysTab:AddRightGroupbox("🔵 Blue Booster")
local BlueBoosterToggle = BlueBoosterGroupbox:AddToggle("BlueBoosterToggle", {
    Text = "🎄 Auto Blue Booster (30 min)",
    Default = false,
    Callback = function(Value)
        blueBoosterEnabled = Value
        saveSettings()
        if Value then
            useBlueBooster()
            addToConsole("🔵 Auto Blue Booster enabled! 🎄")
        else
            addToConsole("🔵 Auto Blue Booster disabled")
        end
    end
})

-- ⏰ Wealth Clock
local WealthClockGroupbox = ToysTab:AddRightGroupbox("⏰ Wealth Clock")
local WealthClockToggle = WealthClockGroupbox:AddToggle("WealthClockToggle", {
    Text = "🎄 Auto Wealth Clock (1 hour)",
    Default = false,
    Callback = function(Value)
        wealthClockEnabled = Value
        saveSettings()
        if Value then
            useWealthClock()
            addToConsole("⏰ Auto Wealth Clock enabled! 🎄")
        else
            addToConsole("⏰ Auto Wealth Clock disabled")
        end
    end
})

-- 🌐 Webhook Tab
local WebhookTab = Window:AddTab("Webhook", "globe")
local WebhookGroupbox = WebhookTab:AddLeftGroupbox("🎄 Webhook Settings")

local WebhookToggle = WebhookGroupbox:AddToggle("WebhookToggle", {
    Text = "🎄 Enable Webhook",
    Default = false,
    Callback = function(Value)
        webhookEnabled = Value
        saveSettings()
        if Value then
            addToConsole("🎄 Webhook enabled!")
        else
            addToConsole("🎄 Webhook disabled")
        end
    end
})

local WebhookURLBox = WebhookGroupbox:AddInput("WebhookURL", {
    Text = "🎄 Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(Value)
        webhookURL = Value
        saveSettings()
    end
})

local WebhookIntervalSlider = WebhookGroupbox:AddSlider("WebhookInterval", {
    Text = "🎄 Send Interval (minutes)",
    Default = 5,
    Min = 1,
    Max = 60,
    Rounding = 1,
    Compact = true,
    Callback = function(Value)
        webhookInterval = Value
        saveSettings()
    end
})

WebhookGroupbox:AddButton("🎄 Send Test Webhook", function()
    if webhookEnabled and webhookURL ~= "" then
        addToConsole("🎄 Sending test webhook...")
        sendWebhook()
    else
        addToConsole("❌ Enable webhook and set URL first 🎄")
    end
end)

-- 🖥️ Console Tab
local ConsoleTab = Window:AddTab("Console", "terminal")
local ConsoleGroupbox = ConsoleTab:AddLeftGroupbox("🎄 Output")
consoleLabel = ConsoleGroupbox:AddLabel({ Text = "🎄 Lavender Hub v0.6 Ready! ⛄", DoesWrap = true })

-- 🐛 Debug Tab
local DebugTab = Window:AddTab("Debug", "bug")
local DebugGroupbox = DebugTab:AddLeftGroupbox("🎄 Performance Stats")
debugLabels.fps = DebugGroupbox:AddLabel("🎮 FPS: 0")
debugLabels.memory = DebugGroupbox:AddLabel("💾 Memory: 0 MB")
debugLabels.objects = DebugGroupbox:AddLabel("🗑️ Objects Deleted: 0")

local HoneyStatsGroupbox = DebugTab:AddRightGroupbox("🍯 Honey Statistics")
local HoneyMadeLabel = HoneyStatsGroupbox:AddLabel("🍯 Honey Made: 0")
local HourlyRateLabel = HoneyStatsGroupbox:AddLabel("⏰ Hourly Rate: 0")
local SessionHoneyLabel = HoneyStatsGroupbox:AddLabel("📊 Session Honey: 0")
local DailyHoneyLabel = HoneyStatsGroupbox:AddLabel("📅 Daily Honey: 0")

local DebugActionsGroupbox = DebugTab:AddRightGroupbox("🎄 Actions")
DebugActionsGroupbox:AddButton("🎄 Run Anti-Lag", function()
    if toggles.antiLag then
        runAntiLag()
    else
        addToConsole("🎄 Enable Anti-Lag first")
    end
end)

DebugActionsGroupbox:AddButton("🎄 Clear Console", function()
    consoleLogs = {}
    if consoleLabel then
        consoleLabel:SetText("🎄 Console cleared! ⛄")
    end
end)

DebugActionsGroupbox:AddButton("🎄 Equip Tools", function()
    equipAllTools()
    addToConsole("🎄 Manually equipped all tools!")
end)

-- 🔧 Status Groupbox
local StatusGroupbox = MainTab:AddRightGroupbox("🎄 Status")
local StatusLabel = StatusGroupbox:AddLabel("🔧 Status: Idle")
local PollenLabel = StatusGroupbox:AddLabel("🌸 Pollen: 0")
local HourlyHoneyLabel = StatusGroupbox:AddLabel("⏰ Hourly Honey: 0")
local SprinklerStatusLabel = StatusGroupbox:AddLabel("🚿 Sprinklers: 0 placed")

-- ⚙️ UI Settings Tab
local UISettingsTab = Window:AddTab("UI Settings", "settings")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)
SaveManager:LoadAutoloadConfig()

-- 🎄 Anti-AFK
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- 🎅 Setup death detection on startup
setupDeathDetection()

-- 🎄 Optimized Main Loops
local lastHeartbeatTime = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastHeartbeatTime < 0.1 then return end
    lastHeartbeatTime = currentTime
    
    updateFarmState()
    updateWalkspeed()
    clearVisitedTokens()
    updatePerformanceStats()
    autoEquipTools()
    updateToys()
    updateHoneyStats()
    sendWebhook()
    
    -- 🎄 Update status display
    local statusText = "⛄ Idle"
    local currentPollen = getCurrentPollen()
    local currentHoney = getCurrentHoney()
    
    if toggles.autoFarm then
        if toggles.isFarming and toggles.atField then
            statusText = "🎄 Farming"
        elseif toggles.isConverting and toggles.atHive then
            statusText = "🏠 Converting"
        elseif toggles.isFarming then
            statusText = "🎄 Moving to Field"
        elseif toggles.isConverting then
            statusText = "🏠 Moving to Hive"
        end
    end
    
    StatusLabel:SetText("🔧 Status: " .. statusText)
    PollenLabel:SetText("🌸 Pollen: " .. formatNumberCorrect(currentPollen))
    HourlyHoneyLabel:SetText("⏰ Hourly Honey: " .. formatNumberCorrect(honeyStats.hourlyRate))
    SprinklerStatusLabel:SetText("🚿 Sprinklers: " .. placedSprinklersCount .. "/" .. expectedSprinklerCount .. " placed")
    
    -- 🎄 Update debug labels
    HoneyMadeLabel:SetText("🍯 Honey Made: " .. formatNumberCorrect(honeyStats.honeyMade))
    HourlyRateLabel:SetText("⏰ Hourly Rate: " .. formatNumberCorrect(honeyStats.hourlyRate))
    SessionHoneyLabel:SetText("📊 Session Honey: " .. formatNumberCorrect(honeyStats.sessionHoney))
    DailyHoneyLabel:SetText("📅 Daily Honey: " .. formatNumberCorrect(honeyStats.dailyHoney))
end)

-- 🎄 Stats Update Loop
spawn(function()
    while task.wait(1) do
        local currentPollen = getCurrentPollen()
        local currentHoney = getCurrentHoney()
        
        WrappedLabel:SetText(string.format(
            "🍯 Honey: %s\n🌸 Pollen: %s\n🌾 Field: %s\n🏠 Hive: %s\n🚶 Move: %s\n⛄ Dig: %s\n🎁 Equip: %s\n🎄 Anti-Lag: %s\n⏰ Hourly Honey: %s\n🚿 Auto Sprinklers: %s\n🚿 Sprinkler Type: %s\n🎫 Ticket Converters: %s\n📊 Session Honey: %s\n📅 Daily Honey: %s",
            formatNumberCorrect(currentHoney),
            formatNumberCorrect(currentPollen),
            toggles.field,
            displayHiveName,
            toggles.movementMethod,
            toggles.autoDig and "ON" or "OFF",
            toggles.autoEquip and "ON" or "OFF",
            toggles.antiLag and "ON" or "OFF",
            formatNumberCorrect(honeyStats.hourlyRate),
            autoSprinklersEnabled and "ON" or "OFF",
            selectedSprinkler,
            useTicketConverters and "ON" or "OFF",
            formatNumberCorrect(honeyStats.sessionHoney),
            formatNumberCorrect(honeyStats.dailyHoney)
        ))
    end
end)

-- 🎄 Load settings on startup
loadSettings()

-- 🎅 Apply loaded settings to GUI
FieldDropdown:Set(toggles.field)
AutoFarmToggle:Set(toggles.autoFarm)
AutoDigToggle:Set(toggles.autoDig)
AutoEquipToggle:Set(toggles.autoEquip)
AntiLagToggle:Set(toggles.antiLag)
MovementMethodDropdown:Set(toggles.movementMethod)
TweenSpeedSlider:Set(toggles.tweenSpeed)
WalkspeedToggle:Set(toggles.walkspeedEnabled)
WalkspeedSlider:Set(toggles.walkspeed)
AutoSprinklersToggle:Set(autoSprinklersEnabled)
SprinklerDropdown:Set(selectedSprinkler)
WebhookToggle:Set(webhookEnabled)
WebhookURLBox:Set(webhookURL)
WebhookIntervalSlider:Set(webhookInterval)
TicketConvertersToggle:Set(useTicketConverters)
MountainBoosterToggle:Set(mountainBoosterEnabled)
RedBoosterToggle:Set(redBoosterEnabled)
BlueBoosterToggle:Set(blueBoosterEnabled)
WealthClockToggle:Set(wealthClockEnabled)

-- 🏠 Update owned hive after claiming
ownedHive = getOwnedHive()
displayHiveName = ownedHive and "🏠 Hive" or "💔 None"

-- 🍯 Initialize honey tracking - STARTS AT 0
honeyStats.startHoney = getCurrentHoney()
honeyStats.currentHoney = honeyStats.startHoney
honeyStats.lastHoneyValue = honeyStats.startHoney
honeyStats.trackingStarted = false
honeyStats.firstAutoFarmEnabled = false
honeyStats.honeyMade = 0
honeyStats.hourlyRate = 0
honeyStats.sessionHoney = 0
honeyStats.dailyHoney = 0

-- 🎄 Run anti-lag on startup if enabled
if toggles.antiLag then
    addToConsole("🎄 Running startup Anti-Lag...")
    runAntiLag()
end

addToConsole("🎄 MERRY CHRISTMAS! 🎅")
addToConsole("✅ 🎄 Lavender Hub v0.6 Ready! ⛄")
addToConsole("🎯 🎄 Auto Farm System Ready!")
addToConsole("🚿 🎄 IMPROVED Auto Sprinklers System Ready!")
addToConsole("💀 🎄 Death Respawn System Ready!")
addToConsole("🌐 🎄 Webhook System Ready!")
addToConsole("🎫 🎄 Ticket Converters System Ready!")
addToConsole("🎁 🎄 Toys/Boosters System Ready!")
if ownedHive then
    addToConsole("🏠 🎄 Owned Hive: " .. ownedHive)
else
    addToConsole("💔 🎄 No hive owned")
end
