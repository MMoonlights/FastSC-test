return function(ctx)
    local loadIntoEnv=assert(ctx.LoadIntoEnv,"FastSC shared-environment loader is unavailable")
    local base=(getfenv and getfenv()) or _G
    local env=setmetatable({ctx=ctx},{__index=base})
    env._G=env

    local chunks={
        "games/piggy/state.lua",
        "games/piggy/data.lua",
        "games/piggy/scanner.lua",
        "games/piggy/puzzles.lua",
        "games/piggy/objectives.lua",
        "games/piggy/bypasses.lua",
        "games/piggy/ui.lua",
    }

    for _,path in ipairs(chunks) do
        local ok,err=pcall(loadIntoEnv,path,env)
        if not ok then
            error(path..": "..tostring(err))
        end
    end
end
