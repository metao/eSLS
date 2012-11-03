
SLASH_eSLS1 = eSLS_slash1
SLASH_eSLS2 = eSLS_slash2

local reset_in_progress = 0

----------------------------------------------------------------
local function printRaidHelp(sender)

    local channel = eSLS_channel

    if sender ~= "RAID" then
        channel = "WHISPER"
    else
        sender = nil
    end

    SendChatMessage(eSLS_outPrefix.."Options:", channel, nil, sender)
    SendChatMessage(eSLS_outPrefix.." !eshroud   - bid half your points (high priority upgrade)", channel, nil, sender)
    SendChatMessage(eSLS_outPrefix.." !estandard - bid 10 points (normal priority)", channel, nil, sender)
    SendChatMessage(eSLS_outPrefix.." !esave     - bid 10 points, but not if someone else wants it (low priority/sidegrade)", channel, nil, sender)
    SendChatMessage(eSLS_outPrefix.." !ecancel   - cancel a bid", channel, nil, sender)
    SendChatMessage(eSLS_outPrefix.." !epoints   - see how many points you have", channel, nil, sender)
end

----------------------------------------------------------------
local function printLeaderHelp()

    print(eSLS_outPrefix..eSLS_slash1.." start - starts a raid")
    print(eSLS_outPrefix..eSLS_slash1.." stop  - ends a raid")
    print(eSLS_outPrefix..eSLS_slash1.." restart  - add 1 point and restart raid timers (eg because you got DC'd)")
    print(eSLS_outPrefix..eSLS_slash1.." open [item] - opens item for bidding")
    print(eSLS_outPrefix..eSLS_slash1.." close - closes bidding")
    print(eSLS_outPrefix..eSLS_slash1.." hold [player] - stop this player earning points")
    print(eSLS_outPrefix..eSLS_slash1.." shroud [player] [item] - shroud a player")
    print(eSLS_outPrefix..eSLS_slash1.." std [player] [item] - deduct points for a standard bid")
    print(eSLS_outPrefix..eSLS_slash1.." save [player] [item] - deduct points for a save bid")
    print(eSLS_outPrefix..eSLS_slash1.." add [player] [points] [reason] - give points to a player")
    print(eSLS_outPrefix..eSLS_slash1.." correct [player] [points] - set points on a player")
    print(eSLS_outPrefix..eSLS_slash1.." deduct [player] [points] [reason] - remove points from a player")
    print(eSLS_outPrefix..eSLS_slash1.." addraid [points] [reason] - add points to the raid")
    print(eSLS_outPrefix..eSLS_slash1.." raidhelp - print a list of ! commands players can use to talk to the addon")
    print(eSLS_outPrefix..eSLS_slash1.." reset - resets the saved points. Send this 3x.")
end


