--[[

Hello!!
This is an re-creation of my unreleased custom Doors gamemode, "Doors But Horror".
The premise is basically a pitch-black environment, with the only light source being curious light.
There may be a few new entities you will not recognize aswell.

SyncHelper Utility Module Source: https://github.com/thelostw3r/ScriptsForMyModes/blob/main/SyncHelper.lua
-- Chrono @Comet Development
-- Fixed By THE_LOSTW3R

--]]

if _G.ExecutedHorror then
	return
end

-- DEBUGGING
_G.ShowNodes = false
_G.EnableLights = false

local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local LIGHTING_KEYWORDS = {
	"Light_Fixtures",
	"Chandelier"
}

local LIGHTING_CONFIGURATION = {
	["FogColor"] = Color3.fromRGB(14, 13, 18),
	["FogEnd"] = 100,
	["FogStart"] = 5
}

local DEFAULT_COLOR_CORRECTION_VALUES = {
	["Brightness"] = 0.04,
	["Contrast"] = 0.05,
	["Saturation"] = 0.2,
	["Tint"] = Color3.fromRGB(255, 255, 255)
}

local NODE_PARAMETERS = {
	WaypointSpacing = 20,
	AgentRadius = 5
}

local STORE_VALUES = {}
local AMBIENCE_SOUNDS = {
    {
        9126214611,
        {
           ["Volume"] = 1,
           ["Pitch"] = 0.9
        }
    },
    {
        9043347465,
        {
           ["Volume"] = 0.3
        }
    },
    {
       8202539690,
       {
           ["Volume"] = 1,
           ["Pitch"] = 0.2
        }
    }
}

-- // Functions

local function runCoreCall(ITitle: string, IText: string, IDuration: number): ()
	local Success, Return = pcall(
		function(): boolean?
			StarterGui:SetCore("SendNotification", {
				Title = ITitle,
				Text = IText,
				Duration = IDuration
			})
		end
	)

	assert(Success, Return)
end

local function fetchCurrentRoom(Room: number, CurrentRooms: Folder): Model?
	local Room = CurrentRooms:FindFirstChild(tostring(Room))
	return Room
end

local function fetchRoomNodes(RoomModel: Model): Folder?
	local NodesFolder = nil
	if RoomModel:FindFirstChild("Nodes") then
		NodesFolder = RoomModel:FindFirstChild("Nodes")
	else
		NodesFolder = RoomModel:FindFirstChild("PathfindNodes")
	end
	return NodesFolder
end

local function getGitSoundId(GithubSoundPath: string, AssetName: string): Sound
	local Url = GithubSoundPath

	if not isfile(AssetName..".mp3") then 
		writefile(AssetName..".mp3", game:HttpGet(Url)) 
	end

	local Sound = Instance.new("Sound")
	Sound.SoundId = (getcustomasset or getsynasset)(AssetName..".mp3")
	return Sound 
end

local function displaySystemMessage(Message, Color): ()
	local TextChannels = TextChatService.TextChannels
	local RBXGeneral = TextChannels.RBXGeneral

	RBXGeneral:DisplaySystemMessage(string.format('<font color="rgb(%d, %d, %d)">%s</font>', Color.R, Color.G, Color.B, Message))
end

local function runGuidingLight(Text: table, Type: string): ()
	local RemotesFolder = ReplicatedStorage.RemotesFolder
	local DeathHint = RemotesFolder.DeathHint

  firesignal(DeathHint.OnClientEvent, Text, Type)
end

local function changeDeathCause(Cause: string, Player: Player): ()
	local Character = Player.Character
	local Humanoid = Character.Humanoid

	local GameStats = ReplicatedStorage.GameStats
	local PlayerStats = GameStats[string.format("Player_%s", Player.Name)]
	local Total = PlayerStats.Total
	local DeathCause = Total.DeathCause

	DeathCause.Value = Cause
	Humanoid:TakeDamage(100)
end

