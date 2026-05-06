local modname = minetest.get_current_modname()
local bridge_dir = minetest.settings:get("oni_cadia_bridge_dir")
if bridge_dir == nil or bridge_dir == "" then
	bridge_dir = minetest.get_worldpath() .. "/oni-cadia-bridge"
end
local actions_dir = bridge_dir .. "/actions"
local state_path = bridge_dir .. "/state.json"
local chat_path = bridge_dir .. "/chat.jsonl"
local processed_path = bridge_dir .. "/processed.json"
local cleanup_marker_path = bridge_dir .. "/legacy-static-citizens-cleared-v1"

minetest.mkdir(bridge_dir)
minetest.mkdir(actions_dir)

local processed = {}
local processed_count = 0
local agents = {}
local persisted_agent_positions = {}
local persisted_agent_inventories = {}
local chat_log = {}
local last_action = nil
local tick = 0
local max_chat_log = 80
local previous_processed_count = 0
local citizen_stand_offset = 1.3
local surface_search_min_y = -32
local surface_search_max_y = 80
local surface_search_radius = 96
local forest_stage_name = "easy_forest_survival"

local profiles = {
	[1] = { username = "iori", name = "いおり", color = "#8fd3ff", origin = { x = -8, y = 3, z = 0 }, material = "default:stone" },
	[2] = { username = "tsumugi", name = "つむぎ", color = "#ffd479", origin = { x = 0, y = 3, z = 8 }, material = "default:wood" },
	[3] = { username = "saku", name = "さく", color = "#b7ff9a", origin = { x = 8, y = 3, z = 0 }, material = "oni_cadia_core:glass" },
	[4] = { username = "ruri", name = "るり", color = "#b5a4ff", origin = { x = 0, y = 3, z = -8 }, material = "oni_cadia_core:brick" },
	[5] = { username = "hibiki", name = "ひびき", color = "#ff9a9a", origin = { x = -12, y = 3, z = 8 }, material = "default:torch" },
	[6] = { username = "kanae", name = "かなえ", color = "#9affdf", origin = { x = 12, y = 3, z = -8 }, material = "default:dirt_with_grass" },
	[7] = { username = "kimi", name = "きみ", color = "#f4a7ff", origin = { x = -16, y = 3, z = -8 }, material = "oni_cadia_core:brick" },
	[8] = { username = "qwen", name = "くえん", color = "#a7c7ff", origin = { x = 16, y = 3, z = 8 }, material = "default:stone" },
	[9] = { username = "minimax", name = "みにま", color = "#fff4a7", origin = { x = 0, y = 3, z = 16 }, material = "default:torch" },
}

local palette = {
	stone = "default:stone",
	wood = "default:wood",
	glass = "default:glass",
	brick = "default:brick",
	light = "default:torch",
	grass = "default:dirt_with_grass",
	road = "oni_cadia_core:road",
}

local function texture(color)
	return "[fill:16x16:" .. color
end

minetest.register_item(":", {
	type = "none",
	wield_image = "wieldhand.png",
	wield_scale = { x = 1, y = 1, z = 2.5 },
	range = 8,
	tool_capabilities = {
		full_punch_interval = 0.6,
		max_drop_level = 0,
		groupcaps = {
			choppy = { times = { [1] = 1.2, [2] = 0.8, [3] = 0.4 }, uses = 0, maxlevel = 3 },
			cracky = { times = { [1] = 1.8, [2] = 1.2, [3] = 0.6 }, uses = 0, maxlevel = 3 },
			crumbly = { times = { [1] = 1.0, [2] = 0.6, [3] = 0.3 }, uses = 0, maxlevel = 3 },
			snappy = { times = { [1] = 0.8, [2] = 0.4, [3] = 0.2 }, uses = 0, maxlevel = 3 },
			oddly_breakable_by_hand = { times = { [1] = 0.7, [2] = 0.4, [3] = 0.2 }, uses = 0, maxlevel = 3 },
		},
		damage_groups = { fleshy = 1 },
	},
})

minetest.register_node("oni_cadia_core:grass", {
	description = "ONI-CADIA Grass",
	tiles = { texture("#4d9f57") },
	groups = { crumbly = 3, oddly_breakable_by_hand = 2 },
})

minetest.register_node("oni_cadia_core:dirt", {
	description = "ONI-CADIA Forest Dirt",
	tiles = { texture("#6b4f2a") },
	groups = { crumbly = 3, soil = 1, oddly_breakable_by_hand = 2 },
})

minetest.register_node("oni_cadia_core:dirt_with_grass", {
	description = "ONI-CADIA Forest Floor",
	tiles = { texture("#4d9f57"), texture("#6b4f2a"), texture("#5d7f39") },
	groups = { crumbly = 3, soil = 1, oddly_breakable_by_hand = 2 },
})

minetest.register_node("oni_cadia_core:forest_grass", {
	description = "ONI-CADIA Forest Grass",
	drawtype = "plantlike",
	tiles = { texture("#76b852") },
	inventory_image = texture("#76b852"),
	wield_image = texture("#76b852"),
	paramtype = "light",
	walkable = false,
	buildable_to = true,
	groups = { snappy = 3, flora = 1, grass = 1, oddly_breakable_by_hand = 3 },
})

minetest.register_node("oni_cadia_core:stone", {
	description = "ONI-CADIA Stone",
	tiles = { texture("#7d8794") },
	groups = { cracky = 2, oddly_breakable_by_hand = 3 },
})

minetest.register_node("oni_cadia_core:wood", {
	description = "ONI-CADIA Wood",
	tiles = { texture("#a66a3f") },
	groups = { choppy = 2, oddly_breakable_by_hand = 2 },
})

minetest.register_node("oni_cadia_core:tree", {
	description = "ONI-CADIA Forest Tree",
	tiles = { texture("#7a4a28") },
	groups = { tree = 1, choppy = 2, oddly_breakable_by_hand = 2 },
})