----------------------------------------------------------------
SlashCmdList["eSLS"] = function(msg)
    local cmd, arg = string.split(" ", msg)
    
    cmd = cmd:lower()

    if cmd == "start" then
        eSLS:startRaid()

    elseif cmd == "restart" then
        if eSLS_currentRaid then
            eSLS_addRaidPoints(eSLS_pointsPerPeriod)
        end

    elseif cmd == "stop" then
        eSLS:stopRaid()
        
    elseif cmd == "open" and arg then
        local item = msg:match("^open%s+(.+)")
        eSLS:openBidding(item)
    
    elseif cmd == "close" then
        eSLS:closeBidding()

    elseif cmd == "cancel" then
        eSLS:cancelBidding()

    elseif cmd == "shroud" and arg then
        local player, item = msg:match("^shroud%s+(.+)%s+(.+)")
        eSLS:shroudPlayer(player, item)

    elseif cmd == "std" and arg then
        local player, item = msg:match("^std%s+(.+)%s+(.+)")
        eSLS:stdPlayer(player, item)

    elseif cmd == "save" and arg then
        local player, item = msg:match("^save%s+(.+)%s+(.+)")
        eSLS:savePlayer(player, item)
        
    elseif cmd == "add" and arg then
        local player, points, reason = msg:match("^add%s+(.+)%s+([0-9]+)%s*(.*)")
        eSLS:addPlayerPoints(player, tonumber(points), reason)

    elseif cmd == "deduct" and arg then
        local player, points, reason = msg:match("^deduct%s+(.+)%s+([0-9]+)%s*(.*)")
        eSLS:deductPlayerPoints(player, tonumber(points), reason)
        
    elseif cmd == "addraid" and arg then
        local points, reason = msg:match("^addraid%s+([0-9]+)%s*(.*)")
        eSLS:addRaidPoints(tonumber(points), reason)

    elseif cmd == "hold" and arg then
        local player = msg:match("^hold%s+(.+)")
        eSLS:holdPointsForPlayer(player)

    elseif cmd == "unhold" and arg then
        local player = msg:match("^unhold%s+(.+)")
        eSLS:unholdPointsForPlayer(player)

    elseif cmd == "status" then
        eSLS_reportRaid()

    elseif cmd == "totals" then
        
        for i, v in pairs(eSLS_points) do
            print (eSLS_outPrefix..i..": "..v)
        end

    elseif cmd == "check" and arg then

        local player = msg:match("^check%s+(.+)")
        print(eSLS_outPrefix..player..": "..eSLS_points[player])
    
    elseif cmd == "correct" and arg then

        local player, points = msg:match("^correct%s+(.+)%s+([0-9]+)")
        eSLS_points[player] = tonumber(points)
        print(eSLS_outPrefix..player.." corrected to "..points)
    
    elseif cmd == "help" then
        printLeaderHelp()
        
    elseif cmd == "raidhelp" then
        printRaidHelp("RAID")

    elseif cmd == "reset" then
        if reset_in_progress < 3 then
            reset_in_progress = reset_in_progress + 1
            print(eSLS_outPrefix.."Reset in progress. ("..reset_in_progress.."/3)")
        else
            print(eSLS_outPrefix.."All points now reset.")
            eSLS_points = {}
            reset_in_progress = 0
        end
    else
        print("Invalid command")
    end
end

----------------------------------------------------------------
function eSLS:onWhisper(sender, msg)

    msg = msg:lower()

    if msg:sub(1, 1) == "!" and msg:sub(1, 2) ~= eSLS_inPrefix then
    
        if msg == "!help" then
        
            printRaidHelp(sender)
        else
        
            SendChatMessage(eSLS_outPrefix.."Try !e[command]", "WHISPER", nil, sender)
        end
        return
    end

    if msg:sub(1, 2) ~= eSLS_inPrefix then
        return
    end

    -- commands you can do outside of a raid

    if msg == "!epoints" then
    
        if eSLS_points[sender] then
            SendChatMessage(eSLS_outPrefix.."You have "..eSLS_points[sender].." points.", "WHISPER", nil, sender)
        else
            SendChatMessage(eSLS_outPrefix.."You have no points to bid with.", "WHISPER", nil, sender)
        end
        return
    end

    -- commands requiring items to be open for bid
    
    if not eSLS_currentItem then
        SendChatMessage(eSLS_outPrefix.."No items are currently open for bid.", "WHISPER", nil, sender)
        return
    end

    if msg == "!esave"  or msg == "!estd" or msg == "!estandard" or msg == "!eshroud" or msg == "!ecancel" then

        eSLS:addBid(sender, msg)
    else
        -- :TODO: handle self
        if (sender ~= "Grimtar") then
            SendChatMessage(eSLS_outPrefix.."You must !eshroud, !estandard or !esave to bid. !epoints for your current point total. Do !ehelp for a full list of options", "WHISPER", nil, sender)
        end
        return
    end
end

----------------------------------------------------------------
function eSLS:onRaidUpdate()

    eSLS:updateRaid()
end

----------------------------------------------------------------
function eSLS:onFlagChange(id)

    eSLS:updatePlayerStatus(id)
end