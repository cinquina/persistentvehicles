local Vehicles = {}
local ezBridge = {}

if GetResourceState("es_extended") == "started" then
    local ESX = exports.es_extended:getSharedObject()
    ezBridge.GetPlayer = ESX.GetPlayerFromId
    ezBridge.HasPermission = function(source)
        local player = ezBridge.GetPlayer(source)
        return player.group == "admin"
    end
else
    local QBCore = exports['qb-core']:GetCoreObject()
    ezBridge.GetPlayer = function(source)
        local player = QBCore.Functions.GetPlayer(source)
        player.identifier = player.citizenid
        return player
    end
    ezBridge.HasPermission = function(source)
        return QBCore.Functions.HasPermission(source, 'admin')
    end
end

vehiclesQuery = MySQL.query.await('SELECT * FROM `owned_vehicles`', {})
if vehiclesQuery then
    for k, v in pairs(vehiclesQuery) do
        v.vehicle = json.decode(v.vehicle)
        Vehicles[v.plate] = v
    end
end

CreateThread(function()
    if not Vehicles then return end
    for _, vehicleData in pairs(Vehicles) do
        vehicleData.vehicle = type(vehicleData.vehicle) == "string" and json.decode(vehicleData.vehicle) or
        vehicleData.vehicle

        if vehicleData.coords then
            vehicleData.coords = json.decode(vehicleData.coords)
            local vehicle = CreateVehicleServerSetter(vehicleData.vehicle.model, vehicleData.type, vehicleData.coords.x,
                vehicleData.coords.y, vehicleData.coords.z, vehicleData.coords.w)
            SetVehicleDoorsLocked(vehicle, 2)
            vehicleData.netId = NetworkGetNetworkIdFromEntity(vehicle)
        end
    end
end)

local function SaveVehiclesPositions()
    for k, v in pairs(Vehicles) do
        local vehicle = NetworkGetEntityFromNetworkId(v.netId)
        if DoesEntityExist(vehicle) then
            local coords = GetEntityCoords(vehicle)

            MySQL.update.await('UPDATE owned_vehicles SET vehicle = ?, coords = ? WHERE plate = ?',
                { json.encode(v.vehicle), json.encode(vec4(coords.x, coords.y, coords.z, GetEntityHeading(vehicle))), v
                    .plate })
        end
    end
end

local function AddVehicle(targetId, props, coords, netId)
    local xPlayer = ezBridge.GetPlayer(targetId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    local vehicleType = GetVehicleType(entity)
    MySQL.insert('INSERT INTO `owned_vehicles` (owner, plate, vehicle, type, coords) VALUES (?, ?, ?, ?, ?)',
        { xPlayer.identifier, props.plate, json.encode(props), vehicleType or "automobile", coords and
        json.encode(coords) or nil }, function(id)
        local data = {
            owner = xPlayer.identifier,
            plate = props.plate,
            vehicle = props,
            type = vehicleType or "automobile",
            coords = coords
        }
        Vehicles[props.plate] = data
        if not coords then
            DeleteEntity(entity)
        end
    end)
end

exports('AddVehicle', AddVehicle)

-- you could replace this with a event, but italy is full of smart modders so i honestly prefer using callbacks :C (you need to uncomment things)
lib.callback.register('persistentvehicles:updateVehicle', function(source, props, coords, saveOnDatabase)
    if not Vehicles[props.plate] then return end
    Vehicles[props.plate].vehicle = props
    Vehicles[props.plate].coords = coords

    if saveOnDatabase then
        MySQL.update.await('UPDATE owned_vehicles SET vehicle = ?, coords = ? WHERE plate = ?',
            { json.encode(props), json.encode(coords), props.plate })
    end
end)

-- RegisterNetEvent('persistentvehicles:updateVehicle', function (props, coords, saveOnDatabase)
--     if not Vehicles[props.plate] then return end
--     Vehicles[props.plate].vehicle = props
--     Vehicles[props.plate].coords = coords

--     if saveOnDatabase then
--         MySQL.update.await('UPDATE owned_vehicles SET vehicle = ?, coords = ? WHERE plate = ?',
--             { json.encode(props), json.encode(coords), props.plate })
--     end
-- end)

lib.callback.register('persistentvehicles:addVehicle', function(source, props, coords, netId, targetId)
    return AddVehicle(targetId or source, props, coords, netId)
end)

CreateThread(function()
    while true do
        Wait(20 * 1000 * 60) -- saves vehicles every 20 minutes
        SaveVehiclesPositions()
    end
end)

AddEventHandler('onResourceStop', function(rn)
    if rn ~= GetCurrentResourceName() then return end
    for k, v in pairs(Vehicles) do
        DeleteEntity(NetworkGetEntityFromNetworkId(v.netId))
    end
end)

AddEventHandler("txAdmin:events:scheduledRestart", function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(50000)
            SaveVehiclesPositions()
        end)
    end
end)

RegisterCommand('saveallvehs', function(source)
    if ezBridge.HasPermission(source) then
        SaveVehiclesPositions()
    end
end)

RegisterCommand('rollbackvehs', function(source)
    if ezBridge.HasPermission(source) then
        for _, vehicleData in pairs(Vehicles) do
            local veh = NetworkGetEntityFromNetworkId(vehicleData.netId)
            if not DoesEntityExist(veh) then
                if vehicleData.coords then
                    local vehicle = CreateVehicleServerSetter(vehicleData.vehicle.model, vehicleData.type,
                        vehicleData.coords.x, vehicleData.coords.y, vehicleData.coords.z, vehicleData.coords.w)
                    SetVehicleDoorsLocked(vehicle, 2)
                    vehicleData.netId = NetworkGetNetworkIdFromEntity(vehicle)
                    SetVehicleNumberPlateText(vehicle, vehicleData.plate)
                    TriggerClientEvent('persistentvehicles:reloadProperties', -1, vehicleData.plate, vehicleData.netId)
                end
            end
        end
    end
end)
