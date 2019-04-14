local Entity = require('__stdlib__/stdlib/entity/entity')
local Event = require('__stdlib__/stdlib/event/event')

--local Logger = require '__stdlib__/stdlib/misc/logger'
--LOG = Logger.new('graphtool', 'main', 'true', {force_append=true})

local Csv = require 'csv'
local Graphtool = require 'graphtool'

local function onPlaceEntity(event)
  local entity = event.created_entity or event.entity
  if not entity.valid then
    log("onPlaceEntity: invalid entity?")
    return
  end

  if entity.name == 'graphtool' then
    if not global._GPs then global._GPs = {} end
    global._GPs[entity.unit_number] = Graphtool(entity)
  end
end

local function onRemoveEntity(event)
  local eventEntity = event.entity
  if eventEntity.name == 'graphtool' then
    global._GPs[eventEntity.unit_number]:destroy(event.player_index)
    global._GPs[eventEntity.unit_number] = nil
  end
end

local function onTick(event)
  if not global._GPs then return end

  for _, GP in pairs(global._GPs) do
    GP:onTick()
  end
end

local function toggleGui(event, action)
  if event.entity and event.entity.name == "graphtool" then
    local player_index = event.player_index
    local GP = global._GPs[event.entity.unit_number]
    if GP then
      if action == "open" then
        GP:createGui(player_index)
      elseif action == "close" then
        GP:removeGui(player_index)
      end
    end
  end
end

local function config_changed(event)
  log("Got config changed.")
end

local function onLoad()
  if global._GPs then
    for _, GP in pairs(global._GPs) do
      Graphtool.metatable(GP)
    end
  end
end

local evs = defines.events
--[[
script.on_event({evs.on_built_entity,evs.on_robot_built_entity}, onPlaceEntity)
script.on_event({evs.on_entity_died, evs.on_pre_player_mined_item, evs.robot_pre_mined, evs.script_raised_destroy}, onRemoveEntity)
script.on_event(evs.on_tick, onTick)
script.on_event(evs.on_gui_opened, function(e) toggleGui(e, "open") end)
script.on_event(evs.on_gui_closed, function(e) toggleGui(e, "close") end)
script.on_event(evs.on_gui_value_changed, guiValue)
script.on_load(onLoad)
--]]

----[[
Event.register({evs.on_built_entity,evs.on_robot_built_entity}, onPlaceEntity)
Event.register({evs.on_entity_died, evs.on_pre_player_mined_item, evs.robot_pre_mined, evs.script_raised_destroy}, onRemoveEntity)
Event.register(evs.on_tick, onTick)
Event.register(evs.on_gui_opened, function(e) toggleGui(e, "open") end)
Event.register(evs.on_gui_closed, function(e) toggleGui(e, "close") end)
--Event.register(evs.on_gui_value_changed, guiValue)
Event.on_load(onLoad)
--]]
