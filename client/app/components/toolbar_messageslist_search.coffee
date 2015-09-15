{div, i, button, input, form} = React.DOM
{Dropdown} = require './basic_components'
{MessageFilter, Tooltips} = require '../constants/app_constants'

LayoutActionCreator = require '../actions/layout_action_creator'

filters =
    from: t "list filter from"
    dest: t "list filter dest"


module.exports = SearchToolbarMessagesList = React.createClass
    displayName: 'SearchToolbarMessagesList'

    propTypes:
        accountID: React.PropTypes.string.isRequired
        mailboxID: React.PropTypes.string.isRequired

    getInitialState: ->
        type:    'from'
        value:   ''
        isEmpty: true


    showList: ->
        filter = MessageFilter.ALL
        sort =
            order:  '-'
            before: @state.value
        if @state.value? and @state.value isnt ''
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