minetest.register_node("oni_cadia_core:leaves", {
	description = "ONI-CADIA Forest Leaves",
	drawtype = "allfaces_optional",
	tiles = { texture("#2f7d3f") },
	paramtype = "light",
	walkable = false,
	groups = { snappy = 3, leaves = 1, flora = 1, oddly_breakable_by_hand = 3 },
})

minetest.register_node("oni_cadia_core:water_source", {
	description = "ONI-CADIA Forest Water",
	drawtype = "liquid",
	tiles = { texture("#3b82f6") },
	special_tiles = { texture("#3b82f6") },
	alpha = 160,
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	liquidtype = "source",
	liquid_alternative_source = "oni_cadia_core:water_source",
	liquid_alternative_flowing = "oni_cadia_core:water_source",
	liquid_viscosity = 1,
	groups = { water = 3, liquid = 3 },
})

minetest.register_node("oni_cadia_core:glass", {
	description = "ONI-CADIA Glass",
	tiles = { texture("#8fd3ff") },
	drawtype = "glasslike",
	paramtype = "light",
	sunlight_propagates = true,
	use_texture_alpha = "blend",
	groups = { cracky = 3, oddly_breakable_by_hand = 3 },
})

minetest.register_node("oni_cadia_core:brick", {
	description = "ONI-CADIA Brick",
	tiles = { texture("#bd5c5c") },
	groups = { cracky = 2, oddly_breakable_by_hand = 3 },
})

minetest.register_node("oni_cadia_core:road", {
	description = "ONI-CADIA Road",
	tiles = { texture("#2f3542") },
	groups = { cracky = 2, oddly_breakable_by_hand = 3 },
})

minetest.register_node("oni_cadia_core:light", {
	description = "ONI-CADIA Wood Lamp",
	tiles = { texture("#ffe66d") },
	light_source = 12,
	groups = { cracky = 2, oddly_breakable_by_hand = 3 },
})

local function round_coord(value)
	return math.floor((tonumber(value) or 0) + 0.5)
end

local function copy_pos(pos)
	return { x = round_coord(pos.x), y = round_coord(pos.y), z = round_coord(pos.z) }
end

local function object_pos(object)
	if not object then
		return nil
	end
	local ok, pos = pcall(function()
		return object:get_pos()
	end)
	if ok and pos then
		return pos
	end
	return nil
end

local function distance_squared(a, b)
	if not a or not b then
		return math.huge
	end
	local dx = (a.x or 0) - (b.x or 0)
	local dy = (a.y or 0) - (b.y or 0)
	local dz = (a.z or 0) - (b.z or 0)
	return dx * dx + dy * dy + dz * dz
end

local function agent_key(agent_id)
	return string.format("agent_%03d", tonumber(agent_id) or 0)
end

local function profile_for(agent_id, agent_name)
	local id = tonumber(agent_id) or 1
	local profile = profiles[id] or {
		username = "agent_" .. tostring(id),
		name = agent_name or ("agent_" .. tostring(id)),
		color = "#ffffff",
		origin = { x = (id - 1) * 4, y = 3, z = 12 },
		material = "default:stone",
	}
	if agent_name and agent_name ~= "" then
		profile.name = agent_name
	end
	return profile
end

local function table_copy(source)
	local copy = {}
	if type(source) == "table" then
		for key, value in pairs(source) do
			copy[key] = value
		end
	end
	return copy
end

local function normalize_inventory(source)
	local inventory = {}
	if type(source) == "table" then
		for key, value in pairs(source) do
			local name = tostring(key or "")
			local count = math.max(0, math.floor(tonumber(value) or 0))
			if name ~= "" and count > 0 then
				inventory[name] = count
			end
		end
	end
	return inventory
end

local function ensure_inventory(agent)
	if type(agent.inventory) ~= "table" then
		agent.inventory = {}
	end
	return agent.inventory
end

local function inventory_count(agent, material)
	local inventory = ensure_inventory(agent)
	return math.max(0, math.floor(tonumber(inventory[material]) or 0))
end

local function add_inventory(agent, material, count)
	local name = tostring(material or "")
	local amount = math.max(0, math.floor(tonumber(count) or 0))
	if name == "" or amount <= 0 then
		return
	end
	local inventory = ensure_inventory(agent)
	inventory[name] = inventory_count(agent, name) + amount
end

local function consume_inventory(agent, material, count)
	local name = tostring(material or "")
	local amount = math.max(0, math.floor(tonumber(count) or 0))
	if name == "" or amount <= 0 then
		return true
	end
	local available = inventory_count(agent, name)
	if available < amount then
		return false, available, amount
	end
	ensure_inventory(agent)[name] = available - amount
	return true, available, amount
end

local function load_previous_state()
	local handle = io.open(state_path, "r")
	if not handle then
		return
	end
	local payload = minetest.parse_json(handle:read("*a") or "")
	handle:close()
	if type(payload) ~= "table" then
		return
	end
	previous_processed_count = tonumber(payload.processed_count) or 0
	if type(payload.chat_log) == "table" then
		chat_log = payload.chat_log
	end
	if type(payload.agents) ~= "table" then
		return
	end
	for key, agent in pairs(payload.agents) do
		if type(agent) == "table" and type(agent.pos) == "table" then
			persisted_agent_positions[key] = copy_pos(agent.pos)
		end
		if type(agent) == "table" and type(agent.inventory) == "table" then
			persisted_agent_inventories[key] = normalize_inventory(agent.inventory)
		end
	end
end

local function save_processed()
	local ids = {}
	for id, done in pairs(processed) do
		if done then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	minetest.safe_file_write(processed_path, minetest.write_json({
		updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		processed_count = processed_count,
		ids = ids,
	}, true) .. "\n")
end

local function load_processed()
	local handle = io.open(processed_path, "r")
	if not handle then
		return false
	end
	local payload = minetest.parse_json(handle:read("*a") or "")
	handle:close()
	if type(payload) ~= "table" then
		return false
	end
	if type(payload.ids) == "table" then
		for _, id in ipairs(payload.ids) do
			processed[tostring(id)] = true
		end
	elseif type(payload.processed) == "table" then
		for id, done in pairs(payload.processed) do
			if done then
				processed[tostring(id)] = true
			end
		end
	end
	processed_count = tonumber(payload.processed_count) or previous_processed_count or 0
	return true
