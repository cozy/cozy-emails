REINDEXING_MSG = "This page will refresh in a minute."


describe 'Index page', ->

    it "When I get the index", (done) ->
        @timeout 6000
        setTimeout ->
            client.get '/', (err, res, body) ->
                console.log body
                res.statusCode.should.equal 200
                body.indexOf(REINDEXING_MSG).should.not.equal -1
                done()
        , 500

    it "Wait reindexing", (done) ->
        @timeout 30000
        do attempt = ->
            client.get '/', (err, res, body) ->
                if -1 is body?.indexOf(REINDEXING_MSG) then done()
                else setTimeout attempt, 1000


