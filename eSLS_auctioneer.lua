
-- local openBidding closeBidding placeBid cancelBidding onEvent

local bids = {}

-- the higher the better
local priority_shroud = 3
local priority_std = 2
local priority_save = 1

----------------------------------------------------------------
local function sortBids(v1, v2)
    
    -- use cases:
     -- shroud 11 vs standard 10 > priority wins
     -- shroud vs shroud > high bid wins
     -- shroud 9 vs standard 10
      -- only possible if eSLS_minPointsToShroud < 2xeSLS_stdPoints
    -- all other uses cases are simple priority wins or bid wins
    
    -- case 1: same priority
    if v1.priority == v2.priority then
    
        return v1.bid > v2.bid

    -- TODO... somehow....   
    --elseif eSLS_allowStdToBeatLowShroud and
        
    else
    -- case 2: different priority
        return v1.priority > v2.priority
    end
end

function eSLS_scheduledCloseBidding(dummy)
    eSLS:closeBidding()
end

----------------------------------------------------------------
function eSLS:openBidding(item)
    if eSLS_currentItem then
        print(eSLS_outPrefix.."Auction already running on " .. eSLS_currentItem)
        return
    end
    
    eSLS_currentItem = item
    
    SendChatMessage(eSLS_outPrefix.."Bids open for " .. item, eSLS_channel)
    
    if (eSLS_auctionTime > 10) then
        eSLS:Timer_schedule(eSLS_auctionTime - 10, SendChatMessage, eSLS_outPrefix.."Time remaining: 10 seconds", eSLS_channel)
    end
    
    eSLS:Timer_schedule(eSLS_auctionTime, eSLS_scheduledCloseBidding, 1)
end

----------------------------------------------------------------    
function eSLS:cancelBidding()

    if not eSLS_currentItem then
        return
    end

    SendChatMessage(eSLS_outPrefix.."Bids cancelled for " .. eSLS_currentItem, eSLS_channel)
    
    eSLS_currentItem = nil
    table.wipe(bids)
    
    eSLS:Timer_unschedule(SendChatMessage)
    eSLS:Timer_unschedule(eSLS_scheduledCloseBidding)
end    

----------------------------------------------------------------    
function eSLS:closeBidding()

    if not eSLS_currentItem then
        return
    end

    eSLS:Timer_unschedule(SendChatMessage)
    eSLS:Timer_unschedule(scheduledCloseBidding)

    SendChatMessage(eSLS_outPrefix.."Bids closed for " .. eSLS_currentItem, eSLS_channel)
    
    table.sort(bids, sortBids)
    
    if #bids == 0 then
    
        SendChatMessage(eSLS_outPrefix.."No bids - Disenchant!", eSLS_channel)
    elseif #bids == 1 then
    
        bids[1].bid = math.min(eSLS_saveBid, bids[1].bid)
        SendChatMessage(eSLS_outPrefix.."Only bidder: " .. bids[1].name .. " for " .. bids[1].bid.." (minimum bid)", eSLS_channel)

    elseif (bids[1].bid ~= bids[2].bid) then
    
        SendChatMessage(eSLS_outPrefix.."Winner: " .. bids[1].name .. " for " .. bids[1].bid, eSLS_channel)
        for i = 2, #bids do
            if (bids[i].bid == bids[2].bid) then
                SendChatMessage(eSLS_outPrefix.."Runner-up: " .. bids[i].name .. " for " .. bids[i].bid, eSLS_channel)
            end
        end
    else
        
        SendChatMessage(eSLS_outPrefix.."Bidders:", eSLS_channel)    
        -- Table to hold the players who bid on item. tells all the people who should to roll
        local rollplayers = {}
        local rollplayersindex = 1
        
        -- scroll through bids, adding them to the list, until one has a lower bid or priority
        local winners_str  = ""
        local winners = 0
        for i = 1, #bids do
        
        	local bidText = ""
        	
        	if(bids[i].priority == priority_shroud) then bidText = "Shroud"
        	elseif(bids[i].priority == priority_std) then bidText = "Standard"
        	elseif(bids[i].priority == priority_save) then bidText = "Save"
        	end
        	
            SendChatMessage(eSLS_outPrefix..bids[i].name..": ".."("..bidText..") "..bids[i].bid, eSLS_channel)
            if (bids[i].bid ~= bids[1].bid) or (bids[i].priority ~= bids[1].priority) then
            
                break
            end
            rollplayers[rollplayersindex] = bids[i].name
            rollplayersindex = rollplayersindex + 1
            winners_str = winners_str .. " " .. bids[i].name
            winners = winners + 1
        end
        
        if winners == 1 then
            SendChatMessage(eSLS_outPrefix.."Winner: " .. bids[1].name .. " for " .. bids[1].bid, eSLS_channel)
            eSLS:winner(bids[1].name, bids[1].bid, eSLS_currentItem)
        else
        
            SendChatMessage(eSLS_outPrefix.."Equal bids for " .. bids[1].bid .. " from:" .. winners_str, eSLS_channel)
            SendChatMessage(eSLS_outPrefix.."Roll off!", eSLS_channel)
            
            -- implement roll monitor OR
            
            -- Whisper players to roll
            for i = 1, #rollplayers do        
	            SendChatMessage(eSLS_outPrefix.."You are currently contesting loot, please roll!", "WHISPER", nil, rollplayers[i] )
	        end
            
        end
        -- trigger a watcher for giving out loot, record the target and deduct DKP
    end
    
    table.wipe(rollplayers)
    eSLS_currentItem = nil
    table.wipe(bids)