local function getNodes(Start, End): ()
	local Nodes = Instance.new("Folder")
	Nodes.Name = "PathNodes"

	local function CreateNode(Index, Position)
		local Node = Instance.new("Part", Nodes)
		Node.Name = Index
		Node.Anchored = true
		Node.CanCollide = false
		Node.CanTouch = false
		Node.CanQuery = false
		Node.Shape = "Ball"
		Node.Material = "ForceField"
		Node.Size = Vector3.new(2, 2, 2)
		Node.Color = Color3.fromRGB(0, 255, 255)
		Node.Position = Position
		Node.Transparency = (_G.ShowNodes == true and 0 or 1)
	end

	local success, error = pcall(function()
		local Path = PathfindingService:CreatePath(NODE_PARAMETERS)
		Path:ComputeAsync(Start, End)

		local Waypoints = Path:GetWaypoints()

		for Index, Waypoint in pairs(Waypoints) do
			CreateNode(Index, Waypoint.Position)
		end
	end)
	assert(success, error)

	local LastNode = CreateNode(#Nodes:GetChildren() + 1, End + Vector3.new(0, -2.5, 0)) 

	return Nodes
end

local function toggleLights(room, turnOn, ambientColor): () -- LSPlash Code!
	local targetRoom = room;

	task.spawn(function()
		if typeof(targetRoom) ~= "Instance" then
			if typeof(targetRoom) == "number" then
				targetRoom = workspace.CurrentRooms:FindFirstChild(targetRoom);
			else
				targetRoom = nil;
			end
		end

		if targetRoom == nil then
			warn("Cannot find room");
		end

		local randomSeed = Random.new(math.ceil(os.time()));
		local lightFixtures = {};

		for _, object in pairs(targetRoom:GetDescendants()) do
			if object:IsA("Model") and (object.Name == "LightStand" or object.Name == "Chandelier") then
				table.insert(lightFixtures, object);
			end
		end

		if not turnOn then
			for _, fixture in pairs(lightFixtures) do
				for _, descendant in pairs(fixture:GetDescendants()) do
					if descendant:IsA("Light") then
						descendant:SetAttribute("OriginalBrightness", descendant.Brightness);
					elseif descendant:IsA("Sound") then
						descendant:SetAttribute("OriginalVolume", descendant.Volume);
					end
				end
			end
		end

		TweenService:Create(game.Lighting, TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
			Ambient = ambientColor
		}):Play()
		targetRoom:SetAttribute("Ambient", ambientColor)

		if turnOn then
			for _, fixture in pairs(lightFixtures) do
				local randomDelay = randomSeed:NextInteger(-10, 10) / 50
				local turnOnDuration = randomSeed:NextInteger(5, 20) / 100

				task.delay((targetRoom.RoomEntrance.Position - fixture.PrimaryPart.Position).Magnitude / 150 + randomDelay, function()
					local neonPart = fixture:FindFirstChild("Neon", true)

					for _, descendant in pairs(fixture:GetDescendants()) do
						if descendant:IsA("Light") then
							TweenService:Create(descendant, TweenInfo.new(turnOnDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
								Brightness = descendant:GetAttribute("OriginalBrightness") * 1
							}):Play();
						elseif descendant:IsA("Sound") then
							TweenService:Create(descendant, TweenInfo.new(turnOnDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
								Volume = descendant:GetAttribute("OriginalVolume")
							}):Play();
						end
					end

					if neonPart then
						neonPart.Transparency = 0.9;
						neonPart.Material = Enum.Material.Neon;
						TweenService:Create(neonPart, TweenInfo.new(turnOnDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
							Transparency = 0.2
						}):Play();
					end
				end);
			end
		else
			for _, fixture in pairs(lightFixtures) do
				local randomDelay = randomSeed:NextInteger(-10, 10) / 50;
				local turnOffDuration = randomSeed:NextInteger(5, 20) / 100;

				task.delay((targetRoom.RoomEntrance.Position - fixture.PrimaryPart.Position).Magnitude / 150 + randomDelay, function()
					local chargeSound = game:GetService("ReplicatedStorage").Sounds.BulbCharge:Clone();
					chargeSound.Parent = fixture.PrimaryPart;
					chargeSound.Pitch = chargeSound.Pitch + math.random(-140, 140) / 800;
					chargeSound:Play()
					game.Debris:AddItem(chargeSound, 2);

					local neonPart = fixture:FindFirstChild("Neon", true);
					if neonPart then
						TweenService:Create(neonPart, TweenInfo.new(turnOffDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
							Transparency = 0
						}):Play()
					end

					for _, descendant in pairs(fixture:GetDescendants()) do
						if descendant:IsA("Light") then
							TweenService:Create(descendant, TweenInfo.new(turnOffDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
								Brightness = descendant:GetAttribute("OriginalBrightness") * 2
							}):Play()
						elseif descendant:IsA("Sound") then
							TweenService:Create(descendant, TweenInfo.new(turnOffDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
								Volume = 0
							}):Play()
						end
					end

					task.wait(turnOffDuration + 0.01);

					if neonPart then
						neonPart.Transparency = 0
						neonPart.Material = Enum.Material.Glass
					end

					for _, descendant in pairs(fixture:GetDescendants()) do
						if descendant:IsA("Light") then
							TweenService:Create(descendant, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
								Brightness = 0
							}):Play()
						end
					end

					chargeSound:Stop()
				end)
			end
		end
	end)
