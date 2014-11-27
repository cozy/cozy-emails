{div, form, input, span, ul, li, a, img, i} = React.DOM
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
        query = @refs.contactInput?.getDOMNode().value.trim()
        return {
            contacts: if query?.length > 2 then ContactStore.getResults() else null
            selected: 0
        }

    componentWillMount: ->
        @setState contacts: null

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->
        listClass = if @state.contacts?.length > 0 then 'open' else ''
        current = 0

        form className: "contact-form",
            div null,
                div className: 'input-group',
                    input
                        className: 'form-control search-input',
                        type: 'text',
                        placeholder: t('contact form placeholder'),
                        onKeyDown: @onKeyDown,
                        ref: 'contactInput',
                        defaultValue: @props.query
                    div
                        className: 'input-group-addon btn btn-cozy search-btn',
                        onClick: @onSubmit,
                            span className: 'fa fa-search'

            if @state.contacts?
                div className: listClass,
                    ul className: "contact-list",
                        @state.contacts.map (contact, key) =>
                            selected = current is @state.selected
                            current++
                            @renderContact contact, selected
                        .toJS()


    renderContact: (contact, selected) ->
        selectContact = =>
            @props.onContact contact
        avatar = contact.get 'avatar'

        classes = classer
            selected: selected

        li className: classes, onClick: selectContact,
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
            ContactActionCreator.searchContactLocal query

    onKeyDown: (evt) ->
        switch evt.key
            when "Tab"
                @onSubmit()
                evt.preventDefault()
                return false
            when "Enter"
                if @state.contacts?.count() > 0
                    @props.onContact
                    contact = @state.contacts.slice(@state.selected).first()
                    @props.onContact contact
                else
                    @onSubmit()
                evt.preventDefault()
                return false
            when "ArrowUp"
                @setState selected: if @state.selected is 0 then @state.contacts.count() - 1 else @state.selected - 1
            when "ArrowDown"
                @setState selected: if @state.selected is (@state.contacts.count() - 1) then 0 else @state.selected + 1
