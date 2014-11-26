should = require 'should'
log = -> console.log.apply(console, arguments)
fs = require 'fs'

describe 'Activity testing', ->

    it "Search bob", (done) ->
        searchBobActivity =
            name: 'search'
            data:
                type: 'contact'
                query: 'bobb'

        client.post "/activity", searchBobActivity, (err, res, body) ->
            should.not.exist err
            res.statusCode.should.equal 200
            body.result.should.be.instanceof(Array).and.have.lengthOf 0
            done()

    it "Search all", (done) ->
        searchAllActivity =
            name: 'search'
            data:
                type: 'contact'

        client.post "/activity", searchAllActivity, (err, res, body) ->
            should.not.exist err
            res.statusCode.should.equal 200
            body.result.should.be.instanceof(Array).and.have.lengthOf 0
            done()


    it "Create a contact", (done) ->
        createContactActivity =
            name: 'create'
            data:
                type: 'contact'
                contact:
                    name: 'bobby'
                    address: 'bob@test.com'

        client.post "/activity", createContactActivity, (err, res, body) =>
            should.not.exist err
            res.statusCode.should.equal 200
            body.result.should.be.instanceof(Array).and.have.lengthOf 1
            store.bobID = body.result[0].id
            done()

    it "Create a contact", (done) ->
        createContactActivity =
            name: 'create'
            data:
                type: 'contact'
                contact:
                    name: 'alice'
                    address: 'alice@test.com'

        client.post "/activity", createContactActivity, (err, res, body) =>
            should.not.exist err
            res.statusCode.should.equal 200
            body.result.should.be.instanceof(Array).and.have.lengthOf 1
            done()

    it "Search bob", (done) ->
        searchBobActivity =
            name: 'search'
            data:
                type: 'contact'
                query: 'bobb'

        client.post "/activity", searchBobActivity, (err, res, body) ->
            should.not.exist err
            res.statusCode.should.equal 200
            body.result.should.be.instanceof(Array).and.have.lengthOf 1
            store.bobID.should.equal body.result[0].id
            done()

    it "Search all", (done) ->
        searchAllActivity =
            name: 'search'
            data:
                type: 'contact'

        client.post "/activity", searchAllActivity, (err, res, body) ->
            should.not.exist err
            res.statusCode.should.equal 200
            body.result.should.be.instanceof(Array).and.have.lengthOf 2
            done()

    it "Delete bob", (done) ->
        deleteBobActivity =
            name: 'delete'
            data:
                type: 'contact'
                id: store.bobID

        client.post "/activity", deleteBobActivity, (err, res, body) ->
            should.not.exist err
            res.statusCode.should.equal 200
            done()

    it "Search all", (done) ->
        searchAllActivity =
            name: 'search'
            data:
                type: 'contact'

        client.post "/activity", searchAllActivity, (err, res, body) ->
            should.not.exist err
            res.statusCode.should.equal 200
            body.result.should.be.instanceof(Array).and.have.lengthOf 1
            done()


