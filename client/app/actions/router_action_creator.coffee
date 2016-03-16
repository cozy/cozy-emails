_ = require 'lodash'

AppDispatcher = require '../app_dispatcher'

RouterStore = '../stores/router_store'

{ActionTypes} = require '../constants/app_constants'

RouterActionCreator =

    setAction: (value) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_ROUTE_ACTION
            value: value

    updateFilter: (query) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.QUERY_PARAMETER_CHANGED
            parameters: query

    navigate: (url) ->
        router = RouterStore.getRouter()

        if url and not _.isString url
            params = url
            url = RouterStore.getURL params

        if url and _.isString url
            router.navigate url

module.exports = RouterActionCreator
