--[[

	TechAge
	=======

	Copyright (C) 2019-2022 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	TA2/TA3/TA4 Pusher
	Nodes for push/pull operation of StackItems from chests or other
	inventory/server nodes to tubes or other inventory/server nodes.

                 +--------+
                /        /|
               +--------+ |
     IN (L) -->|        |X--> OUT (R)
               | PUSHER | +
               |        |/
               +--------+

]]--

-- for lazy programmers
local M = minetest.get_meta
local S = techage.S

-- Consumer Related Data
local CRD = function(pos) return (minetest.registered_nodes[techage.get_node_lvm(pos).name] or {}).consumer end
local Tube = techage.Tube

local STANDBY_TICKS = 2
local COUNTDOWN_TICKS = 4
local CYCLE_TIME = 2

local WRENCH_MENU = {
	{
		type = "number",
		name = "limit",
		label = S("Number of items"),
		tooltip = S("Number of items that are allowed to be pushed"),
		default = "0",
	},
}

local function ta4_formspec(self, pos, nvm)
	if CRD(pos).stage == 4 then -- TA4 node?
		return "size[8,7.2]"..
			default.gui_bg..
			default.gui_bg_img..
			default.gui_slots..
			"box[0,-0.1;7.8,0.5;#c6e8ff]"..
			"label[3,-0.1;"..minetest.colorize("#000000", S("Pusher")).."]"..
			techage.question_mark_help(7.5, S("Optionally configure\nthe pusher with one item"))..
			techage.wrench_image(7.4, -0.05) ..
			"list[context;main;3.5,0.8;1,1;]"..
			"image_button[3.5,2;1,1;".. self:get_state_button_image(nvm) ..";state_button;]"..
			"tooltip[3.5,2;1,1;"..self:get_state_tooltip(nvm).."]"..
			"list[current_player;main;0,3.5;8,4;]"..
			"listring[context;main]"..
			"listring[current_player;main]"
	end
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	local nvm = techage.get_nvm(pos)
	if CRD(pos).State:get_state(nvm) ~= techage.STOPPED then
		return 0
	end

	local inv = M(pos):get_inventory()
	local list = inv:get_list(listname)
	if list[index]:get_count() == 0 then
		stack:set_count(1)
		inv:set_stack(listname, index, stack)
		return 0
	end
	return 0
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end

	local nvm = techage.get_nvm(pos)
	if CRD(pos).State:get_state(nvm) ~= techage.STOPPED then
		return 0
	end

	local inv = M(pos):get_inventory()
	inv:set_stack(listname, index, nil)
	return 0
end

local function set_limit(pos, nvm, val)
	val = tonumber(val) or 0
	if val > 0 then
		nvm.limit = val
		nvm.num_items = 0
		M(pos):set_int("limit", val)
	else
		nvm.limit = nil
		nvm.num_items = nil
		M(pos):set_string("limit", "")
	end
end

-- Function returns the number of pushed items
local function push(pos, crd, meta, nvm, pull_dir, push_dir, num)
	local items = techage.pull_items(pos, pull_dir, num, nvm.item_name)
	if items ~= nil then
		local taken = items:get_count()
		local leftover = techage.push_items(pos, push_dir, items)
		if not leftover then
			-- place item back
			techage.unpull_items(pos, pull_dir, items)
			crd.State:blocked(pos, nvm)
			return 0
		elseif leftover ~= true then
			-- place item back
			taken = taken - leftover:get_count()
			techage.unpull_items(pos, pull_dir, leftover)
			crd.State:blocked(pos, nvm)
			return taken
		end
		return taken
	end
	crd.State:idle(pos, nvm)
	return 0
end

local function pushing(pos, crd, meta, nvm)
	local pull_dir = meta:get_int("pull_dir")
	local push_dir = meta:get_int("push_dir")

	if not nvm.limit then
		local num = nvm.item_count or nvm.num_items or crd.num_items
		num = push(pos, crd, meta, nvm, pull_dir, push_dir, num)
		if num > 0 then
			if nvm.item_count then
				nvm.item_count = nvm.item_count - num
				if nvm.item_count <= 0 then
					crd.State:stop(pos, nvm)
					nvm.item_count = nil
				end
			end
			crd.State:keep_running(pos, nvm, COUNTDOWN_TICKS)
		end
	elseif nvm.num_items < nvm.limit then
		local num = math.min(crd.num_items, nvm.limit - nvm.num_items)
		num = push(pos, crd, meta, nvm, pull_dir, push_dir, num)
		if num > 0 then
			nvm.num_items = nvm.num_items + num
			if nvm.num_items >= nvm.limit then
				crd.State:stop(pos, nvm)
			else
				crd.State:keep_running(pos, nvm, COUNTDOWN_TICKS)
			end
		end
	end
end

