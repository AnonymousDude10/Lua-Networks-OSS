local HttpService = game:GetService("HttpService")
local ChatService = game:GetService("Chat")
local Configuration = require(game.ServerScriptService:FindFirstChild("LuaNetworks"):FindFirstChild("Configuration"))

if not game.ServerScriptService:FindFirstChild("LuaNetworks") then
	warn("// Lua Networks // Configuration file not found.. Deleting script and cleaning up //")
end

local response = HttpService:RequestAsync({
	Url = 'https://luaapi.britdev.tech/api/v1/guildinfo',
	Headers = {
		["Content-Type"] = "application/json",
		['Authorization'] = "Bearer ".. Configuration.General.APIKey
	}
})
local decoded = HttpService:JSONDecode(response.Body)

if decoded.isPremium == true then
	warn("// Lua Networks // Successfully authenticated with the tier of premium and allowed //")
elseif decoded.isInternal == true then
	warn("// Lua Networks // Successfully authenticated with the tier of internal and allowed //")
else
	warn("// Lua Networks // Your guild doesn't have premium, please purchase it in the Lua Networks shop //")
	return script:Destroy()
end

game.Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(char)
		local playerRoleplay
		local filteredRoleplay
		
		local response = HttpService:RequestAsync({
			Url = 'https://luaapi.britdev.tech/api/v1/getoverhead',
			Method = 'POST',
			Body = HttpService:JSONEncode({
				playerUsername = Player.Name,
				playerId = Player.UserId,
			}),
			Headers = {
				["Content-Type"] = "application/json",
				['Authorization'] = "Bearer ".. Configuration.General.APIKey
			}
		})
		local decoded = HttpService:JSONDecode(response.Body)

		if response["StatusCode"] == 201 then
			if decoded.roleplay == "None" then
				filteredRoleplay = " "
			else
				playerRoleplay = decoded.roleplay
				filteredRoleplay = ChatService:FilterStringForBroadcast(playerRoleplay, Player)
			end
		elseif response["StatusCode"] == 429 then
			return warn("// Lua Networks // Your guild has reached the API rate limit for the day //")
		elseif response["StatusCode"] == 401 then
			return warn("// Lua Networks // Your guild has needs to have the premium tier //")
		else
			return warn("// Lua Networks // An internal error occured.. PLease provide this code to a administrator: "..response["StatusCode"].." //")
		end
		
		char.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		local PlayerOverhead = script.Storage.PlayerOverhead:Clone()
		PlayerOverhead.Parent = char.Head
		
		Player.Character.Head.PlayerOverhead.RoleplayName.Text = filteredRoleplay
		Player.Character.Head.PlayerOverhead.Username.Text = "@"..Player.Name
		Player.Character.Head.PlayerOverhead.Role.Text = Player:GetRoleInGroup(Configuration.General.GroupId)
	end)
end)
