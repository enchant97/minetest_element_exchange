function get_element_deconstructor_formspec()
    local formspec = {
        "size[8,9]",
        "label[2,1;Fuel]",
        "list[context;fuel;2,2;1,1;]",
        "label[5,1;Orb]",
        "list[context;dst;5,2;1,1;]",
        "list[current_player;main;0,5;8,4;]",
    }
    return table.concat(formspec, "")
end

local function can_dig(pos, player)
    local meta = minetest.get_meta(pos);
    local inv = meta:get_inventory()
    return inv:is_empty("fuel") and inv:is_empty("dst")
end

local function on_timer(pos, elapsed)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local update = true
    while elapsed > 0 and update do
        update = false
        if not inv:is_empty("dst") and not inv:is_empty("fuel") then
            -- remove one item from fuel inventory
            local fuel_stack = inv:get_stack("fuel", 1)
            local energy_value = get_item_energy(fuel_stack:get_name())
            fuel_stack:set_count(fuel_stack:get_count() - 1)
            inv:set_stack("fuel", 1, fuel_stack)

            -- only get 1 orb as we can only use one
            local dest_orb = inv:get_stack("dst", 1)
            local stored = dest_orb:get_meta():get_int("stored_charge") or 0
            stored = stored + energy_value
            dest_orb:get_meta():set_int("stored_charge", stored)
            inv:set_stack("dst", 1, dest_orb)

            update = true
        end
    end
    minetest.get_node_timer(pos):stop()
    return false
end

local function on_construct(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size("fuel", 1)
    inv:set_size("dst", 1)
    meta:set_string("formspec", get_element_deconstructor_formspec())
    meta:set_string("infotext", "Element Deconstructor")
    on_timer(pos, 0)
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0
    end
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if listname == "dst" then
        if stack:get_name() == "element_exchange:exchange_orb" then
            return stack:get_count()
        else
            return 0
        end
    elseif listname == "fuel" then
        return stack:get_count()
    end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local stack = inv:get_stack(from_list, from_index)
    return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0
    end
    return stack:get_count()
end

local function on_blast(pos)
    local drops = {}
    default.get_inventory_drops(pos, "fuel", drops)
    default.get_inventory_drops(pos, "dst", drops)
    drops[#drops+1] = "element_exchange:element_deconstructor"
    minetest.remove_node(pos)
    return drops
end

minetest.register_node("element_exchange:element_deconstructor", {
    description = "Element Deconstructor",
    tiles = {
        "ee_deconstructor_up.png",
        "ee_deconstructor_down.png",
        "ee_deconstructor_right.png",
        "ee_deconstructor_right.png",
        "ee_deconstructor_right.png",
        "ee_deconstructor_right.png"
    },
    groups = {cracky = 2},
    is_ground_content = false,
    can_dig = can_dig,
    on_timer = on_timer,
    on_construct = on_construct,
    on_metadata_inventory_move = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,
    on_metadata_inventory_put = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,
    on_metadata_inventory_take = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,
    on_blast = on_blast,
    allow_metadata_inventory_put = allow_metadata_inventory_put,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
})

minetest.register_craft({
    type = "shaped",
    output = "element_exchange:element_deconstructor",
    recipe = {
        {"", "element_exchange:exchange_orb",""},
        {"element_exchange:exchange_orb", "default:furnace", "element_exchange:exchange_orb"},
        {"", "element_exchange:exchange_orb",  ""}
    }
})
