local TPS = game:GetService("TeleportService")
local checkValid = require(game.ReplicatedStorage.CheckValidPlayer)
local getData = require(game.ReplicatedStorage.GetData)

local TouchParts = {}
local stuff = workspace:GetDescendants()
for i = 1, #stuff do
	if stuff[i].Name == "QueueTouch" then
		table.insert(TouchParts,stuff[i])
	end
end

local queueMap = {}
local queueMapCounters = {}
local queueIsTeleporting = {}

for i = 1, #TouchParts do
	local nightName = TouchParts[i].Parent.NightName.Value
	queueMap[nightName] = {"EMPTY","EMPTY","EMPTY","EMPTY"}
	queueMapCounters[nightName] = 0
	queueIsTeleporting[nightName] = false
end

function getSeatIndex(nightName)
	local queue = queueMap[nightName]
	for i = 1, #queue do
		if queue[i] == "EMPTY" then
			return i
		end
	end
	return nil
end

function getPlayerIndex(nightName,player)
	local queue = queueMap[nightName]
	for i = 1, #queue do
		if queue[i] == player then
			return i
		end
	end
	return nil
end

script.StartTimer.Event:Connect(function(timerVal,nightName)
	timerVal.Value = 25
	repeat
		wait(1)
		if timerVal.Value ~= 999 then
			timerVal.Value = timerVal.Value - 1
		end
	until timerVal.Value <= 0 or timerVal.Value == 999
	if timerVal.Value <= 0 and queueIsTeleporting[nightName] == false then
		queueIsTeleporting[nightName] = true
		for i = 1, #queueMap[nightName] do
			local player = queueMap[nightName][i]
			if type(player) ~= "string" and player ~= nil then
				local playerData = getData.getDataFromPlayer(player)
				if playerData then
					playerData.Queue.Value = "TP"
				end
				game.ReplicatedStorage.Remotes.ChangeUI:FireClient(player,"Hide")
				game.ReplicatedStorage.Remotes.Fade:FireClient(player,Color3.fromRGB(18, 0, 36),1,.5,1)
				game.ReplicatedStorage.Remotes.PlaySound:FireClient(player,"FadeOut","MainThemeLoop")
			end
		end
		wait(1.25)
		local playersToTP = {}
		for i = 1, #queueMap[nightName] do
			local player = queueMap[nightName][i]
			if type(player) ~= "string" and player ~= nil and checkValid.checkPlayer(player) then
				table.insert(playersToTP,player)
				player.Character.HumanoidRootPart.CFrame = workspace.TPSPOT.CFrame
			end
		end
		local difficultyData = nil
		if nightName == "Custom" and game.ReplicatedStorage.IsVip.Value == true then
			difficultyData = {}
			difficultyData["RedBelly"] = workspace.CustomSettings.RedBellySetting.DifficultySetting.Value
			difficultyData["Kitty"] = workspace.CustomSettings.KittySetting.DifficultySetting.Value
			difficultyData["Honey"] = workspace.CustomSettings.HoneySetting.DifficultySetting.Value
			difficultyData["Starry"] = workspace.CustomSettings.StarrySetting.DifficultySetting.Value
			difficultyData["Wailey"] = workspace.CustomSettings.WaileySetting.DifficultySetting.Value
			difficultyData["Froggy"] = workspace.CustomSettings.FroggySetting.DifficultySetting.Value
		end
		local QueueData = {
			NightName = nightName,
			Difficulties = difficultyData
		}
		script.TeleportPlayers:Fire(playersToTP,QueueData)
		queueIsTeleporting[nightName] = false
		queueMap[nightName] = {"EMPTY","EMPTY","EMPTY","EMPTY"}
		updateCounter(nightName)
	end
end)

function updateCounter(nightName)
	local maxCount = 4
	local count = 0
	local queue = queueMap[nightName]
	for i = 1, #queue do
		if queue[i] ~= "EMPTY" then
			count = count + 1
		end
	end
	workspace[nightName].BillBoardPart.BillboardGui.Frame.Counter.Text = count.."/"..maxCount
	if count == 0 then
		workspace[nightName].TimerVal.Value = 999
	end
	if count ~= 0 and workspace[nightName].TimerVal.Value == 999 then
		script.StartTimer:Fire(workspace[nightName].TimerVal,nightName)
	end
end

