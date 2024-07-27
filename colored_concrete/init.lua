-- Minetest colored_concrete Mod (c) 2021-2022 Niklp
-- https://github.com/Niklp09/colored_concrete

local path = minetest.get_modpath("colored_concrete")

dofile(path .. "/register.lua") -- Register Items

if minetest.settings:get_bool("colored_concrete_enable_aliases", true) then
    minetest.register_alias("colored_concrete:darkgray", "colored_concrete:dark_grey")
    minetest.register_alias("colored_concrete:gray", "colored_concrete:grey")

    if minetest.get_modpath("stairsplus") then
        stairsplus.api.register_alias_all("colored_concrete:darkgray", "colored_concrete:dark_gray")
        stairsplus.api.register_alias_all("colored_concrete:gray", "colored_concrete:grey")
    end
end

print("[colored_concrete] loaded")
