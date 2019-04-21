--
-- Includes
--
-- factorio
require 'mod-gui'
-- stdlib
local String = require('__stdlib__/stdlib/utils/string')
local Event    = require('__stdlib__/stdlib/event/event')

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
  --TODO: horribly messy, duplicated, etc.
  if Gui.Caller.ui_events then
    for p_i, event_table in pairs(Gui.Caller.ui_events) do
      if p_i ~= player_index then
        for event_name, event_id in pairs(event_table) do
          Event.dispatch({name = event_id})
        end
      end
    end
  end
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
        element.text = tostring(num)
      end
      Gui.Caller.config.ticks = num
      --TODO: horribly messy, duplicated, etc.
      if Gui.Caller.ui_events then
        for p_i, event_table in pairs(Gui.Caller.ui_events) do
          if p_i ~= player_index then
            log("event loop, player_index: " .. p_i)
            log("event loop, event_table: " .. serpent.block(event_table))
            for event_name, event_id in pairs(event_table) do
              Event.dispatch({name = event_id})
            end
          end
        end
      end
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
  log("Guiconfig.gui_event_handler")
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

local refresh = {}

--function refresh.Ticks(Graphtool, textTicks, sliderTicks)
function refresh.Ticks(event, Gui)
  log("refresh.Ticks")
  --log("refresh.Ticks, data:" .. serpent.block(data))
  if Gui and Gui.Caller and Gui.Caller.config then
    local ticks = Gui.Caller.config.ticks
    Gui.elements["textTicks"].text = tostring(ticks)
    Gui.elements["sliderTicks"].slider_value = ticks
  end
end

function defaults.Ticks(name, Graphtool)
  log("default.Ticks")
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

local function label_with_tooltip(name, caption, tooltip)
  local element_label = { type = "label", name = name, caption = caption }
  return
    {
      { type = "table",                 name = "tableLabelTooltip" .. name, column_count = 2, direction = "horizontal",
                                        style = { left_padding = 0, right_padding = 0, horizontal_spacing = 5,
                                                  column_alignments = { "middle-left", "middle-left"} },
                                        children =
          {
            element_label,
            info_button("buttonTooltip" .. name, tooltip)
          }
      }
    }
end

local function radiobutton_pair(name, caption, on_state_name, off_state_name, config_name, tooltip_text, event_func, default_func)
  local element_table = {}

  local on_element_name = "radio" .. name .. on_state_name

  local event_function = event_func or function (element, Gui, player_index, target)
    log("radiobutton_pair->event_function")
    if element.state == target.state then
      target.state = not element.state
    end
    Gui.Caller.config[config_name] = Gui.elements[on_element_name].state
  end

  local default_function = default_func or function (elemname, caller)
    log("radiobutton_pair->default_function")
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
  --table.insert(element_table, element_label)
  local tooltip = tooltip_text or {"tooltip." .. config_name}
  table.insert(element_table, label_with_tooltip(name, caption, config_name, tooltip))
  --table.insert(element_table, info_button("radioButtonTooltip" .. config_name, tooltip))
  table.insert(element_table, element(on_state_name, off_state_name))
  table.insert(element_table, element(off_state_name, on_state_name))
  return element_table
end

local function column_headers(table_name, headers)
  log("column_headers, table_name: " ..table_name)
  log("column_headers, headers: " .. serpent.block(headers))
  local element_table = {}
  for _, label in pairs(headers) do
    local header_label = { type = "label", name = "label" .. table_name .. label, caption = label }
    table.insert(element_table, header_label)
  end
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
                  { type = "table",             name = "tableConfigRadio", column_count = 3, direction = "horizontal",
                        style = { left_padding = 0, right_padding = 0, horizontal_spacing = 10, horizontally_stretchable = true,
                                 column_alignments = { "bottom-left", "middle-left", "bottom-left", "bottom-right" } },
                        children =
                    {
                      radiobutton_pair("Graphing", {"label.enabled"}, "On", "Off", "enabled", {"tooltip.enabled", {"label.graphtool"}}),
                      radiobutton_pair("Separate", {"label.separate"}, "Yes", "No", "separate", {"tooltip.separate", {"label.Yes"}, {"label.No"}}),
                      radiobutton_pair("AllowNeg", {"label.allow_neg"}, "Yes", "No", "allow_neg",
                                      {"tooltip.allow_neg", {"label.Yes"}, {"label.No"}, {"gui-electric-network.production"}, {"gui-electric-network.title"} }),
                      label_with_tooltip("labelTicks", {"label.ticks"}, {"tooltip.ticks_info", {"label.graphtool"}})
                    },
                  },
                  { type = "flow",          name  = "flowConfigTicksControls", direction="horizontal",
                                            style = { right_padding = 0, left_padding = 0, horizontal_align = "right", horizontally_stretchable = true },
                                            children =
                    {
                      { type = "slider",    name  = "sliderTicks",  default = defaults.Ticks, refresh = refresh.Ticks,
                                            style = { width = 280, top_margin = 7, vertical_align = "center",  vertically_stretchable = true },
                                            event = { event_id = evs.on_gui_value_changed, func = doEvent.sliderTicks, target = "textTicks"} },
                      { type = "textfield", name  = "textTicks", vertical_align = "center", default = defaults.Ticks, refresh = refresh.Ticks,
                                            style = { width=50, horizontal_align = "center", vertical_align="center" },
                                            event = { event_id = evs.on_gui_text_changed, func = doEvent.textTicks, target = "sliderTicks" } },
                    }
                  }
                }
              }
            }
          },
          { type = "frame",                 name = "frameCSVHeader", caption = {"label.CSV"}, direction = "vertical",
                                            children =
            {
              { type = "flow",              name = "flowCsv", direction = "vertical",
                                            style = { bottom_margin = 10, top_margin = 10, left_margin = 10, right_margin = 10 },
                                            children =
                {
                  { type = "button",            name = "buttonCSVAddFile", caption = {"label.buttonCSVAddFile"},
                                                event = { event_id = evs.on_gui_click, func = doEvent.buttonCSVAddFile }
                  },
                  { type = "flow",                  name = "flowCSV", direction = "vertical",
                                                    style = { bottom_margin = 10, top_margin = 10, left_margin = 10, right_margin = 10 },
                                                    children =
                    {
                      { type = "table",             name = "tableCSVFiles", column_count = 4, direction = "horizontal",
                            style = { left_padding = 0, right_padding = 0, horizontal_spacing = 10, horizontally_stretchable = true,
                                     column_alignments = { "bottom-left", "middle-left", "bottom-left", "bottom-right" } },
                            children =
                        {
                          column_headers("CSVFiles", {"Active", "Filename", "Separator", "Num. Items"} )
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