end

local function removeRoomLights(Room: Model): ()
	if not Room:IsA("Model") then
		return --// This should never happen, but it's worth checking.
	end
	if _G.EnableLights == true then
		return
	end

	task.wait(1) -- Allow streaming in

	local LightingAssets = {}

	for _, Asset in Room:GetDescendants() do
		if table.find(LIGHTING_KEYWORDS, Asset.Name) then
			table.insert(LightingAssets, Asset)
		end
	end

	for _, Asset in pairs(LightingAssets) do
		Asset:Destroy()
	end

	Room:SetAttribute("Ambient", Color3.fromRGB(0, 0, 0))
end

local function makeNodes(Room: Model): ()
	local Nodes = getNodes(Room:WaitForChild("RoomEntrance").Position, Room:WaitForChild("RoomExit").Position)
	Nodes.Parent = Room
	return Nodes
end

local function convertHelpfulLight(Light: Part, Music: Sound): ()
	local HelpParticle = Light.HelpParticle
	HelpParticle.Color = ColorSequence.new(Color3.fromRGB(255, 238, 0))
	HelpParticle.Rate = 10

	Music.Parent = Light
	Music.Looped = true
	Music.RollOffMaxDistance = 100
	Music.RollOffMinDistance = 0
	Music.RollOffMode = Enum.RollOffMode.Linear
	Music.Volume = 0.5
	Music:Play()

	for _, PointLight: PointLight in Light:GetChildren() do
		if not PointLight:IsA("PointLight") then
			continue
		end

		PointLight.Brightness = 1
		PointLight.Color = Color3.fromRGB(255, 238, 55)

		local Change = PointLight:GetPropertyChangedSignal("Brightness"):Connect(
		function(): ()
			if PointLight.Brightness ~= 1 then
				PointLight.Brightness = 1
			end
		end
		)

		task.delay(
			5,
			function(): ()
				Change:Disconnect()
			end
		)

		if not PointLight.Shadows then
			PointLight.Shadows = true
		end
	end
end

--// Functionality (wink wink get it!!)

local PlaceId = game.PlaceId
local DoorsPlaceId = 6839171747

if PlaceId ~= DoorsPlaceId then
	return runCoreCall(
		"Error",
		"Make sure you are running this script in the Hotel!",
		5
	)
end

local SyncHelper: ModuleScript = loadstring(game:HttpGet("https://raw.githubusercontent.com/thelostw3r/ScriptsForMyModes/refs/heads/main/SyncHelper.lua"))()

local GameData: Folder = ReplicatedStorage:WaitForChild("GameData")
local LatestRoom: NumberValue = GameData:WaitForChild("LatestRoom")
local CurrentRooms: Folder = workspace:WaitForChild("CurrentRooms")
local Player: Player = Players.LocalPlayer
local Camera: Camera = workspace.CurrentCamera

local ENTITY_SPAWN_AFTER = SyncHelper:generateRandom(5, 9, 1)

if LatestRoom.Value ~= 0 then
	return runCoreCall(
		"Error",
		"The game has already started!",
		5
	)
end

_G.ExecutedHorror = true

-- Await Game Start

LatestRoom:GetPropertyChangedSignal("Value"):Wait()

-- Game Start

