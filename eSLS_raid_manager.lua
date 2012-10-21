
----------------------------------------------------------------
function eSLS:winner(player, points, item)

    local i = 0

    if eSLS_winners then
        i = #eSLS_winners
    else
        eSLS_winners = {}
    end

    eSLS_winners[i] = player.." "..points.." "..item
end

----------------------------------------------------------------
local function eSLS_getPlayer(index)

    --print("eSLS_getPlayer: "..index)

    local player= {}
    
    player.name, player.rank, player.subgroup, player.level, player.class, player.fileName, player.zone, player.isDead, player.role, player.isML =  GetRaidRosterInfo(index)

    player.index = index
    player.unitid = "raid"..index

    return player
end

----------------------------------------------------------------
function eSLS_getIndexFromName(name)

    if not name then
        --print("eSLS_getIndexFromName: nil")
        return nil
    end

    --print("eSLS_getIndexFromName: "..name)

    for i = 1, GetRealGroupMembers() do

        player = eSLS_getPlayer(i)
    
        if player.name == name then
            return player.index
        end
    end
    
    return nil
end

----------------------------------------------------------------
local function eSLS_reportPlayer(name)

    local p = eSLS_currentRaid[name]
    
    if not p then
        print(p.name.." not found in current raid!")
    elseif eSLS_points[name] then
        print(p.name.." ["..p.unitid..", "..p.points..", "..p.hold..", "..p.joinTime.."]["..eSLS_points[p.name].."]")
    else
        print(p.name.." ["..p.unitid..", "..p.points..", "..p.hold..", "..p.joinTime.."]")
    end
end

----------------------------------------------------------------
function eSLS_reportRaid()

    if not eSLS_currentRaid then
        return
    end
    
    for name, player in pairs(eSLS_currentRaid) do
        eSLS_reportPlayer(name)
    end
end

----------------------------------------------------------------
function eSLS_addRaidPoints(points, reason)

    eSLS:addRaidPoints(points, reason)

    -- schedule the next event
    eSLS:Timer_schedule(eSLS_pointsPeriod, eSLS_addRaidPoints, eSLS_pointsPerPeriod)
end

----------------------------------------------------------------
----------------------------------------------------------------
function eSLS:startRaid()
    
    if eSLS_currentRaid then
        print("Raid is in progress.")
        return
    end
    
    eSLS_currentRaid = {}
    eSLS_winners = {}
        
    local hour,minute = GetGameTime()
    SendChatMessage(eSLS_outPrefix.."Raid started at "..hour..":"..minute, eSLS_channel)

    eSLS:updateRaid()
    eSLS:addRaidPoints(eSLS_pointsForStarting)
    eSLS:Timer_schedule(eSLS_pointsPeriod, eSLS_addRaidPoints, eSLS_pointsPerPeriod)
end

----------------------------------------------------------------
function eSLS:stopRaid()

    if not eSLS_currentRaid then
        print("No raid is in progress.")
        return
    end

    local hour,minute = GetGameTime()
    local remaining = eSLS:Timer_unschedule(eSLS_addRaidPoints)
 
    -- Don't forget to add an extra 2 points if the timer was nearly up
    if #remaining ~= 1 then
        print(eSLS_outPrefix.."I'm confused about my timers...")
    elseif remaining[1] > (eSLS_pointsPeriod / 2) then
        SendChatMessage(eSLS_outPrefix.."Adding "..eSLS_PointsPerPeriod.." for remaining time.", eSLS_channel)
        eSLS:addRaidPoints(eSLS_pointsPerPeriod)
    end

    eSLS:updateRaid()
    eSLS:addRaidPoints(eSLS_pointsForEnding)

--    SendChatMessage(eSLS_outPrefix.."Raid ended at "..hour..":"..minute..". " + eSLS_currentRaid["TotalForRaid"].." points earned!", eSLS_channel)
    SendChatMessage(eSLS_outPrefix.."Raid ended at "..hour..":"..minute..".", eSLS_channel)
    
    eSLS_lastRaid = {}
    
    -- serialise points
    for player_name, v in pairs(eSLS_currentRaid) do

        if eSLS_points[player_name] then
            eSLS_points[player_name] = eSLS_points[player_name] + v.points
        else
            eSLS_points[player_name] = v.points
        end
        
        eSLS_lastRaid[player_name] = v.points
    end
    
--    eSLS_lastRaid = eSLS_currentRaid
    
    -- reset current raid
    eSLS_currentRaid = nil
end

----------------------------------------------------------------
function eSLS:addPlayerPoints(player_name, points, reason)

    if not eSLS_currentRaid then
        print("No raid is in progress.")
        return
    end

    if not eSLS_currentRaid[player_name] then
        print("Player not found")
        return
    end

    if not points then
        return
    end
    
    local line = points.." points added to "..player_name
    if points < 0 then
        line = abs(points).." points deducted from "..player_name
    end
    
    if strlen(reason) > 0 then
        SendChatMessage(eSLS_outPrefix..line.." for "..reason..".", eSLS_channel)
    else
        SendChatMessage(eSLS_outPrefix..line..".", eSLS_channel)
    end

    eSLS_currentRaid[player_name].points = max(eSLS_currentRaid[player_name].points + points, 0)

    --eSLS_reportRaid()
end

----------------------------------------------------------------
function eSLS:deductPlayerPoints(player_name, points, reason)

    eSLS:addPlayerPoints(player_name, 0 - points, reason)
end

