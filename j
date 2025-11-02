--// Load Rayfield ---------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// Services ---------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local LocalPlayer       = Players.LocalPlayer
local Lighting          = game:GetService("Lighting")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local HttpService       = game:GetService("HttpService")

--// Remotes ---------------------------------------------------------------
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework"):WaitForChild("Network")
    :WaitForChild("Remote"):WaitForChild("RemoteEvent")

local RemoteFunction = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework"):WaitForChild("Network")
    :WaitForChild("Remote"):WaitForChild("RemoteFunction")

local SpawnPickups      = ReplicatedStorage:WaitForChild("Remotes")
    :WaitForChild("Pickups"):WaitForChild("SpawnPickups")
local CollectPickup     = ReplicatedStorage:WaitForChild("Remotes")
    :WaitForChild("Pickups"):WaitForChild("CollectPickup")

--// Rayfield Window -------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "demonhub",
    LoadingTitle = "demonhub",
    LoadingSubtitle = "sskint",
    ConfigurationSaving = { Enabled = true, FolderName = "demonhub" }
})

--// Helper: Fire Touch 10 Times --------------------------------------------
local function fireTouchTenTimes(part)
    if not part or not part:FindFirstChild("UnlockHitbox") then return end
    local hitbox = part.UnlockHitbox
    if not hitbox or not hitbox:FindFirstChild("TouchInterest") then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for i = 1, 10 do
        firetouchinterest(root, hitbox, 0); task.wait()
        firetouchinterest(root, hitbox, 1); task.wait(0.05)
    end
end

--// UNLOCKS TAB -----------------------------------------------------------
local UnlocksTab = Window:CreateTab("Unlocks")

UnlocksTab:CreateButton({
    Name = "Unlock Overworld",
    Callback = function()
        local world = Workspace:FindFirstChild("Worlds") and Workspace.Worlds:FindFirstChild("The Overworld")
        if not world then Rayfield:Notify({Title="Error",Content="Overworld not found!",Duration=3}); return end
        local c = 0
        for _,island in ipairs(world.Islands:GetChildren()) do
            if island:FindFirstChild("Island") then fireTouchTenTimes(island.Island); c+=1 end
        end
        Rayfield:Notify({Title="Unlocked",Content=string.format("Unlocked %d Overworld islands (10x)!",c),Duration=4})
    end
})

UnlocksTab:CreateButton({
    Name = "Unlock Minigame Paradise",
    Callback = function()
        local world = Workspace:FindFirstChild("Worlds") and Workspace.Worlds:FindFirstChild("Minigame Paradise")
        if not world then Rayfield:Notify({Title="Error",Content="Minigame Paradise not found!",Duration=3}); return end
        local c = 0
        for _,island in ipairs(world.Islands:GetChildren()) do fireTouchTenTimes(island); c+=1 end
        Rayfield:Notify({Title="Unlocked",Content=string.format("Unlocked %d Minigame islands (10x)!",c),Duration=4})
    end
})

--// AUTOMATION TAB --------------------------------------------------------
local AutoTab = Window:CreateTab("Automation")

local autoBubbleEnabled = false
AutoTab:CreateToggle({
    Name = "Auto Bubble",
    CurrentValue = false,
    Callback = function(v)
        autoBubbleEnabled = v
        if v then task.spawn(function()
            while autoBubbleEnabled do
                RemoteEvent:FireServer("BlowBubble")
                task.wait(0.1)
            end
        end) end
    end
})

--// EGG LIST --------------------------------------------------------------
local eggList = {
    "Puppet Egg","100M Egg","200M Egg","500M Egg","Atlantis Egg","Aura Egg","Autumn Egg","Beach Egg","Bee Egg","Brainrot Egg","Bruh Egg",
    "Bunny Egg","Candy Egg","Cartoon Egg","Chance Egg","Classic Egg","Common Egg","Costume Egg","Crystal Egg","Cyber Egg","Dark Egg",
    "Developer Egg","Dreamer Egg","Duality Egg","Easter Egg","Easter2 Egg","Federation Egg","Fossil Egg","Fruit Egg","Game Egg",
    "Hell Egg","Icecream Egg","Iceshard Egg","Icy Egg","Inferno Egg","Infinity Egg","Jester Egg","July4th Egg","Lava Egg","Light Egg",
    "Lunar Egg","Magma Egg","Mining Egg","Mutant Egg","Neon Egg","Nightmare Egg","Pastel Egg","Pirate Egg","Pumpkin Egg","Rainbow Egg",
    "Season 1 Egg","Season 2 Egg","Season 3 Egg","Season 4 Egg","Season 5 Egg","Season 6 Egg","Season 7 Egg","Season 8 Egg","Season 9 Egg",
    "Secret Egg","Series 1 Egg","Series 2 Egg","Shadow Egg","Shop Egg","Showman Egg","Silly Egg","Sinister Egg","Spikey Egg","Spooky Egg",
    "Spotted Egg","Stellaris Egg","Throwback Egg","Underworld Egg","Vine Egg","Void Egg","Voidcrystal Egg"
}
table.sort(eggList)

