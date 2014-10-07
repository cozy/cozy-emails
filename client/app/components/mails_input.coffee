MessageUtils = require '../utils/message_utils'
{div, label, input} = React.DOM

# Public: input to enter multiple mails
# @TODO : use something tag-it like
# @TODO : autocomplete contacts

module.exports = MailsInput = React.createClass
    displayName: 'MailsInput'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

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

        div className: className,
            label htmlFor: @props.id, className: classLabel, 
                @props.label
            div className: classInput,
                input 
                    id: @props.id,
                    className: 'form-control', 
                    ref: @props.ref, 
                    valueLink: @proxyValueLink(), 
                    type: 'text', 
                    placeholder: @props.placeholder