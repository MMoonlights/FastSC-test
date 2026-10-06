function shortValue(instance)
    if instance:IsA("StringValue") then return tostring(instance.Value) end
    if instance:IsA("IntValue") or instance:IsA("NumberValue") then return tostring(instance.Value) end
    if instance:IsA("TextLabel") or instance:IsA("TextBox") then return tostring(instance.Text) end
end

function normalizedShortValue(instance)
    local value = shortValue(instance)
    if not value then return nil end
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    if #value == 0 or #value > 24 then return nil end
    return value
end

function ancestorText(instance, depth)
    local chunks = {}
    local current = instance
    for _ = 1, depth or 5 do
        if not current or current == workspace then break end
        chunks[#chunks + 1] = string.lower(current.Name)
        current = current.Parent
    end
    return table.concat(chunks, " ")
end

function mapAndEvents()
    local map = currentMapModel()
    if not map then return nil, nil end
    local events = map:FindFirstChild("Events") or map:FindFirstChild("events") or map
    return map, events
end

function controlPosition(control)
    if not control or not control.Parent then return nil end
    if control.Parent:IsA("BasePart") then return control.Parent.Position end
    local model = control.Parent:FindFirstAncestorOfClass("Model")
    local part = model and getPart(model)
    return part and part.Position
end

function clickControl(control)
    if not control or not control.Parent then return false end
    if control:IsA("ClickDetector") and fireclickdetector then
        pcall(function()
            control.MaxActivationDistance = math.huge
            fireclickdetector(control)
        end)
        return true
    end
    if control:IsA("ProximityPrompt") and fireproximityprompt then
        pcall(function()
            control.HoldDuration = 0
            fireproximityprompt(control)
        end)
        return true
    end
    if control:IsA("TouchTransmitter") and firetouchinterest then
        local part = control.Parent
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if part and part:IsA("BasePart") and root then
            pcall(function()
                firetouchinterest(root, part, 0)
                task.wait(0.01)
                firetouchinterest(root, part, 1)
            end)
            return true
        end
    end
    return false
end

function controlsUnder(root)
    local result = {}
    local seen = {}
    if not root then return result end
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("ClickDetector")
            or descendant:IsA("ProximityPrompt")
            or descendant:IsA("TouchTransmitter") then
            local part = descendant.Parent
            if part and not seen[part] and controlPosition(descendant) then
                seen[part] = true
                result[#result + 1] = descendant
            end
        end
    end
    return result
end

function findCanonicalRoot(kind)
    local map = currentMapModel()
    if not map then return nil end
    local names = canonicalRoots[kind]
    if not names then return nil end
    local best
    local bestLength = math.huge
    for _, descendant in ipairs(map:GetDescendants()) do
        if descendant:IsA("Model") or descendant:IsA("Folder") or descendant:IsA("BasePart") then
            local name = token(descendant.Name)
            for _, wanted in ipairs(names) do
                if name == wanted or name:find(wanted, 1, true) then
                    local controls = controlsUnder(descendant)
                    if #controls > 0 and #controls < bestLength then
                        best = descendant
                        bestLength = #controls
                    end
                end
            end
        end
    end
    return best
end

function uniqueControls(controls)
    local result = {}
    local seen = {}
    for _, control in ipairs(controls) do
        local part = control and control.Parent
        if part and not seen[part] and controlPosition(control) then
            seen[part] = true
            result[#result + 1] = control
        end
    end
    return result
end

function boundsScore(controls)
    if #controls == 0 then return math.huge end
    local minV = Vector3.new(math.huge, math.huge, math.huge)
    local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, control in ipairs(controls) do
        local p = controlPosition(control)
        if not p then return math.huge end
        minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
        maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
    end
    return (maxV - minV).Magnitude
end

function compactSubset(controls, expected)
    controls = uniqueControls(controls)
    if #controls <= expected then return controls end
    local best
    local bestScore = math.huge
    for _, seed in ipairs(controls) do
        local seedPos = controlPosition(seed)
        local ranked = {}
        for _, control in ipairs(controls) do
            local pos = controlPosition(control)
            if pos then
                ranked[#ranked + 1] = {Control = control, Distance = (pos - seedPos).Magnitude}
            end
        end
        table.sort(ranked, function(a, b) return a.Distance < b.Distance end)
        local group = {}
        for index = 1, math.min(expected, #ranked) do
            group[index] = ranked[index].Control
        end
        local score = boundsScore(group)
        if #group == expected and score < bestScore then
            best = group
            bestScore = score
        end
    end
    return best or {}
end

function keywordScore(instance, keywords)
    local text = ancestorText(instance, 6)
    local score = 0
    for _, word in ipairs(keywords or {}) do
        if text:find(word, 1, true) then score += 1 end
    end
    return score
end

function puzzleAnchorPosition()
    if currentObjective and currentObjective.Part and currentObjective.Part.Parent then
        return currentObjective.Part.Position
    end
    local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local best
    local bestDistance = math.huge
    for part in pairs(escapeTargets) do
        if part.Parent then
            local distance = root and (part.Position - root.Position).Magnitude or 0
            if distance < bestDistance then
                best = part.Position
                bestDistance = distance
            end
        end
    end
    return best
end

function groupCenter(controls)
    local center = Vector3.zero
    local count = 0
    for _, control in ipairs(controls) do
        local position = controlPosition(control)
        if position then
            center += position
            count += 1
        end
    end
    return count > 0 and center / count or nil
end

function puzzleEligibleControl(control)
    if not control or not control.Parent then return false end
    if playerCharacterAncestor(control) or underPiggyFolder(control) then return false end
    if itemObjectFrom(control) or belongsToItem(control) then return false end
    local current = control.Parent
    for _ = 1, 4 do
        if not current or current == workspace then break end
        local lower = string.lower(current.Name)
        if lower:find("trap", 1, true) then return false end
        current = current.Parent
    end
    return controlPosition(control) ~= nil
end

function groupedControls(expected, keywords, allowDouble)
    local map, events = mapAndEvents()
    if not map then return {}, nil end

    local controls = {}
    for _, control in ipairs(controlsUnder(map)) do
        if puzzleEligibleControl(control) then
            controls[#controls + 1] = control
        end
    end
    controls = uniqueControls(controls)

    local groups = {}
    for _, control in ipairs(controls) do
        local current = control.Parent
        for _ = 1, 7 do
            if not current or current == workspace or current == map.Parent then break end
            local group = groups[current]
            if not group then
                group = {}
                groups[current] = group
            end
            group[#group + 1] = control
            if current == map then break end
            current = current.Parent
        end
    end

    local bestControls
    local bestRoot
    local bestScore = math.huge
    local anchor = puzzleAnchorPosition()

    for root, group in pairs(groups) do
        group = uniqueControls(group)
        local count = #group
        local countDelta = math.abs(count - expected)
        if allowDouble then
            countDelta = math.min(countDelta, math.abs(count - expected * 2))
        end
        if count >= expected and count <= expected * 3 then
            local words = keywordScore(root, keywords)
            local score = countDelta * 1400 + boundsScore(group) * 2 - words * 900
            local center = anchor and groupCenter(group)
            if anchor and center then
                score += math.min((center - anchor).Magnitude, 300)
            end
            if events and root:IsDescendantOf(events) then
                score -= 150
            end
            if score < bestScore then
                bestControls = group
                bestRoot = root
                bestScore = score
            end
        end
    end

    if bestControls then return bestControls, bestRoot end
    return compactSubset(controls, expected), map
end

function selectPuzzleControls(kind, expected, keywords, allowDouble)
    local root = findCanonicalRoot(kind)
    if root then
        local controls = controlsUnder(root)
        if #controls >= expected then
            return controls, root
        end
    end
    return groupedControls(expected, keywords, allowDouble)
end

function progressFingerprint()
    local map = currentMapModel()
    if not map then return "none" end
    local chunks = {}
    for value in pairs(requirements) do
        if value.Parent then
            chunks[#chunks + 1] = "r:" .. tostring(value.Value) .. ":" .. tostring(value.Parent)
        end
    end
    for _, descendant in ipairs(map:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local text = ancestorText(descendant, 4)
            if text:find("door", 1, true)
                or text:find("exit", 1, true)
                or text:find("gate", 1, true)
                or text:find("barrier", 1, true)
                or text:find("safe", 1, true)
                or text:find("portal", 1, true)
                or text:find("armory", 1, true) then
                local p = descendant.Position
                chunks[#chunks + 1] = table.concat({
                    "p", tostring(descendant),
                    string.format("%.2f", p.X),
                    string.format("%.2f", p.Y),
                    string.format("%.2f", p.Z),
                    tostring(descendant.CanCollide),
                    string.format("%.2f", descendant.Transparency),
                }, ":")
            end
        elseif descendant:IsA("BoolValue") then
            local n = string.lower(descendant.Name)
            if n:find("open", 1, true)
                or n:find("unlock", 1, true)
                or n:find("complete", 1, true)
                or n:find("solved", 1, true) then
                chunks[#chunks + 1] = "b:" .. tostring(descendant) .. ":" .. tostring(descendant.Value)
            end
        end
    end
    table.sort(chunks)
    return table.concat(chunks, "|")
end

function localSolved(root)
    if not root or not root.Parent then return true end
    for _, descendant in ipairs(root:GetDescendants()) do
        local value = normalizedShortValue(descendant)
        if value then
            local lower = string.lower(value)
            if lower == "open"
                or lower == "opened"
                or lower == "correct"
                or lower == "complete"
                or lower == "completed"
                or lower == "unlocked"
                or lower == "solved" then
                return true
            end
        end
        if descendant:IsA("BoolValue") and descendant.Value then
            local n = string.lower(descendant.Name)
            if n:find("open", 1, true)
                or n:find("unlock", 1, true)
                or n:find("complete", 1, true)
                or n:find("solved", 1, true) then
                return true
            end
        end
    end
    return false
end

function waitForSolved(before, root, timeout)
    local deadline = os.clock() + (timeout or 0.4)
    repeat
        if localSolved(root) then return true end
        if progressFingerprint() ~= before then return true end
        task.wait(0.02)
    until os.clock() >= deadline
    return false
end

function planarCoordinates(positions)
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for _, p in ipairs(positions) do
        minX, minY, minZ = math.min(minX, p.X), math.min(minY, p.Y), math.min(minZ, p.Z)
        maxX, maxY, maxZ = math.max(maxX, p.X), math.max(maxY, p.Y), math.max(maxZ, p.Z)
    end
    local ranges = {
        {Axis = "X", Range = maxX - minX},
        {Axis = "Y", Range = maxY - minY},
        {Axis = "Z", Range = maxZ - minZ},
    }
    table.sort(ranges, function(a, b) return a.Range > b.Range end)
    local a, b = ranges[1].Axis, ranges[2].Axis
    local function coord(p, axis)
        if axis == "X" then return p.X end
        if axis == "Y" then return p.Y end
        return p.Z
    end
    return function(p) return coord(p, a), coord(p, b) end
end

function linearOrder(objects, positionGetter)
    local positions = {}
    for _, object in ipairs(objects) do
        local p = positionGetter(object)
        if not p then return objects end
        positions[#positions + 1] = p
    end
    local a, b = positions[1], positions[1]
    local maxDistance = -1
    for i = 1, #positions do
        for j = i + 1, #positions do
            local d = (positions[i] - positions[j]).Magnitude
            if d > maxDistance then
                maxDistance = d
                a, b = positions[i], positions[j]
            end
        end
    end
    local axis = b - a
    if axis.Magnitude < 0.001 then return objects end
    axis = axis.Unit
    local absX, absY, absZ = math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z)
    if (absX >= absY and absX >= absZ and axis.X < 0)
        or (absY >= absX and absY >= absZ and axis.Y < 0)
        or (absZ >= absX and absZ >= absY and axis.Z < 0) then
        axis = -axis
    end
    table.sort(objects, function(left, right)
        return positionGetter(left):Dot(axis) < positionGetter(right):Dot(axis)
    end)
    return objects
end

function circularOrder(controls)
    local entries = {}
    local positions = {}
    local center = Vector3.zero
    for _, control in ipairs(controls) do
        local p = controlPosition(control)
        if p then
            positions[#positions + 1] = p
            center += p
            entries[#entries + 1] = {Control = control, Position = p}
        end
    end
    if #entries == 0 then return entries end
    center /= #entries
    local project = planarCoordinates(positions)
    local cu, cv = project(center)
    table.sort(entries, function(a, b)
        local au, av = project(a.Position)
        local bu, bv = project(b.Position)
        return math.atan2(av - cv, au - cu) < math.atan2(bv - cv, bu - cu)
    end)
    return entries
end

function gridOrder(objects, positionGetter)
    if #objects ~= 9 then return objects end
    local positions = {}
    for _, object in ipairs(objects) do
        local p = positionGetter(object)
        if not p then return objects end
        positions[#positions + 1] = p
    end
    local project = planarCoordinates(positions)
    local entries = {}
    for _, object in ipairs(objects) do
        local u, v = project(positionGetter(object))
        entries[#entries + 1] = {Object = object, U = u, V = v}
    end
    table.sort(entries, function(a, b)
        if math.abs(a.V - b.V) > 0.5 then return a.V > b.V end
        return a.U < b.U
    end)
    local result = {}
    for index, entry in ipairs(entries) do result[index] = entry.Object end
    return result
end

function controlPositiveScore(control)
    if not control or not control.Parent then return 0 end
    local text = ancestorText(control, 3)
    if control:IsA("ProximityPrompt") then
        text = text .. " " .. string.lower(tostring(control.ActionText or "")) .. " " .. string.lower(tostring(control.ObjectText or ""))
    end
    local label = control.Parent:FindFirstChildWhichIsA("TextLabel", true)
    if label then text = text .. " " .. string.lower(tostring(label.Text or "")) end
    local score = 0
    if text:find("plus", 1, true) or text:find("add", 1, true) or text:find("increase", 1, true) or text:find("+", 1, true) then score += 10 end
    if text:find("minus", 1, true) or text:find("subtract", 1, true) or text:find("decrease", 1, true) or text:find("-", 1, true) then score -= 10 end
    if control.Parent:IsA("BasePart") then
        local color = control.Parent.Color
        if color.G > color.R * 1.25 and color.G > color.B * 1.1 then score += 4 end
        if color.R > color.G * 1.25 and color.R > color.B * 1.1 then score -= 4 end
    end
    return score
end

function collapseSlotControls(controls, slots)
    controls = uniqueControls(controls)
    if #controls == slots then
        return linearOrder(controls, controlPosition)
    end

    if #controls >= slots * 2 then
        controls = compactSubset(controls, slots * 2)
        local unused = {}
        for _, control in ipairs(controls) do unused[control] = true end
        local pairs = {}

        while #pairs < slots and next(unused) do
            local first
            for control in pairs(unused) do
                first = control
                break
            end
            if not first then break end
            unused[first] = nil
            local firstPos = controlPosition(first)
            local nearest
            local nearestDistance = math.huge

            for candidate in pairs(unused) do
                local pos = controlPosition(candidate)
                if pos and firstPos then
                    local distance = (pos - firstPos).Magnitude
                    if distance < nearestDistance then
                        nearest = candidate
                        nearestDistance = distance
                    end
                end
            end

            if nearest then unused[nearest] = nil end
            local selected = first
            if nearest and controlPositiveScore(nearest) > controlPositiveScore(first) then
                selected = nearest
            end

            local a = firstPos or Vector3.zero
            local b = nearest and controlPosition(nearest) or a
            pairs[#pairs + 1] = {
                Control = selected,
                Position = (a + b) * 0.5,
            }
        end

        if #pairs == slots then
            linearOrder(pairs, function(entry) return entry.Position end)
            local result = {}
            for index, entry in ipairs(pairs) do result[index] = entry.Control end
            return result
        end
    end

    return compactSubset(controls, slots)
end

function cyclePuzzleControls(controls, states, limit, root)
    controls = collapseSlotControls(controls, #controls >= 3 and 3 or #controls)
    if #controls == 0 then return false end
    local before = progressFingerprint()
    local maxSteps = limit or (states ^ #controls)
    local counters = table.create(#controls, 0)
    for _ = 1, maxSteps do
        local carry = true
        for index = 1, #controls do
            if carry then
                clickControl(controls[index])
                counters[index] += 1
                if counters[index] >= states then
                    counters[index] = 0
                else
                    carry = false
                end
            end
        end
        task.wait(0.005)
        if localSolved(root) or progressFingerprint() ~= before then return true end
    end
    return false
end

function cyclePuzzle(keywords, expected, states, limit, kind)
    local controls, root = selectPuzzleControls(kind, expected, keywords, expected == 3)
    controls = collapseSlotControls(controls, expected)
    if #controls ~= expected then return false end
    local before = progressFingerprint()
    local maxSteps = limit or (states ^ expected)
    local counters = table.create(expected, 0)
    for _ = 1, maxSteps do
        local carry = true
        for index = 1, expected do
            if carry then
                clickControl(controls[index])
                counters[index] += 1
                if counters[index] >= states then
                    counters[index] = 0
                else
                    carry = false
                end
            end
        end
        task.wait(0.005)
        if localSolved(root) or progressFingerprint() ~= before then return true end
    end
    return false
end

function readPanelCode(host)
    if not host then return nil end
    local found = {}
    for _, descendant in ipairs(host:GetDescendants()) do
        local value = normalizedShortValue(descendant)
        if value then
            local digits = value:gsub("%D", "")
            if #digits >= 2 and #digits <= 8 then
                found[digits] = true
            end
        end
    end
    local only
    local count = 0
    for digits in pairs(found) do
        only = digits
        count += 1
        if count > 1 then return nil end
    end
    return only
end

function readGlobalMapCode(exclude)
    local map = currentMapModel()
    if not map then return nil end
    local found = {}
    for _, descendant in ipairs(map:GetDescendants()) do
        if not exclude or not descendant:IsDescendantOf(exclude) then
            local value = normalizedShortValue(descendant)
            local name = string.lower(descendant.Name)
            if value and (name:find("code", 1, true)
                or name:find("password", 1, true)
                or name:find("pin", 1, true)
                or name:find("digit", 1, true)
                or ancestorText(descendant, 3):find("hint", 1, true)) then
                local digits = value:gsub("%D", "")
                if #digits >= 2 and #digits <= 8 then found[digits] = true end
            end
        end
    end
    local only
    local count = 0
    for digits in pairs(found) do
        only = digits
        count += 1
        if count > 1 then return nil end
    end
    return only
end

function numericButtons(host)
    local buttons = {}
    for _, control in ipairs(controlsUnder(host)) do
        local source = tostring(control.Parent and control.Parent.Name or "")
        if control:IsA("ProximityPrompt") then
            source = source .. " " .. tostring(control.ObjectText or "") .. " " .. tostring(control.ActionText or "")
        end
        local label = control.Parent and control.Parent:FindFirstChildWhichIsA("TextLabel", true)
        if label then source = source .. " " .. tostring(label.Text) end
        local digit = source:match("(%d)")
        if digit and #digit == 1 and not buttons[digit] then buttons[digit] = control end
    end
    return buttons
end

function solveCodePanel(host)
    if not host then return false end
    local code = readPanelCode(host) or readGlobalMapCode(host)
    if not code then return false end
    local buttons = numericButtons(host)
    for index = 1, #code do
        if not buttons[code:sub(index, index)] then return false end
    end
    local before = progressFingerprint()
    for index = 1, #code do
        clickControl(buttons[code:sub(index, index)])
        task.wait(0.02)
    end
    return waitForSolved(before, host, 0.45)
end

puzzleColors = {
    Red = Color3.fromRGB(255, 0, 0),
    Yellow = Color3.fromRGB(255, 255, 0),
    Blue = Color3.fromRGB(0, 85, 255),
    Green = Color3.fromRGB(0, 255, 0),
    Purple = Color3.fromRGB(170, 0, 255),
}

function nearestPuzzleColor(color)
    local best
    local distance = math.huge
    for name, reference in pairs(puzzleColors) do
        local dr = color.R - reference.R
        local dg = color.G - reference.G
        local db = color.B - reference.B
        local d = dr * dr + dg * dg + db * db
        if d < distance then
            best = name
            distance = d
        end
    end
    return best, distance
end

function coloredPartCandidates(exclude)
    local map = currentMapModel()
    local result = {}
    if not map then return result end
    for _, part in ipairs(map:GetDescendants()) do
        if part:IsA("BasePart") and (not exclude or not part:IsDescendantOf(exclude)) then
            local colorName, distance = nearestPuzzleColor(part.Color)
            local light = part:FindFirstChildWhichIsA("PointLight", true)
                or part:FindFirstChildWhichIsA("SurfaceLight", true)
            local text = ancestorText(part, 4)
            if distance < 0.36
                and part.Transparency < 0.9
                and (part.Material == Enum.Material.Neon
                    or light
                    or text:find("screen", 1, true)
                    or text:find("monitor", 1, true)
                    or text:find("display", 1, true)
                    or text:find("control", 1, true)) then
                result[#result + 1] = {Part = part, Color = colorName}
            end
        end
    end
    return result
end

function partBoundsScore(parts)
    if #parts == 0 then return math.huge end
    local minV = Vector3.new(math.huge, math.huge, math.huge)
    local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, part in ipairs(parts) do
        local p = part.Position
        minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
        maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
    end
    return (maxV - minV).Magnitude
end

function coloredGroupOfFour(exclude)
    local candidates = coloredPartCandidates(exclude)
    local groups = {}
    for _, entry in ipairs(candidates) do
        local current = entry.Part.Parent
        for _ = 1, 5 do
            if not current or current == workspace then break end
            local group = groups[current]
            if not group then group = {}; groups[current] = group end
            group[#group + 1] = entry
            current = current.Parent
        end
    end
    local best
    local bestScore = math.huge
    for root, entries in pairs(groups) do
        local unique = {}
        local seen = {}
        for _, entry in ipairs(entries) do
            if not seen[entry.Part] then
                seen[entry.Part] = true
                unique[#unique + 1] = entry
            end
        end
        if #unique >= 4 and #unique <= 8 then
            local parts = {}
            for _, entry in ipairs(unique) do parts[#parts + 1] = entry.Part end
            local score = math.abs(#unique - 4) * 1000
                + partBoundsScore(parts)
                - keywordScore(root, {"control", "monitor", "screen", "display"}) * 200
            if score < bestScore then
                best = unique
                bestScore = score
            end
        end
    end
    if not best then return nil end
    while #best > 4 do table.remove(best) end
    return best
end

function controlColorName(control)
    if not control or not control.Parent then return nil end
    local candidates = {}
    if control.Parent:IsA("BasePart") then candidates[#candidates + 1] = control.Parent end
    for _, descendant in ipairs(control.Parent:GetDescendants()) do
        if descendant:IsA("BasePart") then candidates[#candidates + 1] = descendant end
    end
    local best
    local bestDistance = math.huge
    for _, part in ipairs(candidates) do
        local name, distance = nearestPuzzleColor(part.Color)
        if distance < bestDistance then
            best = name
            bestDistance = distance
        end
    end
    if bestDistance < 0.45 then return best end
end

function solveShipColorCode()
    local pad = findCanonicalRoot("ColorCode")
    puzzleStatus = "ColorCode: discovering"
    local padControls
    local groupRoot
    if pad then
        padControls = controlsUnder(pad)
        groupRoot = pad
    else
        padControls, groupRoot = selectPuzzleControls("ColorCode", 4, {"color", "code", "button"}, false)
        pad = groupRoot
    end
    padControls = uniqueControls(padControls or {})

    local byColor = {}
    for _, control in ipairs(padControls) do
        local name = controlColorName(control)
        if name and not byColor[name] then byColor[name] = control end
    end

    local colorNames = {"Red", "Yellow", "Blue", "Green"}
    for _, name in ipairs(colorNames) do
        if not byColor[name] then
            puzzleStatus = "ColorCode: missing " .. name .. " button"
            return false
        end
    end

    local sequences = {}
    local seenSequences = {}
    local function addSequence(sequence)
        if #sequence ~= 4 then return end
        local key = table.concat(sequence, ",")
        if not seenSequences[key] then
            seenSequences[key] = true
            sequences[#sequences + 1] = sequence
        end
    end

    local clues = coloredGroupOfFour(pad)
    if clues and #clues == 4 then
        local parts = {}
        local colorByPart = {}
        for _, entry in ipairs(clues) do
            parts[#parts + 1] = entry.Part
            colorByPart[entry.Part] = entry.Color
        end
        linearOrder(parts, function(part) return part.Position end)
        local forward = {}
        for _, part in ipairs(parts) do forward[#forward + 1] = colorByPart[part] end
        local reverse = {}
        for index = #forward, 1, -1 do reverse[#reverse + 1] = forward[index] end
        addSequence(forward)
        addSequence(reverse)
    end

    local function permute(values, index)
        if index > #values then
            local copy = {}
            for i, value in ipairs(values) do copy[i] = value end
            addSequence(copy)
            return
        end
        for i = index, #values do
            values[index], values[i] = values[i], values[index]
            permute(values, index + 1)
            values[index], values[i] = values[i], values[index]
        end
    end
    permute({"Red", "Yellow", "Blue", "Green"}, 1)

    puzzleStatus = "ColorCode: buttons=4 attempts=" .. tostring(#sequences)
    local before = progressFingerprint()
    for attempt, sequence in ipairs(sequences) do
        puzzleStatus = "ColorCode: attempt " .. tostring(attempt) .. "/" .. tostring(#sequences)
        for _, colorName in ipairs(sequence) do
            clickControl(byColor[colorName])
            task.wait(0.025)
        end
        if waitForSolved(before, pad, 0.28) then return true end
        task.wait(0.04)
    end
    return false
end

function partLit(part)
    if not part or not part:IsA("BasePart") then return false end
    local light = part:FindFirstChildWhichIsA("PointLight", true)
        or part:FindFirstChildWhichIsA("SurfaceLight", true)
    if light and light.Enabled and light.Brightness > 0 then return true end
    if part.Material == Enum.Material.Neon then
        return math.max(part.Color.R, part.Color.G, part.Color.B) > 0.55
    end
    return false
end

function campSolved(root, entries)
    if localSolved(root) then return true end
    if root then
        for _, part in ipairs(root:GetDescendants()) do
            if part:IsA("BasePart") then
                local n = string.lower(part.Name)
                if n:find("center", 1, true)
                    or n:find("middle", 1, true)
                    or n:find("indicator", 1, true) then
                    if part.Color.G > 0.45
                        and part.Color.G > part.Color.R * 1.3
                        and part.Color.G > part.Color.B * 1.2 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function solveCampLightCircle()
    local controls, root = selectPuzzleControls("LightCircle", 8, {"light", "circle", "roulette", "button"}, false)
    controls = compactSubset(controls, 8)
    puzzleStatus = "LightCircle: controls=" .. tostring(#controls) .. " root=" .. tostring(root and root.Name or "none")
    if #controls ~= 8 then return false end
    local entries = circularOrder(controls)
    if #entries ~= 8 then return false end

    local startIndex
    local bestBrightness = -1
    for index, entry in ipairs(entries) do
        local part = entry.Control.Parent
        if part and part:IsA("BasePart") then
            local brightness = math.max(part.Color.R, part.Color.G, part.Color.B)
            if partLit(part) and brightness > bestBrightness then
                startIndex = index
                bestBrightness = brightness
            end
        end
    end
    if not startIndex then return false end

    local before = progressFingerprint()
    for _, direction in ipairs({1, -1}) do
        local clicked = {}
        for _, offset in ipairs({2, 5, 6}) do
            local index = ((startIndex - 1 + direction * offset) % 8) + 1
            clicked[#clicked + 1] = entries[index].Control
            clickControl(entries[index].Control)
            task.wait(0.03)
        end
        if campSolved(root, entries) or waitForSolved(before, root, 0.3) then return true end
        for _, control in ipairs(clicked) do
            clickControl(control)
            task.wait(0.02)
        end
    end

    local previousGray = 0
    for step = 1, 255 do
        local gray = bit32.bxor(step, bit32.rshift(step, 1))
        local changed = bit32.bxor(gray, previousGray)
        previousGray = gray
        for bit = 0, 7 do
            if bit32.band(changed, bit32.lshift(1, bit)) ~= 0 then
                clickControl(entries[bit + 1].Control)
                break
            end
        end
        task.wait(0.006)
        if campSolved(root, entries) or progressFingerprint() ~= before then return true end
    end
    return false
end

function colorIsGreen(part)
    return part
        and part:IsA("BasePart")
        and part.Color.G > 0.45
        and part.Color.G > part.Color.R * 1.25
        and part.Color.G > part.Color.B * 1.15
end

function findLabGrid()
    local root = findCanonicalRoot("ReactorGrid")
    local map = currentMapModel()
    local searchRoot = root or map
    if not searchRoot then return nil, {} end

    local candidates = {}
    for _, part in ipairs(searchRoot:GetDescendants()) do
        if part:IsA("BasePart") then
            local green = colorIsGreen(part)
            local red = part.Color.R > 0.4 and part.Color.R > part.Color.G * 1.2
            if green or red then candidates[#candidates + 1] = part end
        end
    end

    local groups = {}
    for _, part in ipairs(candidates) do
        local current = part.Parent
        for _ = 1, 5 do
            if not current or current == workspace then break end
            local group = groups[current]
            if not group then group = {}; groups[current] = group end
            group[#group + 1] = part
            current = current.Parent
        end
    end

    local bestRoot
    local bestParts
    local bestScore = math.huge
    for groupRoot, parts in pairs(groups) do
        local unique = {}
        local seen = {}
        for _, part in ipairs(parts) do
            if not seen[part] then seen[part] = true; unique[#unique + 1] = part end
        end
        if #unique >= 9 and #unique <= 12 then
            local score = math.abs(#unique - 9) * 1000 - keywordScore(groupRoot, {"square", "grid", "panel", "code"}) * 250
            if score < bestScore then
                bestRoot = groupRoot
                bestParts = unique
                bestScore = score
            end
        end
    end

    if not bestParts then return root, {} end
    while #bestParts > 9 do table.remove(bestParts) end
    return bestRoot or root, gridOrder(bestParts, function(part) return part.Position end)
end

function activateLabPower()
    local _, events = mapAndEvents()
    if not events then return false end
    local candidates = {}
    for _, control in ipairs(controlsUnder(events)) do
        local text = ancestorText(control, 6)
        if text:find("aux", 1, true)
            or text:find("power", 1, true)
            or text:find("reactor", 1, true) then
            candidates[#candidates + 1] = control
        end
    end
    local used = {}
    local usedCount = 0
    for _, control in ipairs(candidates) do
        local host = control.Parent
        if host and not used[host] then
            used[host] = true
            usedCount += 1
            clickControl(control)
            task.wait(0.15)
            if usedCount >= 2 then break end
        end
    end
    if usedCount > 0 then
        task.wait(4.2)
        return true
    end
    return false
end

function transformGridIndex(index, transform)
    local row = math.floor((index - 1) / 3)
    local col = (index - 1) % 3
    local r, c = row, col
    if transform >= 4 then c = 2 - c end
    local rotations = transform % 4
    for _ = 1, rotations do
        r, c = c, 2 - r
    end
    return r * 3 + c + 1
end

function solveLabLevers()
    puzzleStatus = "ReactorLevers: discovering"

    local gridRoot, grid = findLabGrid()
    local green = {}
    if #grid == 9 then
        for index, part in ipairs(grid) do
            if colorIsGreen(part) then green[#green + 1] = index end
        end
    end

    if #grid ~= 9 or #green ~= 3 then
        activateLabPower()
        gridRoot, grid = findLabGrid()
        green = {}
        if #grid == 9 then
            for index, part in ipairs(grid) do
                if colorIsGreen(part) then green[#green + 1] = index end
            end
        end
    end

    local controls, leverRoot = selectPuzzleControls(nil, 9, {"lever", "switch", "office", "room"}, false)
    controls = uniqueControls(controls)
    local filtered = {}

    for _, control in ipairs(controls) do
        if not gridRoot or not control:IsDescendantOf(gridRoot) then
            filtered[#filtered + 1] = control
        end
    end

    if #filtered ~= 9 then
        filtered = compactSubset(filtered, 9)
        if #filtered ~= 9 then
            filtered = compactSubset(controls, 9)
        end
    end

    puzzleStatus = "ReactorLevers: grid=" .. tostring(#grid)
        .. " green=" .. tostring(#green)
        .. " levers=" .. tostring(#filtered)

    if #filtered ~= 9 then return false end

    local before = progressFingerprint()

    if #grid == 9 and #green == 3 then
        local ordered = gridOrder(filtered, controlPosition)
        if #ordered == 9 then
            for transform = 0, 7 do
                local chosen = {}
                for _, index in ipairs(green) do
                    chosen[#chosen + 1] = ordered[transformGridIndex(index, transform)]
                end
                for _, control in ipairs(chosen) do
                    clickControl(control)
                    task.wait(0.025)
                end
                if waitForSolved(before, leverRoot, 0.22) then return true end
                for _, control in ipairs(chosen) do
                    clickControl(control)
                    task.wait(0.015)
                end
            end
        end
    end

    puzzleStatus = "ReactorLevers: exhaustive 0/511"
    local previousGray = 0
    for step = 1, 511 do
        local gray = bit32.bxor(step, bit32.rshift(step, 1))
        local changed = bit32.bxor(gray, previousGray)
        previousGray = gray

        for bit = 0, 8 do
            if bit32.band(changed, bit32.lshift(1, bit)) ~= 0 then
                clickControl(filtered[bit + 1])
                break
            end
        end

        if step % 16 == 0 then
            puzzleStatus = "ReactorLevers: exhaustive " .. tostring(step) .. "/511"
        end

        task.wait(0.008)
        if localSolved(leverRoot) or progressFingerprint() ~= before then
            return true
        end
    end

    return false
end

function solveDigitCode()
    local root = findCanonicalRoot("DigitCode")
    puzzleStatus = "DigitCode: discovering"

    if root and solveCodePanel(root) then return true end

    local rawControls
    local groupRoot
    if root then
        rawControls = controlsUnder(root)
        groupRoot = root
    else
        rawControls, groupRoot = selectPuzzleControls("DigitCode", 6, {"digit", "number", "code", "keypad", "plus", "minus"}, false)
        if #rawControls < 6 then
            rawControls, groupRoot = selectPuzzleControls("DigitCode", 3, {"digit", "number", "code", "keypad"}, true)
        end
    end

    local controls = collapseSlotControls(rawControls or {}, 3)
    local puzzleRoot = root or groupRoot
    puzzleStatus = "DigitCode: raw=" .. tostring(#(rawControls or {}))
        .. " slots=" .. tostring(#controls)
        .. " root=" .. tostring(puzzleRoot and puzzleRoot.Name or "none")

    if #controls ~= 3 then return false end
    return cyclePuzzleControls(controls, 10, 1000, puzzleRoot)
end

function solveRomanCode()
    local raw, root = selectPuzzleControls("RomanCode", 6, {"roman", "numeral", "code", "pillar"}, false)
    if #raw < 3 then
        raw, root = selectPuzzleControls("RomanCode", 3, {"roman", "numeral", "code", "pillar"}, true)
    end
    local controls = collapseSlotControls(raw, 3)
    puzzleStatus = "RomanCode: raw=" .. tostring(#raw)
        .. " slots=" .. tostring(#controls)
        .. " root=" .. tostring(root and root.Name or "none")
    if #controls ~= 3 then return false end
    local before = progressFingerprint()
    local counters = {0, 0, 0}
    for attempt = 1, 64 do
        local carry = true
        for index = 1, 3 do
            if carry then
                clickControl(controls[index])
                counters[index] += 1
                if counters[index] >= 4 then counters[index] = 0 else carry = false end
            end
        end
        task.wait(0.012)
        puzzleStatus = "RomanCode: " .. tostring(attempt) .. "/64"
        if localSolved(root) or progressFingerprint() ~= before then return true end
    end
    return false
end

function solveShapeWheel()
    local raw, root = selectPuzzleControls("ShapeWheel", 6, {"shape", "wheel", "symbol", "circle"}, false)
    if #raw < 3 then
        raw, root = selectPuzzleControls("ShapeWheel", 3, {"shape", "wheel", "symbol", "circle"}, true)
    end
    local controls = collapseSlotControls(raw, 3)
    puzzleStatus = "ShapeWheel: raw=" .. tostring(#raw)
        .. " slots=" .. tostring(#controls)
        .. " root=" .. tostring(root and root.Name or "none")
    if #controls ~= 3 then return false end
    local before = progressFingerprint()
    local counters = {0, 0, 0}
    for attempt = 1, 64 do
        local carry = true
        for index = 1, 3 do
            if carry then
                clickControl(controls[index])
                counters[index] += 1
                if counters[index] >= 4 then counters[index] = 0 else carry = false end
            end
        end
        task.wait(0.012)
        puzzleStatus = "ShapeWheel: " .. tostring(attempt) .. "/64"
        if localSolved(root) or progressFingerprint() ~= before then return true end
    end
    return false
end


function breakoutArmoryRoot()
    local map = currentMapModel()
    if not map then return nil end
    local best
    local bestCount = math.huge

    for _, descendant in ipairs(map:GetDescendants()) do
        if descendant:IsA("Model") or descendant:IsA("Folder") or descendant:IsA("BasePart") then
            local text = ancestorText(descendant, 3)
            if text:find("armory", 1, true) then
                local controls = uniqueControls(controlsUnder(descendant))
                if #controls >= 4 and #controls < bestCount then
                    best = descendant
                    bestCount = #controls
                end
            end
        end
    end

    if best then return best end

    local controls, root = groupedControls(4, {"armory", "code", "color", "button"}, false)
    if #controls >= 4 then return root end
    return nil
end

function breakoutColorButtons(root)
    if not root then return nil end
    local byColor = {}
    for _, control in ipairs(uniqueControls(controlsUnder(root))) do
        local color = controlColorName(control)
        if color and not byColor[color] then byColor[color] = control end
    end

    for _, color in ipairs({"Red", "Blue", "Green", "Purple"}) do
        if not byColor[color] then return nil end
    end
    return byColor
end

function breakoutKnife()
    if findOwnedById then
        local owned = findOwnedById("MilitaryKnife")
        if owned then return owned end
    end

    for item in pairs(items) do
        if item.Parent and itemId(item) == "MilitaryKnife" and isAvailableWorldItem(item) then
            local ok = grabItem(item, false, "MilitaryKnife")
            if ok and findOwnedById then
                local owned = findOwnedById("MilitaryKnife")
                if owned then return owned end
            end
        end
    end
end

function breakoutOmbra()
    local fallback
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Model") then
            local name = token(descendant.Name)
            if name == "ombra" then return descendant end
            if name:find("ombra", 1, true)
                and not name:find("red", 1, true)
                and not name:find("purple", 1, true) then
                fallback = fallback or descendant
            end
        end
    end
    return fallback
end

function useBreakoutKnife()
    local knife = breakoutKnife()
    local ombra = breakoutOmbra()
    if not knife or not ombra then return false end

    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local ombraPart = getPart(ombra)
    if not character or not humanoid or not ombraPart then return false end

    if knife.Parent ~= character then
        humanoid:EquipTool(knife)
        task.wait(0.04)
        knife = findOwnedById and findOwnedById("MilitaryKnife") or knife
    end

    local before = progressFingerprint()
    local handle = knife and (knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart", true))
    beginAutomationMove(ombraPart.CFrame + ombraPart.CFrame.LookVector * -1.5 + Vector3.new(0, 1, 0))
    task.wait(0.04)

    if handle and firetouchinterest then
        pcall(function()
            firetouchinterest(handle, ombraPart, 0)
            task.wait(0.03)
            firetouchinterest(handle, ombraPart, 1)
        end)
    end
    pcall(function() knife:Activate() end)

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and firetouchinterest then
        pcall(function()
            firetouchinterest(root, ombraPart, 0)
            task.wait(0.03)
            firetouchinterest(root, ombraPart, 1)
        end)
    end

    task.wait(0.12)
    endAutomationMove()
    return not ombra.Parent or progressFingerprint() ~= before
end

function solveBreakoutArmory()
    if useBreakoutKnife() then
        puzzleStatus = "Breakout: Ombra defeated"
        return true
    end

    local armory = breakoutArmoryRoot()
    local buttons = breakoutColorButtons(armory)
    if not armory or not buttons then
        puzzleStatus = "Breakout: armory not ready"
        return false
    end

    local colors = {"Red", "Blue", "Green", "Purple"}
    local sequences = {}
    local function permute(index)
        if index > #colors then
            local copy = {}
            for i, value in ipairs(colors) do copy[i] = value end
            sequences[#sequences + 1] = copy
            return
        end
        for i = index, #colors do
            colors[index], colors[i] = colors[i], colors[index]
            permute(index + 1)
            colors[index], colors[i] = colors[i], colors[index]
        end
    end
    permute(1)

    local before = progressFingerprint()
    for attempt, sequence in ipairs(sequences) do
        puzzleStatus = "Breakout: armory " .. tostring(attempt) .. "/24"
        for _, color in ipairs(sequence) do
            clickControl(buttons[color])
            task.wait(0.02)
        end
        if waitForSolved(before, armory, 0.22) then
            task.wait(0.12)
            if useBreakoutKnife() then return true end
            return true
        end
        task.wait(0.025)
    end

    return false
end

function breakoutCircleRoots()
    local map = currentMapModel()
    if not map then return {} end

    local result = {}
    local signatures = {}
    for _, descendant in ipairs(map:GetDescendants()) do
        if descendant:IsA("Model") or descendant:IsA("Folder") or descendant:IsA("BasePart") then
            local name = token(descendant.Name)
            if name:find("circle", 1, true) or name:find("colorpad", 1, true) then
                local controls = uniqueControls(controlsUnder(descendant))
                local byColor = {}
                local parts = {}
                for _, control in ipairs(controls) do
                    local color = controlColorName(control)
                    if color and (color == "Red" or color == "Blue" or color == "Green" or color == "Purple") then
                        byColor[color] = byColor[color] or control
                        parts[#parts + 1] = tostring(control.Parent)
                    end
                end
                if byColor.Red and byColor.Blue and byColor.Green and byColor.Purple then
                    table.sort(parts)
                    local signature = table.concat(parts, "|")
                    if not signatures[signature] then
                        signatures[signature] = true
                        result[#result + 1] = {Root = descendant, Buttons = byColor}
                    end
                end
            end
        end
    end
    return result
end

function solveBreakoutCircles()
    local roots = breakoutCircleRoots()
    if #roots == 0 then
        puzzleStatus = "Breakout: circles not found"
        return false
    end

    local progressed = false
    for index, entry in ipairs(roots) do
        if not localSolved(entry.Root) then
            for _, color in ipairs({"Red", "Blue", "Green", "Purple"}) do
                local before = progressFingerprint()
                puzzleStatus = "Breakout: circle " .. tostring(index) .. "/" .. tostring(#roots) .. " " .. color
                clickControl(entry.Buttons[color])
                if waitForSolved(before, entry.Root, 0.45) then
                    progressed = true
                    break
                end
                task.wait(1.05)
            end
        end
    end
    return progressed
end

function solveBreakout()
    if solveBreakoutArmory() then return true end
    if solveBreakoutCircles() then
        task.wait(0.08)
        if solveBreakoutArmory() then return true end
        return true
    end
    return false
end


function namedPuzzleControls(expected, keywords, allowDouble)
    local map = currentMapModel()
    if not map then return {}, nil end

    local bestControls
    local bestRoot
    local bestScore = math.huge

    for _, root in ipairs(map:GetDescendants()) do
        if root:IsA("Model") or root:IsA("Folder") or root:IsA("BasePart") then
            local words = keywordScore(root, keywords)
            if words > 0 then
                local controls = uniqueControls(controlsUnder(root))
                local count = #controls
                local countDelta = math.abs(count - expected)
                if allowDouble then
                    countDelta = math.min(countDelta, math.abs(count - expected * 2))
                end
                if count >= expected and count <= expected * 3 then
                    local score = countDelta * 1000 + boundsScore(controls) - words * 300
                    if score < bestScore then
                        bestControls = controls
                        bestRoot = root
                        bestScore = score
                    end
                end
            end
        end
    end

    return bestControls or {}, bestRoot
end

function solveHuntBookPuzzle()
    local controls, root = namedPuzzleControls(3, {"book", "library", "shelf"}, false)
    controls = uniqueControls(controls)
    if #controls < 3 then return false end
    controls = compactSubset(controls, 3)
    if #controls ~= 3 then return false end

    local before = progressFingerprint()
    for code = 0, 26 do
        local value = code
        local sequence = {}
        for index = 1, 3 do
            sequence[index] = (value % 3) + 1
            value = math.floor(value / 3)
        end

        puzzleStatus = "The Hunt: library " .. tostring(code + 1) .. "/27"
        for _, controlIndex in ipairs(sequence) do
            clickControl(controls[controlIndex])
            task.wait(0.02)
        end

        if waitForSolved(before, root, 0.16) then return true end
        task.wait(0.02)
    end
    return false
end

function solveHuntDials()
    local controls, root = namedPuzzleControls(3, {"valve", "dial", "cool", "engine"}, false)
    controls = uniqueControls(controls)
    if #controls < 3 then return false end
    controls = compactSubset(controls, 3)
    if #controls ~= 3 then return false end

    puzzleStatus = "The Hunt: cooling dials"
    return cyclePuzzleControls(controls, 4, 64, root)
end

function solveHuntCoordinates()
    local raw, root = namedPuzzleControls(6, {"coordinate", "coord", "time", "machine"}, true)
    if #raw < 3 then
        raw, root = namedPuzzleControls(3, {"coordinate", "coord", "time", "machine"}, true)
    end
    local controls = collapseSlotControls(raw, 3)
    if #controls ~= 3 then return false end

    puzzleStatus = "The Hunt: coordinates"
    return cyclePuzzleControls(controls, 10, 1000, root)
end

function solveHuntVault()
    local raw, root = namedPuzzleControls(3, {"vault", "ring", "safe"}, false)
    raw = uniqueControls(raw)
    if #raw < 3 then return false end
    local controls = compactSubset(raw, 3)
    if #controls ~= 3 then return false end

    puzzleStatus = "The Hunt: vault"
    return cyclePuzzleControls(controls, 10, 1000, root)
end

function solveHuntSequence()
    if solveHuntVault() then return true end
    if solveHuntCoordinates() then return true end
    if solveHuntDials() then return true end
    if solveHuntBookPuzzle() then return true end
    return false
end

function solveSpecialPuzzle(force)
    local mapName = currentMapName()
    local profile = mapProfiles[mapName]
    local puzzle = profile and profile.Puzzle
    if not puzzle then return false end
    local puzzleKey = mapName .. ":" .. puzzle
    local solvedAt = solvedPuzzles[puzzleKey]
    if solvedAt and not force and os.clock() - solvedAt < 1.5 then return false end
    if puzzleBusy or (not force and os.clock() < puzzleRetryAt) then return false end

    puzzleBusy = true
    local ok, solved = pcall(function()
        if puzzle == "DigitCode" then return solveDigitCode() end
        if puzzle == "ColorCode" then return solveShipColorCode() end
        if puzzle == "RomanCode" then return solveRomanCode() end
        if puzzle == "ShapeWheel" then return solveShapeWheel() end
        if puzzle == "LightCircle" then return solveCampLightCircle() end
        if puzzle == "ReactorLevers" then return solveLabLevers() end
        if puzzle == "BreakoutCircles" then return solveBreakout() end
        if puzzle == "HuntSequence" then return solveHuntSequence() end
        return false
    end)
    puzzleBusy = false

    if ok and solved then
        puzzleStatus = puzzle .. ": solved"
        solvedPuzzles[puzzleKey] = os.clock()
        puzzleRetryAt = os.clock() + 0.2
        return true
    end
    if not ok then
        puzzleStatus = puzzle .. ": error " .. tostring(solved):sub(1, 80)
    elseif puzzleStatus == "idle" then
        puzzleStatus = puzzle .. ": not ready"
    end
    puzzleRetryAt = os.clock() + 0.8
    return false
end

return solveCodePanel, solveSpecialPuzzle, function()
    return puzzleStatus
end, progressFingerprint
end)()
