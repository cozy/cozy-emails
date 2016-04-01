_ = require 'lodash'

AppDispatcher = require '../app_dispatcher'

RouterStore = require '../stores/router_store'

{ActionTypes} = require '../constants/app_constants'

RouterActionCreator =

    setAction: (value) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_ROUTE_ACTION
            value: value


    getNextPage: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_FETCH_REQUEST
            value: action: 'page.next'


    addFilter: (params) ->
        filter = {}
        separator = ','
        filters = RouterStore.getFilter()

        _.each params, (value, key) ->
            # Toggle filter value
            # Add value if it doesnt exist
            # Remove if from filters otherwhise
            tmp = filters[key]
            tmp = tmp.split separator if _.isString filters[key]
            tmp ?= []
            if -1 < tmp.indexOf value
                tmp = _.without tmp, value
            else
                tmp.push value
            filter[key] = tmp?.join separator

        isServer = false
        @navigate url: RouterStore.getCurrentURL {filter, isServer}

    navigate: (params={}) ->
        {url} = params
        url ?= RouterStore.getURL params

        if url
            # Update URL && context
            router = RouterStore.getRouter()
            router.navigate url, trigger: true

module.exports = RouterActionCreator
