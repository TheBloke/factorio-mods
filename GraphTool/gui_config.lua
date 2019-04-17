--
-- Includes
--
-- factorio
require 'mod-gui'

local evs = defines.events

local Guiconfig = {}

local onEvent =
  {
    __index = function(_, k)
      if doEvent[k] then
        return function(event, Gui, target)
          local element = event.element
          local player_index = element.player_index
          target = Gui.elements[target] or target
          return doEvent[k](element, Gui, player_index, target)
        end
       end
    end
  }

--setmetatable(onEvent, onEvent)

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
  if tonumber(element.slider_value) ~= textTicks.text then
    textTicks.text = tostring(math.floor(element.slider_value))
  end
end

function doEvent.textTicks(element, Gui, player_index, sliderTicks)
  log("doEvent.textTicks")
  if element.text then
    local num = tonumber(element.text)
    if num then
      if num > 60 then
        num = 60
        element.text = tostring(num)
      elseif num < 1 then
        num = 1
        element.text = tostring(num)
      end
      if num ~= sliderTicks.slider_value then
        sliderTicks.slider_value = num
      end
    end
  end
end

function doEvent.radioOnOff(element, Gui, player_index, target)
  log("doEvent.radioOnOff")
  if element.state == target.state then
    target.state = not element.state
  end
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

function Guiconfig.gui_top(player_index)
  local player = game.players[player_index]
  return mod_gui.get_frame_flow(player)
end

function Guiconfig.gui_layout()
  return
    {
      { type = "frame",                 name = "Graphtool", caption = "Graphtool", direction = "vertical" , children =
        {
          { type = "frame",               name = "configFrame", caption = "Configuration", direction = "vertical", children =
            {
              { type = "flow",            name = "configRow1", direction = "horizontal", children =
                {
                  { type = "label",       name = "label-Graphing", caption = "Graphing" },
                  { type = "radiobutton", name = "radioGraphingOn", caption = "On", state = true,
                                          event = { event_id = evs.on_gui_click, func = doEvent.radioOnOff, target = "radioGraphingOff"} },
                  { type = "radiobutton", name = "radioGraphingOff", caption = "Off", state = false,
                                          event = { event_id = evs.on_gui_click, func = doEvent.radioOnOff, target = "radioGraphingOn"} },
                }
              },
              { type = "flow",            name = "configRow2", direction="horizontal", children =
                {
                  { type = "label",       name = "label-Ticks", caption = "Ticks per read" },
                  { type = "textfield",   name = "textTicks", text = "1", vertical_align = "center", vertically_stretchable = true,
                                          style = { width=35, vertical_align="center" },
                                          event = { event_id = evs.on_gui_text_changed, func = doEvent.textTicks, target = "sliderTicks" } },
                  { type = "slider",      name = "sliderTicks", minimum_value = 1, maximum_value = 60, value = 1,
                                          style = { vertical_align = "center" },
                                          event = { event_id = evs.on_gui_value_changed, func = doEvent.sliderTicks, target = "textTicks"} },
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
                  { type = "button",      name = "itemButton", caption = "Items",
                                          event = { event_id = evs.on_gui_click, func = doEvent.itemButton, target = "tableRow" } },
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

return Guiconfig
