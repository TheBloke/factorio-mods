local graph = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])

graph.name = "graphtool"
graph.type = "constant-combinator"
graph.item_slot_count = 0
graph.energy_usage = "0kW"
graph.render_no_network_icon = false
graph.render_no_power_icon = false

--data:extend{generate_constant_combinator{graph}}
data:extend({graph})

data:extend({
	{
    type = "item",
    name = "graphtool",
    icon = "__base__/graphics/icons/constant-combinator.png",
    icon_size = 32,
    flags = { },
    subgroup = "circuit-network",
    place_result = "graphtool",
    order = "b[combinators]-u[advanced-combinator]",
    stack_size= 50,
  }
})

local pole = table.deepcopy(data.raw["electric-pole"]["small-electric-pole"])

pole.name = "graphtool-hiddenpole"
pole.icon="__base__/graphics/icons/constant-combinator.png"
pole.corpse = nil
pole.minable = nil
pole.maximum_wire_distance = 0
pole.supply_area_distance = 0.5
pole.fast_replaceable_group = nil
pole.render_no_network_icon = false
pole.render_no_power_icon = false
pole.order="c-c"
pole.draw_copper_wires = false
pole.draw_circuit_wires = false
pole.collision_box = {{0,0}, {0,0}}
pole.selection_box = {{0.0,0.0}, {2.5,2.5}}
pole.drawing_box = {{0,0}, {0,0}}
--pole.connection_points = {}
pole.picture = {
    filename = "__core__/graphics/empty.png",
    priority = "extra-high",
    width = 1,
    height = 1
  }
data:extend{pole}
