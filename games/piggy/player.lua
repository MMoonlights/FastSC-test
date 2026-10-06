return function(ctx,core,tab)
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local scope=ctx.Scope
    local speed=false
    local speedValue=60
    local jump=false
    local jumpValue=90
    local infinite=false
    local noclip=false

    local function restoreCharacter()
        local char=core.Player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            scope:Restore(hum,"WalkSpeed")
            scope:Restore(hum,"JumpPower")
            scope:Restore(hum,"UseJumpPower")
        end
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then scope:Restore(p,"CanCollide") end
            end
        end
    end

    tab:CreateSection("Movement")
    tab:CreateToggle("WalkSpeed",false,function(v)
        speed=v
        if not v then
            local hum=core.Player.Character and core.Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then scope:Restore(hum,"WalkSpeed") end
        end
    end)
    tab:CreateSlider("WalkSpeed value",{Min=16,Max=120,Default=speedValue},function(v) speedValue=v end)
    tab:CreateToggle("JumpPower",false,function(v)
        jump=v
        if not v then
            local hum=core.Player.Character and core.Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then scope:Restore(hum,"JumpPower"); scope:Restore(hum,"UseJumpPower") end
        end
    end)
    tab:CreateSlider("JumpPower value",{Min=50,Max=160,Default=jumpValue},function(v) jumpValue=v end)
    tab:CreateToggle("Infinite jump",false,function(v) infinite=v end)
    tab:CreateToggle("Noclip",false,function(v)
        noclip=v
        if not v then
            local char=core.Player.Character
            if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then scope:Restore(p,"CanCollide") end end end
        end
    end)

    scope:Connect(UIS.JumpRequest,function()
        if not infinite then return end
        local hum=core.Player.Character and core.Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)

    scope:Connect(RunService.Stepped,function()
        local char=core.Player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if speed then scope:Set(hum,"WalkSpeed",speedValue) end
            if jump then
                scope:Set(hum,"UseJumpPower",true)
                scope:Set(hum,"JumpPower",jumpValue)
            end
        end
        if noclip and char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then scope:Set(p,"CanCollide",false) end
            end
        end
    end)

    scope:Connect(core.Player.CharacterAdded,function()
        task.defer(function()
            if not speed and not jump and not noclip then restoreCharacter() end
        end)
    end)
    scope:AddRestore(restoreCharacter)
end
