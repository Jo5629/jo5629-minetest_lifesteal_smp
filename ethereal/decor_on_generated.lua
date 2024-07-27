
local random = math.random

-- Generate Illumishroom in caves on top of coal
local function generate(minp, maxp)

	if minp.y > -30 or maxp.y < -3000 then
		return
	end

	local coal = minetest.find_nodes_in_area_under_air(
			minp, maxp, "default:stone_with_coal")

	for n = 1, #coal do

		if random(2) == 1 then

			local bpos = {x = coal[n].x, y = coal[n].y + 1, z = coal[n].z}

			if bpos.y > -3000 and bpos.y < -2000 then
				minetest.set_node(bpos, {name = "ethereal:illumishroom3"})
			elseif bpos.y > -2000 and bpos.y < -1000 then
				minetest.set_node(bpos, {name = "ethereal:illumishroom2"})
			elseif bpos.y > -1000 and bpos.y < -30 then
				minetest.set_node(bpos, {name = "ethereal:illumishroom"})
			end
		end
	end
end

if minetest.save_gen_notify then -- async env (5.9+)
	minetest.register_on_generated(function(vmanip, minp, maxp, blockseed)
		generate(minp, maxp)
	end)
else -- main thread (5.8 and earlier)
	minetest.register_on_generated(function(minp, maxp, blockseed)
		generate(minp, maxp)
	end)
end