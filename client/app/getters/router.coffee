AccountStore = require '../stores/account_store'
LayoutStore = require '../stores/layout_store'
MessageStore = require '../stores/message_store'
RouterStore = require '../stores/router_store'

AppDispatcher = require '../app_dispatcher'

_ = require 'lodash'

class RouteGetter

    getNextUrl: ->
        RouterStore.getNextUrl()

    getURL: (params) ->
        RouterStore.getURL params

    getAction: ->
        RouterStore.getAction()

    getQueryParams: ->
        RouterStore.getFilter()

    # Uniq Key from URL params
    #
    # return a {string}
    getKey: (str = '') ->
        filter = RouterStore.getFilter()
        keys = _.compact ['before', 'after'].map (key) ->
            filter[key] if filter[key] isnt '-'
        keys.unshift str unless _.isEmpty str
        keys.join('-')


module.exports = new RouteGetter()
