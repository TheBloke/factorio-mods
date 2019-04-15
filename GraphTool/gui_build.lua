require 'mod-gui'

local table = require('__stdlib__/stdlib/utils/table')
local Is = require('__stdlib__/stdlib/utils/is')
local Event = require('__stdlib__/stdlib/event/event')

local evs = defines.events

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

local onEvent = {}
local doEvent = {}

local onEvent_mt =
  {
    __index = function(_, k)
      if doEvent[k] then
        return function(event)
          local element = event.element
          local player_index = element.player_index
          local GTG = get_player_data(player_index)
          return doEvent[k](element, GTG, player_index)
        end
       end
    end
  }

setmetatable(onEvent, onEvent_mt)

function doEvent.itemButton(element, GTG, player_index)
  log("in itemButton")
  local tableRow = GTG.UI["Graphtool"]["tableFrame"]["itemScroll"]["tableRow"]
  tableRow.clear()
  for item_name, item_table in pairs(GTG.GT.items) do
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

local GTGui =
  {
    _cache = {},
    __call = function(self, ...)
      return self.get(...)
    end
  }

local GTG_meta =
  {
    __index = GTGui
  }

function GTGui.get(player_index, GT)
  -- TODO cache can't work because there can be multiple GTGuis per player (multiple entities)?
  --return GTGui._cache[player_index] or GTGui.new(player_index, GT)
  return GTGui.new(player_index, GT)
end

function GTGui.metatable(GTG)
  if GTG then
    setmetatable(GTG, GTG_meta)
  end
end

function GTGui.new(player_index, GT)
  log("GTGui.new")
  local GTG =
  {
    GT = GT,
    UI = {},
    events = {},
    player_index = player_index,
    ui_top = nil
  }

  GTGui.metatable(GTG)
  GTGui._cache[player_index] = player_index

  --UI.root = player.gui.left
  local player = game.players[player_index]
  GTG.UI = mod_gui.get_frame_flow(player)

  GTG:build(gui_layout())

  set_player_data(player_index, GTG)
  return GTG
end

setmetatable(GTGui, GTGui)

local function eventmatcher(event, pattern)
  -- Copied from stdlib/stdlib/event/gui
    if event.element and event.element.valid then
        local match_str = event.element.name:match(pattern)
        if match_str then
            event.match = match_str
            event.state = event.name == defines.events.on_gui_checked_state_changed and event.element.state or nil
            event.text = event.name == defines.events.on_gui_text_changed and event.element.text or nil
            return match_str
        end
    end
end

function GTGui:register_event(event_table)
  Event.register(table.unpack(event_table))
  table.insert(self.events, event_table)
end

function GTGui:elem_callback(elem)
  local callback = elem.callback
  if callback and Is.Callable(callback) then
    local event_table = {evs.on_gui_click, callback, eventmatcher, elem.name}
    self:register_event(event_table)
    elem.callback = nil
  end
end

function GTGui:elem_add(elem, root)
  if elem then
    local newroot
    self:elem_callback(elem)
    if elem.style then
      local style = table.deep_copy(elem.style)
      elem.style = nil
      newroot = root.add(elem)
      for k, v in pairs(style) do
        newroot.style[k] = v
      end
    else
      newroot = root.add(elem)
    end
    if not self.ui_top then
      self.ui_top = newroot
    end
    return newroot
  end
end

-- TODO: Rename GTGui to generic name eg Gui.  Move gui_layout and on/doEvent to Graphtool.

function GTGui:build(layout, root)
  log("GTGui:build")
  local root = root or self.UI
  if layout then
    local child, newroot
    for _, elem in pairs(layout) do
      if elem.children then
        child = table.deep_copy(elem.children)
        elem.children = nil
        newroot = self:elem_add(elem, root)
        self:build(child, newroot)
      else
        newroot = self:elem_add(elem, root)
      end
    end
  end
end

function GTGui:removeGui()
  log("GTGui:removeGui")
  local UI = self.UI
  if UI and self.ui_top then
    if self.events then
      for _, event in pairs(self.events) do
        Event.remove(table.unpack(event))
      end
    end
    self.ui_top.destroy()
  end
end


return GTGui
