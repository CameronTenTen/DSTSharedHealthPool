Assets = {
	Asset("ATLAS", "images/sharedHealth.xml"),
	Asset("IMAGE", "images/sharedHealth.tex"),
	Asset("ATLAS", "images/iceBoulderv4.xml"),
	Asset("IMAGE", "images/iceBoulderv4.tex"),
	Asset("ATLAS", "images/teleportv2.xml"),
	Asset("IMAGE", "images/teleportv2.tex"),
	-- Asset("ATLAS", "images/sharedHealthPoolv3.xml"),
	-- Asset("IMAGE", "images/sharedHealthPoolv3.tex"),
}
--local debugtools = require("debugtools")

-- local AllPlayers = GLOBAL.AllPlayers
-- local TheNet = GLOBAL.TheNet
-- local TheWorld = GLOBAL.TheWorld

-- local TEMPLATES = require "widgets/redux/templates"
local TEMPLATES = require "widgets/templates"

local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"

local UserCommands = require("usercommands")
-- local iconAtlas = "images/sharedHealthPoolv3.xml"
-- local freezeIcon = "images/iceBoulder.tex"
-- local Assets = Asset("ATLAS", iconAtlas)
-- local Assets =
-- {
-- 	Asset("ANIM", "anim/bindingring_build.zip"), -- a standard asset
--     Asset("ATLAS", "images/inventoryimages/bindingring.xml"),    -- a custom asset, found in the mod folder
-- }
--Configuration TODO
--Freeze duration (0 disables it)
local freezeTime = GetModConfigData("FREEZE_LENGTH")
--Freeze range (0 disables it)
local freezeRange = 30
--Freeze cooldown
local freezeCooldown = 30
--Health penalty (make 0 possible)
local teleportHealthPenalty = 20
--Teleport debounce (0 is instant)
--Teleport cooldown
--Per player/global cooldowns

--Feature TODO
--Resurrection/Meat effigy behaviour
--Teams
--Handling of caves
--Different teleport options, e.g. teleport to effigy? teleport to other structure? teleport yourself to someone?
--Key bindings
--change to menu version of the icon
--Button positioning
--Button label/icon


-- Array of player original max health values
local maxHealthOrig = {}
-- Current server health values
local currentMaxHealth = 0
local currentHealth = 0

--plalyer 3 joining gets 1 health, but reset other players to full
--

-- Shared Stats mod (2187805379) used as a basis for the delta code
local function DoDelta(healthChangeAmount, healthChangeAfflicter, skipPlayer)
	currentHealth = currentHealth + healthChangeAmount
	for i, v in pairs(GLOBAL.AllPlayers) do
		print ("player", v)
		print ("inst", skipPlayer)
		-- GLOBAL.dumptable(v)
		-- Update all the players except the one that already took the damage
		if (skipPlayer == nil or v.GUID ~= skipPlayer.GUID) then
		-- 	-- amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb
		-- 	-- I think there is invincible frames when a player takes damage?
		-- 	-- I think absorb is armour?
			print ("do delta")
			v.components.health:DoDelta(healthChangeAmount, nil, "update", true, healthChangeAfflicter, true)
		-- 	-- v.components.health:SetCurrentHealth(currentHealth)
		-- 	-- v.components.health:DoDelta(0, nil, "update") -- fixes issue when caves are disabled.
		end
	end
end

local OnHealthDelta = function(inst, data)
	GLOBAL.dumptable(data)
	print ("on health delta", inst)
	--     K: 	amount	 V: 	20
	-- [00:01:57]: 	K: 	cause	 V: 	meat_dried
	-- [00:01:57]: 	K: 	newpercent	 V: 	0.75
	-- [00:01:57]: 	K: 	oldpercent	 V: 	0.71681415929204
	if data.cause ~= "update" then
		DoDelta(data.amount, data.afflicter, inst)
	end
end

