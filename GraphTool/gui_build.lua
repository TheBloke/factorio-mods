local table = require('__stdlib__/stdlib/utils/table')
local Is = require('__stdlib__/stdlib/utils/is')
local Event = require('__stdlib__/stdlib/event/event')

local evs = defines.events

local Guibuild =
  {
    _cache = {},
    __call = function(self, ...)
      return self.get(...)
    end
  }

local GB_meta =
  {
    __call = function(self, ...)
      return self:gui_elem_iter(...)
    end,
    __index = Guibuild
  }

function Guibuild.get(...)
  local UI = ...
  return Guibuild._cache[UI] or Guibuild.new(UI)
end

function Guibuild.metatable(GB)
  if GB then
    setmetatable(GB, GB_meta)
  end
end

function Guibuild.new(UI)
  local GB =
  {
    events = {},
    UI = UI
  }

  Guibuild.metatable(GB)
  Guibuild._cache[UI] = GB
  return GB
end

function Guibuild:destroy()
  if self.events then
    for _, event in pairs(self.events) do
      Event.remove(table.unpack(event))
    end
  end
  Guibuild._cache[self.UI] = nil
  self = nil
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

function Guibuild:gui_elem_callback(elem)
  local callback = elem.callback
  if callback and Is.Callable(callback) then
    local event_table = {evs.on_gui_click, callback, eventmatcher, elem.name}
    self:register_event(event_table)
    elem.callback = nil
  end
end

function Guibuild:gui_elem_add(elem, root)
  if elem then
    local newroot
    self:gui_elem_callback(elem)
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
    return newroot
  end
end

function Guibuild:gui_elem_iter(layout, root)
  local root = root or self.UI
  if layout then
    local child, newroot
    for _, elem in pairs(layout) do
      if elem.children then
        child = table.deep_copy(elem.children)
        elem.children = nil
        newroot = self:gui_elem_add(elem, root)
        self:gui_elem_iter(child, newroot)
      else
        newroot = self:gui_elem_add(elem, root)
      end
    end
  end
end



return Guibuild
