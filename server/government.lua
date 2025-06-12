-- Government system for SC:RP FiveM

Government = {
    mayor = 0, -- Character ID of the mayor
    treasury = 1000000, -- City treasury amount
    taxRate = 5, -- Tax rate percentage
    propertyTaxRate = 2, -- Property tax rate percentage
    businessTaxRate = 3, -- Business tax rate percentage
    incomeTaxRate = 4, -- Income tax rate percentage
    electionActive = false, -- Is an election currently active
    electionEndTime = 0, -- When the current election ends
    candidates = {} -- List of candidates for mayor
}

-- Initialize government tables
function initializeGovernmentTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `government` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Mayor` int(11) DEFAULT 0,
            `Treasury` int(11) DEFAULT 1000000,
            `TaxRate` int(2) DEFAULT 5,
            `PropertyTaxRate` int(2) DEFAULT 2,
            `BusinessTaxRate` int(2) DEFAULT 3,
            `IncomeTaxRate` int(2) DEFAULT 4,
            `LastTaxCollection` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `government_laws` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(64) NOT NULL,
            `Description` text NOT NULL,
            `CreatedBy` int(11) NOT NULL,
            `CreatedDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `Active` int(1) DEFAULT 1,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `government_elections` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `StartDate` datetime DEFAULT CURRENT_TIMESTAMP,
            `EndDate` datetime NOT NULL,
            `Winner` int(11) DEFAULT NULL,
            `Active` int(1) DEFAULT 1,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `government_candidates` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ElectionID` int(11) NOT NULL,
            `CharacterID` int(11) NOT NULL,
            `Votes` int(11) DEFAULT 0,
            `Campaign` text DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`ElectionID`) REFERENCES `government_elections`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `government_votes` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `ElectionID` int(11) NOT NULL,
            `VoterID` int(11) NOT NULL,
            `CandidateID` int(11) NOT NULL,
            `VoteDate` datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`ElectionID`) REFERENCES `government_elections`(`ID`),
            FOREIGN KEY (`CandidateID`) REFERENCES `government_candidates`(`ID`),
            UNIQUE KEY `ElectionVoter` (`ElectionID`, `VoterID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])
}

-- Function to load government data
function loadGovernment()
    local query = [[
        SELECT * FROM `government` ORDER BY `ID` DESC LIMIT 1
    ]]

    MySQL.query(query, {}, function(rows)
        if #rows > 0 then
            local data = rows[1]
            Government.mayor = data.Mayor
            Government.treasury = data.Treasury
            Government.taxRate = data.TaxRate
            Government.propertyTaxRate = data.PropertyTaxRate
            Government.businessTaxRate = data.BusinessTaxRate
            Government.incomeTaxRate = data.IncomeTaxRate
        else
            -- Insert default government data
            MySQL.query([[
                INSERT INTO `government` (`Mayor`, `Treasury`, `TaxRate`, `PropertyTaxRate`, `BusinessTaxRate`, `IncomeTaxRate`)
                VALUES (0, 1000000, 5, 2, 3, 4)
            ]])
        end
        
        -- Load active election if any
        loadActiveElection()
    end)
end

-- Function to load active election
function loadActiveElection()
    local query = [[
        SELECT * FROM `government_elections` WHERE `Active` = 1 AND `EndDate` > NOW() ORDER BY `ID` DESC LIMIT 1
    ]]

    MySQL.query(query, {}, function(rows)
        if #rows > 0 then
            local election = rows[1]
            Government.electionActive = true
            Government.electionEndTime = os.time() + (os.difftime(os.time(election.EndDate), os.time()))
            
            -- Load candidates
            loadElectionCandidates(election.ID)
        else
            Government.electionActive = false
            Government.electionEndTime = 0
            Government.candidates = {}
        end
    end)
end

