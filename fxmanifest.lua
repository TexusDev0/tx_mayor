fx_version 'cerulean'
game 'gta5'

author 'TexusDev'
description 'Municipal Command & Mayor Dashboard (Qbox + ox_lib + oxmysql)'
version '1.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/mayor_bg.jpg'
}