--// FINAL RIFT MANAGER SYSTEM (CLEAN + OPTIMIZED)
--// Author: ChatGPT GPT-5

--// Services
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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

--// Rift Refresh Logic

local function refreshRifts()
	local folder = Workspace:FindFirstChild("Rendered") and Workspace.Rendered:FindFirstChild("Rifts")
	if not folder then
		if autoTPEnabled and not returnedToOriginal then
			returnToOriginalPosition()
			returnedToOriginal = true
			Rayfield:Notify({
				Title = "Rift Scanner",
				Content = "Rifts not found, returned to original position.",
				Duration = 3
			})
		end
		return
	end

	local seen = {}

	for _, rift in ipairs(folder:GetChildren()) do
		if rift:IsA("Model") then
			local id = rift:GetAttribute("_riftID") or generateRiftID(rift)
			seen[id] = true
			local luck = getLuckFromRift(rift)

			if not RiftMemory[id] then
				RiftMemory[id] = rift
				createRiftUI(rift, id, luck)
			else
				local ui = RiftLabels[id]
				if ui and ui.label then
					local name = RiftNameMap[rift.Name] or rift.Name
					ui.label:Set(name .. " | Luck: " .. luck .. "x")
				end
			end
		end
	end

	-- Cleanup deleted Rifts
	for id, rift in pairs(RiftMemory) do
		if not seen[id] or not (rift and rift.Parent) then
			removeRiftFromMemory(id)
		end
	end

	-- Choose best Rift
	local bestRift, bestLuck = nil, -math.huge
	for id, rift in pairs(RiftMemory) do
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
