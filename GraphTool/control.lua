--
-- Includes
--
-- mod
local Graphtool = require 'graphtool'
local Defines   = require('defines')
-- stdlib
local Entity    = require('__stdlib__/stdlib/entity/entity')
local Event     = require('__stdlib__/stdlib/event/event')

local function onPlaceEntity(event)
  local entity = event.created_entity or event.entity
  if not entity.valid then
    log("onPlaceEntity: invalid entity?")
    return
  end

  if entity.name == Defines.mod_entity then
    if not global._GTs then global._GTs = {} end
    global._GTs[entity.unit_number] = Graphtool(entity)
  end
end

local function onRemoveEntity(event)
  local eventEntity = event.entity
  if eventEntity.name == Defines.mod_entity then
    global._GTs[eventEntity.unit_number]:destroy()
    global._GTs[eventEntity.unit_number] = nil
  end
end

local function onTick()
  for _, GT in pairs(global._GTs) do
    if GT.config.enabled then
      GT:onTick()
    end
    -- if game.tick % 1800 == 0 then
    --   log("GT.ui: " .. serpent.block(GT.ui))
    -- end
  end
end

local function toggleGui(event, action)
  if event.entity and event.entity.name == Defines.mod_entity then
    local player_index = event.player_index
    local GT = global._GTs[event.entity.unit_number]
    if GT then
      if action == "open" then
        GT:createGui(player_index)
      elseif action == "close" then
        GT:removeGui(player_index)
      end
    end
  end
end

local function onInit(event)
  if not global._GTs then global._GTs = {} end
end

local function onLoad()
  if global._GTs then
    for _, GT in pairs(global._GTs) do
      Graphtool.metatable(GT) -- rebuild metatables for the Graphtool objects
      GT:Gui_metatable()      -- rebuild metatables for the Guibuild object(s)
      GT:removeAllGui()       -- remove any open GUIs, as their events can't work post-load. User(s) can just re-open them.
    end
  end
end

local evs = defines.events

Event.register({evs.on_built_entity,evs.on_robot_built_entity}, onPlaceEntity)
Event.register({evs.on_entity_died, evs.on_pre_player_mined_item, evs.robot_pre_mined, evs.script_raised_destroy}, onRemoveEntity)
Event.register(evs.on_tick, onTick)
Event.register(evs.on_gui_opened, function(e) toggleGui(e, "open") end)
Event.register(evs.on_gui_closed, function(e) toggleGui(e, "close") end)
Event.on_load(onLoad)
Event.on_init(onInit)
Event.on_configuration_changed(onInit)
