{section, header, ul, li, span, i, p, h3, a, button} = React.DOM

MessageUtils = require '../utils/message_utils'
ContactStore = require '../stores/contact_store'
ContactActionCreator = require '../actions/contact_action_creator'
LayoutActionCreator  =  require '../actions/layout_action_creator'
{AddressLabel} = require './basic_components'


# Small component used to display contact label in message headers.
module.exports = ContactLabel = React.createClass

    shouldComponentUpdate: (nextProps, nextState) ->
        should = not (_.isEqual(nextProps, @props))
        return should

    # Display contact label as a link to the contact page if the contact
    # exists, else it displays it as a clickable span than allows to create
    # a contact object in the Cozy for this contact.
    render: ->
        if @props.contact?

            contactModel = ContactStore.getByAddress @props.contact.address

            if contactModel?
                contactId = contactModel.get 'id'
                a
                    ref: 'contact'
                    target: '_blank'
                    href: "/#apps/contacts/contact/#{contactId}"
                    onClick: (event) -> event.stopPropagation()
                    AddressLabel
                        contact: @props.contact

            else
                span
                    ref: 'contact'
                    className: 'participant'
                    onClick: (event) =>
                        event.stopPropagation()
                        @addContact()
                    AddressLabel
                        contact: @props.contact
        else
            span null



    _initTooltip: ->
        if @props.tooltip and @refs.contact?
            node = @refs.contact.getDOMNode()
            # because of absolute positionning of some elements, we must insert
            # tooltip at article level
            container = node.parentNode
            container = container.parentNode while container.tagName isnt 'ARTICLE'
            options =
                showOnClick: false
                container: container
            MessageUtils.tooltip @refs.contact.getDOMNode(), @props.contact, @addContact, options

    componentDidMount: ->
        @_initTooltip()

    componentDidUpdate: ->
        @_initTooltip()

    # When a contact is clicked, it asks to the user if he wants to add it to
    # its Cozy. If the user agrees it runs a contact creation action.
    addContact: ->
        params = contact: MessageUtils.displayAddress @props.contact
        modal =
            title       : t 'message contact creation title'
            subtitle    : t 'message contact creation', params
            closeModal  : ->
                LayoutActionCreator.hideModal()
            closeLabel  : t 'app cancel'
            actionLabel : t 'app confirm'
            action      : =>
                ContactActionCreator.createContact @props.contact
                LayoutActionCreator.hideModal()
        LayoutActionCreator.displayModal modal