local function InitPlayer(inst, player)
	-- Want to update the max health and health of everyone
	print("init player", inst, player, player.GUID)
	-- for k,v in pairs(player) do
	-- 	print("player joined", k)
	-- end
	-- GLOBAL.dumptable(player)
	print("health", player.components.health.currenthealth, player.components.health.maxhealth)
	-- keep a record of this players original max health so we can remove it when they leave
	local newPlayerMaxHealth = player.components.health.maxhealth
	local newPlayerHealth = player.components.health.currenthealth
	maxHealthOrig[player.GUID] = newPlayerMaxHealth
	-- update the shared health pool with the amount of health the player has
	currentMaxHealth = currentMaxHealth + newPlayerMaxHealth
	-- add the current health of the player to the pool
	-- when a player leaves, they leave with their health at the current percentage as the pool, and the same amount is added back when they rejoin
	currentHealth = currentHealth + newPlayerHealth
	-- update the health component for all the players
	for i, v in pairs(GLOBAL.AllPlayers) do
		print("set healths ", currentMaxHealth, currentHealth)
		v.components.health:SetMaxHealth(currentMaxHealth)
		v.components.health:SetCurrentHealth(currentHealth)
	end
end

local function RemovePlayer(inst, player)
	-- Want to update the max health and health of everyone
	print("remove player", inst, player)
	--print(maxHealthOrig[player.id])
	local leavingPlayerOrigMaxHealth = maxHealthOrig[player.GUID]
	-- when a player leaves, they leave with their health at the current percentage as the pool, and the same amount is added back when they rejoin
	local leavingPlayerHealth = leavingPlayerOrigMaxHealth * (currentHealth / currentMaxHealth)
	currentMaxHealth = currentMaxHealth - leavingPlayerOrigMaxHealth
	currentHealth = currentHealth - leavingPlayerHealth
	-- update the health component for all the players
	for i, v in pairs(GLOBAL.AllPlayers) do
		if (player.GUID == v.GUID) then
			-- Update the health of the leaving player, back to its original max and value
			v.components.health:SetMaxHealth(leavingPlayerOrigMaxHealth)
			v.components.health:SetCurrentHealth(leavingPlayerHealth)
		else
			-- Update the health of the remaining players
			v.components.health:SetMaxHealth(currentMaxHealth)
			v.components.health:SetCurrentHealth(currentHealth)
		end
	end
end

AddPlayerPostInit(function(inst)
	if GLOBAL.TheNet:GetIsServer() then
		print("adding player", inst)
		-- GLOBAL.dumptable(inst)
		if (GetModConfigData("Health") or 1) == 1 then
			inst:ListenForEvent("healthdelta", OnHealthDelta)
		end
	end
end)

