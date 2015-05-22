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
        flagged:  false
        unseen:   false
        attach:   false
        date:     false
        expanded: false


    _resetFiltersState: (name) ->
        filters =
            flagged: false
            unseen:  false
            attach:  false

        filters[name] = not @state[name] if name
        @setState filters


    showList: ->
        params           = _.clone(MessageStore.getParams())
        params.accountID = @props.accountID
        params.mailboxID = @props.mailboxID
        LayoutActionCreator.showMessageList parameters: params


    onDateFilter: (start, end) ->
        @_resetFiltersState()
        LayoutActionCreator.sortMessages
            order:  '-'
            field:  'date'
            before: start
            after:  end
        @showList()


    toggleFilters: (name) ->
        filter = MessageFilter[if @state[name] then 'ALL' else name.toUpperCase()]
        LayoutActionCreator.filterMessages filter
        @_resetFiltersState name
        @showList()


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
                'aria-selected':          @state.unseen
                onClick:                  @toggleFilters.bind(@, 'unseen')
                'aria-describedby':       Tooltips.FILTER_ONLY_UNREAD
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-circle'
                span className: 'btn-label', t 'filters unseen'
                # span className: 'badge', '##'

            button
                role:                     'menuitem'
                'aria-selected':          @state.flagged
                onClick:                  @toggleFilters.bind(@, 'flagged')
                'aria-describedby':       Tooltips.FILTER_ONLY_IMPORTANT
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-star'
                span className: 'btn-label', t 'filters flagged'
                # span className: 'badge', '##'

            button
                role:                     'menuitem'
                'aria-selected':          @state.attach
                onClick:                  @toggleFilters.bind(@, 'attach')
                'aria-describedby':       Tooltips.FILTER_ONLY_WITH_ATTACHMENT
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-paperclip'
                span className: 'btn-label', t 'filters attach'
                # span className: 'badge', '##'

            DateRangePicker
                onDateFilter: @onDateFilter


    toggleExpandState: ->
        @setState expanded: not @state.expanded
