-- Database schema and initialization

function initializeDatabase()
    -- Create accounts table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `accounts` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Username` varchar(24) NOT NULL,
            `Password` varchar(129) NOT NULL,
            `Email` varchar(64) DEFAULT NULL,
            `RegisterDate` datetime NOT NULL,
            `LoginDate` datetime NOT NULL,
            `LastIP` varchar(16) DEFAULT NULL,
            `AdminLevel` int(2) DEFAULT 0,
            `DonatorLevel` int(2) DEFAULT 0,
            `Warnings` int(2) DEFAULT 0,
            `Banned` int(1) DEFAULT 0,
            `BanReason` varchar(128) DEFAULT NULL,
            PRIMARY KEY (`ID`),
            UNIQUE KEY `Username` (`Username`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    -- Create characters table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `characters` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `AccountID` int(11) NOT NULL,
            `Name` varchar(24) NOT NULL,
            `Age` int(3) DEFAULT 18,
            `Gender` int(1) DEFAULT 1,
            `Skin` int(3) DEFAULT 26,
            `Money` int(11) DEFAULT 5000,
            `BankMoney` int(11) DEFAULT 0,
            `PosX` float DEFAULT 1642.22,
            `PosY` float DEFAULT -2335.48,
            `PosZ` float DEFAULT 13.54,
            `PosA` float DEFAULT 0.0,
            `Health` float DEFAULT 100.0,
            `Armour` float DEFAULT 0.0,
            `FactionID` int(11) DEFAULT 0,
            `FactionRank` int(2) DEFAULT 0,
            `JobID` int(11) DEFAULT 0,
            `Level` int(3) DEFAULT 1,
            `Exp` int(11) DEFAULT 0,
            `PlayingHours` int(11) DEFAULT 0,
            `PhoneNumber` int(11) DEFAULT 0,
            `Jailed` int(1) DEFAULT 0,
            `JailTime` int(11) DEFAULT 0,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`AccountID`) REFERENCES `accounts`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    -- Create factions table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `factions` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Name` varchar(32) NOT NULL,
            `Type` int(2) DEFAULT 0,
            `Color` varchar(8) DEFAULT '#FFFFFF',
            `MOTD` varchar(128) DEFAULT 'Welcome to the faction!',
            `Budget` int(11) DEFAULT 0,
            `MaxMembers` int(3) DEFAULT 30,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    -- Create vehicles table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `vehicles` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `Model` int(11) NOT NULL,
            `OwnerID` int(11) DEFAULT 0,
            `FactionID` int(11) DEFAULT 0,
            `PosX` float DEFAULT 0.0,
            `PosY` float DEFAULT 0.0,
            `PosZ` float DEFAULT 0.0,
            `PosA` float DEFAULT 0.0,
            `Color1` int(3) DEFAULT 1,
            `Color2` int(3) DEFAULT 1,
            `Paintjob` int(2) DEFAULT -1,
            `Locked` int(1) DEFAULT 0,
            `Fuel` float DEFAULT 100.0,
            `Engine` int(1) DEFAULT 0,
            `Lights` int(1) DEFAULT 0,
            PRIMARY KEY (`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    -- Create inventory table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `inventory` (
            `ID` int(11) NOT NULL AUTO_INCREMENT,
            `CharacterID` int(11) NOT NULL,
            `ItemName` varchar(32) NOT NULL,
            `Quantity` int(11) DEFAULT 1,
            `Data` text DEFAULT NULL,
            PRIMARY KEY (`ID`),
            FOREIGN KEY (`CharacterID`) REFERENCES `characters`(`ID`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    ]])

    print("[SC:RP] Database tables initialized.")
end
