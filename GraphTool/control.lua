require 'mod-gui'
local Entity = require('__stdlib__/stdlib/entity/entity')

local Logger = require '__stdlib__/stdlib/misc/logger'
LOG = Logger.new('graphtool', 'main', 'true', {force_append=true})

local Csv = require 'csv'

local graphtool = require 'graphtool'

local colours =
  {
    ["red"] = defines.wire_type.red,
    ["green"] = defines.wire_type.green
  }

local function onPlaceEntity(event)
  local entity = event.created_entity or event.entity
  if not entity.valid then
    LOG.log("onPlaceEntity: invalid entity?")
    return
  end

  if entity.name == 'graphtool' then
    LOG.log("onPlaceEntity: Got new entity.")
    if not global.graphtool_entities then global.graphtool_entities = {} end
    --if not global.graphtool_items then global.graphtool_items = {} end
    graphtool.new(entity)
    --local csv = Csv("test1")
    global.graphtool_entities[entity.unit_number] = entity
  end
end

local function onRemoveEntity(event)
  local eventEntity = event.entity
  if eventEntity.name == 'graphtool' then
    LOG.log("onRemoveEntity: Found entity to remove")
    local entity = global.graphtool_entities[eventEntity.unit_number]
    if entity then
      graphtool.destroy(entity)
      global.graphtool_entities[eventEntity.unit_number] = nil
    end
  end
end

local function onTick(event)
  if not global.graphtool_entities then return end

  for _, graphtool in pairs(global.graphtool_entities) do
    local state = Entity.get_data(graphtool)
    for colour, wire in pairs(colours) do
      local network = graphtool.get_circuit_network(wire)
      if network then
        if network.signals then
          for _, signal in ipairs(network.signals) do
            state.stats.on_flow("graphtool-" .. colour .. "-" .. signal.signal.name, signal.count/60)
            local signal_type = signal.signal.type
            --if signal_type == 'virtual' then signal_type = 'signal' end
            state.items[signal.signal.name] = {item_type = signal_type, item_count=signal.count}
            --graphtool.csv.log(signal.signal.name, signal.count)
          end
        end
      end
    end
  end
end

local function doGui(player, entity)
  local ui = {}
  ui.top = player.gui.top
  if ui.top.GraphTool then ui.top.GraphTool.destroy() end

  local topframe = ui.top.add{type = "frame", name = "GraphTool", caption = "GraphTool", direction="vertical"}
  local configFrame = topframe.add{type = "frame", name = "configFrame", caption = "Configuration", direction = "vertical"}

  local configRow1 = configFrame.add{type = "flow", direction="horizontal"}

  local toggleBoxCaption = configRow1.add{type = "label", caption = "Graphing"}
  local c1t = configRow1.add{type = "radiobutton", caption = "On", state = true}
  local c1t = configRow1.add{type = "radiobutton", caption = "Off", state = false}

  local configRow2 = configFrame.add{type = "flow", direction="horizontal"}

  local periodBoxCaption = configRow2.add{type = "label", caption = "Ticks per read"}
  local periodField = configRow2.add{type = "textfield", text = "1", vertical_align = "center", vertically_stretchable = true }
  periodField.style.width = 25
  periodField.style.vertical_align = "center"
  local periodSlider = configRow2.add{type = "slider", minimum_value = 1, maximum_value = 60, value=1}
  periodSlider.style.vertical_align = "center"

  local configRow3 = configFrame.add{type = "flow", direction="horizontal"}

  local csvNameCaption = configRow3.add{type = "label", caption = "CSV Filename"}
  local csvName = configRow3.add{type = "textfield", name = "csvName", caption = "CSV Filanem"}

  local tableFrame = topframe.add{type = "frame", name = "tableFrame", caption = "Items", direction = "horizontal"}
  local itemScroll =tableFrame.add{type = "scroll-pane", caption = "Items", direction = "vertical"}
  local tableRow = itemScroll.add{type = "table", name = "testTable",
                                 direction = "horizontal", column_count = 3}
  local state = Entity.get_data(entity)
  for item_name, item_table in pairs(state.items) do
    tableRow.add{type = "choose-elem-button", elem_type = "signal", signal = {type=item_table.item_type, name=item_name} }
    tableRow.add{type = "label", name = item_name .. "-type", caption = item_table.item_type}
    tableRow.add{type = "label", name = item_name .. "-name", caption = item_name}
  end
end

local function onGui(event)
  local entity
  if event.entity then
    if event.entity.name == "graphtool" then
      doGui(game.players[event.player_index], event.entity)
    end

  end
end

local function closeGui(event)
  local entity
  if event.entity then
    if event.entity.name == "graphtool" then
      doGui(game.players[event.player_index], event.entity)
    end
  end
end

local function config_changed(event)
  log("Got config changed.")
end

local evs = defines.events
script.on_event({evs.on_built_entity,evs.on_robot_built_entity}, onPlaceEntity)
script.on_event({evs.on_entity_died, evs.on_pre_player_mined_item, evs.robot_pre_mined, evs.script_raised_destroy}, onRemoveEntity)
script.on_event(evs.on_tick, onTick)
script.on_event(evs.on_gui_opened, onGui)
script.on_event(defines.events.on_gui_closed, closeGui)

script.on_configuration_changed(config_changed)
