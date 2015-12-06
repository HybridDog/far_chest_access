local load_time_start = os.clock()


local get = vector.get_data_from_pos
local set = vector.set_data_to_pos
local remove = vector.remove_data_from_pos

-- cache known chest positions with an abm
local known_chests = {}
minetest.register_abm({
	nodenames = {"default:chest"},
	interval = 10,
	chance = 1,
	catch_up = false,
	action = function(pos)
		if not get(known_chests, pos.z,pos.y,pos.x) then
			set(known_chests, pos.z,pos.y,pos.x, true)
		end
	end,
})

-- tests if there's a chest node
local function chest_exists(pos)
	local chest = minetest.get_node(pos).name
	if chest == "ignore" then
		minetest.get_voxel_manip():read_from_map(pos, pos)
		chest = minetest.get_node_or_nil(pos)
		if not chest then
			return false
		end
		chest = chest.name
	end
	return chest == "default:chest"
end

local function vecsort(a,b)
	return vector.length(a) < vector.length(b)
end

-- returns the formspec showing chest positions relative to the fca
local function get_select_formspec(pos)
	local ps,num = {},1
	for _,c in pairs(vector.get_data_pos_table(known_chests)) do
		local z,y,x = unpack(c)
		local p = {x=x, y=y, z=z}
		if not chest_exists(p) then
			-- removes not existing chests from the cache table
			remove(known_chests, z,y,x)
		else
			p = vector.subtract(p, pos)
			ps[num] = p
			num = num+1
		end
	end
	num = num-1
	table.sort(ps, vecsort)
	local spec = "size[3,1]"..
		"dropdown[0,0;3,1;"..pos.z .." "..pos.y .." "..pos.x ..";"
	for i = 1,num do
		local pos = ps[i]
		spec = spec..pos.x .." "..pos.y .." "..pos.z
		if i ~= num then
			spec = spec..","
		end
	end
	spec = spec..";]"
	return spec
end

-- finds the position of the chest the node directs to
local function get_chest_goal(pos)
	local goal = minetest.get_meta(pos):get_string("goal")
	if goal == "" then
		return
	end
	goal = string.split(goal, " ")
	if #goal ~= 3 then
		return
	end
	local p = {}
	p.z,p.y,p.x = unpack(goal)
	p = vector.apply(p, tonumber)
	if not chest_exists(p) then
		print(dump(p))
		return
	end
	return p
end

local function get_chest_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	return "size[8,9]" ..
		"list[nodemeta:" .. spos .. ";main;0,0.3;8,4;]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]"
end

minetest.register_node("far_chest_accessor:fca", {
	description = "far chest accessor",
	tiles = {"far_chest_accessor.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	sounds = default.node_sound_stone_defaults(),
	on_rightclick = function(pos, _, player)
		local pname = player:get_player_name()
		local p = get_chest_goal(pos)
		local formname,spec
		if not p
		or player:get_player_control().aux1 then
			-- show the chest selection formspec
			formname = "far_chest_accessor:sel_form"
			spec = get_select_formspec(pos)
		else
			-- show the chest's inventory
			formname = "far_chest_accessor:cesform"
			spec = get_chest_formspec(p)
		end
		minetest.show_formspec(pname, formname, spec)
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "far_chest_accessor:sel_form"
	or fields.quit then
		return
	end
	local pos = next(fields)
	if not pos
	or pos == "" then
		minetest.log("error", "[far_chest_accessor] error with field index "..dump(fields))
		return
	end
	local relp = fields[pos]
	local z,y,x = unpack(string.split(pos, " "))
	if not x then
		minetest.log("error", "[far_chest_accessor] error with field index converting "..dump(fields))
		return
	end
	local rx,ry,rz = unpack(string.split(relp, " "))
	if not rz then
		minetest.log("error", "[far_chest_accessor] error with field value converting "..dump(fields))
		return
	end
	local chestpos = {x=x+rx, y=y+ry, z=z+rz}
	if not chest_exists(chestpos) then
		minetest.log("action", "[far_chest_accessor] chest seems to be removed")
		return
	end
	minetest.get_meta({x=x, y=y, z=z}):set_string("goal", z+rz.." "..y+ry.." "..x+rx)
	minetest.chat_send_player(player:get_player_name(), "fca directs to "..minetest.pos_to_string(chestpos))
end)


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[far_chest_accessor] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
