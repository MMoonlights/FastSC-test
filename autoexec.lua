local path = "FastSC-test/loader.lua"
if isfile and readfile and isfile(path) then
    loadstring(readfile(path), "@FastSC/loader.lua")()
else
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/FastSC-test/main/loader.lua"))()
end
