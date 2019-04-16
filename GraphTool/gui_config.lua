--
-- Includes
--
-- factorio
require 'mod-gui'

local Guiconfig = {}

local doEvent = {}
local onEvent =
  {
    __index = function(_, k)
      if doEvent[k] then
        return function(event, Gui, targetfor)
          local element = event.element
          local player_index = element.player_index
          return doEvent[k](element, Gui, player_index, targetfor)
        end
       end
    end
  }

setmetatable(onEvent, onEvent)

function doEvent.itemButton(element, Gui, player_index, target)
  log("doEvent.itemButton")
  local tableRow = Gui.elements[target]
  tableRow.clear()
  for item_name, item_table in pairs(Gui.Caller.items) do
    tableRow.add{type = "choose-elem-button", elem_type = "signal", signal = {type=item_table.item_type, name=item_name} }
    tableRow.add{type = "label", name = item_name .. "-type", caption = item_table.item_type}
    tableRow.add{type = "label", name = item_name .. "-name", caption = item_name}
  end
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
                  { type = "button",      name = "itemButton", caption = "Items", callback = onEvent.itemButton, target = "tableRow" }
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
