# 🚗 persistent vehicles
**ESX** (easy to convert to QB) and **ox_lib** based persistent vehicles system.
I haven't worked on this too much, decided to release because it's working but unfinished, so y'all can use it but at your own risk.
You can use it and it should be safe but **IT IS NOT USER FRIENDLY** you might need to get help by a **Developer** to use this script, since it is **NOT** completely ready for production.
If you need help you can join our [Discord Server](https://discord.gg/547nKvQhZ7)

## ❓ Documentation
- How to add new vehicle?
```lua
    Server side:
    exports["persistentvehicles"]:AddVehicle(targetId, vehicleProps, coords, netId)
    /*
        targetId: server id of the car owner
        vehicleProps: vehicle properties
        coords: coords where the vehicle is currently spawned (it will not spawn your vehicle, you need to spawn it yourself)
        netId: vehicle current netId
    */
    Client side (callback):
    lib.callback.await("persistentvehicles:addVehicle", false, vehicleProps, coords, netId, targetId)
    /*
        vehicleProps: vehicle properties
        coords: coords where the vehicle is currently spawned (it will not spawn your vehicle, you need to spawn it yourself)
        netId: vehicle current netId
        targetId: server id of the car owner (if its null, it will use the source that triggered the callback)
    */
```

## 🤝 Support
- [Discord Server](https://discord.gg/547nKvQhZ7)

## 💻 Developer
- [Five Developments](https://discord.gg/547nKvQhZ7)