-- Function to load election candidates
function loadElectionCandidates(electionId)
    local query = [[
        SELECT gc.*, c.Name as CandidateName FROM `government_candidates` gc
        JOIN `characters` c ON gc.CharacterID = c.ID
        WHERE gc.`ElectionID` = @electionId
    ]]

    MySQL.query(query, {
        ['@electionId'] = electionId
    }, function(rows)
        Government.candidates = {}
        for i = 1, #rows do
            local candidate = rows[i]
            table.insert(Government.candidates, {
                ID = candidate.ID,
                CharacterID = candidate.CharacterID,
                Name = candidate.CandidateName,
                Votes = candidate.Votes,
                Campaign = candidate.Campaign
            })
        end
    end)
end

-- Function to start an election
function startElection(duration)
    if Government.electionActive then
        return false, "An election is already active!"
    end
    
    local endDate = os.date("%Y-%m-%d %H:%M:%S", os.time() + (duration * 86400)) -- duration in days
    
    local query = [[
        INSERT INTO `government_elections` (`EndDate`, `Active`)
        VALUES (@endDate, 1)
    ]]

    MySQL.query(query, {
        ['@endDate'] = endDate
    }, function(rows, affected)
        if affected > 0 then
            local electionId = MySQL.insertId
            Government.electionActive = true
            Government.electionEndTime = os.time() + (duration * 86400)
            Government.candidates = {}
            
            -- Announce election
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 255, 255, 0 }, 
                ("A mayoral election has started! It will end in %d days. Use /runformayor to become a candidate."):format(duration))
            
            -- Set timer to end election
            SetTimeout(duration * 86400 * 1000, function()
                endElection(electionId)
            end)
            
            return true, "Election started successfully!"
        end
        
        return false, "Failed to start election!"
    end)
end

-- Function to end an election
function endElection(electionId)
    local query = [[
        UPDATE `government_elections` SET `Active` = 0 WHERE `ID` = @electionId
    ]]

    MySQL.query(query, {
        ['@electionId'] = electionId
    })
    
    -- Find winner
    local query2 = [[
        SELECT gc.*, c.Name as CandidateName FROM `government_candidates` gc
        JOIN `characters` c ON gc.CharacterID = c.ID
        WHERE gc.`ElectionID` = @electionId
        ORDER BY gc.`Votes` DESC LIMIT 1
    ]]

    MySQL.query(query2, {
        ['@electionId'] = electionId
    }, function(rows)
        if #rows > 0 then
            local winner = rows[1]
            
            -- Update election winner
            MySQL.query([[
                UPDATE `government_elections` SET `Winner` = @winnerId WHERE `ID` = @electionId
            ]], {
                ['@winnerId'] = winner.CharacterID,
                ['@electionId'] = electionId
            })
            
            -- Update government mayor
            MySQL.query([[
                UPDATE `government` SET `Mayor` = @mayor
            ]], {
                ['@mayor'] = winner.CharacterID
            })
            
            Government.mayor = winner.CharacterID
            
            -- Announce winner
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 0, 255, 0 }, 
                ("The election has ended! %s has been elected as the new mayor with %d votes!"):format(winner.CandidateName, winner.Votes))
        else
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 255, 0, 0 }, 
                "The election has ended with no candidates!")
        end
        
        Government.electionActive = false
        Government.electionEndTime = 0
        Government.candidates = {}
    end)
end