local function keep_running(pos, elapsed)
	local nvm = techage.get_nvm(pos)
	local crd = CRD(pos)
	pushing(pos, crd, M(pos), nvm)
	crd.State:is_active(nvm)
end

local function on_rightclick(pos, node, clicker)
	if CRD(pos).stage ~= 4 then -- Not TA4 node?
		local nvm = techage.get_nvm(pos)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			if CRD(pos).State:get_state(nvm) == techage.STOPPED then
				CRD(pos).State:start(pos, nvm)
			else
				CRD(pos).State:stop(pos, nvm)
			end
		end
	end
end

local function on_receive_fields(pos, formname, fields, player)
	if CRD(pos).stage == 4 then -- TA4 node?
		if minetest.is_protected(pos, player:get_player_name()) then
			return
		end
		local nvm = techage.get_nvm(pos)
		CRD(pos).State:state_button_event(pos, nvm, fields)
		M(pos):set_string("formspec", ta4_formspec(CRD(pos).State, pos, nvm))
	end
end

local function tubelib2_on_update2(pos, outdir, tlib2, node)
	local pull_dir = M(pos):get_int("pull_dir")
	local push_dir = M(pos):get_int("push_dir")
	local is_ta4_tube = true

	for i, pos, node in Tube:get_tube_line(pos, pull_dir) do
		is_ta4_tube = is_ta4_tube and techage.TA4tubes[node.name]
	end
	for i, pos, node in Tube:get_tube_line(pos, push_dir) do
		is_ta4_tube = is_ta4_tube and techage.TA4tubes[node.name]
	end

	local nvm = techage.get_nvm(pos)
	local crd = CRD(pos)
	if CRD(pos).stage == 4 and not is_ta4_tube then
		nvm.num_items = crd.num_items / 2
	else
		nvm.num_items = crd.num_items
	end
end

local function can_start(pos, nvm, state)
	if CRD(pos).stage == 4 then -- TA4 node?
		local inv = M(pos):get_inventory()
		local name = inv:get_stack("main", 1):get_name()
		if name ~= "" then
			nvm.item_name = name
		else
			nvm.item_name = nil
		end
	else
		nvm.item_name = nil
	end
	return true
end

local function ta_after_formspec(pos, fields, playername)
	local nvm = techage.get_nvm(pos)
	set_limit(pos, nvm, fields.limit)
end

local function on_state_change(pos, old_state, new_state)
	if old_state == techage.STOPPED and new_state == techage.RUNNING then
		local nvm = techage.get_nvm(pos)
		set_limit(pos, nvm,  M(pos):get_int("limit"))
	end
end

local function config_item(pos, payload)
	if type(payload) == "string" then
		if payload == "" then
			local inv = M(pos):get_inventory()
			inv:set_stack("main", 1, nil)
			return 0
		else
			local name, count = unpack(payload:split(" "))
			if name and (minetest.registered_nodes[name] or minetest.registered_items[name]
					or minetest.registered_craftitems[name]) then
				count = tonumber(count) or 1
				local inv = M(pos):get_inventory()
				inv:set_stack("main", 1, {name = name, count = 1})
				return count
			end
		end
	end
	return 0
end

local tiles = {}
-- '#' will be replaced by the stage number
-- '{power}' will be replaced by the power PNG
tiles.pas = {
	"techage_filling_ta#.png^techage_frame_ta#_top.png^techage_appl_arrow.png",
	"techage_filling_ta#.png^techage_frame_ta#_bottom.png^techage_appl_arrow.png",
	"techage_filling_ta#.png^techage_frame_ta#.png^techage_appl_outp.png",
	"techage_filling_ta#.png^techage_frame_ta#.png^techage_appl_inp.png",
	"techage_appl_pusher.png^[transformR180]^techage_frame_ta#.png",
	"techage_appl_pusher.png^techage_frame_ta#.png",
}
tiles.act = {
	-- up, down, right, left, back, front
	"techage_filling_ta#.png^techage_frame_ta#_top.png^techage_appl_arrow.png",
	"techage_filling_ta#.png^techage_frame_ta#_bottom.png^techage_appl_arrow.png",
	"techage_filling_ta#.png^techage_frame_ta#.png^techage_appl_outp.png",
	"techage_filling_ta#.png^techage_frame_ta#.png^techage_appl_inp.png",
	{
		name = "techage_appl_pusher14.png^[transformR180]^techage_frame14_ta#.png",
		backface_culling = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 32,
			aspect_h = 32,
			length = 2.0,
		},
	},
	{
		name = "techage_appl_pusher14.png^techage_frame14_ta#.png",
		backface_culling = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 32,
			aspect_h = 32,
			length = 2.0,
		},
	},
}

