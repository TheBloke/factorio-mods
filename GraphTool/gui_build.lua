--
-- Includes
--
-- mod
local Defines  = require('defines')
-- stdlib
local table    = require('__stdlib__/stdlib/utils/table')
local Is       = require('__stdlib__/stdlib/utils/is')
local Event    = require('__stdlib__/stdlib/event/event')

local Guibuild =
  {
    __call = function(self, ...)
      return self.new(...)
    end
  }

local Guibuild_meta =
  {
    __index = Guibuild
  }

setmetatable(Guibuild, Guibuild)

-- if Defines.debug then
--   debug_obj(Guibuild, "Guibuild")
-- end

function Guibuild.metatable(Gui)
  if Is.Table(Gui) then
    setmetatable(Gui, Guibuild_meta)
  end
end

function Guibuild.new(Guiconfig, caller)
  log("Guibuild.new")
  local Gui =
    {
      Caller       = caller,
      handler      = Guiconfig.gui_event_handler,
      player_index = Guiconfig.player_index,
      ui_top       = Guiconfig:gui_top(),
      events       = {},
      elements     = {}
    }

  Guibuild.metatable(Gui)

  log(serpent.block(Guiconfig.gui_layout()))
  Gui:build(Guiconfig.gui_layout())

  return Gui
end

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

function Guibuild:elem_event(event, elem)
  if Is.Table(event)  then
    local target = event.target or nil
    local handler_func
    if self.handler then
      handler_func = self.handler(event, self, target)
    else
      handler_func = function() return event.func(elem, self, self.player_index, target) end
    end
    local event_table = {event.event_id, handler_func, eventmatcher, elem.name}
    self:register_event(event_table)
  end
end

function Guibuild:elem_events(elem)
  if elem.events then
    for _, event in pairs(elem.events) do
      self:elem_event(event, elem)
    end
    elem.events = nil
  elseif elem.event then
    self:elem_event(elem.event, elem)
    elem.event = nil
  end
end

function Guibuild:elem_add(elem, root)
  local newroot = root.add(elem)
  self.elements[elem.name] = newroot
  return newroot
end

function Guibuild:elem_default(elem)
  -- elem.default can reference a function which specifies a default value for this element
  -- The function's return value should be a table including one or more LuaGuiElement.add attributes
  -- eg: { text = 1 } or { value = 15 }
  if Is.Callable(elem.default) then
    local default_func = elem.default
    local default_table = default_func(elem.name, self.Caller)
    table.merge(elem, default_table)
  end
  elem.default = nil
end

function Guibuild:element(elem, root)
  if elem then
    local newroot
    if elem.events or elem.event then
      self:elem_events(elem)
    end
    if elem.default then
      self:elem_default(elem)
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
  log("Guibuild:removeGui")
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
