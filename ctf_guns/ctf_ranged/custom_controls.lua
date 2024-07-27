-- ctf_range/custom_controls.lua
--> Modified code for scopes to work.
local hud = mhud.init()

local function hide_scopehud(playerobj)
   hud:remove(playerobj)

   playerobj:set_fov(0, false, 0.1)
end

local function show_scopehud(playerobj)
   local w_item = playerobj:get_wielded_item()
   local def = w_item:get_definition()
   local scope_zoom = def.ctf_guns_scope_zoom
   if scope_zoom == nil then
      return
   end

   hud:add(playerobj, "scopehud", {
      hud_elem_type = "image",
      position = {x = 0.5, y = 0.5},
      image_scale = -150,
      z_index = -100,
      texture = "rangedweapons_scopehud.png",
   })

   playerobj:set_fov(scope_zoom, false, 0.1)
end

local scopehud_active = false
controls.register_on_press(function(player, key)
   local def = player:get_wielded_item():get_definition()
   if not def.ammo or not def.groups.ranged or not def.ctf_guns_scope_zoom then
      return
   end
   if key == "RMB" then
      if not scopehud_active then
         show_scopehud(player)
         scopehud_active = true
      else
         hide_scopehud(player)
         scopehud_active = false
      end
   end
end)

minetest.register_on_joinplayer(function(player)
   hide_scopehud(player)
end)