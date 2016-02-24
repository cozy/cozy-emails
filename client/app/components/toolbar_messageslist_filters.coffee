_     = require 'underscore'
React = require 'react'

{div, ul, li, span, i, button} = React.DOM
{MessageFilter, Tooltips}      = require '../constants/app_constants'

LayoutActionCreator = require '../actions/layout_action_creator'

DateRangePicker = React.createFactory require './date_range_picker'


module.exports = FiltersToolbarMessagesList = React.createClass
    displayName: 'FiltersToolbarMessagesList'

    propTypes:
        accountID: React.PropTypes.string.isRequired
        mailboxID: React.PropTypes.string.isRequired

    getInitialState: ->
        expanded:  false

    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))
        return should

    onDateFilter: (start, end) ->
        date = if !!start and !!end then [start, end] else null
        @props.onFilterChange
            type: 'date',
            range: date

    toggleFilters: (name) ->
        wasActive = @props.queryParams.type is 'flag' and
                    @props.queryParams.filter is name
        @props.onFilterChange
            type: 'flag',
            value: if wasActive then '-' else name

    render: ->

        currentFilter = @props.queryParams.type is 'flag' and
                        @props.queryParams.filter

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
                'aria-selected': currentFilter is MessageFilter.UNSEEN
                onClick: => @toggleFilters MessageFilter.UNSEEN
                'aria-describedby': Tooltips.FILTER_ONLY_UNREAD
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-eye'
                span className: 'btn-label', t 'filters unseen'

            button
                role: 'menuitem'
                'aria-selected': currentFilter is MessageFilter.FLAGGED
                onClick: => @toggleFilters MessageFilter.FLAGGED
                'aria-describedby': Tooltips.FILTER_ONLY_IMPORTANT
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-star'
                span className: 'btn-label', t 'filters flagged'

            button
                role: 'menuitem'
                'aria-selected': currentFilter is MessageFilter.ATTACH
                onClick: => @toggleFilters MessageFilter.ATTACH
                'aria-describedby': Tooltips.FILTER_ONLY_WITH_ATTACHMENT
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-paperclip'
                span className: 'btn-label', t 'filters attach'

            DateRangePicker
                active: @props.queryParams.type is 'date'
                onDateFilter: @onDateFilter
