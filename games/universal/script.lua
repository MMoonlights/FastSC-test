return function(ctx)
    local scope = ctx.Scope
    local Common = ctx.Common
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local localPlayer = Players.LocalPlayer

    local main = ctx.Window:CreateTab("Universal")
    local esp = ctx.Window:CreateTab("ESP")
    local player = ctx.Window:CreateTab("Player")

    local speedEnabled = false
    local speedValue = 24
    local jumpEnabled = false
    local jumpValue = 60
    local noclip = false
    local infiniteJump = false
    local playerEsp = false
    local highlights = {}

    local function humanoid()
        local character = localPlayer.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end

    local function clearEsp(target)
        local highlight = highlights[target]
        if highlight then
            pcall(function() highlight:Destroy() end)
            highlights[target] = nil
        end
    end

    local function refreshEsp()
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= localPlayer then
                if playerEsp and target.Character then
                    local highlight = highlights[target]
                    if not highlight or not highlight.Parent then
                        highlight = Common.Highlight(scope, target.Character, "FastSCUniversalESP")
                        highlights[target] = highlight
                    else
                        highlight.Adornee = target.Character
                    end
                else
                    clearEsp(target)
                end
            end
        end
    end

    main:CreateSection("Universal")
    main:CreateLabel("Generic features only. No game-specific automation is loaded.")

    player:CreateSection("Movement")
    player:CreateToggle("Speed", false, function(value)
        speedEnabled = value
        if not value then
            local hum = humanoid()
            if hum then scope:Restore(hum, "WalkSpeed") end
        end
    end)
    player:CreateSlider("Speed value", {Min = 16, Max = 120, Default = speedValue}, function(value)
        speedValue = value
    end)
    player:CreateToggle("Jump power", false, function(value)
        jumpEnabled = value
        if not value then
            local hum = humanoid()
            if hum then scope:Restore(hum, "JumpPower") end
        end
    end)
    player:CreateSlider("Jump value", {Min = 50, Max = 160, Default = jumpValue}, function(value)
        jumpValue = value
    end)
    player:CreateToggle("Infinite jump", false, function(value)
        infiniteJump = value
    end)
    player:CreateToggle("Noclip", false, function(value)
        noclip = value
    end)

    esp:CreateSection("Players")
    esp:CreateToggle("Player ESP", false, function(value)
        playerEsp = value
        refreshEsp()
    end)

    scope:Connect(Players.PlayerAdded, function(target)
        scope:Connect(target.CharacterAdded, function()
            task.wait()
            refreshEsp()
        end)
    end)
    scope:Connect(Players.PlayerRemoving, clearEsp)
    scope:Connect(localPlayer.CharacterAdded, function()
        task.wait()
        refreshEsp()
    end)

    scope:Connect(UserInputService.JumpRequest, function()
        if infiniteJump then
            local hum = humanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    scope:Connect(RunService.Stepped, function()
        local character = localPlayer.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if hum then
            if speedEnabled then scope:Set(hum, "WalkSpeed", speedValue) end
            if jumpEnabled then
                scope:Set(hum, "UseJumpPower", true)
                scope:Set(hum, "JumpPower", jumpValue)
            end
        end

        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if noclip then
                        scope:Set(part, "CanCollide", false)
                    else
                        scope:Restore(part, "CanCollide")
                    end
                end
            end
        end
    end)
end
