_ = require 'lodash'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

AccountStore = require '../stores/account_store'
RouterStore = require '../stores/router_store'

XHRUtils      = require '../utils/xhr_utils'

{ActionTypes, MessageActions, MessageFlags} = require '../constants/app_constants'

RouterActionCreator =
    getNextPage: ->
        action = MessageActions.PAGE_NEXT
        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: {action}


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


    mark: (target, action) ->
        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_FLAGS_REQUEST
            value: {target, action}

        timestamp = Date.now()
        ref = 'batchFlag' + timestamp
        XHRUtils.batchFlag {target, action}, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_FAILURE
                    value: {target, ref, error, action}
            else
                message.updated = timestamp for message in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FLAGS_SUCCESS
                    value: {target, ref, updated, action}


    # Delete message(s)
    # target:
    #  - messageID or messageIDs or conversationIDs or conversationIDs
    delete: (target={}) ->
        timestamp = Date.now()
        ref = 'delete' + timestamp
        target.accountID = AccountStore.getAccountID()

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_TRASH_REQUEST
            value: {target, ref}

        # send request
        XHRUtils.batchDelete target, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_TRASH_FAILURE
                    value: {target, ref, error}
            else
                msg.updated = ts for msg in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_TRASH_SUCCESS
                    value: {target, ref, updated}


    move: (target, from, to) ->
        timestamp = Date.now()
        ref = 'move' + timestamp

        AppDispatcher.dispatch
            type: ActionTypes.MESSAGE_MOVE_REQUEST
            value: {target, ref, from, to}

        # send request
        XHRUtils.batchMove target, from, to, (error, updated) =>
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_MOVE_FAILURE
                    value: {target, ref, error}
            else
                message.updated = ts for message in updated
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_MOVE_SUCCESS
                    value: {target, ref, updated}


    navigate: (params={}) ->
        {url} = params
        url ?= RouterStore.getURL params

        if url
            # Update URL && context
            router = RouterStore.getRouter()
            router.navigate url, trigger: true

module.exports = RouterActionCreator
