Defines =
  {
    modname          = "GraphTool",
    mod_entity       = "graphtool",
    pole_entity      = "graphtool-hiddenpole",
    default_ticks    = 1,
    default_separate = false,
    default_enabled  = true,
    max_ticks        = 120,
    debug            = true
  }

function debug_obj (obj, name, exclusions)
  local exclusions = exclusions or {}
  if Defines.debug then
    local cur_index = obj.__index
    obj.__index = function(_, k)
      for a, v in pairs(exclusions) do
        if v == k then
          return cur_index[k]
        end
      end
      log("DEBUG call " .. name .. "." .. k)
      return cur_index[k]
    end
  end
end

return Defines
