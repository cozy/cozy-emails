React = require 'react'
Immutable = require 'immutable'
{span, a, button} = React.DOM

{Tooltips} = require '../constants/app_constants'

{AddressLabel} = require('./basics/components').factories

# Display contact label as a link to the contact page if the contact
# exists, else it displays it as a clickable span than allows to create
# a contact object in the Cozy for this contact.
module.exports = React.createClass

    propTypes: ->
        displayModal: React.PropTypes.func.isRequired
        createContact: React.PropTypes.func.isRequired
        contacts: React.PropTypes.instanceOf(Immutable.Map)
        participant: React.PropTypes.shape(
            address: React.PropTypes.string.isRequired,
            name: React.PropTypes.string
        )



    render: ->

        contact = @props.contacts.get(@props.participant.address)

        span
            ref: 'contact'
            className: 'participant',
            AddressLabel
                participant: @props.participant

            if (contact)?
                a
                    className: 'show-contact'
                    href: "/#apps/contacts/contact/#{contact.get('id')}"
                    target: "_blank"
                    button
                        className: 'fa fa-user'
                        'aria-describedby': Tooltips.SHOW_CONTACT
                        'data-tooltip-direction': 'top'
            else
                span
                    className: 'add-contact'
                    onClick: @addContact
                    button
                        className: 'fa fa-user-plus'
                        'aria-describedby': Tooltips.ADD_CONTACT
                        'data-tooltip-direction': 'top'


    addContact: (event) ->
        event.stopPropagation()
        @props.displayModal {
            title       : t 'message contact creation title'
            subtitle    : t 'message contact creation',
                contact: @props.participant.adress
            closeLabel  : t 'app cancel'
            actionLabel : t 'app confirm'
            action      : (close) =>
                @props.createContact @props.participant
                close()
        }
