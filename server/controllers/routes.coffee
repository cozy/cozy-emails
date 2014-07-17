# See documentation on https://github.com/frankrousseau/americano#routes

index = require './index'

module.exports =
    'foo':
        get: index.main

