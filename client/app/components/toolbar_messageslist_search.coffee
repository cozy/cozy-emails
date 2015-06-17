{div, i, button, input} = React.DOM
{Dropdown} = require './basic_components'

LayoutActionCreator = require '../actions/layout_action_creator'

MessageStore        = require '../stores/message_store'


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
        LayoutActionCreator.sortMessages sort

        params = _.clone(MessageStore.getParams())
        params.accountID = @props.accountID
        params.mailboxID = @props.mailboxID
        LayoutActionCreator.showMessageList parameters: params


    onTypeChange: (filter) ->
        @setState type: filter


    onChange: (event) ->
        @setState
            value:   event.target.value
            isEmpty: event.target.value.length is 0


    onKeyUp: (event) ->
        @showList() if event.key is "Enter" or @state.isEmpty


    reset: ->
        @setState
            value: ''
            isEmpty: true,
            @showList


    render: ->
        div role: 'group', className: 'search',
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

                unless @state.isEmpty
                    div className: 'btn-group',
                        button
                            className: 'btn fa fa-check'
                            onClick: @showList

                        button
                            className: 'btn fa fa-close'
                            onClick: @reset
