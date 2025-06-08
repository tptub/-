-- سكربت تتبع لاعب مع GUI، يمنع السقوط ويتبع اللاعب في الجو + جلوس بدون فيزياء + حركة أمام وخلف خفيفة

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local selectedPlayer = nil
local following = false
local followFromFront = false
local heartbeatConn

local MOVE_INTERVAL = 0.7
local lastMoveTime = 0
local oscillate = 1

local function stopFixingPosition()
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.Anchored = false

    local bp = hrp:FindFirstChild("BodyPosition")
    if bp then
        bp:Destroy()
    end

    local bg = hrp:FindFirstChild("BodyGyro")
    if bg then
        bg:Destroy()
    end
end

local function stopFollowing()
    following = false
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end

    local char = localPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        stopFixingPosition()
    end
end

local function startFollowing()
    if following or not selectedPlayer then return end
    following = true

    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.Sit = true
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if tick() - lastMoveTime < MOVE_INTERVAL then return end
        lastMoveTime = tick()

        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = selectedPlayer.Character.HumanoidRootPart

            oscillate = oscillate + 1
            local offset = math.sin(oscillate / 8) * 0.8 -- حركة خفيفة أمام وخلف

            local direction = 1.5 -- دائمًا أمام اللاعب

            local targetPosition = targetHRP.Position + (targetHRP.CFrame.LookVector * (direction + offset)) + Vector3.new(0, 2.5, 0)

            hrp.Anchored = false

            local bp = hrp:FindFirstChild("BodyPosition")
            if not bp then
                bp = Instance.new("BodyPosition")
                bp.Name = "BodyPosition"
                bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bp.P = 3000
                bp.D = 100
                bp.Parent = hrp
            end
            bp.Position = targetPosition

            local bg = hrp:FindFirstChild("BodyGyro")
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.Name = "BodyGyro"
                bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                bg.P = 10000
                bg.D = 200
                bg.Parent = hrp
            end
            bg.CFrame = CFrame.new(targetPosition, targetHRP.Position)

            hrp.CFrame = CFrame.new(targetPosition, targetHRP.Position)
        else
            stopFollowing()
        end
    end)
end

local function refreshPlayerList(scrollFrame)
    scrollFrame:ClearAllChildren()

    local layout = Instance.new("UIListLayout", scrollFrame)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            local btn = Instance.new("TextButton", scrollFrame)
            btn.Size = UDim2.new(1, -10, 0, 60)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.Text = plr.DisplayName
            btn.Font = Enum.Font.GothamBold
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 16
            btn.LayoutOrder = plr.UserId
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

            local success, thumb = pcall(function()
                return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)
            if success then
                local img = Instance.new("ImageLabel", btn)
                img.Image = thumb
                img.Size = UDim2.new(0, 40, 0, 40)
                img.Position = UDim2.new(0, 5, 0.5, -20)
                img.BackgroundTransparency = 1
            end

            btn.MouseButton1Click:Connect(function()
                selectedPlayer = plr
            end)
        end
    end
end

local function createGUI()
    local screenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "FollowGUI"
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 350, 0, 560)
    mainFrame.Position = UDim2.new(0, 50, 0.2, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "❌"
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextScaled = true
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        stopFollowing()
    end)

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🚀نيك الوجه"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true

    local scroll = Instance.new("ScrollingFrame", mainFrame)
    scroll.Size = UDim2.new(1, -20, 1, -220)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 8
    scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    scroll.BorderSizePixel = 0
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ClipsDescendants = true

    refreshPlayerList(scroll)

    local refreshBtn = Instance.new("TextButton", mainFrame)
    refreshBtn.Size = UDim2.new(1, -20, 0, 40)
    refreshBtn.Position = UDim2.new(0, 10, 1, -170)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    refreshBtn.Text = "🔄 تحديث القائمة"
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.TextScaled = true
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 10)
    refreshBtn.MouseButton1Click:Connect(function()
        refreshPlayerList(scroll)
    end)

    local frontBtn = Instance.new("TextButton", mainFrame)
    frontBtn.Size = UDim2.new(0.5, -15, 0, 40)
    frontBtn.Position = UDim2.new(0, 10, 1, -120)
    frontBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    frontBtn.Text = "👁️ للوجه"
    frontBtn.Font = Enum.Font.GothamBold
    frontBtn.TextColor3 = Color3.new(1, 1, 1)
    frontBtn.TextScaled = true
    Instance.new("UICorner", frontBtn).CornerRadius = UDim.new(0, 10)
    frontBtn.MouseButton1Click:Connect(function()
        followFromFront = true
    end)

    local backBtn = Instance.new("TextButton", mainFrame)
    backBtn.Size = UDim2.new(0.5, -15, 0, 40)
    backBtn.Position = UDim2.new(0.5, 5, 1, -120)
    backBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    backBtn.Text = "👀 من الخلف"
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextColor3 = Color3.new(1, 1, 1)
    backBtn.TextScaled = true
    Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 10)
    backBtn.MouseButton1Click:Connect(function()
        followFromFront = false
    end)

    local startBtn = Instance.new("TextButton", mainFrame)
    startBtn.Size = UDim2.new(1, -20, 0, 40)
    startBtn.Position = UDim2.new(0, 10, 1, -70)
    startBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    startBtn.Text = "▶️ بدء التتبع"
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextColor3 = Color3.new(1, 1, 1)
    startBtn.TextScaled = true
    Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)
    startBtn.MouseButton1Click:Connect(function()
        if selectedPlayer then
            startFollowing()
        else
            warn("يرجى اختيار لاعب أولاً")
        end
    end)

    local stopBtn = Instance.new("TextButton", mainFrame)
    stopBtn.Size = UDim2.new(1, -20, 0, 40)
    stopBtn.Position = UDim2.new(0, 10, 1, -20)
    stopBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    stopBtn.Text = "⏹️ إيقاف التتبع"
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.TextScaled = true
    Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 10)
    stopBtn.MouseButton1Click:Connect(function()
        stopFollowing()
    end)

    local unanchorBtn = Instance.new("TextButton", mainFrame)
    unanchorBtn.Size = UDim2.new(1, -20, 0, 40)
    unanchorBtn.Position = UDim2.new(0, 10, 1, -120)
    unanchorBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    unanchorBtn.Text = "🛑 إلغاء تثبيت الشخصية"
    unanchorBtn.Font = Enum.Font.GothamBold
    unanchorBtn.TextColor3 = Color3.new(1, 1, 1)
    unanchorBtn.TextScaled = true
    Instance.new("UICorner", unanchorBtn).CornerRadius = UDim.new(0, 10)
    unanchorBtn.MouseButton1Click:Connect(function()
        stopFixingPosition()
    end)
end

createGUI()