do
	local Room1 = fetchCurrentRoom(1, CurrentRooms)

	local Success, Return = pcall(
		function(): ()
			local StartSound = getGitSoundId("https://github.com/thelostw3r/ScriptsForMyModes/blob/main/HorrorBeginChime.mp3?raw=true", "HorrorBeginChime")
			StartSound.Parent = SoundService

			task.delay(
				.5,
				function(): ()
					StartSound:Play()
					StartSound.Ended:Wait()
					StartSound:Destroy()
				end
			)
		end
	)

	assert(Success, Return)

	SyncHelper:deltaWait(.5)
	toggleLights(Room1, _G.EnabledLights, Color3.fromRGB(0,0,0))
	removeRoomLights(fetchCurrentRoom(2, CurrentRooms)) -- Remove the lights from the second room, because the event doesnt catch that one :(

	Lighting.FogColor = LIGHTING_CONFIGURATION.FogColor
	Lighting.FogEnd = LIGHTING_CONFIGURATION.FogEnd
	Lighting.FogStart = LIGHTING_CONFIGURATION.FogStart

	displaySystemMessage("Can you survive the darkness?", Color3.fromRGB(199, 125, 125))
end

-- Entities

local EntityStorage = Instance.new("Folder", ReplicatedStorage); EntityStorage.Name = "HorrorModeEntities"
local WhisperEntityBase = game:GetObjects("rbxassetid://90061066167445")[1]; WhisperEntityBase.Parent = EntityStorage
local SpecterEntityBase = game:GetObjects("rbxassetid://125103851470017")[1]; SpecterEntityBase.Parent = EntityStorage
local WraithEntityBase = game:GetObjects("rbxassetid://96925756949051")[1]; WraithEntityBase.Parent = EntityStorage

local CuriousHumm = getGitSoundId("https://github.com/thelostw3r/ScriptsForMyModes/blob/main/CuriousHumm.mp3?raw=true", "CuriousHumm")
CuriousHumm.Parent = SoundService

-- Hotfixes

local WRAITH_SPAWNED = false
pcall(function(): ()
	SpecterEntityBase.Spawn.Playing = false

	WraithEntityBase.WraithNew.PlaySound.Playing = false
	WraithEntityBase.WraithNew.PlaySound2.Playing = false
end)

-- Hotfixes End

local function runSoundAsAmbience(SoundId: string, Properties): ()
     local RandomX = SyncHelper:generateRandom(-300, 300, LatestRoom.Value)
     local RandomZ = SyncHelper:generateRandom(-300, 300, LatestRoom.Value)
     
     local Attachment = Instance.new("Attachment", Camera)
     Attachment.Position += Vector3.new(RandomX, 1, RandomZ)
     
     local Sound = Instance.new("Sound")
     
     for PropertyIndex, PropertyValue in pairs(Properties) do
          pcall(function()
               Sound[PropertyIndex] = PropertyValue
          end)
     end
     
     Sound.Parent = Attachment
     Sound.SoundId = SoundId
     Sound.RollOffMaxDistance = math.huge
     Sound.RollOffMinDistance = math.huge
     Sound:Play()
     
     Sound.Ended:Wait()
     
     Attachment:Destroy()
end

local function whisper(SpawnDistance: number, ChaseDuration: number, GracePeriod: number): ()
	local PlayerCharacter = Player.Character
	local CharacterRoot = PlayerCharacter.HumanoidRootPart
	local CharacterCFrame = PlayerCharacter:GetPivot()
	local CharacterBack = CharacterCFrame.LookVector * -1
	local SpawnPosition = CharacterCFrame.Position + CharacterBack * SpawnDistance

	local WhisperEntity = WhisperEntityBase:Clone()
	local WhisperRig = WhisperEntity.Rig
	local WhisperBreathing = WhisperRig.Breathing
	local WhisperParticles = WhisperRig.Attachment

	WhisperEntity.Parent = workspace
	WhisperEntity:PivotTo(CFrame.new(SpawnPosition))

	WhisperEntity.Name = "WhisperNew"
	WhisperRig.CanCollide = false
	WhisperRig.CanTouch = false
	WhisperRig.CanQuery = false
	WhisperRig.Anchored = false

	local Movement = Instance.new("BodyPosition", WhisperRig)
	Movement.D = 1500
	Movement.P = 3000
	Movement.MaxForce = Vector3.new(1000, 250000, 1000)

	WhisperBreathing:Play()
	WhisperBreathing.Volume = 0
	TweenService:Create(WhisperBreathing, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Volume = 1
	}):Play()

	local TargetDistance = (CharacterRoot.Position - WhisperRig.Position).Magnitude

	local MovementUpdate = RunService.Heartbeat:Connect(
		function(): ()
			TargetDistance = (CharacterRoot.Position - WhisperRig.Position).Magnitude
			Movement.Position = CharacterRoot.Position
		end
	)

	local DeathCheck = task.spawn(
		function(): ()
			SyncHelper:deltaWait(GracePeriod)

			while true do
				if TargetDistance <= 11 then
					runGuidingLight(
						{
							"Oh.. Hello.",
							"I thought I wouldn't see you here.", 
							"The Guiding Celestial is not here with us at the moment.", 
							"They were.. busy fixing some important deals with the lighting.",
							"Let's just get to the point.",
							"The thing is pretty quiet, so we can call it Whisper.",
							"Now normally, it wouldn't be an issue--But as for now.. you just have to avoid them.",
							"Stay as far away from them!"
						},
						"Yellow"
					)
					changeDeathCause("Whisper", Player)
					break
				end
				task.wait(.1)
			end
		end
	)

	SyncHelper:deltaWait(ChaseDuration)

	task.cancel(DeathCheck)
	for _, Effect in WhisperParticles:GetChildren() do
		Effect.Enabled = false
	end

	TweenService:Create(WhisperBreathing, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Volume = 0
	}):Play()

	MovementUpdate:Disconnect()
	Movement:Destroy()
	Debris:AddItem(WhisperEntity, 5)
