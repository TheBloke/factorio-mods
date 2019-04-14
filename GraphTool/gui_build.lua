local table = require('__stdlib__/stdlib/utils/table')
local Gui = require('__stdlib__/stdlib/event/gui')

local gui_build = {}

local function gui_elem_callback(elem)
  if elem.callback then
    local callback = elem.callback
    Gui.on_click(elem.name, function(e) callback(e) end)
    elem.callback = nil
  end
end

local function gui_elem_add(elem, root)
  if elem then
    local newroot
    gui_elem_callback(elem)
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

function gui_build.gui_elem_iter(layout, root)
  if layout then
    local child, newroot
    for _, v in pairs(layout) do
      if v.children then
        child = table.deep_copy(v.children)
        v.children = nil
        newroot = gui_elem_add(v, root)
        gui_build.gui_elem_iter(child, newroot)
      else
        newroot = gui_elem_add(v, root)
      end
    end
  end
end

return gui_build