end

local function seed_existing_actions_as_processed()
	local count = 0
	local files = minetest.get_dir_list(actions_dir, false) or {}
	table.sort(files)
	for _, filename in ipairs(files) do
		if filename:sub(-6) == ".jsonl" then
			local path = actions_dir .. "/" .. filename
			local handle = io.open(path, "r")
			if handle then
				local index = 0
				for line in handle:lines() do
					index = index + 1
					if line and line ~= "" then
						local action = minetest.parse_json(line)
						local id = nil
						if type(action) == "table" then
							id = tostring(action.id or (filename .. ":" .. index))
						else
							id = filename .. ":" .. tostring(index)
						end
						if not processed[id] then
							processed[id] = true
							count = count + 1
						end
					end
				end
				handle:close()
			end
		end
	end
	if count > 0 then
		processed_count = math.max(processed_count, count, previous_processed_count)
	end
	save_processed()
end

local function file_exists(path)
	local handle = io.open(path, "r")
	if handle then
		handle:close()
		return true
	end
	return false
end

local function clear_legacy_static_objects_once()
	if file_exists(cleanup_marker_path) then
		return
	end
	if type(minetest.clear_objects) ~= "function" then
		minetest.safe_file_write(cleanup_marker_path, "clear_objects unavailable\n")
		return
	end
	local ok, err = pcall(function()
		minetest.clear_objects({ mode = "full" })
	end)
	if not ok then
		ok, err = pcall(function()
			minetest.clear_objects("full")
		end)
	end
	if ok then
		minetest.safe_file_write(cleanup_marker_path, os.date("!%Y-%m-%dT%H:%M:%SZ") .. "\n")
	else
		minetest.log("warning", "[" .. modname .. "] failed to clear legacy static citizens: " .. tostring(err))
	end
end

local function node_and_def(pos)
	local target = copy_pos(pos)
	local node = minetest.get_node_or_nil(target)
	if not node then
		minetest.load_area(target)
		node = minetest.get_node_or_nil(target)
	end
	if not node then
		return nil, nil
	end
	return node, minetest.registered_nodes[node.name] or {}
end

local function is_walkable(pos)
	local node, def = node_and_def(pos)
	if not node or node.name == "air" or node.name == "ignore" then
		return false
	end
	return def.walkable ~= false
end

local function is_surface_ground(pos)
	local node, def = node_and_def(pos)
	if not node or node.name == "air" or node.name == "ignore" then
		return false
	end
	if node.name == "oni_cadia_core:tree"
		or node.name == "default:tree"
		or node.name == "oni_cadia_core:leaves"
		or node.name == "default:leaves"
		or node.name == "oni_cadia_core:forest_grass"
		or node.name == "oni_cadia_core:water_source"
		or node.name == "default:water_source"
		or node.name == "default:river_water_source" then
		return false
	end
	return def.walkable ~= false
end

local function is_open(pos)
	local node, def = node_and_def(pos)
	if not node or node.name == "ignore" then
		return false
	end
	return node.name == "air" or def.walkable == false
end

local function surface_y_at(x, z)
	local px = round_coord(x)
	local pz = round_coord(z)
	if math.abs(px) > surface_search_radius or math.abs(pz) > surface_search_radius then
		return nil
	end
	minetest.load_area(
		{ x = px, y = surface_search_min_y, z = pz },
		{ x = px, y = surface_search_max_y + 8, z = pz }
	)
	for y = surface_search_max_y, surface_search_min_y, -1 do
		if is_surface_ground({ x = px, y = y, z = pz })
			and is_open({ x = px, y = y + 1, z = pz })
			and is_open({ x = px, y = y + 2, z = pz }) then
			return y
		end
	end
	return nil
end

local function is_agent_slot_occupied(x, z, skip_key)
	for key, agent in pairs(agents) do
		if key ~= skip_key then
			local pos = object_pos(agent.object) or agent.pos
			if pos and round_coord(pos.x) == x and round_coord(pos.z) == z then
				return true
			end
		end
	end
	return false
end

local function find_surface_near(pos, skip_key)
	local base_x = math.max(-surface_search_radius + 2, math.min(surface_search_radius - 2, round_coord(pos.x)))
	local base_z = math.max(-surface_search_radius + 2, math.min(surface_search_radius - 2, round_coord(pos.z)))
	local fallback = nil
	for radius = 0, 18 do
		for dx = -radius, radius do
			for dz = -radius, radius do
				if radius == 0 or math.abs(dx) == radius or math.abs(dz) == radius then
					local x = base_x + dx
					local z = base_z + dz
					local surface_y = surface_y_at(x, z)
					if surface_y and not is_agent_slot_occupied(x, z, skip_key) then
						fallback = fallback or { x = x, z = z, surface_y = surface_y }
						return { x = x, z = z, surface_y = surface_y }
					end
				end
			end
		end
	end
	if fallback then
		return fallback
	end
	return { x = base_x, z = base_z, surface_y = 1 }
end

local function stand_pos_near(pos, skip_key)
	local surface = find_surface_near(pos, skip_key)
	return { x = surface.x, y = surface.surface_y + citizen_stand_offset, z = surface.z }, surface
end

local function ground_info(pos)
	if not pos then
		return { grounded = false }
	end
	local x = round_coord(pos.x)
	local z = round_coord(pos.z)
	local surface_y = surface_y_at(x, z)
	if not surface_y then
		return { grounded = false, x = x, z = z }
	end
	local expected_y = surface_y + citizen_stand_offset
	return {
		grounded = (pos.y or 0) >= surface_y + 0.4 and (pos.y or 0) <= surface_y + 2.2,
		x = x,
		z = z,
		surface_y = surface_y,
		stand_y = expected_y,
	}
end

