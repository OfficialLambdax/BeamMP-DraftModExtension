-- Made by Neverless (BeamMP @ Staff)

local version = "1.0" -- works with 0.1 of the Draftmod by Olrosse

-- requirements
local json = require("json")

-- Auth (sf_admins path can be changed)
local admins = {} -- contains all playernames that have access to the Chat Commands
local sf_admins = "Resources/Server/draft_serverside/data/admins.json" -- contains the playername on the disk

-- Default Client Variables (Changeable either Manualy or through Commands)
local defaultForce = 1
local defaultEnabled = true

-- Default Server Variables (Changeable either Manualy or through Commands)
local defaultClientUpdate = 10000 -- in ms

-- Internals (Dont Change)
local excludePlayers = {}


--[[

	admins.json file format
		
		{"admins":["PlayerName1","PlayerName2"]}
		
		All players in the admins array have access to the Commands below

	Commands
	
		Note: Whenever a Admin calls any of these Commands, the Successful Result of that Command is
		propagated to every Admin that is currently Online.

		/draftmod updatetimer X
			This script updates the Default Values to each player every so often. This command
			allows you to set the interval time, where X is a Number in Seconds.
			eg.
				/draftmod updatetimer 10
					will update the values every 10 seconds
			
			Setting it to 0 will disable the update entirely
			
			
			
		/draftmod setstate X
			Enables/Disables the DraftMod for each Client. Where X is true or false
			eg. 
				/draftmod setstate false
					disables the draftmod for every player



		/draftmod setforce X
			Sets the Draft force multiplier. Where X is a Number
			eg.
				/draftmod setforce 2
					multiplies the draft force by 2

	
	
		/draftmod setadmin X Y
			Makes a Player a Admin or removes him from the Admins. Sets are Permanent
			Where X is the Player Name and Y the state in true or false
			eg.
				/draftmod setadmin SomeonesName true
					gives SomeonesName admin rights for this script
					
		
		
		/draftmod exclude X Y
			Every player excluded will have their Draft Mod disabled. Usefull for Time trail /
			Qualification Scenarios.
			Where X is the PlayerName and Y the state in true or fals 
			eg.
				/draftmod exclude SomeonesName true
					SomeonesName will have its draftmod disabled
		
]]--



-- Internals
-- ========================================================================================
-- ========================================================================================
-- ========================================================================================

-- loads the disk json of all admins into memory
local function loadAdmins()
	for k, v in pairs(admins) do
		admins[k] = nil
	end

	local handle = io.open(sf_admins, "r")
	local oAdmins = json.parse(handle:read("*all"))
	handle:close()
	
	-- {"admins":["Player1","Player2"]}
	local players = oAdmins.admins
	if players ~= nil then
		for i in pairs(players) do
			admins[players[i]] = true
		end
	end
end

local function isAdmin(name)
	return admins[name] ~= nil
end

-- creates an array from the message split by a whitespace
-- [0] = /draftmod
-- [1] = param1
-- [2] = arg
-- [n]
local function messageSplit(message)
	local messageSplit = {}
	local nCount = 0
	for i in string.gmatch(message, "%S+") do
		messageSplit[nCount] = i
		nCount = nCount + 1
	end
	
	return messageSplit
end

local function toBool(value)
	local value = string.upper(value)
	if value == "TRUE" then return true end
	if value == "FALSE" then return false end
	return nil
end

local function setAdmin(playerName, state)
	if state == true then
		if isAdmin(playerName) then return false end
		admins[playerName] = true
	else
		if isAdmin(playerName) == false then return false end
		admins[playerName] = nil
	end
	
	local newadmins = {}
	local players = {}
	
	local nCount = 1 -- required to have the json.lua treat this as a Array instead of a Object
	for playerName, v in pairs(admins) do
		players[nCount] = playerName
		nCount = nCount + 1
	end
	
	newadmins["admins"] = players
	
	local handle = io.open(sf_admins, "w")
	handle:write(json.stringify(newadmins))
	handle:close()
	
	return true
end

-- propagates message to all admins
local function propagateMessage(senderId, message)
	local players = MP.GetPlayers()
	
	print("draftmod: " .. message .. " (by " .. MP.GetPlayerName(senderId) .. ")")
	
	for playerId, playerName in pairs(players) do
		if isAdmin(playerName) == true then
			MP.SendChatMessage(playerId, "draftmod: " .. message .. " (by " .. MP.GetPlayerName(senderId) .. ")")
		end
	end
end

-- The Messageformat of BeamMP uses ":" as data seperator. We want to send/receive data as json
-- but json also contains ":". Thats why we replace every ":" with "%%"
local function encodeHCAJSON(data)
    return string.gsub(json.stringify(data), ":", "%%%%")
end

local function decodeHCAJSON(str)
    local t = string.gsub(str, "%%%%", ":")
    return json.parse(t)
end

local function isOnline(playername)
	local players = MP.GetPlayers()
	
	for playerId, playerName in pairs(players) do
		if playerName == playername then return true end
	end
	return false
end

-- Event Functions
-- ========================================================================================
-- ========================================================================================
-- ========================================================================================

