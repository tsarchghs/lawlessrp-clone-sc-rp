-- FiveM Server Script for South Central Roleplay
-- mysql-async version 3.3.2 compatible with FiveM artifact 15859

require 'server/config'
require 'server/database'
require 'server/account'
require 'server/player'
require 'server/inventory'
require 'server/factions'
require 'server/jobs'
require 'server/vehicles'
require 'server/properties'
require 'server/banking'
require 'server/weapons'
require 'server/phone'
require 'server/medical'
require 'server/drugs'
require 'server/gangs'
require 'server/businesses'
require 'server/skills'
require 'server/crafting'
require 'server/government'
require 'server/turf_wars'
require 'server/racing'
require 'server/prison'
require 'server/hitman'
require 'server/admin'
require 'server/commands'
require 'server/weapon_commands'
require 'server/business_commands'
require 'server/racing_commands'

-- Initialize all systems on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(1000) -- Wait for mysql-async to be ready
        connectToDatabase()
        initializeDatabase()
        initializePropertiesTable()
        initializeBankingTables()
        initializeWeaponTables()
        initializePhoneTables()
        initializeMedicalTables()
        initializeDrugTables()
        initializeGangTables()
        initializeBusinessTables()
        initializeSkillsTable()
        initializeCraftingTables()
        initializeGovernmentTables()
        initializeTurfWarTables()
        initializeRacingTables()
        initializePrisonTables()
        initializeHitmanTables()
        
        loadFactions()
        loadProperties()
        loadVehicles()
        loadBusinesses()
        loadCraftingStations()
        loadGovernment()
        loadTurfData()
        loadRaces()
        loadContracts()
        
        print("[SC:RP] All systems initialized successfully!")
        print("[SC:RP] Using mysql-async version 3.3.2")
        print("[SC:RP] Compatible with FiveM artifact 15859")
        print("[SC:RP] Advanced Features: Turf Wars, Racing, Prison, Hitman System")
    end
end)

-- Enhanced player data loading with all systems
AddEventHandler('playerJoining', function(source)
    print(('Player joining: %s'):format(GetPlayerName(source)))
    
    -- Send comprehensive welcome message
    TriggerClientEvent('chatMessage', source, "[SC:RP]", { 255, 255, 0 }, 
        "Welcome to South Central Roleplay - Complete Edition!")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Basic: /login, /createaccount, /createchar, /stats, /inventory, /skills")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Business: /businesses, /buybusiness, /hire, /fire, /buy, /restock")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Turf Wars: /captureturf, /turfinfo, /turfs")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Racing: /races, /createrace, /joinrace, /bet")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Prison: /work, /fight, /prisoninfo")
    TriggerClientEvent('chatMessage', source, "[INFO]", { 255, 255, 255 }, 
        "Hitman: /contract, /contracts, /acceptcontract, /hitmaninfo")
end)

-- Enhanced player data saving with all systems
AddEventHandler('playerDropped', function(reason)
    local source = source
    if PlayerData[source] then
        print(('Player dropped: %s'):format(PlayerData[source].Name))
        savePlayerData(source)
        savePlayerSkills(source)
        savePrisonData(source)
        saveHitmanData(source)
        PlayerData[source] = nil
        PlayerSkills[source] = nil
        PrisonData[source] = nil
        HitmanData[source] = nil
    end
end)

-- Enhanced character loading with all systems
RegisterNetEvent('scrp:selectCharacter')
AddEventHandler('scrp:selectCharacter', function(characterId)
    local source = source
    loadPlayerData(source, characterId)
    loadPlayerSkills(source, characterId)
    loadPrisonData(source, characterId)
    loadHitmanData(source, characterId)
end)

-- Handle player death for various systems
AddEventHandler('baseevents:onPlayerDied', function(killerId, deathCause)
    local source = source
    
    if killerId and killerId ~= source then
        -- Handle turf war deaths
        handleTurfWarDeath(killerId, source)
        
        -- Handle hitman contract completion
        completeContract(killerId, source)
        
        -- Log combat for weapons system
        if deathCause then
            logCombat(PlayerData[killerId] and PlayerData[killerId].CharacterID or 0, 
                     PlayerData[source] and PlayerData[source].CharacterID or 0, 
                     deathCause, 100, 0, 0)
        end
    end
end)

-- Auto-save enhanced with all systems
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        for source, _ in pairs(PlayerData) do
            savePlayerData(source)
            savePlayerSkills(source)
            savePrisonData(source)
            saveHitmanData(source)
            
            -- Save vehicle data for spawned vehicles
            for vehicle, vehicleId in pairs(SpawnedVehicles) do
                saveVehicleData(vehicleId)
            end
        end
        print("[SC:RP] Auto-saved all player data and systems")
    end
end)

print("[SC:RP] Complete main server script loaded successfully!")
print("[SC:RP] Features: Businesses, Skills, Crafting, Government, Elections")
print("[SC:RP] Advanced: Turf Wars, Racing, Prison, Hitman Contracts")
print("[SC:RP] Database: mysql-async 3.3.2 compatible with FiveM 15859")
