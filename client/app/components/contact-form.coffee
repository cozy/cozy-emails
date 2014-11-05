{div, input, span, ul, li, a, img, i} = React.DOM
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

        div className: "contact-form",
            div null,
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
                ul className: "contact-list",
                    @state.contacts.map (contact, key) =>
                        @renderContact contact
                    .toJS()


    renderContact: (contact) ->
        selectContact = =>
            @props.onContact contact
        avatar = contact.get 'avatar'

        li onClick: selectContact,
            a null,
                if avatar?
                    img
                        className: 'avatar'
                        src: avatar
                else
                    i className: 'avatar fa fa-user'
                "#{contact.get 'fn'} <#{contact.get 'address'}>"


    onSubmit: ->
        query = @refs.contactInput.getDOMNode().value.trim()
        if query.length > 2
            ContactActionCreator.searchContact query

    onKeyDown: (evt) ->
        if evt.key is "Enter"
            @onSubmit()
            evt.preventDefault()
            return false