function draft_updateclientvalues()
	local values = {}
	values["force"] = defaultForce
	values["enabled"] = defaultEnabled
	local json = encodeHCAJSON(values)
	
	local values = {}
	values["enabled"] = false
	local excludedJson = encodeHCAJSON(values)
	
	local players = MP.GetPlayers()
	for playerId, playerName in pairs(players) do
		if excludePlayers[playerName] == nil then
			MP.TriggerClientEvent(playerId, "draft_updatevalues", json)
		else
			MP.TriggerClientEvent(playerId, "draft_updatevalues", excludedJson)
		end
	end
end

function draft_onDisconnect(playerId)
	excludePlayers[MP.GetPlayerName(playerId)] = nil
end

function draft_onChatMessage(senderId, senderName, message)
	if isAdmin(senderName) ~= true then return end
	if string.sub(message, 0, 9) ~= '/draftmod' then return end
	
	local message = messageSplit(message)
	
	-- parse message
	if message[1] == "updatetimer" then -- [2] = Time in seconds as Number (set the update interval)
		if message[2] == nil then MP.SendChatMessage(senderId, "Missing parameter"); return 1 end
		message[2] = tonumber(message[2])
		if message[2] == nil then MP.SendChatMessage(senderId, "Invalid parameter"); return 1 end
		
		if message[2] == 0 then
			MP.CancelEventTimer("draft_updateclientvalues")
			propagateMessage(senderId, "Disabled Client Update Interval")
			return 1
		end
		
		defaultClientUpdate = message[2] * 1000

		MP.CancelEventTimer("draft_updateclientvalues")
		MP.CreateEventTimer("draft_updateclientvalues", defaultClientUpdate)

		propagateMessage(senderId, "Set Client Update Interval to " .. message[2] .. " seconds")
		return 1
		
	elseif message[1] == "setstate" then -- [2] = True/False (enables/disables the drafting on the clients)
		if message[2] == nil then MP.SendChatMessage(senderId, "Missing parameter"); return 1 end
		message[2] = toBool(message[2])
		if message[2] == nil then MP.SendChatMessage(senderId, "Invalid parameter"); return 1 end
		
		defaultEnabled = message[2]
		draft_updateclientvalues()
		
		propagateMessage(senderId, "State has been set to " .. tostring(defaultEnabled))
		return 1
		
	elseif message[1] == "setforce" then -- [2] = Multiplier as Number (sets the force multiplier)
		if message[2] == nil then MP.SendChatMessage(senderId, "Missing parameter"); return 1 end
		message[2] = tonumber(message[2])
		if message[2] == nil then MP.SendChatMessage(senderId, "Invalid parameter"); return 1 end
		
		defaultForce = message[2]
		draft_updateclientvalues()
		propagateMessage(senderId, "Set Force to " .. message[2])
		return 1
		
	elseif message[1] == "setadmin" then -- [2] = PlayerName [3] = True/False (gives/removed [2] admin rights)
		if message[2] == nil then MP.SendChatMessage(senderId, "Missing parameter"); return 1 end
		if message[3] == nil then MP.SendChatMessage(senderId, "Missing parameter"); return 1 end
		message[3] = toBool(message[3])
		if message[3] == nil then MP.SendChatMessage(senderId, "Invalid parameter"); return 1 end
		
		if setAdmin(message[2], message[3]) == true then
			if message[3] == true then
				propagateMessage(senderId, message[2] .. " has been made a admin")
			else
				propagateMessage(senderId, message[2] .. " is no longer a admin")
			end

		else
			if message[3] == true then
				propagateMessage(senderId, message[2] .. " already is an Admin")
			else
				propagateMessage(senderId, message[2] .. " was no Admin")
			end
		end
		
		return 1
	
	elseif message[1] == "exclude" then -- [2] = PlayerName [3] = True/False (players set here will have their drafing mod disabled - useful for Time Trails / Qualification)
		if message[2] == nil then MP.SendChatMessage(senderId, "Missing parameter"); return 1 end
		if message[3] == nil then MP.SendChatMessage(senderId, "Missing parameter"); return 1 end
		message[3] = toBool(message[3])
		if message[3] == nil then MP.SendChatMessage(senderId, "Invalid parameter"); return 1 end
		
		if isOnline(message[2]) ~= true then MP.SendChatMessage(senderId, "Player is unknown"); return 1 end
		
		if message[3] == true then
			excludePlayers[message[2]] = true
			propagateMessage(senderId, "Player: " .. message[2] .. " has been excluded")
		else
			excludePlayers[message[2]] = nil
			propagateMessage(senderId, "Player: " .. message[2] .. " has been reincluded")
		end
		draft_updateclientvalues()
		
		return 1
	
	end
	
	return 1
	
end

loadAdmins()

-- internals
MP.CancelEventTimer("draft_updateclientvalues")
MP.CreateEventTimer("draft_updateclientvalues", defaultClientUpdate)
MP.RegisterEvent("draft_updateclientvalues", "draft_updateclientvalues")
MP.RegisterEvent("onPlayerDisconnect", "draft_onDisconnect")

-- Called By the Players sending a Chat message
MP.RegisterEvent("onChatMessage", "draft_onChatMessage")

-- testing
--draft_onChatMessage(0, "Neverless", "/draftmod updatetimer 0")
--draft_onChatMessage(0, "Neverless", "/draftmod setstate false")
--draft_onChatMessage(0, "Neverless", "/draftmod setforce 2")
--draft_onChatMessage(0, "Neverless", "/draftmod setadmin Player1 true")


print("-------- Draft Mod loaded --------")