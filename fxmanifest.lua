fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

name 'feather-access'
description 'Durable capability delegation for the Feather Framework'
author 'BCC Scripts'
version '0.1.0'


files {}

shared_scripts {}

client_scripts {}

server_scripts {
    '@feather-mysql/lib/DB.lua',
    'config.lua',
    'server/foundation.lua',
    'server/dependencies.lua',
    'server/migrations.lua',
    'server/providers.lua',
    'server/grant_support.lua',
    'server/grants.lua',
    'server/exports.lua',
    'server/commands.lua',
    'server/main.lua',
}

dependencies {
    'feather-mysql',
    'feather-core',
}
