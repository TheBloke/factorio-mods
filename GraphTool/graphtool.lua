--
-- Includes
--
-- mod
local Defines   = require('defines')
local Guibuild  = require('gui_build')
local Guiconfig = require('gui_config')
local Csv       = require('csv')
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

local function config_default()
  return
    {
      enabled   = Defines.default_enabled,
      ticks     = Defines.default_ticks,
      separate  = Defines.default_separate,
      allow_neg = Defines.default_allow_neg
    }
end

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

local function items_default()
  return { red = {}, green = {}, merged = {} }
end

function Graphtool.new(entity)
  log("Graphtool:new()")
  local GT =
    {
      items  = items_default(),
      ui     = {},
      config = config_default(),
      entity = nil,
      pole   = nil,
      ui_events = {}
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
  self.pole = nil
end

function Graphtool:process_signals(signals, store_key, entity_prefix)
  for _, signal in pairs(signals) do
    local signal_count = signal.count/60
    if signal_count < 0 and not self.config.allow_neg then
      -- If value is negative and config.allow_neg is not set, ignore this signal.
      break
    end
    local signal_name = entity_prefix .. "-" .. signal.signal.name
    self.stats.on_flow(signal_name, signal_count)
    if self.config.ticks > 1 then -- If we're not reading the network every tick, cache values
      self.items[store_key][signal_name] = signal_count
    end
    --self.items[colour][signal.signal.name] = {item_type = signal.signal.type, item_count=signal.count}
  end
end

function Graphtool:onTick()
  if self.config.ticks == 1 or game.tick % self.config.ticks == 0 then
    -- Read the signal network every config.ticks (defaults to 1)
    if self.config.ticks > 1 then
      self.items = items_default()  -- Wipe all stored values, ready for next read.
    end
    if self.config.separate then
      for colour, wire in pairs(colours) do
        local network = self.entity.get_circuit_network(wire)
        if network and network.signals then
          self:process_signals(network.signals, colour, "graphtool-" .. colour)
        end
      end
    else -- Merged signals
      local signals = self.entity.get_merged_signals()
      if signals then
        self:process_signals(signals, "merged", "graphtool")
      end
    end
  else -- If not reading this tick, re-send stored signals.
    stored_list = self.config.separate and {"red", "green"} or {"merged"}
    for _, stored_type in pairs(stored_list) do
      for signal_name, signal_count in pairs(self.items[stored_type]) do
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
  --self.ui[player_index].ui_top["Graphtool"]["frameConfigHeader"]["flowConfig"]["tableConfigRadio"].style.column_alignments[1] = "right"
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
