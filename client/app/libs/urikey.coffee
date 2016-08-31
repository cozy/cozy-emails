{AccountActions, MessageActions} = require '../constants/app_constants'

# Routes = require '../routes'
keyIn = (keys...)-> (value, key) -> key in keys

# Given the state of the app, generate an unique URI to be used
# as a key for requests.
# The URI will look like
#  account=xxxxxx&mailbox=xxxxxx&...
module.exports = (routestate) ->
    action = routestate.get('action')
    switch action
        when AccountActions.CREATE
            params = routestate.toMap().filter keyIn 'action'

        when AccountActions.EDIT
            params = routestate.toMap().filter keyIn 'action', 'accountID',
                                                    'tab'

        when MessageActions.SHOW_ALL
            params = routestate.toMap().filter keyIn 'action', 'accountID',
                                                    'mailboxID'

            filter = routestate.get('messagesFilter')?.get('flags')
            if filter
                params = params.set('filter', [].concat(filter).join('&'))


        when MessageActions.SHOW, \
             MessageActions.EDIT, \
             MessageActions.REPLY, \
             MessageActions.REPLY_ALL, \
             MessageActions.FORWARD, \
             MessageActions.CREATE
            params = routestate.toMap().filter keyIn 'action', 'accountID',
                'mailboxID', 'conversationID','messageID'

        else
            throw new Error("unhandled routeAction #{action}")

    return params.map (value, key) ->
        return key + '=' + value
        "#{key}=#{value}"
    .join('&')
