--
-- Includes
--
-- factorio
require 'mod-gui'
-- stdlib
local String = require('__stdlib__/stdlib/utils/string')

local evs = defines.events

local Guiconfig =
  {
    __call = function(self, ...)
      return self.new(...)
    end
  }

local Guiconfig_meta =
  {
    __index = Guiconfig
  }

setmetatable(Guiconfig, Guiconfig)

local doEvent = {}

function doEvent.itemButton(element, Gui, player_index, tableRow)
  log("doEvent.itemButton")
  tableRow.clear()
  for item_name, item_table in pairs(Gui.Caller.items) do
    tableRow.add{type = "choose-elem-button", elem_type = "signal", signal = {type=item_table.item_type, name=item_name} }
    tableRow.add{type = "label", name = item_name .. "-type", caption = item_table.item_type}
    tableRow.add{type = "label", name = item_name .. "-name", caption = item_name}
  end
end

function doEvent.sliderTicks(element, Gui, player_index, textTicks)
  log("doEvent.sliderTicks")
  local ticks = math.floor(element.slider_value)
  if element.slider_value ~= tostring(textTicks.text) then
    textTicks.text = tostring(ticks)
  end
  Gui.Caller.config.ticks = ticks
end

function doEvent.textTicks(element, Gui, player_index, sliderTicks)
  log("doEvent.textTicks")
  local max = Defines.max_ticks
  if element.text and String.is_digit(element.text) then
    local num = tonumber(element.text)
    if num then
      if num > max then
        num = max
        element.text = tostring(num)
      elseif num < 1 then
        num = 1
        element.text = tostring(num)
      end
      if num ~= sliderTicks.slider_value then
        sliderTicks.slider_value = num
      end
      Gui.Caller.config.ticks = num
    end
  else
    element.text = tostring(sliderTicks.slider_value)
  end
end

function doEvent.radioGraphing(element, Gui, player_index, target)
  log("doEvent.radioGraphing")
  if element.state == target.state then
    target.state = not element.state
  end
  Gui.Caller.config.enabled = Gui.elements["radioGraphingOn"].state
end

function doEvent.radioSeparate(element, Gui, player_index, target)
  log("doEvent.radioSeparate")
  if element.state == target.state then
    target.state = not element.state
  end
  Gui.Caller.config.separate = Gui.elements["radioSeparateYes"].state
end


function Guiconfig.metatable(GC)
  setmetatable(GC, Guiconfig_meta)
end

function Guiconfig.new(player_index)
  local GC =
  {
    player_index = player_index
  }

  Guiconfig.metatable(GC)

  return GC
end

function Guiconfig.gui_event_handler(event, Gui, target)
  local handler_function = function(evnt)
    local element = evnt.element
    local player_index = element.player_index
    target = Gui.elements[target] or target
    return event.func(element, Gui, player_index, target)
  end
  return handler_function
end

function Guiconfig:gui_top()
  local player = game.players[self.player_index]
  return mod_gui.get_frame_flow(player)
end

local defaults = {}

function defaults.Graphing(name, Caller)
  local default = {}
  if name == "radioGraphingOn" then
    default.state = Caller.config.enabled
  else
    default.state = not Caller.config.enabled
  end
  return default
end

function defaults.Separate(name, Caller)
  local default = {}
  if name == "radioSeparateYes" then
    default.state = Caller.config.separate
  else
    default.state = not Caller.config.separate
  end
  return default
end

function defaults.Ticks(name, Caller)
  local default = {}
  local ticks = Caller.config.ticks
  if name == "textTicks" then
    default.text = tostring(ticks)
  else
    default.value = ticks
    default.minimum_value = 1
    default.maximum_value = Defines.max_ticks
  end
  return default
end

