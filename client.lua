local ESX = exports.es_extended:getSharedObject()
local SavedVehicles = {}

CreateThread(function()
    lib.callback('persistentvehicles:getServerVehicles', false, function(Vehicles)
        if not Vehicles then return end
        SavedVehicles = Vehicles
        for plate, vehicleData in pairs(Vehicles) do
            
            if vehicleData then
                local model = type(vehicleData.vehicle.model) == "number" and vehicleData.vehicle.model or GetHashKey(vehicleData.vehicle.model)
                RequestModel(model) -- preloads all the car's models immediately
                while not HasModelLoaded(model) do
                    Wait(1)
                end
                LoadProperties(plate)
            end
        end
    end)
end)

/*
    vehicles' properties won't load properly because of player's distance from the entity.
    i came with this function that could be a little bit heavy, but i think its better 
    than a continuous loop that spawns and despawns cars based on the distance, like 90% of paid scripts of this entity.
    i do not have any other solution, if you have, submit a pr :)
*/
function LoadProperties(plate) 
    CreateThread(function()
        local Vehicle = SavedVehicles[plate]
        while not NetworkDoesEntityExistWithNetworkId(Vehicle.netId) do
            Wait(2000) -- lower it is, more resmon affects but it is way smoother
        end
        
        local vehicleId = NetToVeh(Vehicle.netId)
        if ESX.Math.Trim(GetVehicleNumberPlateText(vehicleId)) ~= ESX.Math.Trim(plate) then
            ESX.Game.SetVehicleProperties(vehicleId, Vehicle.vehicle)
        end
    end)
end

-- havent 
RegisterNetEvent('persistentvehicles:reloadProperties', function (plate, netId)
    local Vehicle = SavedVehicles[plate]
    if not Vehicle then return end
    Vehicle.netId = netId -- replaces the net id
    LoadProperties(plate)
end)

AddEventHandler('esx:exitedVehicle', function(vehicle)
    local coords = GetEntityCoords(vehicle)
    if DoesEntityExist(vehicle) then
        local saveOnDatabase = true -- false = saves just on serverside, true = saves on database
        lib.callback.await('persistentvehicles:updateVehicle', false, ESX.Game.GetVehicleProperties(vehicle), vec4(coords.x, coords.y, coords.z, GetEntityHeading(vehicle)), saveOnDatabase)
        -- uncomment this if you are using events instead of callbacks
        --TriggerServerEvent('persistentvehicles:updateVehicle', ESX.Game.GetVehicleProperties(vehicle), vec4(coords.x, coords.y, coords.z, GetEntityHeading(vehicle)), saveOnDatabase)
    end
end)