end
        
----------------------------------------------------------------
function eSLS:addBid(sender, msg)
    
    if not eSLS_currentItem then
        return
    end
    
    local this_bid_points = 0
    local this_bid_priority = 0
    local senders_points = 0
    
    if eSLS_points[sender] then
        senders_points = eSLS_points[sender]
    end
    
    if msg == "!esave" then
    
        this_bid_priority = priority_save
        this_bid_points = eSLS_saveBid
        
        -- check current points and adjust if required
        if senders_points < eSLS_stdBid then
            this_bid_points = senders_points
        end    
        
    elseif msg == "!estd" or msg == "!estandard" then
        
        this_bid_priority = priority_std
        this_bid_points = eSLS_stdBid

        -- check current points and adjust if required
        if senders_points < eSLS_stdBid then
            this_bid_points = senders_points
        end    

    elseif msg == "!eshroud" then
    
        this_bid_priority = priority_shroud

        -- check current points and adjust if required
        if senders_points < eSLS_minPointsToShroud then
            SendChatMessage(eSLS_outPrefix.."You don't have enough points to Shroud.", "WHISPER", nil, sender)
            return
        end    
    
        this_bid_points = math.floor(senders_points / 2)
            
    elseif msg == "!ecancel" then
        
        for i = #bids, 1, -1 do
    
            local b = bids[i]
        
            if b and b.name == sender then

                table.remove(bids, i)
            end    
            SendChatMessage(eSLS_outPrefix.."You have cancelled your bid on "..eSLS_currentItem, "WHISPER", nil, sender)
            print(eSLS_outPrefix..": "..sender.." has cancelled on "..eSLS_currentItem)
            return
        end
    else
    
        print("This bugged out! No proper command was recognized!")
    end

    SendChatMessage(eSLS_outPrefix.."You have "..msg.." for "..this_bid_points.." points on "..eSLS_currentItem, "WHISPER", nil, sender)
    SendChatMessage(eSLS_outPrefix..msg.." from "..sender.." on "..eSLS_currentItem, eSLS_channel)
    print(eSLS_outPrefix..": "..sender.." has "..msg.." for "..this_bid_points.." points on "..eSLS_currentItem)
   
    -- handle duplicate bidders
    for i, v in ipairs(bids) do
        if sender == v.name then
            v.bid = this_bid_points
            v.priority = this_bid_priority
            return
        end
    end
    
    table.insert(bids, {bid = this_bid_points, name = sender, priority = this_bid_priority})    
end