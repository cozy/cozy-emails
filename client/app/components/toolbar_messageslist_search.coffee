{div, i, button, input, form} = React.DOM
{Dropdown} = require './basic_components'
{MessageFilter, Tooltips} = require '../constants/app_constants'
SearchInput = require './search_input'

RouterMixin           = require '../mixins/router_mixin'

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
        type:  'from'
        value: ''

    onTypeChange: (filter) ->
        @setState type: filter, value: ''

    onValueChange: (newvalue) ->
        @props.onFilterChange
            type: @state.type
            value: newvalue

    render: ->
        form
            role: 'group'
            className: 'search'
            onSubmit: (e) -> e.preventDefault()

            Dropdown
                value:    @state.type
                values:   filters
                onChange: @onTypeChange

            SearchInput
                value: @state.value
                placeholder: t 'filters search placeholder'
                onSubmit: @onValueChange
