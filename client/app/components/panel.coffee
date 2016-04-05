React = require 'react'
_     = require 'underscore'

# Components
{Spinner}      = require('./basic_components').factories
Settings       = React.createFactory require './settings'
SearchResult   = React.createFactory require './search_result'

RouterGetter = require '../getters/router'

Panel = React.createClass
    displayName: 'Panel'
    render: ->

        if @props.action is 'search'
            key = encodeURIComponent @props.searchValue
            SearchResult
                key: "search-#{key}"

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else
            console.error "Unknown action #{@props.action}"
            window.cozyMails.logInfo "Unknown action #{@props.action}"
            return React.DOM.div null, "Unknown component #{@props.action}"

module.exports = Panel
