local load_time_start = os.clock()


local function get_chest(goal)
	if goal == "" then
		return
	end
	goal = string.split(goal, " ")
	if #goal ~= 3 then
		return
	end
	local p = {}
	p.x,p.y,p.z = unpack(goal)
	local chest = minetest.get_node(p).name
	if chest == "ignore" then
		vm:sth
		chest = minetest.get_node_or_nil(p)
		if not chest then
			return
		end
		chest = chest.name
	end
	if chest ~= "default:chest" then
		return
	end
	return p
end

minetest.register_node("far_chest_accessor:fca", {
	description = "far chest accessor",
	tiles = {"far_chest_accessor.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	sounds = default.node_sound_stone_defaults(),
	on_rightclick = function()
		local meta = minetest.get_meta(pos)
		local goal = meta:get_string("goal")
		local p = get_chest(goal)
		if not p then
			return
		end
		local chestmeta = minetest.get_meta(p)
		player:inventory_sth
	end,
})



local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[far_chest_accessor] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
