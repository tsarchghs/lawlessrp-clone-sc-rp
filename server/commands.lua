-- Command system

-- Character creation command
RegisterCommand('createchar', function(source, args, rawCommand)
    if #args < 4 then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, 
            "Usage: /createchar [name] [age] [gender] [skin]")
        return
    end

    local name = args[1]
    local age = tonumber(args[2])
    local gender = tonumber(args[3])
    local skin = tonumber(args[4])

    if not age or age < 18 or age > 80 then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "Age must be between 18 and 80")
        return
    end

    if not gender or (gender ~= 0 and gender ~= 1) then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "Gender must be 0 (female) or 1 (male)")
        return
    end

    -- Assume account ID is stored somewhere (from login)
    local accountId = 1 -- This should be retrieved from the player's session
    createCharacter(source, accountId, name, age, gender, skin)
end, false)

-- Money commands
RegisterCommand('givemoney', function(source, args, rawCommand)
    if #args ~= 2 then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, 
            "Usage: /givemoney [playerid] [amount]")
        return
    end

    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then return end
    if not PlayerData[source] or not PlayerData[targetId] then return end
    if PlayerData[source].Money < amount then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You don't have enough money")
        return
    end

    PlayerData[source].Money = PlayerData[source].Money - amount
    PlayerData[targetId].Money = PlayerData[targetId].Money + amount

    TriggerClientEvent('chatMessage', source, "[MONEY]", { 0, 255, 0 }, 
        ("You gave $%d to %s"):format(amount, PlayerData[targetId].Name))
    TriggerClientEvent('chatMessage', targetId, "[MONEY]", { 0, 255, 0 }, 
        ("You received $%d from %s"):format(amount, PlayerData[source].Name))
end, false)

-- Inventory commands
RegisterCommand('giveitem', function(source, args, rawCommand)
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, 
            "Usage: /giveitem [item] [quantity]")
        return
    end

    local itemName = args[1]
    local quantity = tonumber(args[2]) or 1

    if addItemToInventory(source, itemName, quantity) then
        TriggerClientEvent('chatMessage', source, "[INVENTORY]", { 0, 255, 0 }, 
            ("Added %dx %s to your inventory"):format(quantity, itemName))
    end
end, false)

-- Job commands
RegisterCommand('setjob', function(source, args, rawCommand)
    if #args ~= 2 then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, 
            "Usage: /setjob [playerid] [jobid]")
        return
    end

    local targetId = tonumber(args[1])
    local jobId = tonumber(args[2])
    
    if not targetId or not jobId then return end
    if not PlayerData[targetId] then return end

    setPlayerJob(targetId, jobId)
end, false)

-- Faction commands
RegisterCommand('createfaction', function(source, args, rawCommand)
    if #args < 1 then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, 
            "Usage: /createfaction [name]")
        return
    end

    local name = table.concat(args, " ")
    createFaction(name, 0, "#FFFFFF")
end, false)

RegisterCommand('finvite', function(source, args, rawCommand)
    if #args ~= 2 then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, 
            "Usage: /finvite [playerid] [rank]")
        return
    end

    local targetId = tonumber(args[1])
    local rank = tonumber(args[2])
    
    if not targetId or not rank then return end
    if not PlayerData[source] or not PlayerData[targetId] then return end
    if PlayerData[source].FactionID == 0 then
        TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "You are not in a faction")
        return
    end

    inviteToFaction(source, targetId, PlayerData[source].FactionID, rank)
end, false)
