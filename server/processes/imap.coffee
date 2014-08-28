ImapHelper = require './helper'
Promise = require 'bluebird'
module.exports = ImapProcess = {}

ImapProcess.getMailboxes = (account) ->

    pConnection = ImapHelper.getConnection account

    Promise.using pConnection, (connection) ->
        connection.getBoxesAsync()
            .then ImapHelper.cleanUpBoxTree


ImapProcess.checkForUpdates = (account) ->

# ImapProcess.fetchMail = (account, ) ->

#     account.withConnection ->
#         account.listBoxes()
#             .get(1)
#             .get('path')
#             .then account.getBoxReadOnly
# .then (box) -> console.log "box", box
# .catch (e) -> console.log "ERRORR", e.stack