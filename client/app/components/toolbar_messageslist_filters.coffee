{div, span, i, button} = React.DOM
{MessageFilter, Tooltips} = require '../constants/app_constants'

LayoutActionCreator = require '../actions/layout_action_creator'

DateRangePicker = require './date_range_picker'


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


    showList: (filter, params) ->
        sort =
            order:  '-'
            field:  'date'
        # always close message preview before filtering
        window.cozyMails.messageClose()
        if params?
            [sort.before, sort.after] = params
        else
            sort.after = sort.before = ''
        LayoutActionCreator.showFilteredList filter, sort


    onDateFilter: (start, end) ->
        if !!start and !!end
            params = [start, end]
        else
            params = false

        @showList '-', params


    toggleFilters: (name) ->
        href = window.location.href
        if @props.filter is name
            filter = '-'
            href = href.replace "/sort/-date/flag/#{name}", ""
        else
            filter = name
            href = href.replace "/sort/-date/flag/#{@props.filter}", ""
            href = href + "/sort/-date/flag/#{name}"
        window.location.href = href
        @showList filter, null


    render: ->
        if window.location.href.indexOf('flag') isnt -1
            filter = window.location.href.replace(/.*\/flag\//gi, '')
            @props.filter = filter.replace(/\/.*/gi, '')
        dateFiltered = @props.queryParams.before isnt '-' and
                       @props.queryParams.before isnt '1970-01-01T00:00:00.000Z' and
                       @props.queryParams.before isnt undefined and
                       @props.queryParams.after isnt undefined and
                       @props.queryParams.after isnt '-'
        div
            role:            'group'
            className:       'filters'
            'aria-expanded': @state.expanded

            i
                role:      'presentation'
                className: 'fa fa-filter'
                onClick:   @toggleExpandState

            button
                role:                     'menuitem'
                'aria-selected':          @props.filter is MessageFilter.UNSEEN
                onClick:                  @toggleFilters.bind(@, MessageFilter.UNSEEN)
                'aria-describedby':       Tooltips.FILTER_ONLY_UNREAD
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-circle'
                span className: 'btn-label', t 'filters unseen'

            button
                role:                     'menuitem'
                'aria-selected':          @props.filter is MessageFilter.FLAGGED
                onClick:                  @toggleFilters.bind(@, MessageFilter.FLAGGED)
                'aria-describedby':       Tooltips.FILTER_ONLY_IMPORTANT
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-star'
                span className: 'btn-label', t 'filters flagged'

            button
                role:                     'menuitem'
                'aria-selected':          @props.filter is MessageFilter.ATTACH
                onClick:                  @toggleFilters.bind(@, MessageFilter.ATTACH)
                'aria-describedby':       Tooltips.FILTER_ONLY_WITH_ATTACHMENT
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-paperclip'
                span className: 'btn-label', t 'filters attach'

            DateRangePicker
                active: dateFiltered
                onDateFilter: @onDateFilter


    toggleExpandState: ->
        @setState expanded: not @state.expanded
