local TRAIN_BRAKE_FACTOR_HIGHSPEED = 0.83
local TRAIN_BRAKE_FACTOR_LOWSPEED = 0.7

function setup()
    ---@type {enabled:boolean,limit:number}[]
	storage.speedLimits = storage.speedLimits or {}
    ---@type {enabled:boolean,maxSpeed:number}[]
	storage.trainLimits = storage.trainLimits or {}
end

---@param speed number
function getSpeedCaption(speed)
    if (speed == 0) then
        return "Unrestricted"
    else
        return tostring(speed).." km/h"
    end
end

---@param train LuaTrain
---@param maxSpeed number
function brakeTrain(train,maxSpeed)
    if (math.abs(train.speed - maxSpeed) < 0.01) then
        train.speed = maxSpeed
    elseif ((train.speed * 216) >= 35) then
        train.speed = (TRAIN_BRAKE_FACTOR_HIGHSPEED + math.max(train.weight/100000,0.1)) * train.speed
    else
        train.speed = TRAIN_BRAKE_FACTOR_LOWSPEED * train.speed
    end
end
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for key, value in next, orig, nil do
            copy[deepcopy(key)] = deepcopy(value)
        end
    else
        copy = orig
    end
    return copy
end

script.on_init(setup)
script.on_configuration_changed(setup)

-- run train speed limiter every 5 ticks
script.on_nth_tick(5,function(event)
    for _, train in pairs(game.train_manager.get_trains({is_manual=false,is_moving=true})) do
        -- handle signals
        local position = train.front_end.location.position
        local surface = train.front_end.rail.surface
        local signals = surface.find_entities_filtered{
            type = {"rail-signal", "rail-chain-signal"},
            position = position,
            radius = 5
        }
        local signal = signals[1]
        if (signal and signal.valid) then
            local originalRail = signal.get_connected_rails()[1]
            if (originalRail) then
                local rails = {originalRail}

                for _, dir in pairs({defines.rail_direction.front,defines.rail_direction.back}) do
                    for _, connect in pairs({defines.rail_connection_direction.straight,defines.rail_connection_direction.left,defines.rail_connection_direction.right}) do
                        local neighbour = originalRail.get_connected_rail({rail_direction=dir,rail_connection_direction=connect})
                        if (neighbour) then table.insert(rails,neighbour) end
                    end
                end
                for _, rail in pairs(rails) do
                    if (rail and rail.is_rail_in_same_rail_block_as(train.front_end.rail)) then
                        local signalData = storage.speedLimits[signal.unit_number]
                        if (signalData and signalData.enabled) then
                            -- convert km/h to m/tick (/216)
                            storage.trainLimits[train.id] = {enabled=(signalData.limit > 0),maxSpeed=signalData.limit/216}
                        end
                        break
                    end
                end
            end
        end

        -- handle train braking (clamp when close near limit)
        local trainData = storage.trainLimits[train.id] or {enabled=false,maxSpeed=0}
        if (trainData and trainData.enabled and train.speed > trainData.maxSpeed) then
            brakeTrain(train,trainData.maxSpeed)
        end
    end
end)

--render ALT-mode speed display
script.on_nth_tick(30,function(event)
    local player = game.get_player(1)
    if (not player) then return end
    local signals = player.surface.find_entities_filtered{
        type = {"rail-signal", "rail-chain-signal"},
        position = player.position,
        radius = 50
    }
    for _, signal in ipairs(signals) do
        local signalData = storage.speedLimits[signal.unit_number]
        if (signal.valid and signalData and signalData.enabled) then
            rendering.draw_text{
                text = getSpeedCaption(signalData.limit),
                surface = signal.surface,
                target = signal,
                target_offset = {0, -1.5},
                color = {r = 0.9, g = 0.9, b = 0.9},
                scale = 1,
                players = {player.index},
                alignment = "center",
                time_to_live = 30,
                only_in_alt_mode = true
            }
        end
    end
end)

-- handle signal GUI opened
script.on_event(defines.events.on_gui_opened, function(event)
    if (event.gui_type == defines.gui_type.entity and event.entity and (event.entity.name == "rail-signal" or event.entity.name == "rail-chain-signal")) then
        local player = game.players[event.player_index]
        local signalId = event.entity.unit_number
        local signalData = storage.speedLimits[signalId] or {enabled=false,limit=0}

        if (player.gui.relative.speed_limit_gui) then player.gui.relative.speed_limit_gui.destroy() end
        local gui = player.gui.relative.add{type="frame", name="speed_limit_gui", caption="Set Speed Limit", anchor={
            gui = defines.relative_gui_type.rail_signal_base_gui,
            position = defines.relative_gui_position.bottom,
        }, direction="vertical"}
        gui.add{type="checkbox", name="speed_apply", caption="Apply Speed Limit", state=signalData.enabled,tooltip="When unapplied, this signal does not affect the speed of the train. (Also won't revert the speed limit!)"}
        local labelFrame = gui.add{type="flow",name="speed_slider",direction="horizontal"}
        local slider = labelFrame.add{type="slider", name="speed_slider", caption="Maximum Speed (km/h)", minimum_value=0, maximum_value=300, value=signalData.limit, tooltip="The speed to apply to affected trains. (Set value to zero to revert speed limit!)"}
        slider.style.horizontally_stretchable = true
        labelFrame.add{type="label", name="speed_label", caption=getSpeedCaption(signalData.limit)}
    end
end)

-- handle signal GUI closed
script.on_event(defines.events.on_gui_closed,function(event)
    if (event.gui_type == defines.gui_type.entity and event.entity and (event.entity.name == "rail-signal" or event.entity.name == "rail-chain-signal")) then
        local player = game.players[event.player_index]
        local gui = player.gui.relative.speed_limit_gui
        local signalId = event.entity.unit_number
        if (gui and signalId) then
            local checkbox = gui.speed_apply
            local slider = gui.speed_slider.speed_slider
            storage.speedLimits[signalId] = {enabled=checkbox.state,limit=slider.slider_value}
        end
    end
end)

-- handle speed slider label
script.on_event(defines.events.on_gui_value_changed,function(event)
    if (event.element.name == "speed_slider") then
        local label = event.element.parent.speed_label
        if (label) then
            label.caption = getSpeedCaption(event.element.slider_value)
        end
    end
end)

-- handle entity settings copy/paste
script.on_event(defines.events.on_entity_settings_pasted,function(event)
    if ((not event.source) or (not event.source.valid)) then return end
    if (event.source.name ~= "rail-signal" and event.source.name ~= "rail-chain-signal") then return end
    if ((not event.destination) or (not event.destination.valid)) then return end
    if (event.destination.name ~= "rail-signal" and event.destination.name ~= "rail-chain-signal") then return end

    local sourceData = storage.speedLimits[event.source.unit_number]
    if (sourceData) then
        storage.speedLimits[event.destination.unit_number] = deepcopy(sourceData)
    end
end)