local eggNamesSet = {}
for _, eggName in ipairs(eggList) do eggNamesSet[eggName] = true end

--// SHARED HATCH AMOUNT ---------------------------------------------------
local hatchAmount = 1

AutoTab:CreateSlider({
    Name = "Hatch Amount (for both modes)",
    Range = {1,15},
    Increment = 1,
    CurrentValue = hatchAmount,
    Callback = function(v) hatchAmount = v end
})

--// AUTO HATCH: MULTI-SELECT ---------------------------------------------
local selectedHatchEggs = {}
local autoHatchEnabled = false

AutoTab:CreateDropdown({
    Name = "Select Eggs to Auto Hatch",
    Options = eggList,
    CurrentOption = {},
    MultipleOptions = true,
    Callback = function(selected)
        selectedHatchEggs = selected
        Rayfield:Notify({Title="Auto Hatch", Content="Selected: "..(#selected>0 and table.concat(selected, ", ") or "None"), Duration=3})
    end
})

AutoTab:CreateToggle({
    Name = "Auto Hatch (Multi)",
    CurrentValue = false,
    Callback = function(v)
        autoHatchEnabled = v
        if v and #selectedHatchEggs == 0 then
            Rayfield:Notify({Title="Error", Content="Select at least one egg!", Duration=3})
            return
        end
        if v then
            task.spawn(function()
                while autoHatchEnabled do
                    for _, egg in ipairs(selectedHatchEggs) do
                        if not autoHatchEnabled then break end
                        RemoteEvent:FireServer("HatchEgg", egg, hatchAmount)
                        task.wait(0.1)
                    end
                    task.wait(0.05)
                end
            end)
            Rayfield:Notify({Title="Auto Hatch ON", Content="Hatching "..#selectedHatchEggs.." eggs x"..hatchAmount, Duration=3})
        end
    end
})

--// AUTO HATCH CLOSEST EGG (SPAM + 1s SCAN) ------------------------------
local autoHatchClosestEnabled = false
local closestEggDistance = 30
local currentClosestEgg = nil
local eggCache = {}

local function refreshEggCache()
    eggCache = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if eggNamesSet[obj.Name] then
            local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
            if part then
                table.insert(eggCache, { name = obj.Name, position = part.Position })
            end
        end
    end
end

AutoTab:CreateToggle({
    Name = "Auto Hatch Closest Egg ",
    CurrentValue = false,
    Callback = function(v)
        autoHatchClosestEnabled = v
        if v then
            refreshEggCache()
            task.spawn(function()
                local scanTimer = 0
                while autoHatchClosestEnabled do
                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not root then task.wait(0.5); continue end

                    local playerPos = root.Position
                    local closestName = nil
                    local closestDist = math.huge

                    for _, egg in ipairs(eggCache) do
                        local dist = (playerPos - egg.position).Magnitude
                        if dist < closestDist and dist <= closestEggDistance then
                            closestDist = dist
                            closestName = egg.name
                        end
                    end

                    if closestName and closestName ~= currentClosestEgg then
                        currentClosestEgg = closestName
                        Rayfield:Notify({
                            Title = "hatching",
                            Content = "" .. closestName .. " x" .. hatchAmount .. " (~" .. math.floor(closestDist) .. " studs)",
                            Duration = 2
                        })
                    end

                    -- SPAM REMOTE AS FAST AS POSSIBLE
                    if currentClosestEgg then
                        RemoteEvent:FireServer("HatchEgg", currentClosestEgg, hatchAmount)
                    end

                    -- SCAN EVERY 1 SECOND
                    scanTimer += 0.05
                    if scanTimer >= 1 then
                        refreshEggCache()
                        scanTimer = 0
                    end

                    task.wait(0.05)  -- Max fire rate
                end
            end)
            Rayfield:Notify({Title="hatcging enabled", Content="hatches closest egg  | Scans every 1s", Duration=3})
        else
            currentClosestEgg = nil
            eggCache = {}
        end
    end
})

AutoTab:CreateSlider({
    Name = "Proximity Distance (studs)",
    Range = {10, 100},
    Increment = 5,
    CurrentValue = closestEggDistance,
    Callback = function(v) closestEggDistance = v end
})

--// AUTO SPIN -------------------------------------------------------------
local autoSpinEnabled = false
AutoTab:CreateToggle({
    Name = "Auto Spin Halloween Wheel",
    CurrentValue = false,
    Callback = function(v)
        autoSpinEnabled = v
        if v then task.spawn(function()
            while autoSpinEnabled do
                RemoteFunction:InvokeServer("HalloweenWheelSpin")
                task.wait(2)
            end
        end)
        Rayfield:Notify({Title="Auto Spin",Content="Spinning Halloween Wheel!",Duration=3})
        end
    end
})

--// AUTO PICKUPS ----------------------------------------------------------
local autoPickupsEnabled = false
local pickupConnection = nil
local pickupQueue = {}
AutoTab:CreateToggle({
    Name = "Auto Pickups (0.5s delay)",
    CurrentValue = false,
    Callback = function(v)
        autoPickupsEnabled = v
        if v then
            task.spawn(function()
                while autoPickupsEnabled do
                    if #pickupQueue > 0 then
                        for _, id in ipairs(pickupQueue) do
                            CollectPickup:FireServer(id)
                        end
                        pickupQueue = {}
                    end
                    task.wait(0.5)
                end
            end)
            pickupConnection = SpawnPickups.OnClientEvent:Connect(function(d)
                if not autoPickupsEnabled or not d then return end
                for _, p in ipairs(d) do
                    local id = p.Id or p.id
                    if id and type(id) == "string" and #id == 36 then
                        table.insert(pickupQueue, id)
                    end
                end
            end)
            Rayfield:Notify({Title="Auto Pickups",Content="ON with 0.5s delay",Duration=4})
        else
            if pickupConnection then pickupConnection:Disconnect(); pickupConnection = nil end
            pickupQueue = {}
        end
    end
})

--// EVENT TAB – AUTO HOUSES -----------------------------------------------
local EventTab = Window:CreateTab("Event")

local isAutoHouses = false
local standDelay = 1
local teleportDelay = 0.1

EventTab:CreateToggle({ Name = "Auto Houses (Halloween Event)", CurrentValue = false, Callback = function(v) isAutoHouses = v end })
EventTab:CreateSlider({ Name = "Stand Delay (seconds)", Range = {0.5,5}, Increment = 0.1, CurrentValue = standDelay, Callback = function(v) standDelay = v end })
EventTab:CreateSlider({ Name = "Teleport Delay (seconds)", Range = {0.1,2}, Increment = 0.1, CurrentValue = teleportDelay, Callback = function(v) teleportDelay = v end })

local function tp(cf) 
    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
    if r then r.CFrame = cf end 
end

local function dist(p) 
    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
    if r and p then return (r.Position - p.Position).Magnitude end 
    return math.huge 
end

local function claim(part)
    local base = part.CFrame * CFrame.new(0, 3, 0)
    local off  = part.CFrame * CFrame.new(5, 3, 0)
    tp(off); task.wait(0.1); tp(base)
    for i = 1, math.floor(standDelay) do 
        if not isAutoHouses then break end 
        tp(base * CFrame.new(0, i, 0)); task.wait(1) 
    end
    if standDelay > math.floor(standDelay) then task.wait(standDelay - math.floor(standDelay)) end
end

task.spawn(function()
    while true do
        if not isAutoHouses then task.wait(0.1); continue end
        local hall = Workspace:FindFirstChild("HalloweenEvent")
        if not hall then task.wait(1); continue end
        local houses = hall:FindFirstChild("Houses")
        if not houses then task.wait(1); continue end
        local list = {}
        for _, h in ipairs(houses:GetChildren()) do
            local act = h:FindFirstChild("Activation")
            if act and act:FindFirstChild("Active") and act.Active.Value then
                local p = act.PrimaryPart or act:FindFirstChildWhichIsA("BasePart")
                if p then table.insert(list, {house = h, dist = dist(p)}) end
            end
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)
        for _, v in ipairs(list) do
            if not isAutoHouses then break end
            local act = v.house:FindFirstChild("Activation")
            if act then
                local p = act.PrimaryPart or act:FindFirstChildWhichIsA("BasePart")
                if p then claim(p) end
            end
        end
        task.wait(teleportDelay)
    end
end)

--// FINAL RIFT MANAGER SYSTEM (CLEAN + OPTIMIZED)
--// Author: ChatGPT GPT-5

--// Services (Re-declaring for module safety, though already declared above)
--// local HttpService = game:GetService("HttpService")
--// local Workspace = game:GetService("Workspace")
--// local Players = game:GetService("Players")
--// local LocalPlayer = Players.LocalPlayer

--// Rayfield UI (assumed to exist)
local RiftTab = Window:CreateTab("Rifts")
local OptTab = Window:CreateTab("Optimizations")

--// Internal Data
local RiftMemory = {}
local RiftLabels = {}
local originalPosition = nil
local returnedToOriginal = false
local autoTPEnabled = false
local returnToPositionEnabled = true
local autoMemoryClearEnabled = false
local luckThreshold = 0
local selectedRiftTypes = {}
local teleportDistanceThreshold = 5

--// Rift Name Map
local RiftNameMap = {
    ["event-1"] = "Pumpkin Egg",
    ["event-2"] = "Costume Egg",
    ["event-3"] = "Sinister Egg",
    ["event-4"] = "Mutant Egg",
    ["event-5"] = "Puppet Egg",
}

--// ⚙️ UI ELEMENTS

local CurrentTargetLabel = RiftTab:CreateLabel("Current Target: None")

-- Multi-select dropdown
local RiftSelect = RiftTab:CreateDropdown({
    Name = "Select Rift Types to Prioritize",
    Options = {"Pumpkin Egg", "Costume Egg", "Sinister Egg", "Mutant Egg", "Puppet Egg"},
    CurrentOption = {},
    MultipleOptions = true,
    Callback = function(selected)
        selectedRiftTypes = {}
        for _, riftName in ipairs(selected) do
            for id, name in pairs(RiftNameMap) do
                if name == riftName then
                    selectedRiftTypes[id] = true
                end
            end
        end
    end
})

-- Luck threshold slider
RiftTab:CreateSlider({
    Name = "Luck Threshold",
    Range = {0, 10000},
    Increment = 50,
    Suffix = "x",
    CurrentValue = 0,
    Callback = function(value)
        luckThreshold = value
    end
})

-- Return to original toggle
RiftTab:CreateToggle({
    Name = "Return to Original Position When Auto TP Stops",
    CurrentValue = true,
    Callback = function(v)
        returnToPositionEnabled = v
    end
})

-- Optimization toggle
OptTab:CreateToggle({
    Name = "Auto Clear Memory (Every 1 Minute)",
    CurrentValue = false,
    Callback = function(v)
        autoMemoryClearEnabled = v
        if v then
            task.spawn(function()
                while autoMemoryClearEnabled do
                    task.wait(60)
                    collectgarbage("collect")
                    Rayfield:Notify({
                        Title = "Memory Optimizer",
                        Content = "Cleared unused memory to improve performance.",
                        Duration = 3
                    })
                end
            end)
        end
    end
})

--// Utility Functions

local function generateRiftID(rift)
    local id = HttpService:GenerateGUID(false)
    rift:SetAttribute("_riftID", id)
    return id
end

local function getLuckFromRift(rift)
    if not rift or not rift.Parent then return 0 end

    local luckObj = rift:FindFirstChild("Display")
        and rift.Display:FindFirstChild("SurfaceGui")
        and rift.Display.SurfaceGui:FindFirstChild("Icon")
        and rift.Display.SurfaceGui.Icon:FindFirstChild("Luck")

    if not luckObj then return 0 end

    if luckObj:IsA("TextLabel") then
        local text = luckObj.Text:gsub("[^%d%.]", "")
        return tonumber(text) or 0
    elseif luckObj:IsA("NumberValue") then
        local v = luckObj.Value
        if typeof(v) == "NumberRange" then
            return v.Max or v.Min or 0
        else
            return tonumber(v) or 0
        end
    elseif luckObj:IsA("StringValue") then
        local num = tonumber(luckObj.Value)
        if not num and typeof(luckObj.Value) == "NumberRange" then
            return luckObj.Value.Max or luckObj.Value.Min or 0
        end
        return num or 0
    end

    return 0
end

local function getRiftCFrame(rift)
    if not rift or not rift.Parent then return nil end
    local spawn = rift:FindFirstChild("EggPlatformSpawn")
    if not spawn then return nil end

    if spawn:IsA("BasePart") then
        return spawn.CFrame
    elseif spawn:IsA("Model") then
        if spawn.PrimaryPart then
            return spawn.PrimaryPart.CFrame
        else
            local part = spawn:FindFirstChildWhichIsA("BasePart", true)
            if part then
                return part.CFrame
            end
        end
    end

    return nil
end

local function teleportToRift(rift)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local cf = getRiftCFrame(rift)
    if cf then
        root.CFrame = cf + Vector3.new(0, 3, 0)
        return true
    end
    return false
end

local function returnToOriginalPosition()
    if not returnToPositionEnabled then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and originalPosition then
        root.CFrame = originalPosition
    end
end

--// UI Creation + Removal

local function createRiftUI(rift, id, luck)
    local displayName = RiftNameMap[rift.Name] or rift.Name
    local label = RiftTab:CreateLabel(displayName .. " | Luck: " .. luck .. "x")
    local button = RiftTab:CreateButton({
        Name = "TP to " .. displayName,
        Callback = function() teleportToRift(rift) end
    })
    RiftLabels[id] = {label = label, button = button}
end

local function removeRiftFromMemory(id)
    local ui = RiftLabels[id]
    if ui then
        if ui.label and typeof(ui.label.Destroy) == "function" then
            pcall(function() ui.label:Destroy() end)
        end
        if ui.button and typeof(ui.button.Destroy) == "function" then
            pcall(function() ui.button:Destroy() end)
        end
        RiftLabels[id] = nil
    end
    RiftMemory[id] = nil
end

--// Rift Refresh Logic (FIXED)

local function refreshRifts()
    local folder = Workspace:FindFirstChild("Rendered") and Workspace.Rendered:FindFirstChild("Rifts")
    local seen = {}

    if folder then
        -- Populate 'seen' table with currently visible rifts
        for _, rift in ipairs(folder:GetChildren()) do
            if rift:IsA("Model") then
                local id = rift:GetAttribute("_riftID") or generateRiftID(rift)
                seen[id] = true
                local luck = getLuckFromRift(rift)

                if not RiftMemory[id] then
                    -- New rift found, create UI
                    RiftMemory[id] = rift
                    createRiftUI(rift, id, luck)
                else
                    -- Existing rift, update UI
                    local ui = RiftLabels[id]
                    if ui and ui.label then
                        local name = RiftNameMap[rift.Name] or rift.Name
                        ui.label:Set(name .. " | Luck: " .. luck .. "x")
                    end
                end
            end
        end
    else
        -- Folder not found, handle return to original position
        if autoTPEnabled and not returnedToOriginal then
            returnToOriginalPosition()
            returnedToOriginal = true
            Rayfield:Notify({
                Title = "Rift Scanner",
                Content = "Rifts not found, returned to original position.",
                Duration = 3
            })
        end
        -- Do not return! Allow cleanup to run.
    end

    -- Cleanup deleted Rifts (This now runs regardless of 'folder' existing)
    -- If 'folder' was nil, 'seen' is empty, so everything in RiftMemory will be removed.
    for id, rift in pairs(RiftMemory) do
        if not seen[id] or not (rift and rift.Parent) then
            removeRiftFromMemory(id)
        end
    end

    -- Choose best Rift
    local bestRift, bestLuck = nil, -math.huge
    for id, rift in pairs(RiftMemory) do -- RiftMemory is now clean
        if rift and rift.Parent then
            local internalName = rift.Name
            local luck = getLuckFromRift(rift)
            local allowed = true

            if next(selectedRiftTypes) then
                allowed = selectedRiftTypes[internalName] == true
            end

            if allowed and luck >= luckThreshold and luck > bestLuck then
                bestLuck = luck
                bestRift = rift
            end
        end
    end

    -- Handle auto TP
    if not autoTPEnabled then
        CurrentTargetLabel:Set("Current Target: (Auto TP Disabled)")
        return
    end

    if not bestRift then
        if not returnedToOriginal then
            returnToOriginalPosition()
            returnedToOriginal = true
            Rayfield:Notify({
                Title = "Rift Scanner",
                Content = "No valid rifts left — returned to start.",
                Duration = 3
            })
        end
        CurrentTargetLabel:Set("Current Target: None")
        return
    end

    if returnedToOriginal then
        returnedToOriginal = false
    end

    local name = RiftNameMap[bestRift.Name] or bestRift.Name
    CurrentTargetLabel:Set(("Current Target: %s (%.1fx Luck)"):format(name, bestLuck))

    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local cf = getRiftCFrame(bestRift)
        if cf and (root.Position - cf.Position).Magnitude > teleportDistanceThreshold then
            teleportToRift(bestRift)
        end
    end
end


--// Auto TP Toggle
RiftTab:CreateToggle({
    Name = "Auto TP to Filtered Rifts",
    CurrentValue = false,
    Callback = function(v)
        autoTPEnabled = v
        if v then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                originalPosition = root.CFrame
                returnedToOriginal = false
                Rayfield:Notify({
                    Title = "Rift Scanner",
                    Content = "Saved current position for return.",
                    Duration = 2
                })
            end
        else
            if returnToPositionEnabled then
                returnToOriginalPosition()
                Rayfield:Notify({
                    Title = "Rift Scanner",
                    Content = "Returned to start.",
                    Duration = 2
                })
            end
            returnedToOriginal = false
        end
    end
})

--// 🔁 Fast Scan Loop
task.spawn(function()
    while true do
        pcall(refreshRifts)
        task.wait(0.1)
    end
end)

--// PERFORMANCE TAB -------------------------------------------------------
local PerfTab = Window:CreateTab("Performance")

local limitFpsEnabled = false
local targetFps = 30

PerfTab:CreateToggle({
    Name = "Enable FPS Limiter",
    CurrentValue = false,
    Callback = function(v)
        limitFpsEnabled = v
        Rayfield:Notify({Title="FPS Limiter", Content=v and "ON" or "OFF", Duration=2})
    end
})

PerfTab:CreateSlider({
    Name = "Target FPS",
    Range = {15, 60},
    Increment = 1,
    CurrentValue = targetFps,
    Callback = function(v) targetFps = v end
})

task.spawn(function()
    while true do
        if limitFpsEnabled then
            local t = 1/targetFps
            local dt = RunService.Heartbeat:Wait()
            if dt < t then task.wait(t - dt) end
        else
            RunService.Heartbeat:Wait()
        end
    end
end)

PerfTab:CreateButton({
    Name = "Set Low Quality (Anti-Lag)",
    Callback = function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Rayfield:Notify({Title="Anti-Lag", Content="Graphics set to Low Quality!", Duration=3})
    end
})

local renderEnabled = true
local originalLighting = nil
local originalTerrainDeco = nil
local originalQuality = nil
local originalsCaptured = false

PerfTab:CreateToggle({
    Name = "Toggle Full Render",
    CurrentValue = true,
    Callback = function(v)
        if not originalsCaptured then
            local success = pcall(function()
                originalLighting = { Technology = Lighting.Technology, GlobalShadows = Lighting.GlobalShadows }
                originalTerrainDeco = Workspace.Terrain.Decoration
                originalQuality = settings().Rendering.QualityLevel
                originalsCaptured = true
            end)
            if not success then
                Rayfield:Notify({Title="Error", Content="Could not capture render settings.", Duration=4})
                return
            end
        end

        renderEnabled = v
        if not v then
            Lighting.Technology = Enum.Technology.Compatibility 
            Lighting.GlobalShadows = false
            Workspace.Terrain.Decoration = false
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Rayfield:Notify({Title="Render", Content="OFF", Duration=2})
        else
            Lighting.Technology = originalLighting.Technology 
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Workspace.Terrain.Decoration = originalTerrainDeco
            settings().Rendering.QualityLevel = originalQuality
            Rayfield:Notify({Title="Render", Content="ON", Duration=2})
        end
    end
})

local originalShadows = Lighting.GlobalShadows
PerfTab:CreateToggle({
    Name = "Disable Shadows",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Lighting.GlobalShadows = false
            Rayfield:Notify({Title="Shadows", Content="OFF", Duration=2})
        else
            Lighting.GlobalShadows = originalShadows
            Rayfield:Notify({Title="Shadows", Content="Restored", Duration=2})
        end
    end
})

PerfTab:CreateButton({
    Name = "Disable All Particles",
    Callback = function()
        local c = 0
        for _, v in ipairs(Workspace:GetDescendants()) do 
            if v:IsA("ParticleEmitter") then 
                v.Enabled = false 
                c += 1
            end 
        end
        Rayfield:Notify({Title="Particles", Content="Disabled "..c.." particles.", Duration=3})
    end
})

PerfTab:CreateButton({
    Name = "Disable Animations",
    Callback = function()
        local animCount = 0
        local animatorCount = 0
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Animation") then
                v:Destroy()
                animCount += 1
            elseif v:IsA("Animator") then
                local isPlayer = LocalPlayer.Character and v:IsDescendantOf(LocalPlayer.Character)
                if not isPlayer then
                    v:Destroy()
                    animatorCount += 1
                end
            end
        end
        Rayfield:Notify({Title="Animations", Content=string.format("Removed %d anims & destroyed %d animators.", animCount, animatorCount), Duration=3})
    end
})

PerfTab:CreateButton({
    Name = "Disable World Sounds",
    Callback = function()
        local c = 0
        for _, v in ipairs(Workspace:GetDescendants()) do 
            if v:IsA("Sound") then 
                v:Destroy()
                c += 1
            end 
        end
        Rayfield:Notify({Title="Sounds", Content="Disabled "..c.." sounds.", Duration=3})
    end
})

PerfTab:CreateButton({
    Name = "Disable Textures & Decals",
    Callback = function()
        local c = 0
        for _, v in ipairs(Workspace:GetDescendants()) do 
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then 
                v:Destroy()
                c += 1
            end 
        end
        Rayfield:Notify({Title="Textures", Content="Set material to plastic & removed "..c.." decals/textures.", Duration=3})
    end
})

local function deleteAssets()
    local partsToDelete = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") or v:IsA("MeshPart") then
            local keep = v:IsDescendantOf(LocalPlayer.Character)
            if not keep then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and v:IsDescendantOf(p.Character) then
                        keep = true; break
                    end
                end
            end
            if not keep then
                local current = v
                while current and current ~= Workspace do
                    if eggNamesSet[current.Name] then keep = true; break end
                    current = current.Parent
                end
            end
            if not keep then table.insert(partsToDelete, v) end
        end
    end
    Rayfield:Notify({Title="Asset Deleter", Content="Deleting " .. #partsToDelete .. " assets...", Duration=3})
    for _, v in ipairs(partsToDelete) do pcall(v.Destroy, v) end
    Rayfield:Notify({Title="Asset Deleter", Content="Done!", Duration=2})
end

PerfTab:CreateButton({ Name = "Delete Un-needed Assets", Callback = deleteAssets })


--// MISC TAB --------------------------------------------------------------
local MiscTab = Window:CreateTab("Misc")

local antiIdleConnection = nil
MiscTab:CreateToggle({
    Name = "Anti-Idle (Jumps)",
    CurrentValue = false,
    Callback = function(v)
        if v and not antiIdleConnection then
            antiIdleConnection = LocalPlayer.Idled:Connect(function()
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end)
            Rayfield:Notify({Title="Anti-Idle", Content="ON", Duration=2})
        elseif not v and antiIdleConnection then
            antiIdleConnection:Disconnect()
            antiIdleConnection = nil
            Rayfield:Notify({Title="Anti-Idle", Content="OFF", Duration=2})
        end
    end
})

local autoClickerDelay = 100
local autoClickerEnabled = false
MiscTab:CreateSlider({ Name = "Auto Clicker Delay (ms)", Range = {10, 2000}, Increment = 10, CurrentValue = autoClickerDelay, Callback = function(v) autoClickerDelay = v end })
MiscTab:CreateToggle({ Name = "Auto Clicker (Middle of Screen)", CurrentValue = false, Callback = function(v)
    autoClickerEnabled = v
    if v then
        task.spawn(function()
            while autoClickerEnabled do
                if Workspace.CurrentCamera then
                    local size = Workspace.CurrentCamera.ViewportSize
                    VirtualUser:ClickButton1(Vector2.new(size.X/2, size.Y/2))
                    task.wait(autoClickerDelay / 1000)
                else
                    task.wait(1)
                end
            end
        end)
        Rayfield:Notify({Title="Auto Clicker", Content="ON", Duration=2})
    else
        Rayfield:Notify({Title="Auto Clicker", Content="OFF", Duration=2})
    end
end })

--// WEBHOOK TAB -----------------------------------------------------------
local WebhookTab = Window:CreateTab("Webhook")

local webhookUrl = ""
local webhookEnabled = false
local webhookQueue = {}
local lastSent = 0

local function fixUrl(u) return u:gsub("%s",""):gsub("^https?://discordapp%.com/", "https://discord.com/") end

WebhookTab:CreateInput({ Name = "Discord Webhook URL", PlaceholderText = "https://discord.com/api/webhooks/...", Callback = function(t) webhookUrl = fixUrl(t) end })
WebhookTab:CreateButton({ Name = "Save Webhook URL", Callback = function() webhookUrl = fixUrl(webhookUrl); Rayfield:Notify({Title="Saved", Content="Webhook URL saved!", Duration=2}) end })
WebhookTab:CreateButton({ Name = "Test Webhook", Callback = function()
    if not webhookUrl:match("^https://discord%.com/api/webhooks/") then
        Rayfield:Notify({Title="Error", Content="Invalid URL!", Duration=3}); return
    end
    table.insert(webhookQueue, {type="text", content="Test from demonhub! request() WORKS!"})
    Rayfield:Notify({Title="Test Queued", Content="Sending via request()...", Duration=3})
end })
WebhookTab:CreateToggle({ Name = "Enable Hatch Webhook", CurrentValue = false, Callback = function(v) webhookEnabled = v; Rayfield:Notify({Title="Webhook", Content=v and "ON" or "OFF", Duration=2}) end })



--// WEBHOOK & HATCH LISTENER ---------------------------------------------
local function SendMessage(url, msg)
    if not url then return end
    pcall(function()
        request({ Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode({content = msg}) })
    end)
end

local function SendEmbed(url, embed)
    if not url then return end
    pcall(function()
        request({ Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode({embeds = {embed}}) })
    end)
end

task.spawn(function()
    while true do
        if #webhookQueue > 0 and tick() - lastSent >= 5 then
            local item = table.remove(webhookQueue, 1)
            if item.type == "text" then SendMessage(webhookUrl, item.content)
            elseif item.type == "embed" then SendEmbed(webhookUrl, item.embed) end
            lastSent = tick()
        end
        task.wait(1)
    end
end)

local function queueHatchEmbed(egg, pets)
    if not webhookEnabled or #pets == 0 then return end
    local embed = {
        title = "Hatched "..egg,
        description = "You hatched **"..#pets.."** pet"..(#pets>1 and "s" or "").."!",
        color = 65280,
        fields = {},
        footer = {text = "Player: "..LocalPlayer.Name},
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId="..LocalPlayer.UserId.."&width=150&height=150&format=png"}
    }
    for i, p in ipairs(pets) do table.insert(embed.fields, {name="Pet #"..i, value=p, inline=true}) end
    table.insert(webhookQueue, {type="embed", embed=embed})
end

RemoteEvent.OnClientEvent:Connect(function(action, data)
    if action ~= "HatchEgg" then return end
    local eggName = "Unknown Egg"
    local webhookPets = {}

    if typeof(data) == "table" then
        eggName = data.Name or eggName
        for _, pd in ipairs(data.Pets or {}) do
            if not pd.Deleted then
                local p = pd.Pet
                local label = p.Name or "Unknown"
                local tags = {}
                if p.Shiny then table.insert(tags, "Shiny") end
                if p.Mythic then table.insert(tags, "Mythic") end
                if #tags > 0 then label = label.." **"..table.concat(tags, " ").."**" end
                table.insert(webhookPets, label)
            end
        end
    end

    if webhookEnabled and #webhookPets > 0 then queueHatchEmbed(eggName, webhookPets) end
end)

--// Cleanup & Load --------------------------------------------------------
if pickupConnection then pickupConnection:Disconnect() end
if antiIdleConnection then antiIdleConnection:Disconnect() end

Rayfield:Notify({ Title = "demonhub LOADED", Content = "demonware", Duration = 6 })
print("demonhub")
