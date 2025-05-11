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

-- Category definitions with only working buttons
local categories = {
    { Name = "COMBAT", Buttons = {"AIM ASSIST", "AUTO CLICKER"} },
    { Name = "PLAYER", Buttons = {"FLY", "SPEED", "INF JUMP", "FOV"} },
    { Name = "WORLD", Buttons = {} },
    { Name = "MISC", Buttons = {"ESP"} }
}

-- State variables
local buttonStates = {}
local aiming = false
local autoClicking = false
local flying = false
local flySpeedHorizontal = 23
local flySpeedVertical = 50
local infJump = false
local speedEnabled = false
local walkSpeed = 23
local espEnabled = false
local espHighlights = {}

-- Toggle Button Behavior
local function toggleButton(button)
    local currentState = buttonStates[button] or false
    local newState = not currentState
    buttonStates[button] = newState
    button.BackgroundColor3 = newState and Color3.fromRGB(50, 0, 100) or Color3.fromRGB(80, 0, 200)
end

-- Get Closest Player to Cursor
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

-- ESP Management
local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not espHighlights[player] then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = player.Character
                highlight.FillColor = Color3.fromRGB(170, 0, 255)
                highlight.FillTransparency = 0.4
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0.5
                highlight.Parent = player.Character
                espHighlights[player] = highlight
            end
        end
    end
end

local function removeESP()
    for player, highlight in pairs(espHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    espHighlights = {}
end

-- Build GUI Buttons
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
                if not flying then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        for _, obj in ipairs(LocalPlayer.Character.HumanoidRootPart:GetChildren()) do
                            if obj:IsA("BodyVelocity") then obj:Destroy() end
                        end
                    end
                end
            elseif buttonText == "INF JUMP" then
                infJump = not infJump
            elseif buttonText == "SPEED" then
                speedEnabled = not speedEnabled
                if speedEnabled then
                    LocalPlayer.Character.Humanoid.WalkSpeed = walkSpeed
                else
                    LocalPlayer.Character.Humanoid.WalkSpeed = 16
                end
            elseif buttonText == "FOV" then
                Camera.FieldOfView = 120
            elseif buttonText == "ESP" then
                espEnabled = not espEnabled
                if espEnabled then
                    updateESP()
                else
                    removeESP()
                end
            end
        end)
    end
end

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

-- Aim Assist
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
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = false
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if autoClicking and mouseDown then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if infJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly Movement
RunService.RenderStepped:Connect(function()
    if flying and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local direction = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.new(0, 1, 0) end

        local bodyVelocity = root:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity", root)
        bodyVelocity.Velocity = direction.Unit * flySpeedHorizontal
        bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 1e5
    end
end)