local function trim(text)
	return tostring(text or ""):match("^%s*(.-)%s*$") or ""
end

local function agent_lookup_key(ref)
	local text = trim(ref)
	if text == "" then
		return nil
	end
	local lowered = text:lower()
	local number = lowered:match("^agent[_%-]?(%d+)$") or lowered:match("^(%d+)$")
	if number then
		return agent_key(tonumber(number))
	end
	for key, agent in pairs(agents) do
		if lowered == key:lower() or lowered == tostring(agent.name or ""):lower() then
			return key
		end
	end
	return nil
end

local function agent_label(key, agent)
	local pos = copy_pos(object_pos(agent.object) or agent.pos)
	return key .. " / " .. tostring(agent.name) .. " (" .. tostring(agent.username) .. ") @ " .. pos.x .. "," .. pos.y .. "," .. pos.z
end

local function player_for_agent(agent)
	if not agent then
		return nil
	end
	local username = agent.username
	if not username or username == "" then
		local profile = profile_for(agent.id, agent.name)
		username = profile.username
	end
	return minetest.get_player_by_name(username)
end

local function live_object_for_agent(agent)
	return player_for_agent(agent) or agent.object
end

local function agent_position(agent)
	return object_pos(live_object_for_agent(agent)) or agent.pos
end

local function set_agent_position(agent, pos)
	local player = player_for_agent(agent)
	if player then
		player:set_pos(pos)
	elseif agent.object then
		agent.object:set_pos(pos)
	end
	agent.pos = copy_pos(pos)
end

local function configure_agent_player(player, agent_id)
	local profile = profile_for(agent_id)
	player:set_nametag_attributes({ text = profile.name, color = profile.color })
	player:set_hp(math.max(1, player:get_hp()))
	minetest.set_player_privs(player:get_player_name(), { interact = true, shout = true })
end

local function ensure_player_privs(player)
	if not player then
		return
	end
	local name = player:get_player_name()
	local privs = minetest.get_player_privs(name)
	privs.interact = true
	privs.shout = true
	minetest.set_player_privs(name, privs)
end

local function agent_id_for_username(username)
	for id, profile in pairs(profiles) do
		if profile.username == username then
			return id
		end
	end
	return nil
end

local function loaded_citizen_counts()
	local counts = {}
	for _, object in ipairs(minetest.get_objects_inside_radius({ x = 0, y = 8, z = 0 }, 256) or {}) do
		local entity = object:get_luaentity()
		if entity and entity.name == "oni_cadia_core:citizen" then
			local key = agent_key(entity.agent_id)
			counts[key] = (counts[key] or 0) + 1
		end
	end
	return counts
end

local function connected_agent_players()
	local connected = {}
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local agent_id = agent_id_for_username(name)
		if agent_id then
			local key = agent_key(agent_id)
			connected[key] = {
				username = name,
				name = profile_for(agent_id).name,
				pos = copy_pos(player:get_pos()),
			}
		end
	end
	return connected
end

local function write_state()
	local exported = {}
	for key, agent in pairs(agents) do
		local pos = agent_position(agent)
		local ground = ground_info(pos)
		exported[key] = {
			id = agent.id,
			name = agent.name,
			username = agent.username,
			online = player_for_agent(agent) ~= nil,
			entity_type = "player",
			pos = copy_pos(pos),
			grounded = ground.grounded,
			surface_y = ground.surface_y,
			stand_y = ground.stand_y,
			inventory = normalize_inventory(ensure_inventory(agent)),
			hp = player_for_agent(agent) and player_for_agent(agent):get_hp() or nil,
			last_action = agent.last_action,
			last_message = agent.last_message,
		}
	end
	local payload = {
		updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		bridge_dir = bridge_dir,
		stage = forest_stage_name,
		surface_mode = "natural",
		surface_search_min_y = surface_search_min_y,
		surface_search_max_y = surface_search_max_y,
		processed_count = processed_count,
		agents = exported,
		loaded_citizen_counts = loaded_citizen_counts(),
		connected_agent_players = connected_agent_players(),
		chat_log = chat_log,
		last_action = last_action,
	}
	minetest.safe_file_write(state_path, minetest.write_json(payload, true) .. "\n")
end

local function append_chat(source, speaker, message, extra)
	local text = tostring(message or "")
	if text == "" then
		return
	end
	local entry = {
		at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		source = source,
		speaker = tostring(speaker or source),
		message = text,
	}
	if type(extra) == "table" then
		for key, value in pairs(extra) do
			entry[key] = value
		end
	end
	table.insert(chat_log, entry)
	while #chat_log > max_chat_log do
		table.remove(chat_log, 1)
	end
	local handle = io.open(chat_path, "a")
	if handle then
		handle:write(minetest.write_json(entry, false) .. "\n")
		handle:close()
	end
end

local function civic_chat(agent, message)
	append_chat("agent", agent.name, message, { agent_id = agent.id })
	minetest.chat_send_all("[ONI-CADIA] " .. agent.name .. ": " .. message)
end

local function ensure_ground()
	minetest.load_area(
		{ x = -surface_search_radius, y = surface_search_min_y, z = -surface_search_radius },
		{ x = surface_search_radius, y = surface_search_max_y, z = surface_search_radius }
	)
end

