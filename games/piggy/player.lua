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

    tab:CreateSection("Movement")
    tab:CreateToggle("WalkSpeed",false,function(v) speed=v end)
    tab:CreateSlider("WalkSpeed value",{Min=16,Max=120,Default=speedValue},function(v) speedValue=v end)
    tab:CreateToggle("JumpPower",false,function(v) jump=v end)
    tab:CreateSlider("JumpPower value",{Min=50,Max=160,Default=jumpValue},function(v) jumpValue=v end)
    tab:CreateToggle("Infinite jump",false,function(v) infinite=v end)
    tab:CreateToggle("Noclip",false,function(v) noclip=v end)

    scope:Connect(UIS.JumpRequest,function()
        if infinite then
            local hum=core.Player.Character and core.Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    scope:Connect(RunService.Stepped,function()
        local char=core.Player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if speed then hum.WalkSpeed=speedValue end
            if jump then hum.UseJumpPower=true hum.JumpPower=jumpValue end
        end
        if noclip and char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end)
end
