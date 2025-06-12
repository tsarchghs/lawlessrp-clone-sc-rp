-- Account management functions

-- Function to connect to the database
function connectToDatabase()
    MySQL.createPool({
        host = Config.DatabaseHost,
        user = Config.DatabaseUser,
        password = Config.DatabasePassword,
        database = Config.DatabaseName
    })
    print("[SC:RP] Connected to database.")
end

-- Function to create a new account
function createAccount(source, username, password)
    local query = [[
        INSERT INTO `accounts` (`Username`, `Password`, `RegisterDate`, `LoginDate`)
        VALUES (@username, @password, @registerDate, @loginDate)
    ]]

    MySQL.query(query, {
        ['@username'] = username,
        ['@password'] = sha256(password), -- Hash the password
        ['@registerDate'] = os.date("%Y-%m-%d %H:%M:%S"),
        ['@loginDate'] = os.date("%Y-%m-%d %H:%M:%S")
    }, function(rows, affected)
        if affected > 0 then
            print(("[SC:RP] Account created for %s"):format(username))
            TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 255, 255 }, "Account created successfully!")
        else
            print(("[SC:RP] Failed to create account for %s"):format(username))
            TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "Failed to create account. Please try again.")
        end
    end)
end

-- Function to check account credentials
function checkAccount(source, username, password)
    local query = [[
        SELECT `ID` FROM `accounts` WHERE `Username` = @username AND `Password` = @password
    ]]

    MySQL.query(query, {
        ['@username'] = username,
        ['@password'] = sha256(password) -- Hash the password
    }, function(rows, affected)
        if #rows > 0 then
            -- Login successful
            local accountId = rows[1].ID
            print(("[SC:RP] Account login for %s (ID: %s)"):format(username, accountId))
            TriggerClientEvent('chatMessage', source, "[SERVER]", { 0, 255, 0 }, "Login successful!")
            -- Load character data here
        else
            -- Login failed
            print(("[SC:RP] Account login failed for %s"):format(username))
            TriggerClientEvent('chatMessage', source, "[SERVER]", { 255, 0, 0 }, "Login failed. Incorrect username or password.")
        end
    end)
end
