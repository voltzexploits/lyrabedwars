-- UI and Services Setup
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FuturisticHackUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local uiContainer = Instance.new("Frame")
uiContainer.Size = UDim2.new(0, 1000, 0, 500)
uiContainer.Position = UDim2.new(0.5, -500, 0.5, -250)
uiContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
uiContainer.BackgroundTransparency = 0.2
uiContainer.BorderSizePixel = 0
uiContainer.Visible = true
uiContainer.ClipsDescendants = true
uiContainer.Parent = screenGui

Instance.new("UICorner", uiContainer).CornerRadius = UDim.new(0, 20)

local shadow = Instance.new("ImageLabel", uiContainer)
shadow.Size = UDim2.new(1, 60, 1, 60)
shadow.Position = UDim2.new(0, -30, 0, -30)
shadow.Image = "rbxassetid://1316045217"
shadow.ImageTransparency = 0.8
shadow.BackgroundTransparency = 1
shadow.ZIndex = 0

-- Section definitions
local categories = {
    {
        Name = "COMBAT",
        Buttons = {"AIM ASSIST", "KILLAURA", "AUTO CLICKER"}
    },
    {
        Name = "PLAYER",
        Buttons = {"FLY", "SPEED", "INF JUMP", "FOV"}
    },
    {
        Name = "MISC",
        Buttons = {"CRASHER", "ANTICRASH", "PLAYER HUD"}
    },
    {
        Name = "WORLD",
        Buttons = {"ANTIVOID"}
    }
}

-- State variables
local buttonStates = {}
local aiming = false
local autoClicking = false
local flying = false
local flySpeed = 50
local infJump = false
local speedEnabled = false
local speedMultiplier = 2
local jumpConnection

-- Toggle Button Behavior
local function toggleButton(button)
    local currentState = buttonStates[button] or false
    local newState = not currentState
    buttonStates[button] = newState

    button.BackgroundColor3 = newState and Color3.fromRGB(50, 0, 100) or Color3.fromRGB(80, 0, 200)
end

-- Find closest player to cursor
local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local screenPoint, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- GUI Button Builder
local function createCategory(xOffset, category)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 220, 0, 420)
    panel.Position = UDim2.new(0, xOffset, 0, 40)
    panel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel = 0
    panel.Parent = uiContainer

    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = Color3.fromRGB(120, 0, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.4

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.Text = category.Name
    header.Font = Enum.Font.GothamBold
    header.TextSize = 24
    header.TextColor3 = Color3.fromRGB(180, 180, 255)
    header.Parent = panel

    local uiList = Instance.new("UIListLayout", panel)
    uiList.Padding = UDim.new(0, 12)
    uiList.FillDirection = Enum.FillDirection.Vertical
    uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiList.VerticalAlignment = Enum.VerticalAlignment.Top
    uiList.SortOrder = Enum.SortOrder.LayoutOrder

    header.LayoutOrder = 0

    for _, buttonText in ipairs(category.Buttons) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.9, 0, 0, 48)
        button.BackgroundColor3 = Color3.fromRGB(80, 0, 200)
        button.Text = buttonText
        button.Font = Enum.Font.Gotham
        button.TextSize = 20
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Parent = panel

        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
        local btnStroke = Instance.new("UIStroke", button)
        btnStroke.Color = Color3.fromRGB(200, 150, 255)
        btnStroke.Thickness = 1.5
        btnStroke.Transparency = 0.3

        button.MouseButton1Click:Connect(function()
            toggleButton(button)
            if buttonText == "AIM ASSIST" then
                aiming = not aiming
            elseif buttonText == "AUTO CLICKER" then
                autoClicking = not autoClicking
            elseif buttonText == "FLY" then
                flying = not flying
            elseif buttonText == "INF JUMP" then
                infJump = not infJump
            elseif buttonText == "SPEED" then
                speedEnabled = not speedEnabled
            elseif buttonText == "FOV" then
                Camera.FieldOfView = 120 -- no max cap
            end
        end)
    end
end

-- Build the UI categories
for i, cat in ipairs(categories) do
    createCategory((i - 1) * 240 + 20, cat)
end

-- UI Toggle
local uiVisible = true
local function toggleUI()
    uiVisible = not uiVisible
    local targetPos = uiVisible and UDim2.new(0.5, -500, 0.5, -250) or UDim2.new(0.5, -500, 1.5, 0)
    TweenService:Create(uiContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        toggleUI()
    end
end)

-- Aim Assist loop
RunService.RenderStepped:Connect(function()
    if aiming then
        local target = getClosestPlayerToCursor()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end
end)

-- Auto Clicker
local mouseDown = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = false
    end
end)

spawn(function()
    while true do
        if autoClicking and mouseDown then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
        end
        task.wait(0.01)
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if infJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly
local flyVelocity = Instance.new("BodyVelocity")
flyVelocity.Velocity = Vector3.zero
flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)

RunService.RenderStepped:Connect(function()
    if flying and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        flyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart
        flyVelocity.Velocity = Camera.CFrame.LookVector * flySpeed
    else
        flyVelocity.Parent = nil
    end
end)

-- Speed
RunService.RenderStepped:Connect(function()
    if speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 * speedMultiplier
    elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end
end)
