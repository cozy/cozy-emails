{div, label, input, span, ul, li, a, img, i} = React.DOM

MessageUtils    = require '../utils/message_utils'
Modal           = require './modal'
StoreWatchMixin = require '../mixins/store_watch_mixin'
ContactStore    = require '../stores/contact_store'
ContactActionCreator = require '../actions/contact_action_creator'

classer = React.addons.classSet

# Public: input to enter multiple mails
# @TODO : use something tag-it like

module.exports = MailsInput = React.createClass
    displayName: 'MailsInput'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
        StoreWatchMixin [ContactStore]
    ]

    getStateFromStores: ->
        query = @refs.contactInput?.getDOMNode().value.trim()
        return {
            #contacts: if query?.length > 2 then ContactStore.getResults() else null
            contacts: ContactStore.getResults()
            selected: 0
            open: false
        }

    componentWillMount: ->
        @setState contacts: null, open: false

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    # convert mailslist between human-readable and [{address, name}]
    proxyValueLink: ->
        value: MessageUtils.displayAddresses @props.valueLink.value, true
        requestChange: (newValue) =>
            # reverse of MessageUtils.displayAddresses full
            result = newValue.split(',').map (tupple) ->
                if match = tupple.match /"(.*)" <(.*)>/
                    name: match[1], address: match[2]
                else
                    address: tupple.trim()

            @props.valueLink.requestChange result

    render: ->
        className  = (@props.className or '') + ' form-group'
        classLabel = 'compose-label control-label'
        listClass  = classer
            'contact-form': true
            open: @state.open and @state.contacts?.length > 0
        current    = 0

        div className: className,
            label htmlFor: @props.id, className: classLabel,
                @props.label
            div className: 'contact-group dropdown ' + listClass,
                input
                    id: @props.id,
                    name: @props.id,
                    className: 'form-control compose-input',
                    onKeyDown: @onKeyDown,
                    onBlur: @onBlur,
                    ref: 'contactInput'
                    valueLink: @proxyValueLink(),
                    type: 'text',
                    placeholder: @props.placeholder
                    'autoComplete': 'off'
                div
                    className: 'input-group-addon btn btn-cozy contact',
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
        query = @refs.contactInput.getDOMNode().value.split(',').pop().trim()
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
