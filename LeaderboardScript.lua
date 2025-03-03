local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Manager = require(script.Parent.PlayerData.Manager)

-- Ordered DataStores
local PlayerCoins = DataStoreService:GetOrderedDataStore("Coin")
local PlayerDonated = DataStoreService:GetOrderedDataStore("Donated")
local PlayerTime = DataStoreService:GetOrderedDataStore("Time")

local leaderBoardCoins = workspace.Auditorium.LeaderBoard_Coins.board.Leaderboard
local scrollingFrame = leaderBoardCoins.LBFrame.ScrollingFrame
local playerContentTemplate = scrollingFrame:FindFirstChild("PlayerContent")

local leaderboardDonated = workspace.Auditorium.LeaderBoard_Donated.board.LeaderBoard
local scrollingFrameD = leaderboardDonated.LBFrame.ScrollingFrame
local playercontentDonated = scrollingFrameD.PlayerContent

local leaderboardTime = workspace.Auditorium.LeaderBoard_TimePlayed.board.LeaderboardTime
local scrollingFrameTime = leaderboardTime.LBFrame.ScrollingFrame
local playerContentTime = scrollingFrameTime.PlayerContent
local FormatNumber = require(game:GetService('ReplicatedStorage').FormatNumber.Main)

local abbreviations = FormatNumber.Notation.compactWithSuffixThousands({
	"K", "M", "B", "T",
})
local formatter = FormatNumber.NumberFormatter.with()
	:Notation(abbreviations)
	-- Round to whichever results in longest out of integer and 3 significant digits.
	-- 1.23K  12.3K  123K
	-- If you prefer rounding to certain decimal places change it to something like Precision.maxFraction(1) to round it to 1 decimal place
	:Precision(FormatNumber.Precision.integer():WithMinDigits(3))


local function Format(Int)
	return string.format("%02i", Int)
end

local function convertToHMS(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	return Format(Hours)..":"..Format(Minutes)..":"..Format(Seconds)
end

if not playerContentTemplate then
	warn("No PlayerContent template found in ScrollingFrame!")
end

local function waitForProfile(player)
	while not Manager.Profiles[player] do
		task.wait()
	end
	return Manager.Profiles[player]
end

Players.PlayerAdded:Connect(function(player)
	local profile = waitForProfile(player)
	

	-- Example: once a minute, store the current value
	task.spawn(function()
		while player.Parent do
			task.wait(120)
			local coinValue = profile.Data.Coins or 0
			local donatedValue = profile.Data.Donated or 0
			local TimeValue = profile.Data.Time or 0

			-- Use pcall to avoid errors
			local success, err = pcall(function()
				PlayerCoins:SetAsync(tostring(player.UserId), coinValue)
				PlayerDonated:SetAsync(tostring(player.UserId), donatedValue)
				PlayerTime:SetAsync(tostring(player.UserId), TimeValue)
			end)
			if not success then
				warn("Failed to update DS for", player.Name, err)
			end
		end
	end)
end)


local function RefreshCoinLeaderboard()
	
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child ~= playerContentTemplate then
			child:Destroy()
		end
	end

	
	local success, pages = pcall(function()
		return PlayerCoins:GetSortedAsync(false, 100) 
	end)
	if not success then
		warn("Failed to get coin leaderboard:", pages)
		return
	end

	local dataPage = pages:GetCurrentPage()


	for rank, entry in ipairs(dataPage) do
		if playerContentTemplate then
			local newFrame = playerContentTemplate:Clone()
			newFrame.Visible = true
			newFrame.Name = "Rank_" .. rank
			newFrame.LayoutOrder = rank
			

	
			local userId = tonumber(entry.key)
			local username = "Unknown"
			pcall(function()
				username = Players:GetNameFromUserIdAsync(userId)
			end)
			local timeval = tonumber(entry.value) or 0
			local formattednumber = formatter:Format(timeval)

			newFrame.PlayerName.Text = username
			newFrame.Place.Text = tostring(rank)
			newFrame.Amount.Text = "$"..formattednumber

			newFrame.Parent = scrollingFrame
		end
	end
end

local function RefreshDonatedLeaderboard()

	for _, child in ipairs(scrollingFrameD:GetChildren()) do
		if child:IsA("Frame") and child ~= playercontentDonated then
			child:Destroy()
		end
	end


	local success, pages = pcall(function()
		return PlayerDonated:GetSortedAsync(false, 100) 
	end)
	if not success then
		warn("Failed to get coin leaderboard:", pages)
		return
	end

	local dataPage = pages:GetCurrentPage()


	for rank, entry in ipairs(dataPage) do
		if playercontentDonated then
			local newFrame = playercontentDonated:Clone()
			newFrame.Parent = scrollingFrameD
			newFrame.Visible = true
			newFrame.Name = "Rank_" .. rank
			newFrame.LayoutOrder = rank
			



			local userId = tonumber(entry.key)
			local username = "Unknown"
			pcall(function()
				username = Players:GetNameFromUserIdAsync(userId)
			end)
			local donoVal = tonumber(entry.value) or 0
			local formattedversion = formatter:Format(donoVal)

			newFrame.PlayerName.Text = username
			newFrame.Place.Text = tostring(rank)
			newFrame.Amount.Text = "$"..formattedversion

			
		end
	end
end

local function RefreshTimeLeaderboard()

	for _, child in ipairs(scrollingFrameTime:GetChildren()) do
		if child:IsA("Frame") and child ~= playerContentTime then
			child:Destroy()
		end
	end


	local success, pages = pcall(function()
		return PlayerTime:GetSortedAsync(false, 100) 
	end)
	if not success then
		warn("Failed to get Time leaderboard:", pages)
		return
	end

	local dataPage = pages:GetCurrentPage()


	for rank, entry in ipairs(dataPage) do
		if playerContentTime then
			local newFrame = playerContentTime:Clone()
			newFrame.Parent = scrollingFrameTime
			newFrame.Visible = true
			newFrame.Name = "Rank_" .. rank
			newFrame.LayoutOrder = rank




			local userId = tonumber(entry.key)
			local username = "Unknown"
			pcall(function()
				username = Players:GetNameFromUserIdAsync(userId)
			end)
			
			local timeVal = tonumber(entry.value) or 0

			
			local formattedTime = convertToHMS(timeVal)
			

			newFrame.PlayerName.Text = username
			newFrame.Place.Text = tostring(rank)
			newFrame.Amount.Text = formattedTime


		end
	end
end



task.spawn(function()
	while true do
		RefreshCoinLeaderboard()
		RefreshDonatedLeaderboard()
		RefreshTimeLeaderboard()
		task.wait(120)
	end
end)
