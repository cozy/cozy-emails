_ = require 'lodash'

AppDispatcher = require '../app_dispatcher'

RouterStore = require '../stores/router_store'

{ActionTypes, MessageActions} = require '../constants/app_constants'

RouterActionCreator =

    setAction: (value) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.ROUTE_CHANGE
            value: value


    getNextPage: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: action: MessageActions.PAGE_NEXT


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
