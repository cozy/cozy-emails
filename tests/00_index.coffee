REINDEXING_MSG = "This page will refresh in a minute."


describe 'Index page', ->

    it "When I get the index", (done) ->
        @timeout 6000
        client.get '/', (err, res, body) ->
            res.statusCode.should.equal 200
            body.indexOf(REINDEXING_MSG).should.equal -1
            done()


