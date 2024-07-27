local S = minetest.get_translator(minetest.get_current_modname())
local moreblocks = minetest.get_modpath("moreblocks")

local concrete = {
    {"white", "White"},
    {"orange", "Orange"},
    {"magenta", "Magenta"},
    {"lightblue", "Lightblue"},
    {"yellow", "Yellow"},
    {"lightgreen", "Lightgreen"},
    {"pink", "Pink"},
    {"dark_grey", "Darkgrey"},
    {"grey", "Grey"},
    {"turquoise", "Turquoise"},
    {"violet", "Violet"},
    {"blue", "Blue"},
    {"brown", "Brown"},
    {"green", "Green"},
    {"red", "Red"},
    {"black", "Black"}
}

for _, concrete in pairs(concrete) do

    minetest.register_node("colored_concrete:" .. concrete[1], {
	    description = S(concrete[2] .. " Concrete"),
	    tiles = {"colored_concrete_" .. concrete[1] .. ".png"},
	    groups = {cracky = 3},
	    sounds = default.node_sound_stone_defaults()
    })

    local dye_string = "dye:" .. concrete[1]
    if minetest.registered_items[dye_string] then
        minetest.register_craft({
            output = "colored_concrete:" .. concrete[1] .. " 8",
            recipe = {
                {"default:gravel", "default:sand", "default:gravel"},
                {"default:sand", "dye:" .. concrete[1], "default:sand"},
                {"default:gravel", "default:sand", "default:gravel"}
            }
        })
    else
        minetest.log("warning", "[colored_concrete]: Not registering craft for 'colored_concrete:" .. concrete[1] .. "_concrete' because 'dye:" .. concrete[1] .. "' is not a registered item!")
    end

    if moreblocks then
        stairsplus:register_all("moreblocks", "colored_concrete_" .. concrete[1], "colored_concrete:" .. concrete[1], {
            description = S(concrete[2] .. " Concrete"),
            tiles = {"colored_concrete_" .. concrete[1] .. ".png"},
            groups = {cracky = 3},
            sounds = default.node_sound_stone_defaults(),
        })
        if minetest.settings:get_bool("colored_concrete_enable_aliases", true) then
            stairsplus:register_alias_all("moreblocks", "colored_concrete:" .. concrete[1], "moreblocks", "colored_concrete_" .. concrete[1])
        end
    end
end

if minetest.get_modpath("unifieddyes") then
    minetest.register_craft({
        output = "colored_concrete:turquoise 8",
        recipe = {
            {"default:gravel", "default:sand", "default:gravel"},
            {"default:sand", "dye:medium_cyan", "default:sand"},
            {"default:gravel", "default:sand", "default:gravel"}
        }
    })

    minetest.register_craft({
        output = "colored_concrete:lightgreen 8",
        recipe = {
            {"default:gravel", "default:sand", "default:gravel"},
            {"default:sand", "dye:light_green", "default:sand"},
            {"default:gravel", "default:sand", "default:gravel"}
        }
    })

    minetest.register_craft({
        output = "colored_concrete:lightblue 8",
        recipe = {
            {"default:gravel", "default:sand", "default:gravel"},
            {"default:sand", "dye:light_blue", "default:sand"},
            {"default:gravel", "default:sand", "default:gravel"}
        }
    })
end
