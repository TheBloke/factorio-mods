--
-- Includes
--
-- mod
local Guibuild  = require('gui_build')
local Guiconfig = require('gui_config')
local Defines      = require('defines')
-- stdlib
local Entity    = require('__stdlib__/stdlib/entity/entity')

local Graphtool =
  {
    _cache = {},
    __call = function(self, ...)
      return self:get(...)
    end
  }

if Defines.debug then
  debug_obj(Graphtool, "Graphtool", { "onTick" } )
end

local colours =
  {
    ["red"] = defines.wire_type.red,
    ["green"] = defines.wire_type.green
  }

setmetatable(Graphtool, Graphtool)

function Graphtool.metatable(GT)
  setmetatable(GT, Graphtool)
end

function Graphtool:get(entity)
  if Graphtool._cache[entity] then
    log("Graphtool.get : returning cached GT for entity.")
    return Graphtool._cache[entity]
  else
    return self:new(entity)
  end
end

function Graphtool:new(entity)
  self.items  = {}
  self.ui     = {}
  self.config = {}

  Graphtool._cache[entity.unit_number] = nil

  self.entity = entity
  self.pole   = entity.surface.create_entity{name=Defines.pole_entity,
                                         position = {x = entity.position.x, y = entity.position.y},
                                         force = entity.force}
  self.stats  = self.pole.electric_network_statistics

  Graphtool._cache[entity.unit_number] = self

  return self
end

function Graphtool:removeAllGui()
  if self.ui then
    for player_index, Gui in pairs(self.ui) do
      Gui:removeGui()
      --self.ui[player_index] = nil
    end
  end
end

function Graphtool:destroy()
  self:removeAllGui()
  self.stats = nil
  self.pole.destroy()
  Graphtool._cache[self.entity] = nil
end

function Graphtool:onTick()
  for colour, wire in pairs(colours) do
    local network = self.entity.get_circuit_network(wire)
    if network and network.signals then
      for _, signal in pairs(network.signals) do
        self.stats.on_flow("graphtool-" .. colour .. "-" .. signal.signal.name, signal.count/60)
        self.items[signal.signal.name] = {item_type = signal.signal.type, item_count=signal.count}
      end
    end
  end
end

function Graphtool:createGui(player_index)
  local player = game.players[player_index]
  local ui = self.ui[player_index]
  if self.ui[player_index] then
    self.ui[player_index]:destroy()
  end

  self.ui[player_index] = Guibuild(Guiconfig.gui_top(player_index), Guiconfig.gui_layout(),
                                   player_index, self, Guiconfig.gui_event_handler)
end

function Graphtool:removeGui(player_index)
  if self.ui[player_index] then
    self.ui[player_index]:removeGui()
    self.ui[player_index] = nil
  end
end

function Graphtool:Gui_metatable()
  if self.ui then
    for player_index, Gui in pairs(self.ui) do
      Guibuild.metatable(Gui)
    end
  end
end

return Graphtool
