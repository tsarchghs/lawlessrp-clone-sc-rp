-- FiveM Client Script for South Central Roleplay

local PlayerData = {}
local isLoggedIn = false

-- Event to receive player data from server
RegisterNetEvent('scrp:setPlayerData')
AddEventHandler('scrp:setPlayerData', function(data)
    PlayerData = data
    isLoggedIn = true
    
    -- Set player model
    local model = GetHashKey("mp_m_freemode_01")
    if data.Gender == 0 then
        model = GetHashKey("mp_f_freemode_01")
    end
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end
    
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    
    -- Set player position
    SetEntityCoords(PlayerPedId(), data.Position.x, data.Position.y, data.Position.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), data.Position.heading)
    
    -- Set health and armour
    SetEntityHealth(PlayerPedId(), data.Health)
    SetPedArmour(PlayerPedId(), data.Armour)
    
    print(("[SC:RP] Character loaded: %s"):format(data.Name))
end)

-- Event to update inventory
RegisterNetEvent('scrp:updateInventory')
AddEventHandler('scrp:updateInventory', function(inventory)
    PlayerData.Inventory = inventory
    -- Update UI here if needed
end)

-- Main thread for various checks
CreateThread(function()
    while true do
        Wait(1000)
        
        if isLoggedIn and PlayerData then
            -- Update player position
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            
            PlayerData.Position = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                heading = heading
            }
            
            -- Update health and armour
            PlayerData.Health = GetEntityHealth(ped)
            PlayerData.Armour = GetPedArmour(ped)
        end
    end
end)

-- Command to check stats
RegisterCommand('stats', function()
    if not isLoggedIn or not PlayerData then
        print("You are not logged in!")
        return
    end
    
    TriggerEvent('chatMessage', "[STATS]", { 255, 255, 255 }, 
        ("Name: %s | Level: %d | Money: $%d | Bank: $%d"):format(
            PlayerData.Name, PlayerData.Level, PlayerData.Money, PlayerData.BankMoney))
end, false)

-- Command to check inventory
RegisterCommand('inventory', function()
    if not isLoggedIn or not PlayerData then
        print("You are not logged in!")
        return
    end
    
    if #PlayerData.Inventory == 0 then
        TriggerEvent('chatMessage', "[INVENTORY]", { 255, 255, 255 }, "Your inventory is empty.")
        return
    end
    
    TriggerEvent('chatMessage', "[INVENTORY]", { 255, 255, 255 }, "Your inventory:")
    for i, item in ipairs(PlayerData.Inventory) do
        TriggerEvent('chatMessage', "", { 200, 200, 200 }, 
            ("- %s (x%d)"):format(item.ItemName, item.Quantity))
    end
end, false)
