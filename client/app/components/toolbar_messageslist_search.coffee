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
        type: 'from'


    showList: ->
        value = @refs.searchterms.getDOMNode().value
        LayoutActionCreator.sortMessages
            order:  '-'
            field:  @state.type
            after:  "#{value}\uFFFF"
            before: value

        params = _.clone(MessageStore.getParams())
        params.accountID = @props.accountID
        params.mailboxID = @props.mailboxID
        LayoutActionCreator.showMessageList parameters: params


    onTypeChange: (filter) ->
        @setState type: filter


    onKeyDown: (event) ->
        switch event.key
            when "Enter" then @showList()


    render: ->
        div role: 'group', className: 'search',
            i
                role:      'presentation'
                className: 'fa fa-search'
            Dropdown
                value:    @state.type
                values:   filters
                onChange: @onTypeChange
            input
                    ref: 'searchterms'
                    type: 'text'
                    placeholder: t 'filters search placeholder'
                    onKeyDown: @onKeyDown
