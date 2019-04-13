local Entity = require('__stdlib__/stdlib/entity/entity')

local graphtool = {}

local function init(state)
  state        = state or {}
  state.items  = state.items or {}
  state.ui     = state.ui or {}
  state.config = state.config or {}
  state.pole   = state.pole or nil
  state.stats  = state.stats or nil
  return state
end

function graphtool.new(entity)
  local pole = entity.surface.create_entity{name="graphtool-hiddenpole",
                                            position = {x = entity.position.x, y = entity.position.y},
                                            force = entity.force}
  local stats = pole.electric_network_statistics
  state = init{pole = pole, stats = stats}
  Entity.set_data(entity, state)
end

function graphtool.destroy(entity)
  local state = Entity.get_data(entity)
  log(serpent.block(state.items))
  state.stats = nil
  state.pole.destroy()
end

return graphtool
