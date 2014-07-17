should = require('should')
Client = require('request-json').JsonClient

helpers = require './helpers'
helpers.options =
    serverHost: 'localhost'
    serverPort: '8888'
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"

describe "Template test", ->

    before helpers.startApp
    after helpers.stopApp

    describe "When I GET /foo", ->

        @err = null
        @res = null
        @body = null

        before (done) =>
            client.get 'foo', (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "It should sends me a successful Hello World!", =>
            should.not.exist @err
            should.exist @res
            @res.should.have.property 'statusCode'
            @res.statusCode.should.equal 200

            should.exist @body
            @body.should.have.property 'message'
            @body.message.should.equal 'Hello, world!'