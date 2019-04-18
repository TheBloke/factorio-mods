--
-- Includes
--
-- mod
local Guibuild  = require('gui_build')
local Guiconfig = require('gui_config')
local Defines   = require('defines')
-- stdlib
local Entity    = require('__stdlib__/stdlib/entity/entity')
local Is        = require('__stdlib__/stdlib/utils/is')

local Graphtool =
  {
    __call = function(self, ...)
      return self.new(...)
    end
  }

local Graphtool_meta =
  {
    __index = Graphtool
  }

setmetatable(Graphtool, Graphtool)

-- if Defines.debug then
--   debug_obj(Graphtool, "Graphtool", { "onTick" } )
-- end

local colours =
  {
    ["red"]   = defines.wire_type.red,
    ["green"] = defines.wire_type.green
  }

function Graphtool.metatable(GT)
  if Is.Table(GT) then
    setmetatable(GT, Graphtool_meta)
  end
end

function Graphtool.new(entity)
  log("Graphtool:new()")
  local GT =
    {
      items  = {},
      ui     = {},
      config = {},
      entity = nil,
      pole   = nil
    }
  Graphtool.metatable(GT)

  GT.entity = entity
  GT.pole   = entity.surface.create_entity{ name=Defines.pole_entity,
                                            position = {x = entity.position.x, y = entity.position.y},
                                            force = entity.force }
  GT.stats  = GT.pole.electric_network_statistics

  return GT
end

function Graphtool:removeAllGui()
  log("Graphtool:removeAllGui()")
  if self.ui then
    for player_index, Gui in pairs(self.ui) do
      Gui:removeGui()
      --self.ui[player_index] = nil
    end
  end
end

function Graphtool:destroy()
  log("Graphtool:destroy()")
  self:removeAllGui()
  self.stats = nil
  self.pole.destroy()
  self = nil
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
  log("Graphtool:createGui()")
  local player = game.players[player_index]
  local ui = self.ui[player_index]
  if self.ui[player_index] then
    self.ui[player_index]:destroy()
  end

  local GC = Guiconfig(player_index)
  self.ui[player_index] = Guibuild(GC:gui_top(), GC.gui_layout(),
                                   player_index, self, GC.gui_event_handler)
end

function Graphtool:removeGui(player_index)
  log("Graphtool:removeGui()")
  if self.ui[player_index] then
    self.ui[player_index]:removeGui()
    self.ui[player_index] = nil
  end
end

function Graphtool:Gui_metatable()
  log("Graphtool:Gui_metatable()")
  if self.ui then
    for player_index, Gui in pairs(self.ui) do
      Guibuild.metatable(Gui)
    end
  end
end

return Graphtool
