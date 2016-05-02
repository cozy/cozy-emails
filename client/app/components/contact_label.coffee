React = require 'react'
{span, a, button} = React.DOM

{Tooltips} = require '../constants/app_constants'

ContactGetter = require '../getters/contact'

{AddressLabel} = require('./basic_components').factories


# Small component used to display contact label in message headers.
module.exports = React.createClass

    # Display contact label as a link to the contact page if the contact
    # exists, else it displays it as a clickable span than allows to create
    # a contact object in the Cozy for this contact.
    render: ->
        unless @props.contact?
            return span()

        # FIXME : le lien vers le contact ne peux pas fonctionner
        # -> regarder la forme que devrait avoir ce lien
        # -> le remplacer par une props avec pour value
        # -> une URL générée avec le contactID pour argument
        if (model = ContactGetter.getByAddress @props.contact)?
            return span
                ref: 'contact'
                AddressLabel
                    contact: @props.contact
                a
                    className: 'show-contact'
                    target: '_blank'
                    href: "/#apps/contacts/contact/#{model.get 'id'}",

                    button
                        className: 'fa fa-user'
                        'aria-describedby': Tooltips.SHOW_CONTACT
                        'data-tooltip-direction': 'top'

        span
            ref: 'contact'
            className: 'participant',
            AddressLabel
                contact: @props.contact,

                span
                    className: 'add-contact'
                    onClick: @addContact
                    button
                        className: 'fa fa-user-plus'
                        'aria-describedby': Tooltips.ADD_CONTACT
                        'data-tooltip-direction': 'top'


    # When a contact is clicked, it asks to the user if he wants to add it to
    # its Cozy. If the user agrees it runs a contact creation action.
    addContact: ->
        console.log 'ADD_CONTACT'
        # FIXME: passer par la home pour gérer cette modale
        # lorsque le SUCCESS ou FAILURE est lancé
        # lancer Actiondans le store concerné
        # params = contact: MessageUtils.displayAddress @props.contact
        # modal =
        #     title       : t 'message contact creation title'
        #     subtitle    : t 'message contact creation', params
        #     closeLabel  : t 'app cancel'
        #     actionLabel : t 'app confirm'
        #     action      : =>
        #         ContactActionCreator.createContact @props.contact, =>
        #             # When creation is done the contact is rendered again.
        #             @forceUpdate()
        #         LayoutActionCreator.hideModal()
        # LayoutActionCreator.displayModal modal
