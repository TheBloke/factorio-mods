local table = require('__stdlib__/stdlib/utils/table')
local Gui = require('__stdlib__/stdlib/event/gui')
local Event = require('__stdlib__/stdlib/event/event')
local evs = defines.events

local gui_build = {}

local function gui_elem_callback(elem, events)
  if elem.callback then
    local callback = elem.callback
    -- Gui.on_click(elem.name, function(e) log("start callback") ; callback(e) ; log("end callback") end)
    local eventhandler = function(e) log("start callback") ; callback(e) ; log("end callback") end
    local eventmatcher = function(e, p) return true end
    Event.register(evs.on_gui_click,
                  eventhandler,
                  eventmatcher,
                  elem.name
                  )
    table.insert(events, {evs.on_gui_click, eventhandler, eventmatcher, elem.name})
    elem.callback = nil
  end
end

local function gui_elem_add(elem, root, events)
  if elem then
    local newroot
    gui_elem_callback(elem, events)
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

function gui_build.gui_elem_iter(layout, root, events)
  if layout then
    local child, newroot
    for _, v in pairs(layout) do
      if v.children then
        child = table.deep_copy(v.children)
        v.children = nil
        newroot = gui_elem_add(v, root, events)
        gui_build.gui_elem_iter(child, newroot, events)
      else
        newroot = gui_elem_add(v, root, events)
      end
    end
  end
end

return gui_build