minetest.register_entity("oni_cadia_core:citizen", {
	initial_properties = {
		physical = false,
		pointable = true,
		collide_with_objects = false,
		visual = "cube",
		visual_size = { x = 0.7, y = 1.6, z = 0.7 },
		textures = {
			texture("#ffffff"), texture("#ffffff"), texture("#ffffff"),
			texture("#ffffff"), texture("#ffffff"), texture("#ffffff"),
		},
		static_save = false,
	},
	on_activate = function(self, staticdata)
		local data = minetest.parse_json(staticdata or "") or {}
		self.agent_id = tonumber(data.agent_id) or self.agent_id or 0
		self.agent_name = data.agent_name or self.agent_name or agent_key(self.agent_id)
		local profile = profile_for(self.agent_id, self.agent_name)
		local key = agent_key(self.agent_id)
		local existing = agents[key]
		local existing_pos = existing and object_pos(existing.object) or nil
		local current_pos = object_pos(self.object)
		if existing_pos then
			local target = persisted_agent_positions[key]
			local keep_current = false
			if target then
				keep_current = distance_squared(current_pos, target) < distance_squared(existing_pos, target)
			end
			if keep_current then
				existing.object:remove()
			else
				self.object:remove()
				return
			end
		end
		self.object:set_nametag_attributes({ text = profile.name, color = profile.color })
		local tex = texture(profile.color)
		self.object:set_properties({ textures = { tex, tex, tex, tex, tex, tex } })
		local snapped = stand_pos_near(current_pos or profile.origin, key)
		self.object:set_pos(snapped)
		agents[key] = {
			id = self.agent_id,
			name = profile.name,
			pos = copy_pos(snapped),
			object = self.object,
			inventory = table_copy(persisted_agent_inventories[key]),
			last_action = "activate",
		}
	end,
	get_staticdata = function(self)
		return minetest.write_json({ agent_id = self.agent_id, agent_name = self.agent_name })
	end,
})

local function ensure_agent(agent_id, agent_name)
	local key = agent_key(agent_id)
	local existing = agents[key]
	if existing and (player_for_agent(existing) or object_pos(existing.object)) then
		return existing
	end
	local profile = profile_for(agent_id, agent_name)
	local player = minetest.get_player_by_name(profile.username)
	local spawn_pos = stand_pos_near(player and player:get_pos() or persisted_agent_positions[key] or profile.origin, key)
	minetest.load_area(spawn_pos)
	if player then
		configure_agent_player(player, agent_id)
		player:set_pos(spawn_pos)
	end
	agents[key] = {
		id = tonumber(agent_id) or 0,
		name = profile.name,
		username = profile.username,
		pos = copy_pos(spawn_pos),
		object = nil,
		inventory = table_copy(persisted_agent_inventories[key]),
		last_action = "spawn",
	}
	return agents[key]
end

local function prune_duplicate_agents()
	minetest.load_area(
		{ x = -surface_search_radius, y = surface_search_min_y, z = -surface_search_radius },
		{ x = surface_search_radius, y = surface_search_max_y + 8, z = surface_search_radius }
	)
	for _, object in ipairs(minetest.get_objects_inside_radius({ x = 0, y = 24, z = 0 }, 256) or {}) do
		local entity = object:get_luaentity()
		if entity and entity.name == "oni_cadia_core:citizen" then
			object:remove()
		end
	end
	for id, profile in pairs(profiles) do
		local player = minetest.get_player_by_name(profile.username)
		if player then
			local key = agent_key(id)
			configure_agent_player(player, id)
			local snapped = stand_pos_near(player:get_pos(), key)
			player:set_pos(snapped)
			agents[key] = {
				id = id,
				name = profile.name,
				username = profile.username,
				pos = copy_pos(snapped),
				object = nil,
				inventory = agents[key] and ensure_inventory(agents[key]) or table_copy(persisted_agent_inventories[key]),
				last_action = "player",
			}
		end
	end
end

local directions = {
	north = { x = 0, y = 0, z = 1 },
	south = { x = 0, y = 0, z = -1 },
	east = { x = 1, y = 0, z = 0 },
	west = { x = -1, y = 0, z = 0 },
	up = { x = 0, y = 1, z = 0 },
	down = { x = 0, y = -1, z = 0 },
}

local function material_for(action, agent)
	local requested = tostring(action.material or "")
	if palette[requested] then
		return palette[requested]
	end
	local profile = profile_for(agent.id, agent.name)
	return profile.material
end

local function set_node(pos, name)
	local target = copy_pos(pos)
	minetest.load_area(target)
	minetest.set_node(target, { name = name })
end

local function forest_hash(x, z, seed)
	local value = math.sin((x * 12.9898) + (z * 78.233) + (seed * 0.013)) * 43758.5453
	return math.floor((value - math.floor(value)) * 10000)
end

local function generation_surface_y_at(x, z, min_y, max_y)
	for y = max_y, min_y, -1 do
		local name = minetest.get_node({ x = x, y = y, z = z }).name
		if name ~= "air"
			and name ~= "ignore"
			and name ~= "oni_cadia_core:water_source"
			and name ~= "default:water_source"
			and name ~= "default:river_water_source"
			and name ~= "oni_cadia_core:leaves"
			and name ~= "default:leaves"
			and name ~= "oni_cadia_core:forest_grass"
			and name ~= "oni_cadia_core:tree"
			and name ~= "default:tree" then
			return y, name
		end
	end
	return nil, nil
end

local function generation_replaceable(pos)
	local name = minetest.get_node(pos).name
	if name == "air" or name == "ignore" or name == "oni_cadia_core:forest_grass" then
		return true
	end
	local def = minetest.registered_nodes[name]
	return def and def.buildable_to == true
end

local function place_forest_tree(x, y, z, height)
	for dy = 1, height do
		minetest.set_node({ x = x, y = y + dy, z = z }, { name = "default:tree" })
	end
	local crown_y = y + height
	for dx = -2, 2 do
		for dz = -2, 2 do
			for dy = -1, 2 do
				if math.abs(dx) + math.abs(dz) + math.max(0, dy) <= 4 then
					local leaf_pos = { x = x + dx, y = crown_y + dy, z = z + dz }
					if generation_replaceable(leaf_pos) then
						minetest.set_node(leaf_pos, { name = "default:leaves" })
					end
				end
			end
		end
	end
end

