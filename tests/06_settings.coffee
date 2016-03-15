should = require 'should'

describe "settings changes", ->

    it "When I get the settings (first time)", (done) ->
        client.get "/settings", (err, res, body) =>
            res.statusCode.should.equal 200

            #body.should.have.property 'messagesPerPage'      , 25
            body.should.have.property 'displayPreview'       , true
            body.should.have.property 'composeInHTML'        , true
            body.should.have.property 'composeOnTop'         , false
            body.should.have.property 'messageDisplayHTML'   , true
            body.should.have.property 'messageDisplayImages' , false
            body.should.have.property 'messageConfirmDelete' , true
            body.should.have.property 'plugins'              , null

            done()

    it "When I change some settings (first time)", (done) ->

        changes =
            #messagesPerPage: 20
            messageDisplayHTML: false


        client.put "/settings", changes, (err, res, body) =>
            res.statusCode.should.equal 200

            #body.should.have.property 'messagesPerPage'      , 20
            body.should.have.property 'displayPreview'       , true
            body.should.have.property 'composeInHTML'        , true
            body.should.have.property 'composeOnTop'         , false
            body.should.have.property 'messageDisplayHTML'   , false
            body.should.have.property 'messageDisplayImages' , false
            body.should.have.property 'messageConfirmDelete' , true
            body.should.have.property 'plugins'              , null

            done()

    it "When I get again ", (done) ->

        client.get "/settings", (err, res, body) =>
            res.statusCode.should.equal 200

            #body.should.have.property 'messagesPerPage'      , 20
            body.should.have.property 'displayPreview'       , true
            body.should.have.property 'composeInHTML'        , true
            body.should.have.property 'composeOnTop'         , false
            body.should.have.property 'messageDisplayHTML'   , false
            body.should.have.property 'messageDisplayImages' , false
            body.should.have.property 'messageConfirmDelete' , true
            body.should.have.property 'plugins'              , null

            done()
