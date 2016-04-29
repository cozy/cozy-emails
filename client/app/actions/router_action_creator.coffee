_ = require 'lodash'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

RouterStore = require '../stores/router_store'
XHRUtils = require '../utils/xhr_utils'

{ActionTypes, MessageActions} = require '../constants/app_constants'

RouterActionCreator =

    getCurrentPage: (params={}) ->
        {url} = params

        # Always load messagesList
        action = MessageActions.SHOW_ALL
        url ?= RouterStore.getCurrentURL {action}

        mailboxID = RouterStore.getMailboxID()
        messageID = RouterStore.getMessageID()
        timestamp = (new Date()).toISOString()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {timestamp, messageID, mailboxID}

        XHRUtils.fetchMessagesByFolder url, (error,result) ->
            if error?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {error, timestamp}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {result, timestamp, messageID, mailboxID}


    getNextPage: ->
        if RouterStore.hasNextPage()
            url = RouterStore.getNextURL()
            @getCurrentPage {url}


    addFilter: (params) ->
        filter = {}
        separator = ','
        filters = RouterStore.getFilter()

        for key, value of params
            # Toggle filter value
            # Add value if it doesnt exist
            # Remove if from filters otherwhise
            tmp = filters[key]
            tmp = tmp.split separator if _.isString filters[key]
            value = decodeURIComponent value

            if 'flags' is key
                tmp ?= []
                if -1 < tmp.indexOf value
                    tmp = _.without tmp, value
                else
                    tmp.push value
                filter[key] = tmp?.join separator
            else
                filter[key] = value

        # FIXME : use distacher instead
        # then into routerStore, use navigate
        @navigate url: RouterStore.getCurrentURL {filter, isServer: false}

    navigate: (params={}) ->
        {url} = params
        url ?= RouterStore.getURL params

        if url
            # Update URL && context
            router = RouterStore.getRouter()
            router.navigate url, trigger: true

module.exports = RouterActionCreator
