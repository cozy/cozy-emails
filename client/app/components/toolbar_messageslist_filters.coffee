{div, span, i, button} = React.DOM
{MessageFilter, Tooltips} = require '../constants/app_constants'
RouterMixin           = require '../mixins/router_mixin'

LayoutActionCreator = require '../actions/layout_action_creator'

DateRangePicker = require './date_range_picker'


module.exports = FiltersToolbarMessagesList = React.createClass
    displayName: 'FiltersToolbarMessagesList'

    mixins: [
        RouterMixin,
    ]


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
            @redirect
                direction: 'first'
                action: 'account.mailbox.messages.date'
                parameters: [@props.accountID, @props.mailboxID, '-date', start, end]
        else
            params = false
            @redirect
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [@props.accountID, @props.mailboxID]
        @showList '-', params


    toggleFilters: (name) ->
        if @props.filter is name
            filter = '-'
            @redirect
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [@props.accountID, @props.mailboxID]
        else
            filter = name
            @redirect
                direction: 'first'
                action: 'account.mailbox.messages.filter'
                parameters: [@props.accountID, @props.mailboxID, '-date', name]
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

        if window.location.href.indexOf('/sort/-date/before') isnt -1
            dateFiltered = true

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
