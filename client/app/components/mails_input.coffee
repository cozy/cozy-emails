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

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    getStateFromStores: ->
        contacts: ContactStore.getResults()

    componentWillMount: ->
        @setState contacts: null, open: false

    getInitialState: ->
        state = @getStateFromStores()
        state.known    = []
        state.selected = 0
        state.open     = false
        return state

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

    # Filter addresses. Put known ones into state and return a string with unknown ones
    # @params values Array of {name, address}
    # @returns a string
    _extractAddresses: (values) ->
        known   = []
        unknown = []
        values.map (address) ->
            if address.address.indexOf('@') is -1
                unknown.push address
            else
                res = ContactStore.getByAddress address.address
                if res?
                    # prevent adding same contact twice
                    if not (known.some (a) -> return a.address is address.address)
                        known.push address
                else
                    unknown.push address
        setTimeout =>
            @setState known: known.reverse()
        , 0
        MessageUtils.displayAddresses unknown, true

    # convert mailslist between human-readable and [{address, name}]
    proxyValueLink: ->
        value: @_extractAddresses @props.valueLink.value
        requestChange: (newValue) =>
            # reverse of MessageUtils.displayAddresses full
            result = newValue.split(',').map (tupple) ->
                if match = tupple.match /"{0,1}(.*)"{0,1} <(.*)>/
                    name: match[1], address: match[2]
                else
                    address: tupple.trimLeft()
            .filter (address) ->
                return address.addres isnt ''

            @props.valueLink.requestChange result.concat(@state.known.reverse())
            @_extractAddresses result
            @fixHeight()

    render: ->
        knownContacts = @state.known.map (address, idx) =>
            remove = =>
                known = @state.known.filter (a) ->
                    return a.address isnt address.address
                @setState known: known, =>
                    @proxyValueLink().requestChange @refs.contactInput.getDOMNode().value
            span
                className: 'address-tag'
                key: "#{@props.id}-#{address.address}-#{idx}"
                title: address.address
                MessageUtils.displayAddress address
                    a
                        className: 'clickable'
                        onClick: remove,
                            i className: 'fa fa-times'

        className  = (@props.className or '') + ' form-group'
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
                    valueLink: @proxyValueLink()
                    placeholder: @props.placeholder
                    'autoComplete': 'off'
                    'spellCheck': 'off'
                div
                    className: 'btn btn-cozy btn-contact',
                    onClick: @onQuery,
                        span className: 'fa fa-search'

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
        query = @refs.contactInput.getDOMNode().value.split(',').pop().trimLeft()
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
        switch evt.key
            when "Enter"
                if @state.contacts?.count() > 0
                    @onContact
                    contact = @state.contacts.slice(@state.selected).first()
                    @onContact contact
                else
                    @onQuery()
                evt.preventDefault()
                return false
            when "ArrowUp"
                @setState selected: if @state.selected is 0 then @state.contacts.count() - 1 else @state.selected - 1
            when "ArrowDown"
                @setState selected: if @state.selected is (@state.contacts.count() - 1) then 0 else @state.selected + 1
            when "Backspace"
                # hack needed because proxyValueLink prevent deleting empty contact
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
        # We must use a timeout, otherwise, when user click inside contact list, blur is triggered first
        # and the click event lost. Dirty hack
        setTimeout =>
            # if user cancel comose, component may be unmounted when the timeout is fired
            if @isMounted()
                @setState open: false
        , 100

    onContact: (contact) ->
        val = @proxyValueLink()
        if @props.valueLink.value.length > 0
            current = val.value.split(',').slice(0, -1).join(',')
        else
            current = ""
        if current.trim() isnt ''
            current += ','
        name    = contact.get 'fn'
        address = contact.get 'address'
        val.requestChange "#{current}#{name} <#{address}>,"
        @setState contacts: null, open: false
        # try to put back the focus at the end of the field
        setTimeout =>
            query = @refs.contactInput.getDOMNode().focus()
        , 200

    fixHeight: ->
        input = @refs.contactInput.getDOMNode()
        if input.scrollHeight > input.clientHeight
            input.style.height = input.scrollHeight + "px"