local function ensure_starter_forest()
	local tree_offsets = {
		{ x = -20, z = -2 }, { x = -14, z = -16 }, { x = -8, z = 18 },
		{ x = 6, z = -18 }, { x = 12, z = 14 }, { x = 20, z = -8 },
		{ x = 22, z = 6 }, { x = -24, z = 12 }, { x = 0, z = 24 },
		{ x = 18, z = 22 }, { x = -18, z = -24 }, { x = 28, z = -22 },
	}
	for _, offset in ipairs(tree_offsets) do
		local y = surface_y_at(offset.x, offset.z)
		if y then
			set_node({ x = offset.x, y = y, z = offset.z }, "default:dirt_with_grass")
			for depth = 1, 3 do
				set_node({ x = offset.x, y = y - depth, z = offset.z }, "default:dirt")
			end
			place_forest_tree(offset.x, y, offset.z, 5 + (math.abs(offset.x + offset.z) % 2))
		end
	end
	for x = -28, 28, 2 do
		for z = -28, 28, 2 do
			if forest_hash(x, z, 77) < 1200 then
				local y = surface_y_at(x, z)
				if y and generation_replaceable({ x = x, y = y + 1, z = z }) then
					set_node({ x = x, y = y + 1, z = z }, "oni_cadia_core:forest_grass")
				end
			end
		end
	end
end

minetest.register_on_generated(function(minp, maxp, blockseed)
	if maxp.y < surface_search_min_y or minp.y > surface_search_max_y + 12 then
		return
	end
	for x = minp.x, maxp.x do
		for z = minp.z, maxp.z do
			local y, top_name = generation_surface_y_at(x, z, math.max(minp.y, surface_search_min_y), math.min(maxp.y, surface_search_max_y))
			if y and top_name ~= "oni_cadia_core:water_source" and top_name ~= "default:water_source" then
				minetest.set_node({ x = x, y = y, z = z }, { name = "default:dirt_with_grass" })
				for depth = 1, 3 do
					local below = { x = x, y = y - depth, z = z }
					local below_name = minetest.get_node(below).name
					if below_name == "oni_cadia_core:stone" or below_name == "default:stone" then
						minetest.set_node(below, { name = "default:dirt" })
					end
				end
				local open1 = generation_replaceable({ x = x, y = y + 1, z = z })
				local open2 = generation_replaceable({ x = x, y = y + 2, z = z })
				local h = forest_hash(x, z, blockseed)
				if open1 and open2 and h < 135 then
					place_forest_tree(x, y, z, 4 + (h % 3))
				elseif open1 and h >= 135 and h < 650 then
					minetest.set_node({ x = x, y = y + 1, z = z }, { name = "oni_cadia_core:forest_grass" })
				end
			end
		end
	end
end)

local function material_from_node_name(node_name)
	local name = tostring(node_name or ""):lower()
	if name == "" or name == "air" or name == "ignore" then
		return nil
	end
	if name:find("wood") or name:find("tree") then
		return "wood"
	end
	if name:find("glass") then
		return "glass"
	end
	if name:find("brick") then
		return "brick"
	end
	if name:find("grass") or name:find("dirt") or name:find("leaves") then
		return "grass"
	end
	if name:find("road") then
		return "road"
	end
	if name:find("light") then
		return "wood"
	end
	return "stone"
end

local function mine_one_node(agent, pos, requested_material)
	local target = copy_pos(pos)
	local node, def = node_and_def(target)
	if not node or node.name == "air" or node.name == "ignore" or def.diggable == false then
		return nil
	end
	local material = material_from_node_name(node.name)
	if not material then
		return nil
	end
	local requested = tostring(requested_material or "")
	if requested ~= "" and material ~= requested then
		return nil
	end
	set_node(target, "air")
	add_inventory(agent, material, 1)
	return material
end

local function mine_near_agent(agent, requested_material, count)
	local current = agent_position(agent)
	local ground = ground_info(current)
	local base = {
		x = round_coord(current.x),
		y = ground.surface_y or round_coord((current.y or 1) - 1),
		z = round_coord(current.z),
	}
	local wanted = math.max(1, math.min(tonumber(count) or 8, 24))
	local mined = {}
	local total = 0
	minetest.load_area(
		{ x = base.x - 8, y = base.y - 4, z = base.z - 8 },
		{ x = base.x + 8, y = base.y + 8, z = base.z + 8 }
	)
	for height = 1, 7 do
		for radius = 1, 8 do
			for dx = -radius, radius do
				for dz = -radius, radius do
					if math.abs(dx) == radius or math.abs(dz) == radius then
						local material = mine_one_node(agent, { x = base.x + dx, y = base.y + height, z = base.z + dz }, requested_material)
						if material then
							mined[material] = (mined[material] or 0) + 1
							total = total + 1
							if total >= wanted then
								return mined, total
							end
						end
					end
				end
			end
		end
	end
	for depth = 0, 3 do
		for radius = 1, 4 do
			for dx = -radius, radius do
				for dz = -radius, radius do
					if math.abs(dx) == radius or math.abs(dz) == radius then
						local material = mine_one_node(agent, { x = base.x + dx, y = base.y - depth, z = base.z + dz }, requested_material)
						if material then
							mined[material] = (mined[material] or 0) + 1
							total = total + 1
							if total >= wanted then
								return mined, total
							end
						end
					end
				end
			end
		end
	end
	return mined, total
end

local function format_inventory_delta(counts)
	local parts = {}
	for material, count in pairs(counts or {}) do
		table.insert(parts, tostring(material) .. " x" .. tostring(count))
	end
	table.sort(parts)
	if #parts == 0 then
		return "none"
	end
	return table.concat(parts, ", ")
end

local function build_tower(base, node, height)
	for y = 1, height do
		set_node({ x = base.x, y = base.y + y, z = base.z }, node)
	end
	set_node({ x = base.x, y = base.y + height + 1, z = base.z }, "default:torch")
end

local function build_wall(base, node, width)
	for x = -width, width do
		for y = 1, 3 do
			set_node({ x = base.x + x, y = base.y + y, z = base.z }, node)
		end
	end
end

local function build_road(base, direction, length)
	local delta = directions[direction] or directions.east
	for i = 0, length do
		set_node({ x = base.x + delta.x * i, y = base.y, z = base.z + delta.z * i }, "oni_cadia_core:road")
	end
end

