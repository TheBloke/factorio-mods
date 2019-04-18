local function get_copy(search)
  return table.deepcopy(data.raw[search])
end

local function new_entity_table(name, icons, colour)
  if colour then
    name = "graphtool-" .. colour .. "-" .. name
  else
    name = "graphtool-" .. name
  end
  return {
    type       = "simple-entity",
    name       = name,
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

local function get_icon(entity_table, icon_border)
  -- Layer our modded icon (red or green border) on top of the original icon(s).
  local icons
  if entity_table.icon then
    if icon_border then
      icons =
        {
          { icon = entity_table.icon },
          icon_border
        }
    else
      icons = { { icon = entity_table.icon } }
    end
  elseif entity_table.icons then
    icons = entity_table.icons
    if icon_border then
      table.insert(icons, icon_border)
    end
  else
    return nil
  end
  return icons
end

local function add_entities(item_table)
  local colour_icon =
    {
      ["red"]   = { icon = "__GraphTool__/graphics/icons/red_border.png"  },
      ["green"] = { icon = "__GraphTool__/graphics/icons/green_border.png"  }
    }
  for entity_name, entity_table in pairs(item_table) do
    -- Add entities without colour border for handling merged signals
    local icons = get_icon(entity_table)
    data:extend{new_entity_table(entity_name, icons)}
    -- Add one entity per colour for spearated signals
    for colour, icon_border in pairs(colour_icon) do
      if not entity_table.icon and not entity_table.icons then break end
      local icons = get_icon(entity_table, icon_border)
      if not icons then break end -- Ignore any entity that has no icon(s).
      data:extend{new_entity_table(entity_name, icons, colour)}
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
