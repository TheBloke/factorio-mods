local function get_copy(search)
  return table.deepcopy(data.raw[search])
end

local function new_entity_table(colour, name, icons)
  return {
    type       = "simple-entity",
    name       = "graphtool-" .. colour .. "-" .. name,
    icons      = icons,
    icon_size  = 32,
    flags      = {"hidden"},
    picture    =
    {
      filename = "__core__/graphics/empty.png",
      priority = "extra-high",
      width    = 1,
      height   = 1
    }
  }
end

local function add_entities(item_table)
  local colour_icon =
    {
      ["red"]   = { icon = "__GraphTool__/graphics/icons/red_border.png"  },
      ["green"] = { icon = "__GraphTool__/graphics/icons/green_border.png"  }
    }
  for entity_name, entity_table in pairs(item_table) do
    -- Layer our modded icon (red or green border) on top of the original icon(s).
    for colour, icon_border in pairs(colour_icon) do
      local icons
      if entity_table.icon then
        icons =
          {
            { icon = entity_table.icon },
            icon_border
          }
      elseif entity_table.icons then
        icons = entity_table.icons
        table.insert(icons, icon_border)
      else
        break -- skip any item without an icon or icons.
      end
      data:extend{new_entity_table(colour, entity_name, icons)}
    end
  end
end

local search_list = 
  {
    "fluid", "virtual-signal", "item", "item-with-entity-data",
    "rail-planner", "capsule", "repair-tool", "upgrade-item",
    "module", "tool", "gun", "ammo", "armor",
    "deconstruction-item", "selection-tool", "blueprint-book"
  }

for _, search in ipairs(search_list) do
  add_entities(get_copy(search))
end
