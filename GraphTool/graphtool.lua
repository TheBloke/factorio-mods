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

local config_default =
  {
    enabled  = Defines.default_enabled,
    ticks    = Defines.default_ticks,
    separate = Defines.default_separate
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
      items  = { red = {}, green = {}, merged = {} },
      ui     = {},
      config = config_default,
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
end

function Graphtool:onTick()
  if self.config.ticks == 1 or game.tick % self.config.ticks == 0 then
    -- Read the signal network every config.ticks (defaults to 1)
    if self.config.separate then
      for colour, wire in pairs(colours) do
        local network = self.entity.get_circuit_network(wire)
        if network and network.signals then
          for _, signal in pairs(network.signals) do
            local signal_name = "graphtool-" .. colour .. "-" .. signal.signal.name
            local signal_count = signal.count/60
            self.stats.on_flow(signal_name, signal_count)
            self.items[colour][signal_name] = signal_count
            --self.items[colour][signal.signal.name] = {item_type = signal.signal.type, item_count=signal.count}
          end
        end
      end
    else -- Merged signals
      local signals = self.entity.get_merged_signals()
      if signals then
        for _, signal in pairs(signals) do
          local signal_name = "graphtool-" .. signal.signal.name
          local signal_count = signal.count/60
          self.stats.on_flow(signal_name, signal_count)
          self.items["merged"][signal_name] = signal_count
        end
      end
    end
  else -- If not reading this tick, re-send the last stored value.
    if self.config.separate then
      for _, colour in pairs{"red", "green"} do
        for signal_name, signal_count in pairs(self.items[colour]) do
          self.stats.on_flow(signal_name, signal_count)
        end
      end
    else -- Merged signals
      for signal_name, signal_count in pairs(self.items["merged"]) do
        self.stats.on_flow(signal_name, signal_count)
      end
    end
  end
end

function Graphtool:createGui(player_index)
  log("Graphtool:createGui()")
  if self.ui[player_index] then
    self.ui[player_index]:destroy()
  end

  local GC = Guiconfig(player_index)
  self.ui[player_index] = Guibuild(GC, self)
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