local tubing = {
	-- push item through the pusher in opposit direction
	on_push_item = function(pos, in_dir, stack)
		return in_dir == M(pos):get_int("pull_dir") and techage.safe_push_items(pos, in_dir, stack)
	end,
	is_pusher = true, -- is a pulling/pushing node

	on_recv_message = function(pos, src, topic, payload)
		if topic == "pull" then -- Deprecated command, use config/limit/start instead
			local nvm = techage.get_nvm(pos)
			CRD(pos).State:stop(pos, nvm)
			nvm.item_count = math.min(config_item(pos, payload), 12)
			nvm.rmt_num = src
			CRD(pos).State:start(pos, nvm)
			return true
		elseif topic == "config" then  -- Set item type
			local nvm = techage.get_nvm(pos)
			CRD(pos).State:stop(pos, nvm)
			config_item(pos, payload)
			return true
		elseif topic == "limit" then  -- Set push limit
			local nvm = techage.get_nvm(pos)
			CRD(pos).State:stop(pos, nvm)
			set_limit(pos, nvm, payload)
			return true
		elseif topic == "count" then  -- Get number of push items
			local nvm = techage.get_nvm(pos)
			return nvm.num_items or 0
		else
			return CRD(pos).State:on_receive_message(pos, topic, payload)
		end
	end,
	on_beduino_receive_cmnd = function(pos, src, topic, payload)
		if topic == 65 then  -- Set item type
			local nvm = techage.get_nvm(pos)
			CRD(pos).State:stop(pos, nvm)
			config_item(pos, payload)
			return 0
		elseif topic == 68 or topic == 20 then  -- Set push limit
			local nvm = techage.get_nvm(pos)
			CRD(pos).State:stop(pos, nvm)
			set_limit(pos, nvm, payload[1])
			return 0
		else
			local nvm = techage.get_nvm(pos)
			if nvm.limit then
				nvm.num_items = 0
			end
			return CRD(pos).State:on_beduino_receive_cmnd(pos, topic, payload)
		end
	end,
	on_beduino_request_data = function(pos, src, topic, payload)
		if topic == 150 then  -- Get number of pushed items
			local nvm = techage.get_nvm(pos)
			return 0, {nvm.num_items or 0}
		else
			return CRD(pos).State:on_beduino_request_data(pos, topic, payload)
		end
	end,
}

local node_name_ta2, node_name_ta3, node_name_ta4 =
	techage.register_consumer("pusher", S("Pusher"), tiles, {
		cycle_time = CYCLE_TIME,
		standby_ticks = STANDBY_TICKS,
		formspec = ta4_formspec,
		tubing = tubing,
		can_start = can_start,
		on_state_change = on_state_change,
		after_place_node = function(pos, placer)
			local meta = M(pos)
			local node = minetest.get_node(pos)
			meta:set_int("pull_dir", techage.side_to_outdir("L", node.param2))
			meta:set_int("push_dir", techage.side_to_outdir("R", node.param2))
			if CRD(pos).stage == 4 then -- TA4 node?
				local inv = M(pos):get_inventory()
				inv:set_size('main', 1)
				local nvm = techage.get_nvm(pos)
				M(pos):set_string("formspec", ta4_formspec(CRD(pos).State, pos, nvm))
			end
		end,
		ta_rotate_node = function(pos, node, new_param2)
			Tube:after_dig_node(pos)
			minetest.swap_node(pos, {name = node.name, param2 = new_param2})
			Tube:after_place_node(pos)
			local meta = M(pos)
			meta:set_int("pull_dir", techage.side_to_outdir("L", new_param2))
			meta:set_int("push_dir", techage.side_to_outdir("R", new_param2))
		end,
		allow_metadata_inventory_put = allow_metadata_inventory_put,
		allow_metadata_inventory_take = allow_metadata_inventory_take,
		on_rightclick = on_rightclick,
		on_receive_fields = on_receive_fields,
		node_timer = keep_running,
		on_rotate = screwdriver.disallow,
		tubelib2_on_update2 = tubelib2_on_update2,
		ta4_formspec = WRENCH_MENU,
		ta_after_formspec = ta_after_formspec,

		groups = {choppy=2, cracky=2, crumbly=2},
		is_ground_content = false,
		sounds = default.node_sound_wood_defaults(),
		num_items = {0,2,6,12},
		tube_sides = {L=1, R=1},
	})

minetest.register_craft({
	output = node_name_ta2.." 2",
	recipe = {
		{"group:wood", "wool:dark_green", "group:wood"},
		{"techage:tubeS", "default:mese_crystal", "techage:tubeS"},
		{"group:wood", "techage:iron_ingot", "group:wood"},
	},
})

minetest.register_craft({
	output = node_name_ta3,
	recipe = {
		{"", "techage:iron_ingot", ""},
		{"", node_name_ta2, ""},
		{"", "techage:vacuum_tube", ""},
	},
})

minetest.register_craft({
	output = node_name_ta4,
	recipe = {
		{"", "techage:iron_ingot", ""},
		{"", node_name_ta3, ""},
		{"", "techage:ta4_wlanchip", ""},
	},
})