function removePlayer(player)
	local playerData = getData.getDataFromPlayer(player)
	if playerData and playerData.Queue.Value ~= "" and playerData.Queue.Value ~= nil and playerData.Queue.Value ~= "TP" then
		local queueName = playerData.Queue.Value
		if queueIsTeleporting[queueName] == false then
			local nightQueue = queueMap[queueName]
			playerData.Queue.Value = ""
			local index = getPlayerIndex(queueName,player)
			if index then
				nightQueue[index] = "EMPTY"
			end
			if checkValid.checkPlayer(player) then
				player.Character.HumanoidRootPart.CFrame = workspace[queueName].ExitSpot.CFrame
				game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Stop","QueuePoseLie")
				game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Stop","QueuePoseSit")
				game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Stop","QueuePoseUpSideDown")
				game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Stop","QueuePoseClap")
				
				if player.Character:FindFirstChild("HB") then
					player.Character.HB.CanTouch = true
				end
				if index == 2 and nightQueue[3] ~= "EMPTY" then
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(nightQueue[3],"Stop","QueuePoseClap")
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(nightQueue[3],"Play","QueuePoseSit")
				end
				if index == 3 and nightQueue[2] ~= "EMPTY" then
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(nightQueue[2],"Stop","QueuePoseClap")
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(nightQueue[2],"Play","QueuePoseSit")
				end
				updateCounter(queueName)
				wait(.1)
				if checkValid.checkPlayer(player) then
					local weld = player.Character.HumanoidRootPart:FindFirstChild("BedWeld")
					if weld then
						weld.Part1:Destroy()
						weld:Destroy()
					end
				end
			end
			updateCounter(queueName)
		end
	end
end

game.ReplicatedStorage.Remotes.LeaveQueue.OnServerEvent:Connect(function(player)
	removePlayer(player)
end)

game.Players.PlayerRemoving:Connect(function(player)
	removePlayer(player)
end)

script.RemovePlayer.Event:Connect(function(player)
	removePlayer(player)
end)

script.TeleportPlayers.Event:Connect(function(playersToTP,QueueData)
	for i = 1, #playersToTP do
		if playersToTP[i] == nil then
			table.remove(playersToTP,i)
		end
	end
	if #playersToTP < 1 then
		return
	end
	local code = nil
	local success, errorMessage = pcall(function()
		code = TPS:ReserveServer(13656644128)
	end)
	if not success then
		print("RESERVE ERROR "..errorMessage)
	end
	if code then
		--[[for i = 1, #playersToTP do
			local teleportData = {
				Night = QueueData["NightName"],
				Difficulties = QueueData["Difficulties"]
			}
			local success, errorMessage = pcall(function()
				TPS:TeleportToPrivateServer(13656644128,code,{playersToTP[i]},nil,teleportData)
			end)
		end]]
		local teleportData = {
			Night = QueueData["NightName"],
			Difficulties = QueueData["Difficulties"]
		}
		local success, errorMessage = pcall(function()
			TPS:TeleportToPrivateServer(13656644128,code,playersToTP,nil,teleportData)
		end)
	end
	wait(10)
	local playersLeft = {}
	for i = 1, #playersToTP do
		if playersToTP[i] and game.Players:FindFirstChild(playersToTP[i].Name) then
			table.insert(playersLeft,playersToTP[i])
		end
	end
	wait(10)
	for i = 1, #playersLeft do
		if playersLeft[i] and game.Players:FindFirstChild(playersLeft[i].Name) then
			game.ReplicatedStorage.Remotes.PlayAnim:FireClient(playersLeft[i],"Stop","QueuePoseLie")
			game.ReplicatedStorage.Remotes.PlayAnim:FireClient(playersLeft[i],"Stop","QueuePoseSit")
			game.ReplicatedStorage.Remotes.PlayAnim:FireClient(playersLeft[i],"Stop","QueuePoseUpSideDown")
			game.ReplicatedStorage.Remotes.PlayAnim:FireClient(playersLeft[i],"Stop","QueuePoseClap")
			if playersLeft[i] and playersLeft[i].Character and  playersLeft[i].Character:FindFirstChild("HumanoidRootPart") then
				playersLeft[i].Character.HumanoidRootPart.CFrame = workspace.SpawnSpot.CFrame
			end
			game.ReplicatedStorage.Remotes.PlaySound:FireClient(playersLeft[i],"FadeIn","MainThemeLoop")
			wait(.1)
			if checkValid.checkPlayer(playersLeft[i]) then
				local weld = playersLeft[i].Character.HumanoidRootPart:FindFirstChild("BedWeld")
				if weld then
					weld.Part1:Destroy()
					weld:Destroy()
				end
				playersLeft[i].Character.HB.CanTouch = true
			end
			if getData.getDataFromPlayer(playersLeft[i]) then
				local playerData = getData.getDataFromPlayer(playersLeft[i])
				playerData.Queue.Value = ""
			end
		end
	end
end)