-- Function to run for mayor
function runForMayor(source, campaign)
    if not PlayerData[source] then return false, "You must be logged in!" end
    if not Government.electionActive then return false, "There is no active election!" end
    
    local characterId = PlayerData[source].CharacterID
    
    -- Check if already a candidate
    for _, candidate in ipairs(Government.candidates) do
        if candidate.CharacterID == characterId then
            return false, "You are already a candidate!"
        end
    end
    
    -- Get active election ID
    local query = [[
        SELECT `ID` FROM `government_elections` WHERE `Active` = 1 ORDER BY `ID` DESC LIMIT 1
    ]]

    MySQL.query(query, {}, function(rows)
        if #rows > 0 then
            local electionId = rows[1].ID
            
            -- Add candidate
            local query2 = [[
                INSERT INTO `government_candidates` (`ElectionID`, `CharacterID`, `Campaign`)
                VALUES (@electionId, @characterId, @campaign)
            ]]

            MySQL.query(query2, {
                ['@electionId'] = electionId,
                ['@characterId'] = characterId,
                ['@campaign'] = campaign
            }, function(rows2, affected)
                if affected > 0 then
                    -- Reload candidates
                    loadElectionCandidates(electionId)
                    
                    TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 255, 255, 0 }, 
                        ("%s is now running for mayor! Campaign: %s"):format(PlayerData[source].Name, campaign))
                    
                    return true, "You are now running for mayor!"
                end
                
                return false, "Failed to register as a candidate!"
            end)
        else
            return false, "No active election found!"
        end
    end)
end

-- Function to vote for a candidate
function voteForCandidate(source, candidateId)
    if not PlayerData[source] then return false, "You must be logged in!" end
    if not Government.electionActive then return false, "There is no active election!" end
    
    local characterId = PlayerData[source].CharacterID
    
    -- Check if candidate exists
    local candidateExists = false
    for _, candidate in ipairs(Government.candidates) do
        if candidate.ID == candidateId then
            candidateExists = true
            break
        end
    end
    
    if not candidateExists then
        return false, "Invalid candidate!"
    end
    
    -- Get active election ID
    local query = [[
        SELECT `ID` FROM `government_elections` WHERE `Active` = 1 ORDER BY `ID` DESC LIMIT 1
    ]]

    MySQL.query(query, {}, function(rows)
        if #rows > 0 then
            local electionId = rows[1].ID
            
            -- Check if already voted
            local query2 = [[
                SELECT `ID` FROM `government_votes` WHERE `ElectionID` = @electionId AND `VoterID` = @voterId
            ]]

            MySQL.query(query2, {
                ['@electionId'] = electionId,
                ['@voterId'] = characterId
            }, function(rows2)
                if #rows2 > 0 then
                    return false, "You have already voted in this election!"
                end
                
                -- Add vote
                local query3 = [[
                    INSERT INTO `government_votes` (`ElectionID`, `VoterID`, `CandidateID`)
                    VALUES (@electionId, @voterId, @candidateId)
                ]]

                MySQL.query(query3, {
                    ['@electionId'] = electionId,
                    ['@voterId'] = characterId,
                    ['@candidateId'] = candidateId
                }, function(rows3, affected)
                    if affected > 0 then
                        -- Update candidate votes
                        MySQL.query([[
                            UPDATE `government_candidates` SET `Votes` = `Votes` + 1
                            WHERE `ID` = @candidateId
                        ]], {
                            ['@candidateId'] = candidateId
                        })
                        
                        -- Find candidate name
                        local candidateName = "Unknown"
                        for _, candidate in ipairs(Government.candidates) do
                            if candidate.ID == candidateId then
                                candidateName = candidate.Name
                                candidate.Votes = candidate.Votes + 1
                                break
                            end
                        end
                        
                        TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 0, 255, 0 }, 
                            ("You voted for %s!"):format(candidateName))
                        
                        return true, "Vote cast successfully!"
                    end
                    
                    return false, "Failed to cast vote!"
                end)
            end)
        else
            return false, "No active election found!"
        end
    end)
end

