fx_version 'cerberus'
game 'gta5'

description 'South Central Roleplay - FiveM Conversion'
version '2.0'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/config.lua',
    'server/database.lua',
    'server/account.lua',
    'server/player.lua',
    'server/inventory.lua',
    'server/factions.lua',
    'server/jobs.lua',
    'server/vehicles.lua',
    'server/properties.lua',
    'server/banking.lua',
    'server/admin.lua',
    'server/commands.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/properties.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'mysql-async'
}
