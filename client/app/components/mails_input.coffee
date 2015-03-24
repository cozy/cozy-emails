{div, label, textarea, span, ul, li, a, img, i} = React.DOM

MessageUtils    = require '../utils/message_utils'
Modal           = require './modal'
ContactStore    = require '../stores/contact_store'
ContactActionCreator = require '../actions/contact_action_creator'

classer = React.addons.classSet

# Public: input to enter multiple mails
# @TODO : use something tag-it like

module.exports = MailsInput = React.createClass
    displayName: 'MailsInput'

    getStateFromStores: ->
        contacts: ContactStore.getResults()

    componentWillMount: ->
        @setState contacts: null, open: false

    getInitialState: ->
        state = @getStateFromStores()
        state.known    = @props.valueLink.value
        state.unknown  = ''
        state.selected = 0
        state.open     = false
        return state

    componentWillReceiveProps: (nextProps) ->
        @setState known: nextProps.valueLink.value

    # Code from the StoreWatch Mixin. We don't use the mixin
    # because we store other things into the state
    componentDidMount: ->
        ContactStore.on 'change', @_setStateFromStores
        @fixHeight()

    componentWillUnmount: ->
        ContactStore.removeListener 'change', @_setStateFromStores

    _setStateFromStores: -> @setState @getStateFromStores()

    componentDidUpdate: ->
        @fixHeight()

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->

        renderTag = (address, idx) =>
            remove = =>
                known = @state.known.filter (a) ->
                    return a.address isnt address.address
                @props.valueLink.requestChange known
            if address.name? and address.name.trim() isnt ''
                display = address.name
            else
                display = address.address
            span
                className: 'address-tag'
                key: "#{@props.id}-#{address.address}-#{idx}"
                title: address.address
                display
                    a
                        className: 'clickable'
                        onClick: remove,
                            i className: 'fa fa-times'

        knownContacts = @state.known.map renderTag

        onChange = (event) =>
            value = event.target.value.split ','
            if value.length is 2
                @state.known.push(MessageUtils.parseAddress value[0])
                @props.valueLink.requestChange @state.known
                @setState unknown: value[1].trim()
            else
                @setState unknown: event.target.value

        className  = (@props.className or '') + " form-group #{@props.id}"
        classLabel = 'compose-label control-label'
        listClass  = classer
            'contact-form': true
            open: @state.open and @state.contacts?.length > 0
        current    = 0

        div className: className,
            label htmlFor: @props.id, className: classLabel,
                @props.label
            knownContacts
            div className: 'contact-group dropdown ' + listClass,
                textarea
                    id: @props.id
                    name: @props.id
                    className: 'form-control compose-input'
                    onKeyDown: @onKeyDown
                    onBlur: @onBlur
                    ref: 'contactInput'
                    rows: 1
                    value: @state.unknown
                    onChange: onChange
                    placeholder: @props.placeholder
                    'autoComplete': 'off'
                    'spellCheck': 'off'

                if @state.contacts?
                    ul className: "dropdown-menu contact-list",
                        @state.contacts.map (contact, key) =>
                            selected = current is @state.selected
                            current++
                            @renderContact contact, selected
                        .toJS()

    renderContact: (contact, selected) ->
        selectContact = =>
            @onContact contact
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

    onQuery: (char) ->
        query = @refs.contactInput.getDOMNode().value.split(',').pop().replace(/^\s*/, '')
        if char? and typeof char is 'string'
            query += char
            force = false
        else if char? and typeof char is 'object'
            # always display contact list when user click on contact button
            force = true
        if query.length > 2 or ( force and not @state.open )
            ContactActionCreator.searchContactLocal query
            @setState open: true
            return true
        else
            if @state.open
                @setState contacts: null, open: false
            return false

    onKeyDown: (evt) ->
        count    = @state.contacts?.count()
        selected = @state.selected
        switch evt.key
            when "Enter"
                if @state.contacts?.count() > 0
                    contact = @state.contacts.slice(selected).first()
                    @onContact contact
                else
                    @onQuery()
                evt.preventDefault()
                return false
            when "ArrowUp"
                @setState selected: if selected is 0 then count - 1 else selected - 1
            when "ArrowDown"
                @setState selected: if selected is (count - 1) then 0 else selected + 1
            when "Backspace"
                node = @refs.contactInput.getDOMNode()
                node.value = node.value.trim()
                if node.value.length < 2
                    @setState open: false
            when "Escape"
                @setState contacts: null, open: false
            else
                if (evt.key? or evt.key.toString().length is 1)
                    @onQuery(String.fromCharCode(evt.which))
                    return true

    onBlur: ->
        # We must use a timeout, otherwise, when user click inside contact list,
        # blur is triggered first and the click event lost. Dirty hack
        setTimeout =>
            # if user cancel compose, component may be unmounted when the timeout is fired
            if @isMounted()
                state = {}
                # close suggestion list
                state.open = false
                # Add current value to list of addresses
                value = @refs.contactInput.getDOMNode().value
                if value.trim() isnt ''
                    @state.known.push(MessageUtils.parseAddress value)
                    state.known   = @state.known
                    state.unknown = ''
                    @props.valueLink.requestChange state.known
                @setState state
        , 100

    onContact: (contact) ->
        address =
            name    : contact.get 'fn'
            address : contact.get 'address'
        @state.known.push address
        @props.valueLink.requestChange @state.known
        @setState unknown: '', contacts: null, open: false

        # try to put back the focus at the end of the field
        setTimeout =>
            query = @refs.contactInput.getDOMNode().focus()
        , 200

    fixHeight: ->
        input = @refs.contactInput.getDOMNode()
        if input.scrollHeight > input.clientHeight
            input.style.height = input.scrollHeight + "px"