----------------------------------------------------------------
function eSLS:addRaidPoints(points, reason)

    if not eSLS_currentRaid then
        print("No raid is in progress.")
        return
    end

    if reason and strlen(reason) > 0 then
        SendChatMessage(eSLS_outPrefix.."Adding "..points.." points to raid for "..reason.."!", eSLS_channel)
    else
        SendChatMessage(eSLS_outPrefix.."Adding "..points.." points to raid!", eSLS_channel)
    end

    eSLS:updateRaid()
    --eSLS_reportRaid()
    
    -- for raid members, add points
    -- TODO also check jointime?
    for player_name, v in pairs(eSLS_currentRaid) do
        if eSLS_currentRaid[player_name].hold == 0 then
        
    --        print(eSLS_outPrefix.."Points for "..player_name)
            eSLS_currentRaid[player_name].points = eSLS_currentRaid[player_name].points + points
        else
            print(eSLS_outPrefix.."Points not awarded to "..player_name)
        end
    end
    
--    eSLS_currentRaid["TotalForRaid"] = eSLS_currentRaid["TotalForRaid"] + points
    
    --eSLS_reportRaid()
end

----------------------------------------------------------------
function eSLS:shroudPlayer(player_name, item)

    if not eSLS_currentRaid then
        print("No raid is in progress.")
        return
    end

    if not eSLS_currentRaid[player_name] then
        print(eSLS_outPrefix.."Player not found: "..player_name)
        return
    end

    local points = 0

    if eSLS_points[player_name] then
        points = math.floor(eSLS_points[player_name] / 2)
    end
    
    if (points < eSLS_stdBid) then
        print(eSLS_outPrefix.."That player doesn't have enough points to Shroud.")
        return
    end

    eSLS_points[player_name] = eSLS_points[player_name] - points

    print(eSLS_outPrefix..points.." shrouded from "..player_name..", "..eSLS_points[player_name].." remaining.")
    eSLS:winner(player_name, points, item)

    --eSLS_reportRaid()
end

----------------------------------------------------------------
function eSLS:stdPlayer(player_name, item)

    if not eSLS_currentRaid then
        print("No raid is in progress.")
        return
    end

    if not eSLS_currentRaid[player_name] then
        print(eSLS_outPrefix.."Player not found: "..player_name)
        return
    end

    eSLS_points[player_name] = max(eSLS_points[player_name] - eSLS_stdBid, 0)

    print(eSLS_outPrefix..eSLS_stdBid.." standard taken from "..player_name..", "..eSLS_points[player_name].." remaining.")
    eSLS:winner(player_name, eSLS_stdBid, item)

    --eSLS_reportRaid()
end

----------------------------------------------------------------
function eSLS:savePlayer(player_name, item)

    if not eSLS_currentRaid then
        print("No raid is in progress.")
        return
    end

    if not eSLS_currentRaid[player_name] then
        print(eSLS_outPrefix.."Player not found: "..player_name)
        return
    end

    eSLS_points[player_name] = max(eSLS_points[player_name] - eSLS_saveBid, 0)

    print(eSLS_outPrefix..eSLS_saveBid.." save taken from "..player_name..", "..eSLS_points[player_name].." remaining.")
    eSLS:winner(player_name, eSLS_saveBid, item)

    --eSLS_reportRaid()
end

----------------------------------------------------------------
function eSLS:holdPointsForPlayer(player_name)

    if not eSLS_currentRaid then
        print("No raid is in progress.")
        return
    end

    if not eSLS_currentRaid[player_name] then
        print(eSLS_outPrefix.."Player not found")
        return
    end

    print(eSLS_outPrefix.."Holding points for "..player_name)
    
    eSLS_currentRaid[player_name].hold = 1
end

----------------------------------------------------------------
function eSLS:unholdPointsForPlayer(player_name)

    if not eSLS_currentRaid then
        print("No raid is in progress.")
        return
    end

    if not eSLS_currentRaid[player_name] then
        print(eSLS_outPrefix.."Player not found")
        return
    end

    print(eSLS_outPrefix.."Unholding points for "..player_name)

    eSLS_currentRaid[player_name].hold = 0
end


----------------------------------------------------------------
function eSLS:updateRaid()
    
    if not eSLS_currentRaid then
        return
    end

--    print ("Raid size: "..GetNumGroupMembers())

    for i = 1, GetNumGroupMembers() do

        player = eSLS_getPlayer(i)

--        print("checking "..player.name.." ("..player.unitid..")")
        
        if not eSLS_currentRaid[player.name] then
            print(eSLS_outPrefix.."Adding "..player.name)

            -- don't load points, since this is like a pending deposit
            my_player = {}
            my_player.unitid = player.unitid
            my_player.name = player.name
            my_player.points = 0
            my_player.joinTime = GetTime()
            my_player.hold = 0

            eSLS_currentRaid[player.name] = my_player
        end

        -- detect the newly afk
        if UnitIsAFK(player.unitid) and (eSLS_currentRaid[player.name].hold == 0) then
            print(eSLS_outPrefix.."OFFLINE ALERT - you should hold points for offline player: "..player.name)
        end
    end
    
    -- find people who aren't in the raid any more
    for player_name, v in pairs(eSLS_currentRaid) do
    
        local found = false
    
        for i = 1, GetNumGroupMembers() do
    
            player = eSLS_getPlayer(i)
            
            if (player.name == player_name) then
                found = true
            end
        end
    
        if ((found == false) and (eSLS_currentRaid[player_name].hold == 0)) then
            print(eSLS_outPrefix.."QUITTER ALERT - you should hold points for player not in raid: "..player_name)
        end
    end
    
    --eSLS_reportRaid()
end

----------------------------------------------------------------
function eSLS:updatePlayerStatus(id)
    
    if not eSLS_currentRaid or not (id:sub(1, 4) == "raid") then
        return
    end

    -- fuck it, just do it the crappy slow way
    eSLS:updateRaid()
end
