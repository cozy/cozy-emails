fs     = require 'fs'
{exec} = require 'child_process'
logger = require('printit')
            date: false
            prefix: 'cake'

task 'tests', (opts) ->
    console.log "DEPRECATED : use npm run test:server"

# convert JSON lang files to JS
buildJsInLocales = ->
    path = require 'path'
    for file in fs.readdirSync './client/app/locales/'
        filename = './client/app/locales/' + file
        template = fs.readFileSync filename, 'utf8'
        exported = "module.exports = #{template};\n"
        name     = file.replace '.json', '.js'
        fs.writeFileSync "./build/client/app/locales/#{name}", exported
        # add locales at the end of app.js
    exec "rm -rf build/client/app/locales/*.json"

task 'build', 'Build CoffeeScript to Javascript', ->
    logger.options.prefix = 'cake:build'
    logger.info "Start compilation..."
    command = "coffee -cb --output build/server server && " + \
              "coffee -cb --output build/ server.coffee && " + \
              "mkdir -p build/server/views && " + \
              "cp server/views/* build/server/views/ && " + \
              "rm -rf build/client && mkdir build/client && " + \
              "cd client/ && brunch build --production && cd .. && " + \
              "mkdir -p build/client/app/locales/ && " + \
              "rm -rf build/client/app/locales/* && " + \
              "cp -R client/public build/client/ && " + \
              "rm -rf client/app/locales/*.coffee"

    exec command, (err, stdout, stderr) ->
        if err
            logger.error "An error has occurred while compiling:\n" + err
            process.exit 1
        else
            buildJsInLocales()
            logger.info "Compilation succeeded."
            process.exit 0