-- AddGamePostInit(function (inst)
AddPrefabPostInit("world", function (inst)
	print("should add prefab listener?", inst, GLOBAL)
	if GLOBAL.TheWorld.ismastersim then
		--player event `playerdied`
		--remmove player component `gostenabled`
		print("add prefab listener")
		-- ms_becameghost
		-- ms_playercounts
		-- ms_respawnedfromghost
		-- ms_playerdespawnanddelete
		-- ms_playerdespawnandmigrate
		-- ms_newplayercharacterspawned
		-- ms_newplayerspawned

		-- ms_playerjoined happens on first join and whenever they come through a portal, happens before first health tick
		-- ms_playerleft happens when they use a portal, and not when the server is shutdown
		-- ms_playerspawn same as ms_playerjoined (probably also if their character gets reset?), happens before first health
		-- ms_playerdespawn when a player leaves a cluster (probably also if their character gets reset?)
		-- ms_playerdisconnected when a player leaves a cluster

		GLOBAL.TheWorld:ListenForEvent("ms_playerjoined", function()
			print("player ms_playerjoined")
		end)
		GLOBAL.TheWorld:ListenForEvent("ms_playerleft", function()
			print("player ms_playerleft")
		end)
		GLOBAL.TheWorld:ListenForEvent("ms_playerspawn", function()
			print("player ms_playerspawn")
		end)
		GLOBAL.TheWorld:ListenForEvent("ms_playerdespawn", function()
			print("player ms_playerdespawn")
		end)
		GLOBAL.TheWorld:ListenForEvent("ms_playerdisconnected", function()
			print("player ms_playerdisconnected")
		end)
		GLOBAL.TheWorld:ListenForEvent("ms_playerdespawnanddelete", function()
			print("player ms_playerdespawnanddelete")
		end)
		GLOBAL.TheWorld:ListenForEvent("ms_playerdespawnandmigrate", function()
			print("player ms_playerdespawnandmigrate")
		end)
		GLOBAL.TheWorld:ListenForEvent("ms_newplayercharacterspawned", function()
			print("player ms_newplayercharacterspawned")
		end)
		GLOBAL.TheWorld:ListenForEvent("ms_newplayerspawned", function()
			print("player ms_newplayerspawned")
		end)


		GLOBAL.TheWorld:ListenForEvent("ms_playerspawn", function(inst, player)
			--we get a player spawn event even when the player transitions between shards
			--do the thing only if they haven't already connected
			print("doing init?", player.GUID, maxHealthOrig[player.GUID])
			GLOBAL.dumptable(maxHealthOrig)
			if (maxHealthOrig[player.GUID] == nil) then
				InitPlayer(inst, player)
			end
		end)
		GLOBAL.TheWorld:ListenForEvent("ms_playerdespawn", function(inst, player)
			RemovePlayer(inst, player)
		end)
	end
end)

-- this was copied from the ice hound code, customised to work for this
local NO_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO" }
local FREEZABLE_TAGS = { "freezable" }
local function DoIceExplosion(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 30, FREEZABLE_TAGS, NO_TAGS)
	-- print ("freeze around player!", 3, inst, ents, FREEZABLE_TAGS, NO_TAGS)
	for i, v in pairs(ents) do
		if v.components.freezable ~= nil then
			--Freezable:AddColdness(coldness, freezetime, nofreeze)
			v.components.freezable:AddColdness(v.components.freezable:ResolveResistance(), freezeTime)
			v.components.freezable:SpawnShatterFX()
		end
	end
end

local function TriggerFreeze(inst, arg2, arg3)
	print("trigger freeze client!", inst, arg2, arg3)
	--triggerFreeze
	--the `false` arg makes it run on the server when this code is executed on the client
	UserCommands.RunTextUserCommand("triggerFreeze", GLOBAL.ThePlayer, false)
end

--Used soul ring mod (350811795) as reference for this code
local function TeleportPlayerToPlayer(playerToTeleport, toPlayer)
	-- check if we are teleporting across shards
	-- maybe this returns nil when not in same shard? LookupPlayerInstByUserID('%s')
	print("userid? ", toPlayer.userid, GLOBAL.LookupPlayerInstByUserID(toPlayer.userid))
	-- print(inspect(getmetatable(GLOBAL.TheNet)))
	-- src.net.components.shardstate:GetMasterSessionId()
	-- if (playerToTeleport.world.id ~= toPlayer.world.id)
	-- playerspawner:SpawnAtLocation
	toPos = toPlayer:GetPosition()
	print("pos ", toPos)
	if (GLOBAL.LookupPlayerInstByUserID(toPlayer.userid) == nil) then
		-- if player is on another shard, go to the nearest sinkhole
		-- TODO: migrate to the correct shard
		-- TODO: teleport to the correct loacation in the correct shard
		-- TheWorld:PushEvent("ms_playerdespawnandmigrate", { player = doer, portalid = self.id, worldid = self.linkedWorld })
		-- Copied from admin scoreboard mod (1290774114)
		-- local cave = GetClosestInstWithTag('migrator', ThePlayer, 1000) c_goto(cave)
		toPos = GLOBAL.GetClosestInstWithTag('migrator', playerToTeleport, 1000):GetPosition()
	end
	print("pos ", toPos)
	local tp_pos
	local attempts = 100 --try multiple times to get a spot on ground before giving up so we don't infinite loop
	while attempts > 0 do
		local angle = math.random() * 2 * math.pi
		local distance = math.random() * 30
		tp_pos = toPos + GLOBAL.Vector3( GLOBAL.GetRandomWithVariance(0,2), 0.0, GLOBAL.GetRandomWithVariance(0,2) )
		if GLOBAL.TheWorld.Map:IsAboveGroundAtPoint(tp_pos:Get()) then
			break
		end
		attempts = attempts - 1
	end
	playerToTeleport.Physics:Teleport(tp_pos:Get())
	-- STRINGS.CHARACTERS.WARLY.ANNOUNCE_TOWNPORTALTELEPORT
	playerToTeleport.components.talker:Say(GLOBAL.GetString(playerToTeleport, "ANNOUNCE_TOWNPORTALTELEPORT"))

	local puff = GLOBAL.SpawnPrefab("small_puff")
	puff.Transform:SetPosition(tp_pos:Get())
end


local function TriggerTeleport(inst)
	-- teleport all players to the player that triggered the teleport and apply the health penalty
	UserCommands.RunTextUserCommand("TriggerTeleport", GLOBAL.ThePlayer, false)
end

--BUTTONS

-- local function PositionButton(controls, screensize)
-- 	local hudscale = controls.top_root:GetScale()
-- 	local screenw_full, screenh_full = GLOBAL.unpack(screensize)
-- 	local screenw = screenw_full/hudscale.x
-- 	local screenh = screenh_full/hudscale.y
-- 	controls.minimap_small:SetPosition(
-- 		(anchor_horiz*controls.minimap_small.mapsize.w/2)+(dir_horiz*screenw/2)+(margin_dir_horiz*margin_size_x),
-- 		(anchor_vert*controls.minimap_small.mapsize.h/2)+(dir_vert*screenh/2)+(margin_dir_vert*margin_size_y),
-- 		0
-- 	)
-- end

local function AddButtons(controls, args2)
	if controls then
		print("controls", controls)
		-- GLOBAL.dumptable(controls)
	end
	print("add buttons", args2)
	controls.inst:DoTaskInTime( 0, function()
		if freezeTime > 0 and freezeRange > 0 then
			-- TEMPLATES.IconButton(iconAtlas, iconTexture, labelText, sideLabel, alwaysShowLabel, onclick, textinfo, defaultTexture)
			controls.freezebutton = controls.top_root:AddChild(TEMPLATES.IconButton("images/sharedHealth.xml", "iceBoulder.tex", "Freeze!", false, false, function() TriggerFreeze() end, {offset_x = 0, offset_y = 0}))
			-- controls.freezebutton = controls.top_root:AddChild(ImageButton(iconAtlas, "iceBoulder.tex"))
			-- controls.freezebutton:SetScale(.8,.8,.8)
			-- controls.freezebutton:SetOnClick( function() TriggerFreeze() end )
			controls.freezebutton:SetHAnchor(GLOBAL.ANCHOR_RIGHT)
			controls.freezebutton:SetVAnchor(GLOBAL.ANCHOR_MIDDLE)
			controls.freezebutton:SetPosition(-50, 100, 0)
			controls.freezebutton:MoveToFront()
		end

		controls.teleportbutton = controls.top_root:AddChild(TEMPLATES.IconButton("images/sharedHealth.xml", "iceBoulder.tex", "Escape!", true, false, function() TriggerTeleport() end))
		controls.teleportbutton:SetHAnchor(GLOBAL.ANCHOR_RIGHT)
		controls.teleportbutton:SetVAnchor(GLOBAL.ANCHOR_MIDDLE)
		controls.teleportbutton:SetPosition(-50, 0, 0)
		controls.teleportbutton:MoveToFront()
	end)

	-- self.togglebutton:Hide()
	-- controls.freezebutton = controls.top_root:AddChild( MiniMapWidget( mapscale ) )
	-- controls.minimap_small = controls.top_root:AddChild( MiniMapWidget( mapscale ) )
	-- local screensize = {GLOBAL.TheSim:GetScreenSize()}
	-- PositionMiniMap(controls, screensize)
	--
	-- local OnUpdate_base = controls.OnUpdate
	-- controls.OnUpdate = function(self, dt)
	-- 	OnUpdate_base(self, dt)
	-- 	local curscreensize = {GLOBAL.TheSim:GetScreenSize()}
	-- 	if curscreensize[1] ~= screensize[1] or curscreensize[2] ~= screensize[2] then
	-- 		PositionMiniMap(controls, curscreensize)
	-- 		screensize = curscreensize
	-- 	end
	-- end
end
AddClassPostConstruct( "widgets/controls", AddButtons )

-- local FreezeButton = Class(Widget, function(self, owner)
--     self.owner = owner
--     Widget._ctor(self, "IceOver")
-- 	self:SetClickable(false)
--
-- 	self.img = self:AddChild(Image("images/fx.xml", "ice_over.tex"))
-- 	self.img:SetEffect( "shaders/uifade.ksh" )
--     self.img:SetHAnchor(ANCHOR_MIDDLE)
--     self.img:SetVAnchor(ANCHOR_MIDDLE)
--     self.img:SetScaleMode(SCALEMODE_FILLSCREEN)
--
--     self:Hide()
--     self.laststep = 0
--
--     self.alpha_min = 1
--     self.alpha_min_target = 1
--
--     self.inst:ListenForEvent("temperaturedelta", function() self:OnIceChange() end, self.owner)
-- end)

-- AddClassPostConstruct("screens/playerhud", function(self)
-- 	print("AddClassPostConstruct playerhud", self)
--
-- 	-- self.freezebutton = self.overlayroot:AddChild( Text(UIFONT, 30) )
-- 	-- self.freezebutton:SetVAnchor(ANCHOR_BOTTOM)
-- 	-- self.freezebutton:SetHAnchor(ANCHOR_MIDDLE)
-- 	-- self.freezebutton:SetPosition(0, 85)
-- 	-- self.freezebutton:SetString("TEST string? :D")
-- 	-- self.freezebutton = self.overlayroot:AddChild(ImageButton(HUD_ATLAS, "map_button.tex", nil, nil, nil, nil, {1,1}, {0,0}))
-- 	self.freezebutton = self.overlayroot:AddChild(ImageButton())
-- 	-- self.freezebutton = controls.top_root:AddChild(ImageButton())
-- 	-- self.freezebutton:SetScale(.7,.7,.7)
-- 	self.freezebutton:SetText("test")
-- 	self.freezebutton:SetOnClick( function() self:TriggerFreeze() end )
-- 	self.freezebutton:SetHAnchor(GLOBAL.ANCHOR_MIDDLE)
-- 	self.freezebutton:SetVAnchor(GLOBAL.ANCHOR_MIDDLE)
-- 	-- self.freezebutton:SetPosition(-60,70,0)
-- 	-- self.freezebutton:SetVRegPoint(ANCHOR_MIDDLE)
-- 	-- self.freezebutton:SetHRegPoint(ANCHOR_MIDDLE)
-- 	self.freezebutton:MoveToFront()
-- 	self.freezebutton:Show()
-- 	-- self.freezebutton:SetPosition(50, 50, 0)
-- 	-- self.minimapBtn = self:AddChild(ImageButton(HUD_ATLAS, "map_button.tex", nil, nil, nil, nil, {1,1}, {0,0}))
-- 	-- self.minimapBtn:SetScale(MAPSCALE, MAPSCALE, MAPSCALE)
-- 	-- self.minimapBtn:Show()
-- end)

GLOBAL.AddUserCommand("triggerFreeze", {
	prettyname = "Freeze Everything",
	desc = "Trigger a freeze of all nearby entities",
	permission = GLOBAL.COMMAND_PERMISSION.USER,
	slash = true,
	usermenu = false,
	servermenu = false,
	params = {"commandname"},
	paramsoptional = {true},
	vote = false,
	serverfn = function(params, caller)
		print ("Command Recieved", caller)
		for i, v in pairs(GLOBAL.AllPlayers) do
			DoIceExplosion(v)
		end
	end,
})

GLOBAL.AddUserCommand("TriggerTeleport", {
	prettyname = "Teleport away",
	desc = "Teleport to a random player",
	permission = GLOBAL.COMMAND_PERMISSION.USER,
	slash = true,
	usermenu = false,
	servermenu = false,
	params = {"commandname"},
	paramsoptional = {true},
	vote = false,
	serverfn = function(params, caller)
		print ("Command Recieved", caller)
		--do the teleporting to a random player - but not yourself
		-- get a random index, but if the index is higher than the player index increment it
		-- if #GLOBAL.AllPlayers <= 1 then
		-- 	-- TODO: why doesnt the string work???????
		-- 	--works: STRINGS.CHARACTERS.WARLY.ANNOUNCE_TOWNPORTALTELEPORT
		-- 	--broken: STRINGS.CHARACTERS.GENERIC.DESCRIBE.MIGRATION_PORTAL.GENERIC
		-- 	-- GLOBAL.dumptable(GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE)
		-- 	-- GLOBAL.dumptable(GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE)
		-- 	-- GLOBAL.dumptable(GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE["MIGRATION_PORTAL"])
		-- 	-- GLOBAL.dumptable(GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.MIGRATION_PORTAL)
		-- 	-- GLOBAL.dumptable(GLOBAL.GetString(caller, "DESCRIBE"))
		-- 	-- caller.components.talker:Say(GLOBAL.GetString(caller, "DESCRIBE").MIGRATION_PORTAL.GENERIC)
		-- 	-- caller.components.talker:Say(GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.MIGRATION_PORTAL.GENERIC)
		-- 	caller.components.talker:Say("If I had any friends, this could take me to them.")
		-- 	return
		-- end
		-- local index = math.random(#GLOBAL.AllPlayers - 1)
		-- for i=1, index do
		-- 	if GLOBAL.AllPlayers[i].GUID == caller.GUID then
		-- 		index = index + 1
		-- 		break
		-- 	end
		-- end
		local index = 1
		TeleportPlayerToPlayer(caller, GLOBAL.AllPlayers[index])
		--apply the health penalty, but dont kill!
		penalty = teleportHealthPenalty;
		if (caller.components.health.currenthealth <= penalty)
		then
			penalty = caller.components.health.currenthealth - 1
		end
		DoDelta(-1 * penalty, "Escape Teleport", nil)
	end,
})

-- GLOBAL.AddUserCommand("TriggerTeleport", {
-- 	prettyname = "Teleport to you",
-- 	desc = "Teleport all players to you",
-- 	permission = GLOBAL.COMMAND_PERMISSION.USER,
-- 	slash = true,
-- 	usermenu = false,
-- 	servermenu = false,
-- 	params = {"commandname"},
-- 	paramsoptional = {true},
-- 	vote = false,
-- 	serverfn = function(params, caller)
-- 		print ("Command Recieved", caller)
-- 		--calculate new max health
-- 		newHealth = caller.components.health.currenthealth - teleportHealthPenalty;
-- 		if (newHealth < 1)
-- 		then
-- 			newHealth = 1
-- 		end
-- 		--for every player
-- 		for i, v in pairs(GLOBAL.AllPlayers) do
-- 			--do the teleporting
-- 			TeleportPlayerToPlayer(v, caller)
-- 			--apply the health penalty
-- 			v.components.health:SetVal(newHealth)
-- 			v.components.health:DoDelta(0, nil, "update")
-- 		end
-- 	end,
-- })
