{div, input, span} = React.DOM
classer = React.addons.classSet

SearchActionCreator = require '../actions/SearchActionCreator'

ENTER_KEY = 13

RouterMixin = require '../mixins/RouterMixin'

module.exports = React.createClass
    displayName: 'SearchForm'

    mixins: [RouterMixin]

    render: ->
        div className: 'form-group pull-left',
            div className: 'input-group',
                input className: 'form-control', type: 'text', placeholder: t('app search'), onKeyPress: @onKeyPress, ref: 'searchInput', defaultValue: @props.query
                div className: 'input-group-addon btn btn-cozy', onClick: @onSubmit,
                    span className: 'fa fa-search'

    onSubmit: ->
        query = encodeURIComponent @refs.searchInput.getDOMNode().value.trim()

        # only submit query if it's longer than 3 characters
        # @TODO: validate and give feedback to the user
        if query.length > 3
            @redirect
                direction: 'left'
                action: 'search'
                parameters: [query]

    onKeyPress: (evt) ->
        if evt.charCode is ENTER_KEY
            @onSubmit()
            evt.preventDefault()
            return false
        else
            query = @refs.searchInput.getDOMNode().value
            SearchActionCreator.setQuery query