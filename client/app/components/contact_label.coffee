{section, header, ul, li, span, i, p, h3, a, button} = React.DOM

{Tooltips} = require '../constants/app_constants'
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
                span
                    ref: 'contact'
                    onClick: (event) -> event.stopPropagation()
                    AddressLabel
                        contact: @props.contact
                    a
                        className: 'show-contact'
                        target: '_blank'
                        href: "/#apps/contacts/contact/#{contactId}"
                    ,
                        button
                            className: 'fa fa-user'
                            'aria-describedby': Tooltips.SHOW_CONTACT
                            'data-tooltip-direction': 'top'

            else
                span
                    ref: 'contact'
                    className: 'participant'
                ,
                    AddressLabel
                        contact: @props.contact
                    span
                        className: 'add-contact'
                        onClick: (event) =>
                            event.stopPropagation()
                            @addContact()
                    ,
                        button
                            className: 'fa fa-user-plus'
                            'aria-describedby': Tooltips.ADD_CONTACT
                            'data-tooltip-direction': 'top'
        else
            span()

    componentDidMount: ->

    componentDidUpdate: ->

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
                ContactActionCreator.createContact @props.contact, =>
                    # When creation is done the contact is rendered again.
                    @forceUpdate()
                LayoutActionCreator.hideModal()
        LayoutActionCreator.displayModal modal
