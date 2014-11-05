MessageUtils = require '../utils/message_utils'
ContactForm = require './contact-form'
Modal       = require './modal'
{div, label, input, span} = React.DOM

# Public: input to enter multiple mails
# @TODO : use something tag-it like
# @TODO : autocomplete contacts

module.exports = MailsInput = React.createClass
    displayName: 'MailsInput'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    getInitialState: ->
        return {
            contactShown: false
        }

    # convert mailslist between human-readable and [{address, name}]
    proxyValueLink: ->
        value: MessageUtils.displayAddresses @props.valueLink.value, true
        requestChange: (newValue) =>
            # reverse of MessageUtils.displayAddresses full
            result = newValue.split(',').map (tupple) ->
                if match = tupple.match /"(.*)" <(.*)>/
                    name: match[1], address: match[2]
                else
                    address: tupple

            @props.valueLink.requestChange result

    render: ->
        className = (@props.className or '') + ' form-group'
        classLabel = 'col-sm-2 col-sm-offset-0 control-label'
        classInput = 'col-sm-8'

        onContact = (contact) =>
            val = @proxyValueLink()
            if @props.valueLink.value.length > 0
                current = "#{val.value}, "
            else
                current = ""
            name    = contact.get 'fn'
            address = contact.get 'address'
            val.requestChange "#{current}#{name} <#{address}>"
            @setState contactShown: false

        div className: className,
            label htmlFor: @props.id, className: classLabel,
                @props.label
            div className: classInput,
                div className: 'input-group',
                    input
                        id: @props.id,
                        className: 'form-control',
                        ref: @props.ref,
                        valueLink: @proxyValueLink(),
                        type: 'text',
                        placeholder: @props.placeholder
                    div
                        className: 'input-group-addon btn btn-cozy',
                        onClick: @toggleContact,
                            span className: 'fa fa-search'

                if @state.contactShown
                    content = ContactForm
                        query: @proxyValueLink().value,
                        onContact: onContact
                    Modal {content}

    toggleContact: ->
        @setState contactShown: not @state.contactshown
