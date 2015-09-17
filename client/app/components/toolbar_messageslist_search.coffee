{div, i, button, input, form} = React.DOM
{Dropdown} = require './basic_components'
{MessageFilter, Tooltips} = require '../constants/app_constants'

RouterMixin           = require '../mixins/router_mixin'

LayoutActionCreator = require '../actions/layout_action_creator'

filters =
    from: t "list filter from"
    dest: t "list filter dest"


module.exports = SearchToolbarMessagesList = React.createClass
    displayName: 'SearchToolbarMessagesList'

    mixins: [
        RouterMixin,
    ]

    propTypes:
        accountID: React.PropTypes.string.isRequired
        mailboxID: React.PropTypes.string.isRequired

    getInitialState: ->
        if window.location.href.indexOf('/sort/-from/before') isnt -1
            value = window.location.href.split('before/')[1]
            value: value.split('/')[0]
            isEmpty: false
            type:    'from'
        else
            value:   ''
            isEmpty: true
            type:    'from'

    showList: ->
        filter = MessageFilter.ALL
        sort =
            order:  '-'
            before: @state.value
        if @state.value? and @state.value isnt ''
            @redirect
                direction: 'first'
                action: 'search'
                parameters: [@props.accountID, @props.mailboxID, @state.value, "#{@state.value}\uFFFF", @state.type]
            # always close message preview before filtering
            window.cozyMails.messageClose()
            sort.field = @state.type
            sort.after = "#{@state.value}\uFFFF"
        else
            # reset, use default filter
            sort.field = 'date'
            sort.after = ''
        LayoutActionCreator.showFilteredList filter, sort


    onTypeChange: (filter) ->
        @setState type: filter


    onChange: (event) ->
        @setState
            value:   event.target.value
            isEmpty: event.target.value.length is 0


    onKeyUp: (event) ->
        @showList() if event.key is "Enter" or @state.isEmpty


    reset: ->
        @redirect
            direction: 'first'
            action: 'account.mailbox.messages'
            parameters: [@props.accountID, @props.mailboxID]
        @setState @getInitialState(), @showList


    render: ->
        form role: 'group', className: 'search',
            Dropdown
                value:    @state.type
                values:   filters
                onChange: @onTypeChange

            div role: 'search',
                input
                    ref:         'searchterms'
                    type:        'text'
                    placeholder: t 'filters search placeholder'
                    value:       @state.value
                    onChange:    @onChange
                    onKeyUp:     @onKeyUp
                    name:        'searchterm'

                unless @state.isEmpty
                    div className: 'btn-group',
                        button
                            className: 'btn fa fa-check'
                            onClick: (e) =>
                                e.preventDefault()
                                e.stopPropagation()
                                @showList()

                        button
                            className: 'btn fa fa-close'
                            onClick: (e) =>
                                e.preventDefault()
                                e.stopPropagation()
                                @reset()