local function build_plaza(base, node, radius)
	for x = -radius, radius do
		for z = -radius, radius do
			set_node({ x = base.x + x, y = base.y, z = base.z + z }, "oni_cadia_core:road")
		end
	end
	set_node({ x = base.x, y = base.y + 1, z = base.z }, node)
	set_node({ x = base.x, y = base.y + 2, z = base.z }, "default:torch")
end

local function build_house(base, node)
	for x = -2, 2 do
		for z = -2, 2 do
			set_node({ x = base.x + x, y = base.y, z = base.z + z }, "default:wood")
		end
	end
	for y = 1, 3 do
		for x = -2, 2 do
			set_node({ x = base.x + x, y = base.y + y, z = base.z - 2 }, node)
			set_node({ x = base.x + x, y = base.y + y, z = base.z + 2 }, node)
		end
		for z = -2, 2 do
			set_node({ x = base.x - 2, y = base.y + y, z = base.z + z }, node)
			set_node({ x = base.x + 2, y = base.y + y, z = base.z + z }, node)
		end
	end
	for x = -3, 3 do
		for z = -3, 3 do
			set_node({ x = base.x + x, y = base.y + 4, z = base.z + z }, "oni_cadia_core:brick")
		end
	end
	set_node({ x = base.x, y = base.y + 1, z = base.z - 2 }, "air")
	set_node({ x = base.x, y = base.y + 2, z = base.z - 2 }, "air")
	set_node({ x = base.x, y = base.y + 2, z = base.z }, "default:torch")
end

local function build_cost_for(shape, action)
	if shape == "tower" then
		return math.max(3, math.min(tonumber(action.height) or 6, 16)) + 1
	end
	if shape == "wall" then
		return (math.max(2, math.min(tonumber(action.width) or 5, 12)) * 2 + 1) * 3
	end
	if shape == "road" then
		return math.max(4, math.min(tonumber(action.length) or 12, 32)) + 1
	end
	if shape == "house" then
		return 24
	end
	if shape == "plaza" then
		local radius = math.max(2, math.min(tonumber(action.radius) or 4, 10))
		return math.min((radius * 2 + 1) * (radius * 2 + 1) + 2, 48)
	end
	return 2
end

local function build_resource_for(shape, action)
	local requested = tostring(action.material or "stone")
	if requested == "" or not palette[requested] then
		requested = "stone"
	end
	if requested == "light" then
		return "wood"
	end
	if shape == "road" or shape == "plaza" then
		return "stone"
	end
	return requested
end

local function build_note_for(shape, action, resource)
	local requested = tostring(action.material or "")
	if requested == "light" then
		return " / 照明は wood で作成"
	end
	if shape == "tower" or shape == "house" or shape == "plaza" or shape == "marker" or shape == "" then
		return " / 照明込み"
	end
	return ""
end

local function apply_action(action)
	local agent_id = tonumber(action.agent_id) or 1
	local agent = ensure_agent(agent_id, action.agent_name)
	local kind = tostring(action.action or action.type or "say")
	agent.last_action = kind
	last_action = action

	if kind == "say" then
		local message = tostring(action.message or "")
		if message ~= "" then
			agent.last_message = message
			civic_chat(agent, message)
		end
	elseif kind == "move" then
		local direction = tostring(action.direction or "east")
		local delta = directions[direction] or directions.east
		local steps = math.max(1, math.min(tonumber(action.steps) or 1, 16))
		local current = agent_position(agent)
		local target = {
			x = round_coord(current.x) + delta.x * steps,
			y = current.y + delta.y * steps,
			z = round_coord(current.z) + delta.z * steps,
		}
		local pos = stand_pos_near(target, agent_key(agent.id))
		set_agent_position(agent, pos)
		civic_chat(agent, "移動しました: " .. direction .. " x" .. tostring(steps))
	elseif kind == "mine" then
		local requested = tostring(action.material or "")
		local mined, total = mine_near_agent(agent, requested ~= "" and requested or "wood", action.count)
		if requested == "" and total == 0 then
			mined, total = mine_near_agent(agent, "stone", action.count)
		end
		if requested == "" and total == 0 then
			mined, total = mine_near_agent(agent, "grass", action.count)
		end
		if total > 0 then
			agent.last_action = "mine"
			civic_chat(agent, "採掘しました: " .. format_inventory_delta(mined))
		else
			agent.last_action = "mine_empty"
			civic_chat(agent, "近くで採掘できる資源が見つかりませんでした。少し移動して探します。")
		end
	elseif kind == "build" then
		local pos, surface = stand_pos_near(agent_position(agent), agent_key(agent.id))
		set_agent_position(agent, pos)
		local base = { x = pos.x, y = surface.surface_y, z = pos.z }
		local node = material_for(action, agent)
		local shape = tostring(action.shape or "marker")
		local resource = build_resource_for(shape, action)
		local cost = build_cost_for(shape, action)
		local ok, available = consume_inventory(agent, resource, cost)
		if not ok then
			agent.last_action = "build_blocked"
			civic_chat(agent, "資源が足りません: " .. resource .. " " .. tostring(available) .. "/" .. tostring(cost) .. "。先に採掘します。")
		else
			if shape == "tower" then
				build_tower(base, node, math.max(3, math.min(tonumber(action.height) or 6, 16)))
			elseif shape == "wall" then
				build_wall(base, node, math.max(2, math.min(tonumber(action.width) or 5, 12)))
			elseif shape == "road" then
				build_road(base, tostring(action.direction or "east"), math.max(4, math.min(tonumber(action.length) or 12, 32)))
			elseif shape == "house" then
				build_house(base, node)
			elseif shape == "plaza" then
				build_plaza(base, node, math.max(2, math.min(tonumber(action.radius) or 4, 10)))
			else
				set_node({ x = base.x, y = base.y, z = base.z }, node)
				set_node({ x = base.x, y = base.y + 1, z = base.z }, "default:torch")
			end
			local standby = stand_pos_near({ x = base.x + 2, y = pos.y, z = base.z + 2 }, agent_key(agent.id))
			set_agent_position(agent, standby)
			civic_chat(agent, "建築しました: " .. shape .. " / " .. tostring(action.label or "district") .. " / 消費 " .. resource .. " x" .. tostring(cost) .. build_note_for(shape, action, resource))
		end
	end
	processed_count = processed_count + 1
	write_state()
