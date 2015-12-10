fs     = require 'fs'
{exec} = require 'child_process'
logger = require('printit')
    date: false
    prefix: 'cake'

task 'tests', (opts) ->
    console.log "DEPRECATED : use npm run test:server"

task 'build', 'Build CoffeeScript to Javascript', ->
    logger.options.prefix = 'cake:build'
    logger.info "Start compilation..."
    command = """
        rm -rf build && \
        coffee -cb --output build/server server && \
        coffee -cb --output build/ server.coffee && \
        mkdir -p build/server/views && \
        cp server/views/* build/server/views/ && \
        mkdir -p build/client/app && \
        cp -r client/app/locales build/client/app && \
        cd client/ && brunch build --production
    """

    exec command, (err, stdout, stderr) ->
        if err
            logger.error "An error has occurred while compiling:\n" + err
            process.exit 1
        else
            logger.info "Compilation succeeded."
            process.exit 0
