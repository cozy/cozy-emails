{div, span, i, button} = React.DOM
{MessageFilter, Tooltips} = require '../constants/app_constants'

LayoutActionCreator = require '../actions/layout_action_creator'

MessageStore = require '../stores/message_store'

DateRangePicker = require './date_range_picker'


module.exports = FiltersToolbarMessagesList = React.createClass
    displayName: 'FiltersToolbarMessagesList'

    propTypes:
        accountID: React.PropTypes.string.isRequired
        mailboxID: React.PropTypes.string.isRequired

    getInitialState: ->
        flag:      'ALL'
        filter:    false
        expanded:  false


    showList: ->
        LayoutActionCreator.filterMessages MessageFilter[@state.flag]

        if @state.filter
            # always close message preview before filtering
            window.cozyMails.messageClose()
            [start, end] = @state.filter
        else
            start = end = ''
        LayoutActionCreator.sortMessages
            order:  '-'
            field:  'date'
            before: start
            after:  end

        params           = _.clone(MessageStore.getParams())
        params.accountID = @props.accountID
        params.mailboxID = @props.mailboxID
        LayoutActionCreator.showMessageList parameters: params


    onDateFilter: (start, end) ->
        params = if !!start and !!end
            flag: false
            filter: [start, end]
        else
            filter: false

        @setState params, @showList


    toggleFilters: (name) ->
        params = if @state.flag is name
            flag: 'ALL'
        else
            flag: name
            filter: false,

        @setState params, @showList


    render: ->
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
                'aria-selected':          @state.flag is 'UNSEEN'
                onClick:                  @toggleFilters.bind(@, 'UNSEEN')
                'aria-describedby':       Tooltips.FILTER_ONLY_UNREAD
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-circle'
                span className: 'btn-label', t 'filters unseen'

            button
                role:                     'menuitem'
                'aria-selected':          @state.flag is 'FLAGGED'
                onClick:                  @toggleFilters.bind(@, 'FLAGGED')
                'aria-describedby':       Tooltips.FILTER_ONLY_IMPORTANT
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-star'
                span className: 'btn-label', t 'filters flagged'

            button
                role:                     'menuitem'
                'aria-selected':          @state.flag is 'ATTACH'
                onClick:                  @toggleFilters.bind(@, 'ATTACH')
                'aria-describedby':       Tooltips.FILTER_ONLY_WITH_ATTACHMENT
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-paperclip'
                span className: 'btn-label', t 'filters attach'

            DateRangePicker
                active:       !!@state.filter
                onDateFilter: @onDateFilter


    toggleExpandState: ->
        @setState expanded: not @state.expanded