script.AddPlayer.Event:Connect(function(player,touchPart)
	local nightName = touchPart.Parent.NightName.Value
	if getSeatIndex(nightName) ~= nil and checkValid.checkPlayer(player) then
		local seatIndex = getSeatIndex(nightName)
		local nightNum = touchPart.Parent.NightNum.Value
		local playerData = getData.getDataFromPlayer(player)
		if playerData and playerData.NightUnlocked.Value >= nightNum and (playerData.Queue.Value == "" or playerData.Queue.Value == nil) then

			queueMap[nightName][seatIndex] = player
			playerData.Queue.Value = nightName

			updateCounter(nightName)

			local weld = Instance.new("Weld")
			weld.Part0 = player.Character.HumanoidRootPart
			local partclone = touchPart.Parent["AnimSpot"..seatIndex]:Clone()
			partclone.Parent = workspace
			weld.Part1 = partclone
			weld.Parent = player.Character.HumanoidRootPart
			weld.C0 = CFrame.new(0,0,0)
			weld.C1 = CFrame.new(0,0,0)
			weld.Name = "BedWeld"

			if seatIndex == 1 then
				game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Play","QueuePoseLie")
			end
			if seatIndex == 2 then
				if queueMap[nightName][3] == "EMPTY" then
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Play","QueuePoseSit")
				else
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Play","QueuePoseClap")
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(queueMap[nightName][3],"Stop","QueuePoseSit")
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(queueMap[nightName][3],"Play","QueuePoseClap")
				end
			end
			if seatIndex == 3 then
				if queueMap[nightName][2] == "EMPTY" then
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Play","QueuePoseSit")
				else
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Play","QueuePoseClap")
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(queueMap[nightName][2],"Stop","QueuePoseSit")
					game.ReplicatedStorage.Remotes.PlayAnim:FireClient(queueMap[nightName][2],"Play","QueuePoseClap")
				end
			end
			if seatIndex == 4 then
				game.ReplicatedStorage.Remotes.PlayAnim:FireClient(player,"Play","QueuePoseUpSideDown")
			end

			if player.Character:FindFirstChild("HB") then
				player.Character.HB.CanTouch = false
			end

			local seatNumStart = nil
			local players = game.Players:GetChildren()
			if #players == 1 then
				seatNumStart = 2
			end
			if #players == 2 then
				seatNumStart = 3
			end
			if #players == 3 then
				seatNumStart = 4
			end
			--seatNumStart = nil

			if getSeatIndex(nightName) == seatNumStart then
				queueMapCounters[nightName] = queueMapCounters[nightName] + 1
				local myQueueCount = queueMapCounters[nightName]
				wait(2.25)
				if getSeatIndex(nightName) == seatNumStart and myQueueCount == queueMapCounters[nightName] and queueIsTeleporting[nightName] == false then
					queueIsTeleporting[nightName] = true
					for i = 1, #queueMap[nightName] do
						local player = queueMap[nightName][i]
						if type(player) ~= "string" and player ~= nil then
							local playerData = getData.getDataFromPlayer(player)
							if playerData then
								playerData.Queue.Value = "TP"
							end
							game.ReplicatedStorage.Remotes.ChangeUI:FireClient(player,"Hide")
							game.ReplicatedStorage.Remotes.Fade:FireClient(player,Color3.fromRGB(18, 0, 36),1,.5,1)
							game.ReplicatedStorage.Remotes.PlaySound:FireClient(player,"FadeOut","MainThemeLoop")
						end
					end
					wait(1.25)
					local playersToTP = {}
					for i = 1, #queueMap[nightName] do
						local player = queueMap[nightName][i]
						if type(player) ~= "string" and player ~= nil and checkValid.checkPlayer(player) then
							table.insert(playersToTP,player)
							player.Character.HumanoidRootPart.CFrame = workspace.TPSPOT.CFrame
						end
					end
					local difficultyData = nil
					if nightName == "Custom" and game.ReplicatedStorage.IsVip.Value == true then
						difficultyData = {}
						difficultyData["RedBelly"] = workspace.CustomSettings.RedBellySetting.DifficultySetting.Value
						difficultyData["Kitty"] = workspace.CustomSettings.KittySetting.DifficultySetting.Value
						difficultyData["Honey"] = workspace.CustomSettings.HoneySetting.DifficultySetting.Value
						difficultyData["Starry"] = workspace.CustomSettings.StarrySetting.DifficultySetting.Value
						difficultyData["Wailey"] = workspace.CustomSettings.WaileySetting.DifficultySetting.Value
						difficultyData["Froggy"] = workspace.CustomSettings.FroggySetting.DifficultySetting.Value
					end
					local QueueData = {
						NightName = nightName,
						Difficulties = difficultyData
					}
					script.TeleportPlayers:Fire(playersToTP,QueueData)
					queueIsTeleporting[nightName] = false
					queueMap[nightName] = {"EMPTY","EMPTY","EMPTY","EMPTY"}
					updateCounter(nightName)
				end
			end
		end
	end
end)

for i = 1, #TouchParts do
	TouchParts[i].TouchedEvent.Event:Connect(function(player)
		script.AddPlayer:Fire(player,TouchParts[i])
	end)
end

while true do
	wait(1)
	for i = 1, #TouchParts do
		local touchingParts = TouchParts[i]:GetTouchingParts()
		for j = 1, #touchingParts do
			local player = game.Players:GetPlayerFromCharacter(touchingParts[j].Parent)
			if player then
				script.AddPlayer:Fire(player,TouchParts[i])
			end
		end
	end
end