end

local function wraith(Anger: number)
     if WRAITH_SPAWNED then
        return
     end
	local Times = 0
	local function SpawnWraith(Times)
    	WRAITH_SPAWNED = true
		if Times > 3 then
		    WRAITH_SPAWNED = false
			return
		end
		Times += 1

        local AngerSpeed = math.clamp((Anger * 2) / 3, 0, 50)
		local WraithEntity = WraithEntityBase:Clone()
		WraithEntity.Parent = Workspace

		if Times == 1 then
			WraithEntity.Spawn.Volume += 5
			WraithEntity.Spawn:Play();
		end

		WraithEntity.SpawnAmbience.Volume += 7
		WraithEntity.SpawnAmbience:Play()

		local SpawnEffect = Instance.new("ColorCorrectionEffect", Lighting); SpawnEffect.Saturation = 10; SpawnEffect.Brightness = -10
		TweenService:Create(SpawnEffect, TweenInfo.new(0.345, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = 0, Saturation = 3, TintColor = Color3.fromRGB(128,128,128)}):Play()

		SyncHelper:deltaWait(4)
		
		for _,v in pairs(WraithEntity.WraithNew:GetChildren()) do
		     if v:IsA("Sound") then
		         local PitchProperty = v.Pitch
	         	v.Pitch = 0
	             if table.find(STORE_VALUES, v) then
	                  v.TimePosition = STORE_VALUES[v]
	             else
	                  v.TimePosition = 0
	             end
	             v:Play()
	             TweenService:Create(v, TweenInfo.new(1), {Pitch = PitchProperty}):Play()
	         end
		end
	
		local LastRoom = fetchCurrentRoom(LatestRoom.Value + 1, CurrentRooms)
		assert(LastRoom, "Last room is nil! This aint good..")
		local RoomExit = LastRoom.RoomExit
		assert(RoomExit, "RoomExit is nil! This is not awesome sauce.")
		local SpawnPosition = RoomExit.Position + RoomExit.CFrame.LookVector * 15
		WraithEntity:MoveTo(SpawnPosition)

		local function DragEntity(model, cframe, speed)
			local reached = false

			local connection; connection = RunService.Stepped:Connect(function(_, step)

				local pivot = model:GetPivot()
				local difference = (cframe.Position - pivot.Position)
				local unit = difference.Unit
				local magnitude = difference.Magnitude

				if magnitude > 0.1 then
					model:PivotTo(pivot + unit * math.min(step * speed, magnitude))
				else
					connection:Disconnect()
					reached = true
				end
			end)

			repeat RunService.Stepped:Wait() until reached
		end

		local DeathCheck = task.spawn(
			function(): ()
				while true do
					local Origin = WraithEntity:GetPivot().Position
					local Direction = -(Origin - Player.Character.PrimaryPart.Position).Unit * 50

					local ray = Ray.new(Origin, Direction)
					local Hit, Position = workspace:FindPartOnRay(ray, WraithEntity)

					if Hit then
						if Hit:IsDescendantOf(Player.Character) then
							if not Player.Character:GetAttribute("Hiding") then
								runGuidingLight(
									{
										"Hello.",
										"I thought I wouldn't see you here, again.",
										"Let's just get to the point now.",
										"This one is pretty intresting, you can call it Wraith.",
										"As if you couldn't figure out, or if you're lucky enough.. you might've seen them twice right?",
										"They tend to persist and come back to check after a--couple of rooms.",
										"Just be weary, you'll be fine."
									},
									"Yellow"
								)
								changeDeathCause("Wraith", Player)
								break
							end
						end
					end

					task.wait(.1)
				end
			end
		)

		for RoomIndex = 100, 0, -1 do
			local Room = fetchCurrentRoom(RoomIndex, CurrentRooms)

			if Room then
				if Room:FindFirstChild("PathNodes") then
					local Nodes = Room:FindFirstChild("PathNodes")

					for NodeIndex = #Nodes:GetChildren(), 0, -1 do
						local Node = Nodes:FindFirstChild(NodeIndex)

						if Node then
							DragEntity(WraithEntity, Node.CFrame * CFrame.new(0, 4, 0), 100 + AngerSpeed)
						end
					end
				end

				DragEntity(WraithEntity, Room.RoomEntrance.CFrame, 100 + AngerSpeed)
			end
		end

		WraithEntity.WraithNew.Anchored = false
		WraithEntity.WraithNew.CanCollide = false
		
		task.cancel(DeathCheck)

		TweenService:Create(SpawnEffect, TweenInfo.new(1), {Saturation = 0, TintColor = Color3.fromRGB(255, 255, 255)}):Play()
		Debris:AddItem(SpawnEffect, 2)

		for _,v in pairs(WraithEntity:GetDescendants()) do
			if v:IsA("Sound") then
			    STORE_VALUES[v] = v.TimePosition
				TweenService:Create(v, TweenInfo.new(2), {Pitch = 0, Volume = 10}):Play()
			end
		end

		Debris:AddItem(WraithEntity, 3)

		for NextSpawnIndex = 1, math.floor(SyncHelper:generateRandom(2, 3, LatestRoom.Value)) do
			LatestRoom:GetPropertyChangedSignal("Value"):Wait()
		end

		SpawnWraith(Times)
	end

	SpawnWraith(0)
