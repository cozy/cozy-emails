fs     = require 'fs'
{exec} = require 'child_process'
logger = require('printit')
            date: false
            prefix: 'cake'

option '-f' , '--file [FILE*]' , 'test file to run'
option ''   , '--dir [DIR*]'   , 'directory where to grab test files'
option '-e' , '--env [ENV]'      , 'run with NODE_ENV=ENV. Default is test'

options =  # defaults, will be overwritten by command line options
    file        : no
    dir         : no

# Grab test files of a directory
walk = (dir, excludeElements = []) ->
    fileList = []
    list = fs.readdirSync dir
    if list
        for file in list
            if file and file not in excludeElements
                filename = "#{dir}/#{file}"
                stat = fs.statSync filename
                if stat and stat.isDirectory()
                    fileList2 = walk filename, excludeElements
                    fileList = fileList.concat fileList2
                else if filename.substr(-6) is "coffee"
                    fileList.push filename
    return fileList

task 'tests', 'run server tests, ./test is parsed by default, otherwise use -f or --dir', (opts) ->
    options   = opts
    testFiles = []
    if options.dir
        dirList   = options.dir
        testFiles = testFiles.concat walk dir for dir in dirList
    if options.file
        testFiles  = testFiles.concat options.file
    if not(options.dir or options.file)
        testFiles = walk "tests"

    runTests testFiles

runTests = (fileList) ->

    # Prevent error if the user hasn't installed mocha globally
    testCommand = "mocha --version"
    exec testCommand, (err, stdout, stderr) ->
        if err or stderr
            command = "./node_modules/mocha/bin/mocha"
        else
            command = "mocha"

        if options['env']
            env = "NODE_ENV=#{options.env}"
        else
            env = "NODE_ENV=test"
        console.log "Running tests with #{env}..."

        command = "#{env} #{command}"
        command += " #{fileList.join(" ")} "
        command += " --reporter spec --require should --compilers coffee:coffee-script/register --colors"
        exec command, (err, stdout, stderr) ->
            console.log stdout
            if err
                console.log "Running mocha caught exception: \n" + err

task "lint", "Run coffeelint on source files", ->

    lintFiles = walk '.',  ['node_modules', 'tests']

    # if installed globally, output will be colored
    testCommand = "coffeelint -v"
    exec testCommand, (err, stdout, stderr) ->
        if err or stderr
            command = "./node_modules/coffeelint/bin/coffeelint"
        else
            command = "coffeelint"

        command += " -f coffeelint.json -r " + lintFiles.join " "
        exec command, (err, stdout, stderr) ->
            console.log stderr
            console.log stdout

task 'build', 'Build CoffeeScript to Javascript', ->
    logger.options.prefix = 'cake:build'
    logger.info "Start compilation..."
    command = "coffee -cb --output build/server server && " + \
              "coffee -cb --output build/ server.coffee && " + \
              "cp server/views/* build/server/views/ && " + \
              "rm -rf build/client && mkdir build/client && " + \
              "cd client/ && brunch build --production && cd .. && " + \
              "cp -R client/public build/client/"

    exec command, (err, stdout, stderr) ->
        if err
            logger.error "An error has occurred while compiling:\n" + err
            process.exit 1
        else
            logger.info "Compilation succeeded."
            process.exit 0