local Entity = require('__stdlib__/stdlib/entity/entity')

local GTGui = require('gui_build')

local Graphtool =
  {
    _cache = {},
    __call = function(self, ...)
      return self.get(...)
    end
  }

local GT_meta =
  {
    __index = Graphtool
  }

local colours =
  {
    ["red"] = defines.wire_type.red,
    ["green"] = defines.wire_type.green
  }

setmetatable(Graphtool, Graphtool)

function Graphtool.metatable(GT)
  setmetatable(GT, GT_meta)
end

function Graphtool.get(...)
  local entity = ...
  return Graphtool._cache[entity] or Graphtool.new(entity)
end

function Graphtool.new(entity)
  local GT =
    {
      items = {},
      ui = {},
      config = {},
      entity = nil,
      pole = nil,
      stats = nil
    }

  Graphtool._cache[entity.unit_number] = nil

  GT.entity = entity
  GT.pole = entity.surface.create_entity{name="graphtool-hiddenpole",
                                            position = {x = entity.position.x, y = entity.position.y},
                                            force = entity.force}
  GT.stats = GT.pole.electric_network_statistics

  Graphtool.metatable(GT, GT_meta)
  Graphtool._cache[entity.unit_number] = GT

  return GT
end

function Graphtool:removeAllGui()
  log("Graphtool:removeAllGui")
  if self.ui then
    for player_index, GTG in pairs(self.ui) do
      GTG:removeGui()
      --self.ui[player_index] = nil
    end
  end
end

function Graphtool:destroy()
  log("Graphtool:destroy")
  self:removeAllGui()
  self.stats = nil
  self.pole.destroy()
  Graphtool._cache[self.entity] = nil
end

function Graphtool:onTick()
  for colour, wire in pairs(colours) do
    local network = self.entity.get_circuit_network(wire)
    if network then
      if network.signals then
        for _, signal in ipairs(network.signals) do
          self.stats.on_flow("graphtool-" .. colour .. "-" .. signal.signal.name, signal.count/60)
          self.items[signal.signal.name] = {item_type = signal.signal.type, item_count=signal.count}
        end
      end
    end
  end
end


function Graphtool:createGui(player_index)
  log("Graphtool:createGui")
  local player = game.players[player_index]
  local ui = self.ui[player_index]
  if self.ui[player_index] then
    log("Graphtool:createGui -> self.ui[p_i] exists: " .. serpent.block(self.ui[player_index]))
    self.ui[player_index]:destroy()
  end

  self.ui[player_index] = GTGui(player_index, self)
end

function Graphtool:removeGui(player_index)
  log("Graphtool:removeGui")
  if self.ui[player_index] then
    self.ui[player_index]:removeGui()
    self.ui[player_index] = nil
  end
end

function Graphtool:GTG_metatable()
  if self.ui then
    for player_index, UI in pairs(self.ui) do
      GTGui.metatable(UI)
    end
  end
end

return Graphtool
