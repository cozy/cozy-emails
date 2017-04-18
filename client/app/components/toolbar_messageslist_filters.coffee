_     = require 'underscore'
React = require 'react'

{div, ul, li, span, i, button} = React.DOM
{MessageFilter, Tooltips}      = require '../constants/app_constants'

RouterGetter = require '../getters/router'
RouterActionCreator = require '../actions/router_action_creator'

module.exports = FiltersToolbarMessagesList = React.createClass
    displayName: 'FiltersToolbarMessagesList'

    propTypes:
        accountID: React.PropTypes.string.isRequired
        mailboxID: React.PropTypes.string.isRequired

    getInitialState: ->
        expanded:  false

    toggleFilters: (filter) ->
        RouterActionCreator.addFilter filter

    render: ->
        div
            role:            'group'
            className:       'filters'
            'aria-expanded': @state.expanded

            button
                role: 'presentation'
                onClick: => @setState expanded: not @state.expanded

                i className: 'fa fa-filter'

            button
                role: 'menuitem'
                'aria-selected': RouterGetter.isFlags 'UNSEEN'
                onClick: => @toggleFilters flags: MessageFilter.UNSEEN
                'aria-describedby': Tooltips.FILTER_ONLY_UNREAD
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-eye'
                span className: 'btn-label', t 'filters unseen'

            button
                role: 'menuitem'
                'aria-selected': RouterGetter.isFlags 'FLAGGED'
                onClick: => @toggleFilters flags: MessageFilter.FLAGGED
                'aria-describedby': Tooltips.FILTER_ONLY_IMPORTANT
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-star'
                span className: 'btn-label', t 'filters flagged'