end

local function wailingSpecter(Duration: number): ()
	local SpecterEntity = SpecterEntityBase:Clone()
	local SpawnSound = SpecterEntity.Spawn; SpawnSound.Volume = 3
	local ColorCorrection = Lighting.MainColorCorrection

	local function getRandomPlaybackSpeed(): number
		return math.random() * (1.8 - 0.3) + 0.3
	end

	local function variatePlaybackSpeed(Speed: number): ()
		local PlaybackTween = TweenService:Create(
			SpawnSound,
			TweenInfo.new(0.05, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{
				PlaybackSpeed = Speed
			}
		)

		PlaybackTween:Play()
	end

	local CurrentRoom = fetchCurrentRoom(LatestRoom.Value, CurrentRooms)
	local RoomEntrance = CurrentRoom.RoomEntrance
	assert(RoomEntrance, "RoomEntrance is nil! This is not awesome sauce.")

	LatestRoom:GetPropertyChangedSignal("Value"):Wait()

	local ColorCorrectionVariate = task.spawn(
		function(): ()
			while true do
				local newBrightness = math.random() * (0.1 - 0.01) + 0.01
				local newContrast = math.random() * (0.1 - 0.01) + 0.01
				local newSaturation = math.random() * (0.3 - 0.1) + 0.1
				local newTint = Color3.fromRGB(math.random(200, 255), math.random(200, 255), math.random(200, 255))

				TweenService:Create(ColorCorrection, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Brightness = newBrightness,
					Contrast = newContrast,
					Saturation = newSaturation,
					TintColor = newTint
				}):Play()

				task.wait(0.05)
			end
		end
	)

	local PlaybackSpeedVariate = task.spawn(
		function(): ()
			while true do
				variatePlaybackSpeed(getRandomPlaybackSpeed())
				task.wait(.05)
			end
		end
	)

	local SpecterSpawnPosition = RoomEntrance.Position + RoomEntrance.CFrame.LookVector * 10
	SpecterEntity.Parent = workspace
	SpecterEntity:PivotTo(CFrame.new(SpecterSpawnPosition))
	SpawnSound:Play()

	SyncHelper:deltaWait(Duration)
	task.cancel(PlaybackSpeedVariate)
	task.cancel(ColorCorrectionVariate)

	task.spawn(
		function(): ()
			SyncHelper:deltaWait(1)
			ColorCorrection.Brightness = DEFAULT_COLOR_CORRECTION_VALUES.Brightness
			ColorCorrection.Contrast = DEFAULT_COLOR_CORRECTION_VALUES.Contrast
			ColorCorrection.Saturation = DEFAULT_COLOR_CORRECTION_VALUES.Saturation
			ColorCorrection.TintColor = DEFAULT_COLOR_CORRECTION_VALUES.Tint
		end
	)

	SpecterEntity:Destroy()
