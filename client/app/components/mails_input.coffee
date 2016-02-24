_          = require 'underscore'
React      = require 'react'
classNames = require 'classnames'

{div, label, textarea, span, ul, li, a, img, i} = React.DOM

MessageUtils    = require '../utils/message_utils'
ContactStore    = require '../stores/contact_store'
ContactActionCreator = require '../actions/contact_action_creator'
LayoutActionCreator = require '../actions/layout_action_creator'


# Public: input to enter multiple mails
# @TODO : use something tag-it like

module.exports = MailsInput = React.createClass
    displayName: 'MailsInput'

    getStateFromStores: ->
        contacts: ContactStore.getResults()

    componentWillMount: ->
        @setState contacts: null, open: false

    componentWillReceiveProps: (nextProps) ->
        # Update from parent
        @setState known: nextProps.valueLink.value

    shouldComponentUpdate: (nextProps, nextState) ->
        # Update parent from child
        unless _.isEqual nextProps.valueLink.value, nextState.known
            @props.valueLink.requestChange nextState.known
        not _.isEqual nextState, @state

    getInitialState: ->
        state = @getStateFromStores()
        state.known    = @props.valueLink.value or []
        state.unknown  = ''
        state.selected = 0
        state.open     = false
        state.focus    = !!state.known?.length
        state

    # Code from the StoreWatch Mixin. We don't use the mixin
    # because we store other things into the state
    componentDidMount: ->
        ContactStore.on 'change', @_setStateFromStores

    componentWillUnmount: ->
        ContactStore.removeListener 'change', @_setStateFromStores

    _setStateFromStores: -> @setState @getStateFromStores()

    render: ->
        renderTag = (address, idx) =>
            remove = =>
                @setState known: @state.known.filter (a) ->
                    a.address isnt address.address

            onDragStart = (event) =>
                event.stopPropagation()
                if address?
                    data =
                        name: address.name
                        address: address.address
                    event.dataTransfer.setData 'address', JSON.stringify(data)
                    event.dataTransfer.effectAllowed = 'all'
                    # needed to prevent droping over drag source
                    event.dataTransfer.setData @props.id, true

            onDragEnd = (event) ->
                remove() if event.dataTransfer.dropEffect is 'move'

            if address.name? and address.name.trim() isnt ''
                display = address.name
            else
                display = address.address
            span
                className: 'address-tag'
                draggable: true
                onDragStart: onDragStart
                onDragEnd: onDragEnd
                key: "#{@props.id}-#{address.address}-#{idx}"
                title: address.address
                display
                    a
                        className: 'clickable'
                        onClick: remove,
                            i className: 'fa fa-times'

        knownContacts = @state.known.map renderTag

        # set focus to input area when clicking into component
        onClick = =>
            @refs.contactInput.focus()

        onChange = (event) =>
            value = event.target.value.split ','
            if value.length is 2
                @setState
                    known: MessageUtils.parseAddress value[0]
                    unknown: value[1].trim()
            else
                @setState
                    unknown: event.target.value

        onInput = (event) =>
            input = @refs.contactInput
            input.cols = input.value.length + 2
            input.style.height = input.scrollHeight + 'px'

        className  = """
           #{@props.className or ''} form-group mail-input #{@props.id}
        """
        classLabel = 'compose-label control-label'
        listClass  = classNames
            'contact-form': true
            open: @state.open and @state.contacts?.size > 0
        current    = 0

        # in Chrome, we need to cancel some events for drop to work
        cancelDragEvent = (event) =>
            event.preventDefault()
            # To prevent removing the contact when dropped where it has been dragged,
            # we must set dropEffect to 'none'
            # if Chrome, we can only access types of data, not data themselves
            # In Chrome, types are an array; in Firefox, a DOMStringList
            types = Array.prototype.slice.call(event.dataTransfer.types)
            if types.indexOf(@props.id) is -1
                event.dataTransfer.dropEffect = 'move'
            else
                event.dataTransfer.dropEffect = 'none'

        # Show field if results
        className += ' shown' if @state.focus

        # don't display placeholder if there are dests
        hasNoContact = knownContacts.size > 0
        placeholder = if hasNoContact then @props.placeholder else ''

        div
            className: className,
            onClick: onClick
            onDrop: @onDrop,
            onDragEnter: cancelDragEvent,
            onDragLeave: cancelDragEvent,
            onDragOver: cancelDragEvent,
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
                        onDrop: @onDrop
                        onDragEnter: cancelDragEvent
                        onDragLeave: cancelDragEvent
                        onDragOver: cancelDragEvent
                        ref: 'contactInput'
                        rows: 1
                        value: @state.unknown
                        onChange: onChange
                        onInput: onInput
                        placeholder: placeholder
                        'autoComplete': 'off'
                        'spellCheck': 'off'

                    if @state.contacts?
                        ul className: "dropdown-menu contact-list",
                            @state.contacts.map (contact, key) =>
                                selected = current is @state.selected
                                current++
                                @renderContact contact, selected
                            .toArray()

    renderContact: (contact, selected) ->
        selectContact = =>
            @onContact contact
        avatar = contact.get 'avatar'

        classes = classNames
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
        query = @refs.contactInput.value.split(',').pop().replace(/^\s*/, '')
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
        count    = @state.contacts?.size
        selected = @state.selected
        switch evt.key
            when "Enter"
                # Typing enter key leads to the same behavior as blurring:
                # adding a contact to the current list
                @addContactFromInput() if 13 in [evt.keyCode, evt.which]

                if @state.contacts?.size > 0
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
                node = @refs.contactInput
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
            @addContactFromInput true
        , 100


    # Grab text from the input and ensure it's a valid email address.
    # If the address is valid, adds it to the recipient list.
    addContactFromInput: (isBlur=false) ->
        @state.selected = 0
        # if user cancel compose, component may be unmounted when the timeout
        # is fired
        if @isMounted()
            # Add current value to list of addresses
            value = @refs.contactInput.value
            unless _.isEmpty value.trim()
                address = MessageUtils.parseAddress value
                if address.isValid
                    @update address
                else
                    # Trick to make sure that the alert error is not pop up
                    # twiced due to multiple blur and key down.
                    # Do not display anything when the field is blurred.
                    isContacts = @state.contacts?.size is 0
                    if not isBlur and isContacts

                        msg = t 'compose wrong email format',
                            address: address.address
                        LayoutActionCreator.alertError msg
            else
                @setState open: false


    onContact: (contact) ->
        @update
            name : contact.get 'fn'
            address: contact.get 'address'

        # try to put back the focus at the end of the field
        setTimeout =>
            query = @refs.contactInput.focus()
        , 200

    update: (known, unknown) ->
        state =
            unknown: unknown or ''
            contacts: null
            # close suggestion list
            open: false
        if known
            state.known = _.clone @state.known
            state.known.push known

        @setState state

    onDrop: (event) ->
        event.preventDefault()
        event.stopPropagation()

        data = event.dataTransfer.getData 'address'
        {name, address} = JSON.parse data

        exists = @state.known.some (item) ->
            return item.name is name and item.address is address

        if address? and not exists
            @update name : name, address: address
            event.dataTransfer.dropEffect = 'move'
        else
            event.dataTransfer.dropEffect = 'none'
