--[[
    demonhub | Bubble Gum Simulator INFINITY
    Full Script - Including Rifts Auto-Hatch, Luck Threshold, and Return-to-Base
--]]

--// Load Rayfield ---------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// Services ---------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local Workspace         = game:GetService("Workspace")
local LocalPlayer       = Players.LocalPlayer
local Lighting          = game:GetService("Lighting")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")

--// Remotes ---------------------------------------------------------------
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework"):WaitForChild("Network")
    :WaitForChild("Remote"):WaitForChild("RemoteEvent")

local RemoteFunction = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework"):WaitForChild("Network")
    :WaitForChild("Remote"):WaitForChild("RemoteFunction")

local SpawnPickups     = ReplicatedStorage:WaitForChild("Remotes")
    :WaitForChild("Pickups"):WaitForChild("SpawnPickups")
local CollectPickup    = ReplicatedStorage:WaitForChild("Remotes")
    :WaitForChild("Pickups"):WaitForChild("CollectPickup")

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

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

local function tp(cf) 
    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
    if r then r.CFrame = cf end 
end

local function dist(p) 
    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
    if r and p then return (r.Position - p.Position).Magnitude end 
    return math.huge 
end

--// Rayfield Window -------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "demonhub",
    LoadingTitle = "demonhub",
    LoadingSubtitle = "sskint",
    ConfigurationSaving = { Enabled = true, FolderName = "demonhub" }
})

---
## 🗺️ Unlocks
---
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

---
## ⚙️ Automation
---
local AutoTab = Window:CreateTab("Automation")

local autoBubbleEnabled = false
AutoTab:CreateToggle({
    Name = "Auto Bubble",
    CurrentValue = false,
    Callback = function(v)
        autoBubbleEnabled = v
        if v then task.spawn(function()
            while autoBubbleEnabled and task.wait(0.1) do
                RemoteEvent:FireServer("BlowBubble")
            end
        end) end
    end
})

