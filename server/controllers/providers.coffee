https     = require 'https'
DOMParser = require('xmldom').DOMParser

# fetch account config for a domain
# from prams.domain
module.exports.get = (req, res, next) ->
    url = "https://autoconfig.thunderbird.net/v1.1/" + req.params.domain
    req = https.get url, (response) ->
        if response.statusCode isnt 200
            res.status(response.statusCode).send('')
        else
            body = ''
            response.on 'data', (data) ->
                body += data
            response.on 'end', ->
                doc = new DOMParser().parseFromString body
                providers = doc.getElementsByTagName 'emailProvider'
                infos = []
                getValue = (node, tag) ->
                    nodes = node.getElementsByTagName tag
                    if nodes.length > 0
                        return nodes[0].childNodes[0].nodeValue
                parseServer = (node) ->
                    server =
                        type:       node.getAttribute 'type'
                        hostname:   getValue node, 'hostname'
                        port:       getValue node, 'port'
                        socketType: getValue node, 'socketType'
                    infos.push server
                getServers = (provider) ->
                    servers = provider.getElementsByTagName 'incomingServer'
                    parseServer server for server in servers
                    servers = provider.getElementsByTagName 'outgoingServer'
                    parseServer server for server in servers
                    res.send infos
                getServers provider for provider in providers

    req.on 'error', (e) ->
        res.status(500).send
            error: "Error getting provider infos : " + e.message
