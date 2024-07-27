
--[[
	Original textures from DocFarming mod
	https://forum.minetest.net/viewtopic.php?id=3948
]]

local S = farming.translate

-- cucumber
minetest.register_craftitem("farming:cucumber", {
	description = S("Cucumber"),
	inventory_image = "farming_cucumber.png",
	groups = {
		compostability = 48, seed = 2, food_cucumber = 1, flammable = 2
	},
	on_place = function(itemstack, placer, pointed_thing)
		return farming.place_seed(itemstack, placer, pointed_thing, "farming:cucumber_1")
	end,
	on_use = minetest.item_eat(4)
})

farming.add_eatable("farming:cucumber", 4)

-- cucumber definition
local def = {
	drawtype = "plantlike",
	tiles = {"farming_cucumber_1.png"},
	paramtype = "light",
	walkable = false,
	buildable_to = true,
	drop = "",
	selection_box = farming.select,
	groups = {
		handy = 1, snappy = 3, flammable = 2, plant = 1, attached_node = 1,
		not_in_creative_inventory = 1, growing = 1
	},
	_mcl_hardness = farming.mcl_hardness,
	is_ground_content = false,
	sounds = farming.sounds.node_sound_leaves_defaults()
}

-- stage 1
minetest.register_node("farming:cucumber_1", table.copy(def))

-- stage 2
def.tiles = {"farming_cucumber_2.png"}
minetest.register_node("farming:cucumber_2", table.copy(def))

-- stage 3
def.tiles = {"farming_cucumber_3.png"}
minetest.register_node("farming:cucumber_3", table.copy(def))

-- stage 4 (final)
def.tiles = {"farming_cucumber_4.png"}
def.groups.growing = nil
def.selection_box = farming.select_final
def.drop = {
	items = {
		{items = {"farming:cucumber 2"}, rarity = 1},
		{items = {"farming:cucumber 2"}, rarity = 2}
	}
}
minetest.register_node("farming:cucumber_4", table.copy(def))

-- add to registered_plants
farming.registered_plants["farming:cucumber"] = {
	crop = "farming:cucumber",
	seed = "farming:cucumber",
	minlight = farming.min_light,
	maxlight = farming.max_light,
	steps = 4
}

-- mapgen
local mg = farming.mapgen == "v6"

def = {
	near = mg and "group:water" or nil,
	num = mg and 1 or -1,
}

minetest.register_decoration({
	deco_type = "simple",
	place_on = {"default:dirt_with_grass", "mcl_core:dirt_with_grass"},
	sidelen = 16,
	noise_params = {
		offset = 0,
		scale = farming.cucumber,
		spread = {x = 100, y = 100, z = 100},
		seed = 245,
		octaves = 3,
		persist = 0.6
	},
	y_min = 1,
	y_max = 20,
	decoration = "farming:cucumber_4",
	spawn_by = def.near,
	num_spawn_by = def.num
})