local eggList = {
    "100M Egg","200M Egg","500M Egg","Atlantis Egg","Aura Egg","Autumn Egg","Beach Egg","Bee Egg","Brainrot Egg","Bruh Egg",
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

local selectedEgg = eggList[1]
local hatchAmount = 1
local autoHatchEnabled = false

AutoTab:CreateDropdown({
    Name = "Select Egg",
    Options = eggList,
    CurrentOption = selectedEgg,
    Callback = function(v) selectedEgg = v[1] end
})

AutoTab:CreateSlider({
    Name = "Hatch Amount",
    Range = {1,15},
    Increment = 1,
    CurrentValue = hatchAmount,
    Callback = function(v) hatchAmount = v end
})

AutoTab:CreateToggle({
    Name = "Auto Hatch",
    CurrentValue = false,
    Callback = function(v)
        autoHatchEnabled = v
        if v then
            task.spawn(function()
                while autoHatchEnabled do
                    RemoteEvent:FireServer("HatchEgg", selectedEgg, hatchAmount)
                    task.wait(0.1)
                end
            end)
            Rayfield:Notify({Title = "Auto Hatch ON", Content = "Hatching "..selectedEgg.." x"..hatchAmount.." every 0.1s", Duration = 3})
        end
    end
})

local autoSpinEnabled = false
AutoTab:CreateToggle({
    Name = "Auto Spin Halloween Wheel",
    CurrentValue = false,
    Callback = function(v)
        autoSpinEnabled = v
        if v then task.spawn(function()
            while autoSpinEnabled and task.wait(2) do
                RemoteFunction:InvokeServer("HalloweenWheelSpin")
            end
        end)
        Rayfield:Notify({Title="Auto Spin",Content="Spinning Halloween Wheel!",Duration=3})
        end
    end
})

local autoPickupsEnabled = false
local pickupConnection, pickupQueue = nil,{}
AutoTab:CreateToggle({
    Name = "Auto Pickups (0.5s delay)",
    CurrentValue = false,
    Callback = function(v)
        autoPickupsEnabled = v
        if v then
            task.spawn(function()
                while autoPickupsEnabled do
                    if #pickupQueue>0 then
                        for _,id in ipairs(pickupQueue) do CollectPickup:FireServer(id) end
                        pickupQueue={}
                    end
                    task.wait(0.5)
                end
            end)
            pickupConnection = SpawnPickups.OnClientEvent:Connect(function(d)
                if not autoPickupsEnabled or not d then return end
                for _,p in ipairs(d) do
                    local id = p.Id or p.id
                    if id and type(id)=="string" and #id==36 then table.insert(pickupQueue,id) end
                end
            end)
            Rayfield:Notify({Title="Auto Pickups",Content="ON with 0.5s delay",Duration=4})
        else
            if pickupConnection then pickupConnection:Disconnect(); pickupConnection=nil end
            pickupQueue={}
        end
    end
})

---
## 🎃 Event (Houses)
---
local EventTab = Window:CreateTab("Event")

local isAutoHouses = false
local standDelay = 1
local teleportDelay = 0.1

EventTab:CreateToggle({
    Name = "Auto Houses (Halloween Event)",
    CurrentValue = false,
    Callback = function(v) isAutoHouses = v end
})

EventTab:CreateSlider({
    Name = "Stand Delay (seconds)",
    Range = {0.5,5},
    Increment = 0.1,
    CurrentValue = standDelay,
    Callback = function(v) standDelay = v end
})

EventTab:CreateSlider({
    Name = "Teleport Delay (seconds)",
    Range = {0.1,2},
    Increment = 0.1,
    CurrentValue = teleportDelay,
    Callback = function(v) teleportDelay = v end
})

local function claim(part)
    local base = part.CFrame * CFrame.new(0, 3, 0)
    local off  = part.CFrame * CFrame.new(5, 3, 0)
    tp(off); task.wait(0.1); tp(base)
    for i = 1, math.floor(standDelay) do 
        if not isAutoHouses then break end 
        tp(base * CFrame.new(0, i, 0)); task.wait(1) 
    end
    if standDelay > math.floor(standDelay) then 
        task.wait(standDelay - math.floor(standDelay)) 
    end
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

---
## 💨 Performance
---
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
            local success, err = pcall(function()
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

---
## 🌐 Webhook
---
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

---
## ➕ Misc
---
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

---
## ✨ Rifts
---
do
    local player = LocalPlayer
    
    --// Tab + UI
    local RiftTab = Window:CreateTab("Rifts")
    local RiftSection = RiftTab:CreateSection("Active Rifts")

    --// --- SCRIPT VARIABLES ---
    local autoTPEnabled = false
    local currentTargetRift = nil
    local teleportDistanceThreshold = 5
    local prioritizedRifts = {}
    local RiftLabels = {}
    local luckThreshold = 100 -- Default to 100x luck
    local returnToBaseEnabled = false
    local baseCFrame = nil 

    -- NEW RIFT HATCHING VARIABLES
    local autoHatchRiftEnabled = false
    local riftHatchAmount = 5 -- Default hatch amount set to 5

    --// Rift Name Mapping (Rift Folder Name -> {Friendly Display Name, Expected Egg Name for Remote})
    local RiftNameMap = {
        ["event-1"] = {display="Pumpkin Rift", egg="Pumpkin Egg"},
        ["event-2"] = {display="Costume Rift", egg="Costume Egg"},
        ["event-3"] = {display="Sinister Rift", egg="Sinister Egg"},
        ["event-4"] = {display="Mutant Rift", egg="Mutant Egg"},
        ["event-5"] = {display="Puppet Rift", egg="Puppet Egg"},
        ["darkrift"] = {display="Dark Rift", egg="Dark Rift Egg"},
        ["devrift"] = {display="Dev Rift", egg="Developer Egg"}
    }
    
    -- Build dropdown options (using friendly display names)
    local priorityOptions = {}
    for _, info in pairs(RiftNameMap) do
        table.insert(priorityOptions, info.display)
    end

    -- Utility Function to return the player to the base position
    local function returnPlayerToBase()
        if returnToBaseEnabled and baseCFrame then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = baseCFrame
                Rayfield:Notify({Title="Return to Base", Content="Teleporting back to start position.", Duration=2})
            end
        end
    end

    -- Utility Function to get the correct egg name for a rift
    local function getRiftEggName(riftModel)
        local originalName = riftModel.Name
        if RiftNameMap[originalName] then
            return RiftNameMap[originalName].egg
        end
        return originalName.." Egg"
    end

    --// --- UI ---
    RiftTab:CreateToggle({
        Name = "**Auto TP to Rift**",
        CurrentValue = false,
        Flag = "AutoTP",
        Callback = function(val)
            autoTPEnabled = val
            if val then
                currentTargetRift = nil
                -- Save base CFrame only if Return to Base is enabled
                if returnToBaseEnabled and character and character:FindFirstChild("HumanoidRootPart") then
                    baseCFrame = character.HumanoidRootPart.CFrame
                    Rayfield:Notify({Title="Base Position Saved", Content="Current position saved for return.", Duration=3})
                end
            else
                currentTargetRift = nil
                returnPlayerToBase() -- Teleport back when toggle is OFF
            end
        end
    })
    
    RiftTab:CreateToggle({
        Name = "Return to Base on Disable/Failure",
        CurrentValue = false,
        Flag = "ReturnToBase",
        Callback = function(val)
            returnToBaseEnabled = val
            if val and autoTPEnabled and character and character:FindFirstChild("HumanoidRootPart") and not baseCFrame then
                baseCFrame = character.HumanoidRootPart.CFrame
                Rayfield:Notify({Title="Base Position Saved", Content="Current position saved for return.", Duration=3})
            end
        end
    })

    RiftTab:CreateSlider({
        Name = "Minimum Luck Threshold (X)",
        Range = {1, 1000},
        Increment = 1,
        CurrentValue = luckThreshold,
        Callback = function(val)
            luckThreshold = val
            Rayfield:Notify({Title="Threshold Set", Content="Minimum luck set to: **"..val.."x**", Duration=2})
        end,
    })

    RiftTab:CreateDropdown({
        Name = "Prioritize Rifts",
        Options = priorityOptions,
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "PriorityDropdownMulti",
        Callback = function(selectedOptions)
            prioritizedRifts = selectedOptions
        end,
    })

    RiftTab:CreateSection("Auto Hatch Rift Egg")
    
    RiftTab:CreateSlider({
        Name = "Rift Hatch Amount",
        Range = {1,15},
        Increment = 1,
        CurrentValue = riftHatchAmount,
        Callback = function(v) riftHatchAmount = v end
    })

    RiftTab:CreateToggle({
        Name = "**Auto Hatch Rift Egg**",
        CurrentValue = false,
        Flag = "AutoHatchRift",
        Callback = function(val)
            autoHatchRiftEnabled = val
        end
    })

    local CurrentTargetLabel = RiftTab:CreateLabel("Current Target: None")

    --// --- FIXED LUCK READER ---
    local function getLuckFromRift(rift)
        if not rift or not rift.Parent then return nil end
        local luckObj = rift:FindFirstChild("Display")
                             and rift.Display:FindFirstChild("SurfaceGui")
                             and rift.Display.SurfaceGui:FindFirstChild("Icon")
                             and rift.Display.SurfaceGui.Icon:FindFirstChild("Luck")
        if not luckObj then return nil end

        if luckObj:IsA("TextLabel") then
            local text = luckObj.Text:gsub("[^%d%.]", "")
            return tonumber(text) or 0
        elseif luckObj:IsA("NumberValue") then
            return luckObj.Value
        elseif luckObj:IsA("StringValue") then
            return tonumber(luckObj.Value) or 0
        end
        return 0
    end

    -- Get Rift Spawn CFrame
    local function getRiftSpawnCFrame(rift)
        if not rift or not rift.Parent then return nil end
        local spawn = rift:FindFirstChild("EggPlatformSpawn")
        if not spawn then return nil end

        if spawn:IsA("BasePart") then
            return spawn.CFrame
        elseif spawn:IsA("Model") then
            if spawn.PrimaryPart then
                return spawn.PrimaryPart.CFrame
            else
                local firstPart = spawn:FindFirstChildWhichIsA("BasePart", true)
                if firstPart then return firstPart.CFrame end
            end
        end
        return nil
    end

    -- Teleport to Rift
    local function teleportToRift(rift)
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local targetCF = getRiftSpawnCFrame(rift)
        if targetCF then
            root.CFrame = targetCF + Vector3.new(0, 3, 0)
            return true
        end
        return false
    end

    local function isRiftStillAlive(rift)
        return rift and rift.Parent and rift.Parent.Parent
    end

    --// --- MAIN REFRESH/HATCH LOOP ---
    local function refreshRifts()
        local riftsFolder = Workspace:FindFirstChild("Rendered") and Workspace.Rendered:FindFirstChild("Rifts")
        
        if not riftsFolder then
            if autoTPEnabled then returnPlayerToBase() end
            currentTargetRift = nil
            CurrentTargetLabel:Set("Current Target: None (Rifts Folder Missing)")
            return
        end

        local bestLuckOverall   = -math.huge
        local bestRiftOverall   = nil
        local bestPriorityLuck  = -math.huge
        local bestPriorityRift  = nil
        local validRiftsFound = false

        local riftsInFolder = {}

        for _, rift in ipairs(riftsFolder:GetChildren()) do
            local luck = getLuckFromRift(rift)
            local luckNum = luck or 0
            local riftInfo = RiftNameMap[rift.Name] or {display = rift.Name, egg = rift.Name.." Egg"}
            local displayName = riftInfo.display
            
            riftsInFolder[rift.Name] = true

            -- Update/Create GUI
            if not RiftLabels[rift.Name] then
                RiftLabels[rift.Name] = {
                    label = RiftTab:CreateLabel("Active " .. displayName .. " | Luck: " .. luckNum .. "x"),
                    model = rift
                }
            else
                RiftLabels[rift.Name].label:Set("Active " .. displayName .. " | Luck: " .. luckNum .. "x")
            }

            -- Check luck threshold
            if luckNum >= luckThreshold then
                validRiftsFound = true

                -- Track best overall
                if luckNum > bestLuckOverall then
                    bestLuckOverall = luckNum
                    bestRiftOverall = rift
                end

                -- Track best prioritized
                for _, priName in ipairs(prioritizedRifts) do
                    if displayName == priName and luckNum > bestPriorityLuck then
                        bestPriorityLuck = luckNum
                        bestPriorityRift = rift
                    end
                end
            end
        end

        -- Clean up dead rifts (Removed button creation, now only updates label)
        for name, info in pairs(RiftLabels) do
            if not riftsInFolder[name] then
                if RiftLabels[name] then
                    RiftLabels[name].label:Set("**Inactive** " .. (RiftNameMap[name] and RiftNameMap[name].display or name) .. " | Luck: 0x")
                    RiftLabels[name] = nil
                end
            end
        end

        if not autoTPEnabled then
            CurrentTargetLabel:Set("Current Target: (Auto TP Disabled)")
            return
        end
        
        -- If auto-TP is ON but no rifts met the luck threshold or priority, return to base.
        if not validRiftsFound and #prioritizedRifts == 0 and bestRiftOverall == nil and currentTargetRift == nil then
            CurrentTargetLabel:Set("Current Target: None (No rifts above "..luckThreshold.."x)")
            returnPlayerToBase()
            return
        end

        -- TARGET LOCK LOGIC
        local finalTarget = nil

        -- Priority: Best prioritized Rift over Luck Threshold
        if #prioritizedRifts > 0 and bestPriorityRift and (getLuckFromRift(bestPriorityRift) or 0) >= luckThreshold then
            finalTarget = bestPriorityRift
        -- Secondary: Best overall Rift over Luck Threshold
        elseif bestRiftOverall and (getLuckFromRift(bestRiftOverall) or 0) >= luckThreshold then
            finalTarget = bestRiftOverall
        end
        
        -- Current Target Check: Stick to current target if it's still valid and not massively worse
        if currentTargetRift and isRiftStillAlive(currentTargetRift) and (getLuckFromRift(currentTargetRift) or 0) >= luckThreshold then
            local currentLuck = getLuckFromRift(currentTargetRift) or 0
            local candidateLuck = finalTarget and (getLuckFromRift(finalTarget) or 0) or -math.huge

            -- Only switch if the new best is strictly better
            if candidateLuck > currentLuck then
                finalTarget = finalTarget
            else
                finalTarget = currentTargetRift
            end
        end

        if not finalTarget then
            currentTargetRift = nil
            CurrentTargetLabel:Set("Current Target: None (No Rifts Met Criteria)")
            returnPlayerToBase()
            return
        end

        if currentTargetRift ~= finalTarget then
            currentTargetRift = finalTarget
        end

        local displayName = RiftNameMap[finalTarget.Name] and RiftNameMap[finalTarget.Name].display or finalTarget.Name
        local luckVal = getLuckFromRift(finalTarget) or "?"

        CurrentTargetLabel:Set("Current Target: " .. displayName .. " (" .. luckVal .. "x Luck)")

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local targetCF = getRiftSpawnCFrame(finalTarget)
        if not targetCF then return end

        local distance = (root.Position - targetCF.Position).Magnitude
        
        -- 1. TELEPORT ACTION
        if distance > teleportDistanceThreshold then
            teleportToRift(finalTarget)
        end

        -- 2. AUTO HATCH ACTION (only if we are AT the rift)
        if autoHatchRiftEnabled and finalTarget == currentTargetRift and distance <= teleportDistanceThreshold then
            local eggToHatch = getRiftEggName(finalTarget)
            RemoteEvent:FireServer("HatchEgg", eggToHatch, riftHatchAmount)
        end
    end

    --// Continuous Update Loop
    task.spawn(function()
        while task.wait(0.1) do -- 10 times per second for smooth TP/Hatch
            pcall(refreshRifts)
        end
    end)

    -- Handle respawn
    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        task.wait(1)
    end)
end

---
## 📞 Webhook Listener
---

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
        description = "You hatched **"..#pets.."** pet"..(#pets>1 and "s" or "")."!",
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

--// Final Cleanup & Load
if pickupConnection then pickupConnection:Disconnect() end
if antiIdleConnection then antiIdleConnection:Disconnect() end

Rayfield:Notify({ Title = "demonhub LOADED", Content = "BGSI Script Hub", Duration = 6 })
print("demonhub successfully loaded!")