end

local function spawnEntity(): ()
	if LatestRoom.Value < ENTITY_SPAWN_AFTER then
		return
	end
	local EntityChance = math.floor(SyncHelper:generateRandom(1, 50, LatestRoom.Value))

	if EntityChance > 15 then
		return
	end

	local Entity = SyncHelper:generateFullRandom(1, 2, LatestRoom.Value)
	if Entity == 1 then
		if Workspace:FindFirstChild("Whisper") then
			return
		end
		if Workspace:FindFirstChild("Wraith") then
			return
		end

		task.spawn(
			function(): ()
				local DelayTime = SyncHelper:generateRandom(0, 15, LatestRoom.Value)
				SyncHelper:deltaWait(DelayTime)

				whisper(
					SyncHelper:generateRandom(20, 45, LatestRoom.Value),
					SyncHelper:generateRandom(10, 20, LatestRoom.Value),
					SyncHelper:generateRandom(2, 4, LatestRoom.Value)
				)
			end
		)
	elseif Entity == 2 then
		-- wraith goes here
		if Workspace:FindFirstChild("Wraith") then
			return
		end

		task.spawn(
			function(): ()
				LatestRoom:GetPropertyChangedSignal("Value"):Wait() -- wait for the next room
				SyncHelper:deltaWait(.25)

				wraith(LatestRoom.Value)
			end
		)
	end
end

-- Game Hooks

CurrentRooms.ChildAdded:Connect(removeRoomLights)
CurrentRooms.ChildAdded:Connect(spawnEntity)
CurrentRooms.ChildAdded:Connect(makeNodes)

CurrentRooms.DescendantAdded:Connect(
	function(Asset: Instance): ()
		if Asset.Name == "HelpfulLight" then
			convertHelpfulLight(Asset, CuriousHumm:Clone())
		end
	end
)

-- Loop Hooks

task.spawn(
	function(): ()
		while true do
		  	SyncHelper:deltaWait(SyncHelper:generateRandom(20, 90, LatestRoom.Value))
		
			  local AmbienceSound = AMBIENCE_SOUNDS[math.random(1,#AMBIENCE_SOUNDS)]
			  runSoundAsAmbience(AmbienceSound[1], AmbienceSound[2])
		end
	end
)

task.spawn(
	function(): ()
		while true do
			SyncHelper:deltaWait(SyncHelper:generateRandom(30, 60, LatestRoom.Value))
			local SpecterSpawnChance = SyncHelper:generateFullRandom(1, 75, LatestRoom.Value)

			if SpecterSpawnChance ~= 1 then
				return
			end

			wailingSpecter(SyncHelper:generateRandom(10, 20, LatestRoom.Value))
		end
	end
)
