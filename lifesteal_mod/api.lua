local storage = minetest.get_mod_storage()
local dead_players = {}

function lifesteal_mod.change_hp_max(player, hp, hp_max, change_now)
    player:set_properties({hp_max = hp_max})
	if change_now then
		player:set_hp(hp)
    end

    if minetest.get_modpath("hudbars") then
        hb.change_hudbar(player, "health", player:get_hp(), hp_max)
    end

    local meta = player:get_meta()
    meta:set_int("health", hp_max)
end

if storage:get_string("lifesteal_mod.dead_players") ~= "" then
    dead_players = minetest.deserialize(storage:get_string("lifesteal_mod.dead_players"))
end

function lifesteal_mod.add_player(player)
    dead_players[player] = true

    storage:set_string("lifesteal_mod.dead_players", minetest.serialize(dead_players))
end

function lifesteal_mod.remove_player(player)
    dead_players[player] = nil

    storage:set_string("lifesteal_mod.dead_players", minetest.serialize(dead_players))
end

function lifesteal_mod.is_player_dead(p_name)
    for name, _ in pairs(dead_players) do
        if name == p_name then
            return true, p_name
        end
    end
    return false
end

function lifesteal_mod.handle_newplayer(p_name) --> When new player joins.
    minetest.after(0.1, function()
        local player = minetest.get_player_by_name(p_name)
        
        if not player then return end

        local meta = player:get_meta()

	    local health = meta:get_int("health")
	    if (not health == nil) or health <= 0 or not meta:contains("lifesteal_mod.newplayer") then
		    meta:set_int("health", 20) --> Set the new player's max to a 20hp (10 hearts).
	    end

        meta:set_string("lifesteal_mod.newplayer", "true")
	    lifesteal_mod.change_hp_max(player, health, player:get_properties().hp_max, true)
    end)
end