-- Function to set tax rates (mayor only)
function setTaxRates(source, taxType, rate)
    if not PlayerData[source] then return false, "You must be logged in!" end
    if PlayerData[source].CharacterID ~= Government.mayor then
        return false, "Only the mayor can set tax rates!"
    end
    
    if rate < 0 or rate > 20 then
        return false, "Tax rate must be between 0% and 20%!"
    end
    
    local column = "TaxRate"
    if taxType == "property" then
        column = "PropertyTaxRate"
    elseif taxType == "business" then
        column = "BusinessTaxRate"
    elseif taxType == "income" then
        column = "IncomeTaxRate"
    end
    
    local query = [[
        UPDATE `government` SET ]] .. column .. [[ = @rate
    ]]

    MySQL.query(query, {
        ['@rate'] = rate
    }, function(rows, affected)
        if affected > 0 then
            if taxType == "property" then
                Government.propertyTaxRate = rate
            elseif taxType == "business" then
                Government.businessTaxRate = rate
            elseif taxType == "income" then
                Government.incomeTaxRate = rate
            else
                Government.taxRate = rate
            end
            
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 255, 255, 0 }, 
                ("The mayor has set the %s tax rate to %d%%"):format(taxType, rate))
            
            return true, "Tax rate updated successfully!"
        end
        
        return false, "Failed to update tax rate!"
    end)
end

-- Function to create a law (mayor only)
function createLaw(source, name, description)
    if not PlayerData[source] then return false, "You must be logged in!" end
    if PlayerData[source].CharacterID ~= Government.mayor then
        return false, "Only the mayor can create laws!"
    end
    
    local query = [[
        INSERT INTO `government_laws` (`Name`, `Description`, `CreatedBy`)
        VALUES (@name, @description, @createdBy)
    ]]

    MySQL.query(query, {
        ['@name'] = name,
        ['@description'] = description,
        ['@createdBy'] = PlayerData[source].CharacterID
    }, function(rows, affected)
        if affected > 0 then
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 255, 255, 0 }, 
                ("New law created: %s - %s"):format(name, description))
            
            return true, "Law created successfully!"
        end
        
        return false, "Failed to create law!"
    end)
end

-- Tax collection system
CreateThread(function()
    while true do
        Wait(86400000) -- 24 hours
        
        local totalTaxes = 0
        
        -- Collect property taxes
        for propertyId, property in pairs(Properties) do
            if property.OwnerID > 0 then
                local tax = math.floor(property.Price * (Government.propertyTaxRate / 100))
                
                -- Find owner and deduct tax
                for source, data in pairs(PlayerData) do
                    if data.CharacterID == property.OwnerID then
                        if data.BankMoney >= tax then
                            data.BankMoney = data.BankMoney - tax
                            totalTaxes = totalTaxes + tax
                            
                            TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 255, 0 }, 
                                ("Property tax of $%d was deducted from your bank account"):format(tax))
                        else
                            TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 0, 0 }, 
                                ("You couldn't pay property tax of $%d! Your property may be seized."):format(tax))
                        end
                        break
                    end
                end
            end
        end
        
        -- Collect business taxes
        for businessId, business in pairs(Businesses) do
            if business.OwnerID > 0 then
                local tax = math.floor(business.Price * (Government.businessTaxRate / 100))
                
                if business.Till >= tax then
                    business.Till = business.Till - tax
                    totalTaxes = totalTaxes + tax
                    
                    -- Update database
                    MySQL.query([[
                        UPDATE `businesses` SET `Till` = `Till` - @tax WHERE `ID` = @businessId
                    ]], {
                        ['@tax'] = tax,
                        ['@businessId'] = businessId
                    })
                    
                    -- Notify owner
                    for source, data in pairs(PlayerData) do
                        if data.CharacterID == business.OwnerID then
                            TriggerClientEvent('chatMessage', source, "[GOVERNMENT]", { 255, 255, 0 }, 
                                ("Business tax of $%d was deducted from %s"):format(tax, business.Name))
                            break
                        end
                    end
                end
            end
        end
        
        -- Update government treasury
        Government.treasury = Government.treasury + totalTaxes
        
        MySQL.query([[
            UPDATE `government` SET `Treasury` = @treasury, `LastTaxCollection` = NOW()
        ]], {
            ['@treasury'] = Government.treasury
        })
        
        if totalTaxes > 0 then
            TriggerClientEvent('chatMessage', -1, "[GOVERNMENT]", { 0, 255, 0 }, 
                ("Daily tax collection completed. $%d collected for the city treasury."):format(totalTaxes))
        end
    end
end)
