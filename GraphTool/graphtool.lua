require 'mod-gui'
local Entity = require('__stdlib__/stdlib/entity/entity')
local Gui = require('__stdlib__/stdlib/event/gui')
local table = require('__stdlib__/stdlib/utils/table')
local Event = require('__stdlib__/stdlib/event/event')

local gui_build = require('gui_build')

local function get_player_data(player_index)
    if global.player_data == nil then
        global.player_data = {}
    end
    local player_data = global.player_data[player_index] or {}
    return player_data
end

local function set_player_data(player_index, data)
    if global.player_data == nil then
        global.player_data = {}
    end
    global.player_data[player_index] = data
end

local Graphtool =
  {
    _cache = {},
    __call = function(self, ...)
      return self.get(...)
    end
  }

local GP_meta =
  {
    __index = Graphtool
  }

local colours =
  {
    ["red"] = defines.wire_type.red,
    ["green"] = defines.wire_type.green
  }

setmetatable(Graphtool, Graphtool)

function Graphtool.metatable(GP)
  setmetatable(GP, GP_meta)
end

function Graphtool.get(...)
  local entity = ...
  return Graphtool._cache[entity] or Graphtool.new(entity)
end

function Graphtool.new(entity)
  local GP =
    {
      items = {},
      ui = {},
      config = {},
      entity = nil,
      pole = nil,
      stats = nil
    }

  Graphtool._cache[entity.unit_number] = nil

  GP.entity = entity
  GP.pole = entity.surface.create_entity{name="graphtool-hiddenpole",
                                            position = {x = entity.position.x, y = entity.position.y},
                                            force = entity.force}
  GP.stats = GP.pole.electric_network_statistics

  setmetatable(GP, GP_meta)
  Graphtool._cache[entity.unit_number] = GP

  return GP
end

function Graphtool:destroy(player_index)
  self:removeGui(player_index)
  self.stats = nil
  self.pole.destroy()
  Graphtool._cache[self.entity] = nil
end

function Graphtool:onTick()
  for colour, wire in pairs(colours) do
    local network = self.entity.get_circuit_network(wire)
    if network then
      if network.signals then
        for _, signal in ipairs(network.signals) do
          self.stats.on_flow("graphtool-" .. colour .. "-" .. signal.signal.name, signal.count/60)
          self.items[signal.signal.name] = {item_type = signal.signal.type, item_count=signal.count}
        end
      end
    end
  end
end

function Graphtool:removeGui(player_index)
  if self.ui[player_index] and self.ui[player_index].root and self.ui[player_index].root["Graphtool"] then
    self.ui[player_index].root["Graphtool"].destroy()
    if self.events then
      for _, event in pairs(self.events) do
        Event.remove(table.unpack(event))
      end
    end
  end
end

local onEvent =
  {
    __call = function(self, ...)
      return self.on(...)
    end,
    __index = onEvent
  }

function onEvent:itemButton(event)
  log("onEvent:on, event: " .. serpent.block(event))
  self.element = event.element
  self.player_index = element.player_index
  self.GP = get_player_data(player_index)
end

local onEvent = {}
local doEvent = {}

local onEvent_mt =
  {
    __index = function(_, k)
      if doEvent[k] then
        return function(event)
          local element = event.element
          local player_index = element.player_index
          local GP = get_player_data(player_index)
          return doEvent[k](element, GP, player_index)
        end
       end
    end
  }

setmetatable(onEvent, onEvent_mt)

function doEvent.itemButton(element, GP, player_index)
  log("in itemButton")
  local tableRow = GP.ui[player_index].root["Graphtool"]["tableFrame"]["itemScroll"]["tableRow"]
  tableRow.clear()
  for item_name, item_table in pairs(GP.items) do
    tableRow.add{type = "choose-elem-button", elem_type = "signal", signal = {type=item_table.item_type, name=item_name} }
    tableRow.add{type = "label", name = item_name .. "-type", caption = item_table.item_type}
    tableRow.add{type = "label", name = item_name .. "-name", caption = item_name}
  end
  log("done itemButton")
end

local function gui_layout()
  return
    {
      { type = "frame",                 name = "Graphtool", caption = "Graphtool", direction = "vertical" , children =
        {
          { type = "frame",               name = "configFrame", caption = "Configuration", direction = "vertical", children =
            {
              { type = "flow",            name = "configRow1", direction = "horizontal", children =
                {
                  { type = "label",       name = "label-Graphing", caption = "Graphing" },
                  { type = "radiobutton", name = "radio-Graphing-on", caption = "On", state = true },
                  { type = "radiobutton", name = "radio-Graphing-off", caption = "Off", state = false },
                }
              },
              { type = "flow",            name = "configRow2", direction="horizontal", children =
                {
                  { type = "label",       name = "label-Ticks", caption = "Ticks per read" },
                  { type = "textfield",   name = "text-Ticks", text = "1", vertical_align = "center", vertically_stretchable = true,
                                          style = { width=25, vertical_align="center" } },
                  { type = "slider",      name = "slider-Ticks", minimum_value = 1, maximum_value = 60, value = 1,
                                          style = { vertical_align = "center" } },
                },
              },
              { type = "flow",            name = "configRow3", direction="horizontal", children =
                {
                  { type = "label",       name = "label-Filename", caption = "CSV Filename" },
                  { type = "textfield",   name = "text-Filename", caption = "CSV Filename" }
                }
              }
            }
          },
          { type = "frame",               name = "tableFrame", caption = "Items", direction = "horizontal", children =
            {
              { type = "flow",            name = "itemButtonRow", direction = "horizontal", children =
                {
                  { type = "button",      name = "itemButton", caption = "Items", callback = onEvent.itemButton }
                }
              },
              { type = "scroll-pane",     name = "itemScroll", direction = "vertical", children =
                {
                  { type = "table",       name = "tableRow", direction = "horizontal", column_count = 3 }
                }
              },
            }
          }
        }
      }
    }
end

function Graphtool:createGui(player_index)
  local player = game.players[player_index]
  if not self.ui[player_index] then
    self.ui[player_index] = {}
  else
    if self.ui[player_index].root and self.ui[player_index].root["Graphtool"] then
      self.ui[player_index].root["Graphtool"].destroy()
    end
  end

  local UI = self.ui[player_index]

  --UI.root = player.gui.left
  UI.root = mod_gui.get_frame_flow(player)

  self.events = {}
  gui_build.gui_elem_iter(gui_layout(), UI.root, self.events)
  log("self.events : " .. serpent.block(self.events))

  set_player_data(player_index, self)
end


return Graphtool
