local tasks = {}

----------------------------------------------------------------
local function sortTasks(t1, t2)
    return t1.time > t2.time
end

----------------------------------------------------------------
local function onUpdate(self, elapsed)
    
    for i = #tasks, 1, -1 do
    
        local t = tasks[i]
        
        if t and t.time <= GetTime() then

            table.remove(tasks, i)
            
            t.func(unpack(t))
        end
    end
end

----------------------------------------------------------------
function eSLS:Timer_schedule(time, func, ...)
    local t = {...}
    t.func = func
    t.time = GetTime() + time
    table.insert(tasks, t)
    
    --table.sort(tasks, sortTasks)
end

----------------------------------------------------------------
function eSLS:Timer_unschedule(func, ...)

    local remaining = {}

    for i = #tasks, 1, -1 do
    
        local t = tasks[i]
        
        if func and t.func and t.func == func then

            local matches = true
            for i = 1, select("#", ...) do
                if select(i, ...) ~= t[i] then
                    matches = false
                    break
                end
            end
            if matches then
                table.insert(remaining, GetTime() - t.time)
                table.remove(tasks, i)
            end
        end
    end
    
    return remaining
end

----------------------------------------------------------------
local e = 0

eSLS:SetScript("OnUpdate", function(self, elapsed)
    e = e + elapsed
    if e > 1 then
        e = 0
        return onUpdate(self, elapsed)
    end
end)