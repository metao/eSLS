eSLS = CreateFrame("Frame")

---------------------------------------------------------------
-- config items, you can change these
-- but only if you do it before the addon loads, or you're fucked
-- because apparently these get overwritten by saved values

eSLS_auctionTime = 30
eSLS_stdBid = 10
eSLS_saveBid = 10
eSLS_channel = "RAID_WARNING"
eSLS_slash1 = "/esls"
eSLS_slash2 = "/sls"
eSLS_currentItem = nil
eSLS_minPointsToShroud = eSLS_stdBid * 2
eSLS_pointsPeriod = 15 * 60 -- 15 mins
eSLS_pointsPerPeriod = 1
eSLS_pointsForStarting = 2
eSLS_pointsForEnding = 2

-- even if the above is true, Im scared. Im scared of heights.
if not eSLS_points then
    eSLS_points = {}
end

eSLS_currentRaid = nil
eSLS_lastRaid = nil
eSLS_winners = nil

-- not implemented
eSLS_allowStdToBeatLowShroud = true

-- :TODO should rename these prefixIn and prefixOut
eSLS_outPrefix = "eSLS: "
eSLS_inPrefix = "!e"


---------------------------------------------------------------
-- event handlers, best to leave these alone

local eventHandlers = {}

function eventHandlers.CHAT_MSG_WHISPER(msg, sender)
    eSLS:onWhisper(sender, msg)
end

function eventHandlers.RAID_ROSTER_UPDATE()
    eSLS:updateRaid()
end

function eventHandlers.PLAYER_FLAGS_CHANGED(id)
    eSLS:updatePlayerStatus(id)
end

local function eventHandler(self, event, ...)
    return eventHandlers[event](...)
end
  
    
  
-- can remove these; stole them from a book
--local function setOrHookHandler(frame, script, func)
--    print("setOrHookHandler ")
--    if frame:GetScript(script) then
--        frame:HookScript(script, func)
--    else
--        frame:SetScript(script, func)
--    end
--end

--for i = 1, NUM_CHAT_WINDOWS do
--    local frame = getglobal("ChatFrame"..i)
--    if frame then
--        setOrHookHandler(frame, "OnHyperLinkEnter", showTooltip)
--        setOrHookHandler(frame, "OnHyperLinkLeave", hideTooltip)
--    end
--end

eSLS:RegisterEvent("RAID_ROSTER_UPDATE")
eSLS:RegisterEvent("PLAYER_FLAGS_CHANGED")
eSLS:RegisterEvent("CHAT_MSG_WHISPER")
eSLS:SetScript("OnEvent", eventHandler)


-- filter out tells related to this addon
local function filterIncoming(self, event, ...)
    local msg = ...
    return msg:sub(1, eSLS_inPrefix:len()) == eSLS_inPrefix
end

local function filterOutgoing(self, event, ...)
    local msg = ...
    return msg:sub(0, eSLS_outPrefix:len()) == eSLS_outPrefix, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterIncoming)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterOutgoing)
