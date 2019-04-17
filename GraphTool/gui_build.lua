--
-- Includes
--
-- mod
local Defines  = require('defines')
-- stdlib
local table = require('__stdlib__/stdlib/utils/table')
local Is    = require('__stdlib__/stdlib/utils/is')
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

local Guibuild =
  {
    _cache = {},
    __call = function(self, ...)
      return self.new(...)
    end
  }

local Gui_meta =
  {
    __index = Guibuild
  }

if Defines.debug then
  debug_obj(Gui_meta, "Guibuild")
end

function Guibuild.get(gui_top, layout, player_index, self)
  -- TODO cache can't work because there can be multiple Guibuilds per player (multiple entities)?
  --return Guibuild._cache[player_index] or Guibuild.new(player_index, GT)
  return Guibuild.new(gui_top, layout, player_index)
end

function Guibuild.metatable(Gui)
  if Gui then
    setmetatable(Gui, Gui_meta)
  end
end

function Guibuild.new(gui_top, layout, player_index, caller, handler)
  local Gui =
  {
    handler = handler,
    Caller = caller,
    events = {},
    elements = {},
    player_index = player_index,
    ui_top = nil
  }

  Guibuild.metatable(Gui)
  Guibuild._cache[player_index] = player_index

  Gui.ui_top = gui_top
  Gui:build(layout)

  set_player_data(player_index, Gui)
  return Gui
end

setmetatable(Guibuild, Guibuild)

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

function Guibuild:register_event(event_table)
  Event.register(table.unpack(event_table))
  table.insert(self.events, event_table)
end

function Guibuild:elem_event(elem)
  local event = elem.event
  if Is.Table(event)  then
    local target = event.target or nil
    local handler_func = self.handler(event, self, target)
    local event_table = {event.event_id, handler_func, eventmatcher, elem.name}
    self:register_event(event_table)
  end
  elem.event = nil
end

function Guibuild:elem_add(elem, root)
  local newroot = root.add(elem)
  self.elements[elem.name] = newroot
  return newroot
end

function Guibuild:element(elem, root)
  if elem then
    local newroot
    if elem.event then
      self:elem_event(elem)
    end
    if elem.style then
      local style = table.deep_copy(elem.style)
      elem.style = nil
      newroot = self:elem_add(elem, root)
      for k, v in pairs(style) do
        newroot.style[k] = v
      end
    else
      newroot = self:elem_add(elem, root)
    end
    return newroot
  end
end

function Guibuild:build(layout, root)
  local root = root or self.ui_top
  if layout then
    local child, newroot
    for _, elem in pairs(layout) do
      if elem.children then
        child = table.deep_copy(elem.children)
        elem.children = nil
        newroot = self:element(elem, root)
        self:build(child, newroot)
      else
        newroot = self:element(elem, root)
      end
    end
  end
end

function Guibuild:removeGui()
  if self.ui_top then
    if self.events then
      for _, event in pairs(self.events) do
        Event.remove(table.unpack(event))
      end
    end
    self.ui_top.destroy()
  end
end

return Guibuild