function Guiconfig.radiobutton_pair(name, caption, on_state_name, off_state_name, default_func, event_func)
  local element_table = {}
  local element_label =
    {
      type    = "label",
      name    = name,
      caption = caption
    }
  local function element(state_name, target_name)
    local element_name = "radio" .. name .. state_name
    local target_name = "radio" .. name .. target_name
    return
      {
        type    = "radiobutton",
        name    = element_name,
        caption = state_name,
        default = default_func,
        event   =
          {
            event_id = evs.on_gui_checked_state_changed, func = event_func, target = target_name
          }
      }
  end
  table.insert(element_table, element_label)
  table.insert(element_table, element(on_state_name, off_state_name))
  table.insert(element_table, element(off_state_name, on_state_name))
  return element_table
end

function Guiconfig.gui_layout()
  return
    {
      { type = "frame",                   name  = "Graphtool", caption = "Graphtool", direction = "vertical" , children =
        {
          { type = "frame",               name  = "configFrame", caption = "Configuration", direction = "vertical", children =
            {
              { type = "flow",            name  = "configRow1", direction = "horizontal", children =
                --{
                  Guiconfig.radiobutton_pair("Graphing", "Enabled", "On", "Off", defaults.Graphing, doEvent.radioGraphing)
                  --{ type = "label",       name  = "labelGraphing", caption = "Graphing" },
                  --{ type = "radiobutton", name  = "radioGraphingOn", caption = "On", default = defaults.Graphing,
                  --                        event = { event_id = evs.on_gui_checked_state_changed, func = doEvent.radioGraphing, target = "radioGraphingOff" } },
                  --{ type = "radiobutton", name  = "radioGraphingOff", caption = "Off", default = defaults.Graphing,
                  --                        event = { event_id = evs.on_gui_checked_state_changed, func = doEvent.radioGraphing, target = "radioGraphingOn"} }
                --}
              },
              { type = "flow",            name  = "configRow2", direction="horizontal", children =
                {
                  { type = "label",       name  = "labelTicks", caption = "Ticks per read" },
                  { type = "textfield",   name  = "textTicks", vertical_align = "center", default = defaults.Ticks,
                                          style = { width=35, vertical_align="center" },
                                          event = { event_id = evs.on_gui_text_changed, func = doEvent.textTicks, target = "sliderTicks" } },
                  { type = "slider",      name  = "sliderTicks",  default = defaults.Ticks,
                                          style = { vertical_align = "center" },
                                          event = { event_id = evs.on_gui_value_changed, func = doEvent.sliderTicks, target = "textTicks"} }
                },
              },
              { type = "flow",            name  = "configRow3", direction="horizontal", children =
                Guiconfig.radiobutton_pair("Separate", "Record red/green signals separately?", "Yes", "No", defaults.Separate, doEvent.radioSeparate)
                -- {
                --   { type = "label",       name  = "labelSeparate", caption = "Record red/green signals separately?" },
                --   { type = "radiobutton", name  = "radioSeparateYes", caption = "Yes", default = defaults.Separate,
                --                           event = { event_id = evs.on_gui_checked_state_changed, func = doEvent.radioSeparate, target = "radioSeparateNo" } },
                --   { type = "radiobutton", name  = "radioSeparateNo", caption = "No", default = defaults.Separate,
                --                           event = { event_id = evs.on_gui_checked_state_changed, func = doEvent.radioSeparate, target = "radioSeparateYes"} }
                -- }
              },
              { type = "flow",            name  = "configRow4", direction="horizontal", children =
                {
                  { type = "label",       name  = "labelFilename", caption = "CSV Filename" },
                  { type = "textfield",   name  = "textFilename" }
                }
              }
            }
          },
          { type = "frame",               name  = "tableFrame", caption = "Items", direction = "horizontal", children =
            {
              { type = "flow",            name  = "itemButtonRow", direction = "horizontal", children =
                {
                  { type = "button",      name  = "itemButton", caption = "Items",
                                          event = { event_id = evs.on_gui_click, func = doEvent.itemButton, target = "tableRow" } },
                }
              },
              { type = "scroll-pane",     name  = "itemScroll", direction = "vertical", children =
                {
                  { type = "table",       name  = "tableRow", direction = "horizontal", column_count = 3 }
                }
              },
            }
          }
        }
      }
    }
end

return Guiconfig
