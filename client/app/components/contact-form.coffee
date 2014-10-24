{div, input, span, ul, li, a} = React.DOM
classer = React.addons.classSet

ContactActionCreator = require '../actions/contact_action_creator'
ContactStore    = require '../stores/contact_store'
StoreWatchMixin = require '../mixins/store_watch_mixin'

RouterMixin = require '../mixins/router_mixin'

module.exports = React.createClass
    displayName: 'ContactForm'

    mixins: [
        StoreWatchMixin [ContactStore]
        RouterMixin
    ]

    getStateFromStores: ->
        return {
            query: @props.query
            contacts: ContactStore.getResults()
        }

    componentWillReceiveProps: (props) ->
        @setState query: props.query

    render: ->
        listClass = if @state.contacts.length > 0 then 'open' else ''

        div null,
            div className: 'col-sm-8 col-sm-offset-2',
                div className: 'input-group',
                    input
                        className: 'form-control',
                        type: 'text',
                        placeholder: t('contact form placeholder'),
                        onKeyDown: @onKeyDown,
                        ref: 'contactInput',
                        defaultValue: @state.query
                    div
                        className: 'input-group-addon btn btn-cozy',
                        onClick: @onSubmit,
                            span className: 'fa fa-search'

            div className: listClass,
                ul className: "dropdown-menu",
                    @state.contacts.map (contact, key) =>
                        @renderContact contact
                    .toJS()


    renderContact: (contact) ->
        selectContact = =>
            @props.onContact contact

        li onClick: selectContact,
            a null,
                "#{contact.get 'name'} <#{contact.get 'address'}>"


    onSubmit: ->
        query = @refs.contactInput.getDOMNode().value.trim()
        if query.length > 2
            ContactActionCreator.searchContact query

    onKeyDown: (evt) ->
        if evt.key is "Enter"
            @onSubmit()
            evt.preventDefault()
            return false
