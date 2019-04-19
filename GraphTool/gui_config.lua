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
  local ticks = math.floor(element.slider_value)
  if element.slider_value ~= tostring(textTicks.text) then
    textTicks.text = tostring(ticks)
  end
  Gui.Caller.config.ticks = ticks
end

function doEvent.textTicks(element, Gui, player_index, sliderTicks)
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
  --return player.gui.left
  return mod_gui.get_frame_flow(player)
end

local defaults = {}

function defaults.Ticks(name, Graphtool)
  local default = {}
  local ticks = Graphtool.config.ticks
  if name == "textTicks" then
    default.text = tostring(ticks)
  else
    default.value = ticks
    default.minimum_value = 1
    default.maximum_value = Defines.max_ticks
  end
  return default
end

local function info_button(name, tooltip)
  return
    { type = "sprite-button",  name = name, style = "GT_info_button", tooltip = tooltip }
end

local function radiobutton_pair(name, caption, on_state_name, off_state_name, config_name, tooltip_text, event_func, default_func)
  local element_table = {}
  local element_label = { type = "label", name = name, caption = caption, style = {horizontal_align = "right"} }

  local on_element_name = "radio" .. name .. on_state_name
  local event_function = event_func or function (element, Gui, player_index, target)
    if element.state == target.state then
      target.state = not element.state
    end
    Gui.Caller.config[config_name] = Gui.elements[on_element_name].state
  end

  local default_function = default_func or function (elemname, caller)
    local default = {}
    if elemname == on_element_name then
      default.state = caller.config[config_name]
    else
      default.state = not caller.config[config_name]
    end
    return default
  end

  local function element(state_name, target_name)
    local element_name = "radio" .. name .. state_name
    local target_name  = "radio" .. name .. target_name
    return
      {
        type    = "radiobutton",
        name    = element_name,
        caption = {"label." .. state_name},
        default = default_function,
        event   =
          {
            event_id = evs.on_gui_checked_state_changed, func = event_function, target = target_name
          }
      }
  end
  table.insert(element_table, element_label)
  local tooltip = tooltip_text or {"tooltip." .. config_name}
  table.insert(element_table, info_button("radioButtonTooltip" .. config_name, tooltip))
  table.insert(element_table, element(on_state_name, off_state_name))
  table.insert(element_table, element(off_state_name, on_state_name))
  return element_table
end

function Guiconfig.gui_layout()
  return
    {
      { type = "frame",                         name = "Graphtool", caption = {"label.graphtool"}, direction = "vertical" , children =
        {
          { type = "frame",                     name = "frameConfigHeader", caption = {"label.configuration"}, direction = "vertical", children =
            {
              { type = "flow",                  name = "flowConfig", direction = "vertical",
                                                style = { bottom_margin = 10, top_margin = 10, left_margin = 10, right_margin = 10 },
                                                children =
                {
                  { type = "table",             name = "tableConfigRadio", column_count = 4, direction = "horizontal", children =
                    {
                      radiobutton_pair("Graphing", {"label.enabled"}, "On", "Off", "enabled", {"tooltip.enabled", {"label.graphtool"}}),
                      radiobutton_pair("Separate", {"label.separate"}, "Yes", "No", "separate", {"tooltip.separate", {"label.Yes"}, {"label.No"}}),
                      radiobutton_pair("AllowNeg", {"label.allow_neg"}, "Yes", "No", "allow_neg",
                                      {"tooltip.allow_neg", {"label.Yes"}, {"label.No"}, {"gui-electric-network.production"}, {"gui-electric-network.title"} }),
                      { type = "label",     name  = "labelTicks", caption = {"label.ticks"},
                                            style = { height = 30, vertical_align = "center" } },
                      info_button("buttonTicksInfo", {"tooltip.ticks_info", {"label.graphtool"}})
                    }, style = { horizontal_spacing = 10, horizontally_stretchable = true, column_alignments = { [1] = "middle-left", [2] = "middle-left", [3] = "right", [4] = "right" } }
                  },
                  { type = "flow",              name  = "flowConfigTicks", direction="vertical", children =
                    {
                      { type = "flow",          name  = "flowConfigTicksControls", direction="horizontal",
                                                style = { horizontal_align = "right", horizontally_stretchable = true },
                                                children =
                        {
                          { type = "slider",    name  = "sliderTicks",  default = defaults.Ticks,
                                                style = { top_margin = 7, vertical_align = "center", width = 285, vertically_stretchable = true,  },
                                                event = { event_id = evs.on_gui_value_changed, func = doEvent.sliderTicks, target = "textTicks"} },
                          { type = "textfield", name  = "textTicks", vertical_align = "center", default = defaults.Ticks,
                                                style = { width=50, horizontal_align = "center", vertical_align="center" },
                                                event = { event_id = evs.on_gui_text_changed, func = doEvent.textTicks, target = "sliderTicks" } },
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
end

return Guiconfig
