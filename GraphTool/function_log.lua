local function_log = {}

function function_log.flog(msg)
  local info = debug.getinfo(2)
  local name = info.name or "anonymous"
  if msg then
    log(name .. ": " .. serpent.block(msg))
  else
    log(name)
  end
end

return function_log