end

local function process_action_file(filename)
	local path = actions_dir .. "/" .. filename
	local handle = io.open(path, "r")
	if not handle then
		return
	end
	local index = 0
	for line in handle:lines() do
		index = index + 1
		if line and line ~= "" then
			local action = minetest.parse_json(line)
			if type(action) == "table" then
				local id = tostring(action.id or (filename .. ":" .. index))
				if not processed[id] then
					processed[id] = true
					apply_action(action)
				end
			end
		end
	end
	handle:close()
end

local function process_actions()
	local files = minetest.get_dir_list(actions_dir, false) or {}
	table.sort(files)
	for _, filename in ipairs(files) do
		if filename:sub(-6) == ".jsonl" then
			process_action_file(filename)
		end
	end
end

minetest.register_on_mods_loaded(function()
	load_previous_state()
	if not load_processed() and previous_processed_count > 0 then
		seed_existing_actions_as_processed()
	end
	ensure_ground()
	ensure_starter_forest()
	clear_legacy_static_objects_once()
	for id, profile in pairs(profiles) do
		ensure_agent(id, profile.name)
	end
	minetest.after(2, function()
		prune_duplicate_agents()
		write_state()
	end)
	write_state()
	minetest.log("action", "[" .. modname .. "] bridge ready at " .. bridge_dir)
end)

minetest.register_on_chat_message(function(name, message)
	append_chat("player", name, message)
	write_state()
	return false
end)

minetest.register_chatcommand("oni_agents", {
	description = "List ONI-CADIA agents and their current positions.",
	func = function(name)
		local lines = {}
		local keys = {}
		for key, _ in pairs(agents) do
			table.insert(keys, key)
		end
		table.sort(keys)
		for _, key in ipairs(keys) do
			table.insert(lines, agent_label(key, agents[key]))
		end
		if #lines == 0 then
			return false, "No ONI-CADIA agents are loaded yet."
		end
		minetest.chat_send_player(name, "ONI-CADIA agents:\n" .. table.concat(lines, "\n"))
		return true
	end,
})

minetest.register_chatcommand("oni_tp", {
	params = "<agent id|name>",
	description = "Teleport near an ONI-CADIA agent. Examples: /oni_tp 1, /oni_tp agent_001, /oni_tp いおり",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player is not available."
		end
		local key = agent_lookup_key(param)
		if not key or not agents[key] then
			return false, "Agent not found. Use /oni_agents to list agents."
		end
		local agent = agents[key]
		local agent_pos = object_pos(agent.object) or agent.pos
		local target = stand_pos_near({ x = agent_pos.x + 2, y = agent_pos.y, z = agent_pos.z + 1 }, nil)
		player:set_pos(target)
		return true, "Teleported near " .. agent_label(key, agent)
	end,
})

minetest.register_chatcommand("oni_spawn", {
	description = "Teleport to the natural surface near the ONI-CADIA origin.",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player is not available."
		end
		player:set_pos(stand_pos_near({ x = 0, y = 0, z = 0 }, nil))
		return true, "Teleported to the natural ONI-CADIA surface."
	end,
})

local function move_player_to_surface_if_needed(player)
	if not player then
		return
	end
	local pos = player:get_pos()
	if not pos or pos.y > surface_search_max_y + 8 or not ground_info(pos).grounded then
		player:set_pos(stand_pos_near({ x = 0, y = 0, z = 0 }, nil))
	end
end

local function register_joined_agent_player(player)
	if not player then
		return false
	end
	local name = player:get_player_name()
	local agent_id = agent_id_for_username(name)
	if not agent_id then
		return false
	end
	local key = agent_key(agent_id)
	local profile = profile_for(agent_id)
	configure_agent_player(player, agent_id)
	local pos = stand_pos_near(player:get_pos() or profile.origin, key)
	player:set_pos(pos)
	agents[key] = {
		id = agent_id,
		name = profile.name,
		username = profile.username,
		pos = copy_pos(pos),
		object = nil,
		inventory = agents[key] and ensure_inventory(agents[key]) or table_copy(persisted_agent_inventories[key]),
		last_action = "join",
	}
	write_state()
	return true
end

local function snap_connected_agent_players_to_surface()
	for id, profile in pairs(profiles) do
		local player = minetest.get_player_by_name(profile.username)
		if player then
			local key = agent_key(id)
			configure_agent_player(player, id)
			local pos = player:get_pos()
			if not ground_info(pos).grounded then
				pos = stand_pos_near(pos or profile.origin, key)
				player:set_pos(pos)
			end
			agents[key] = agents[key] or {
				id = id,
				name = profile.name,
				username = profile.username,
				pos = copy_pos(pos),
				object = nil,
				inventory = table_copy(persisted_agent_inventories[key]),
				last_action = "player",
			}
			agents[key].id = id
			agents[key].name = profile.name
			agents[key].username = profile.username
			agents[key].pos = copy_pos(player:get_pos())
		end
	end
end

minetest.register_on_newplayer(function(player)
	minetest.after(0.5, function()
		ensure_player_privs(player)
		if not register_joined_agent_player(player) then
			move_player_to_surface_if_needed(player)
		end
	end)
end)

minetest.register_on_joinplayer(function(player)
	minetest.after(0.8, function()
		ensure_player_privs(player)
		if not register_joined_agent_player(player) then
			move_player_to_surface_if_needed(player)
		end
	end)
end)

minetest.register_on_respawnplayer(function(player)
	player:set_pos(stand_pos_near({ x = 0, y = 0, z = 0 }, nil))
	return true
end)

minetest.register_globalstep(function(dtime)
	tick = tick + dtime
	if tick >= 1.0 then
		tick = 0
		snap_connected_agent_players_to_surface()
		process_actions()
		write_state()
	end
end)
