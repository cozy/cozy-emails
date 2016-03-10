React = require 'react'

{div, ul, li, span, a, button} = React.DOM

Immutable = require 'immutable'

{Dropdown} = require('./basic_components').factories
PropTypes = require '../libs/prop_types'
RouterMixin = require '../mixins/router_mixin'
cachedTransform = require '../libs/cached_transform'
ShouldComponentUpdate = require '../mixins/should_update_mixin'


module.exports = React.createClass
    displayName: 'MailboxPicker'

    mixins: [RouterMixin, ShouldComponentUpdate.UnderscoreEqualitySlow]

    propTypes:
        allowUndefined: React.PropTypes.bool
        mailboxes: PropTypes.mapOfMailbox
        valueLink: PropTypes.valueLink(PropTypes.string).isRequired

    getDefaultOptions: -> allowUndefined: true

    makeOptions: ->
        cachedTransform @, 'mailboxesOptions', @props.mailboxes, =>
            @props.mailboxes
                .map (box) ->
                    pusher = new Array(box.get('depth') + 1).join '--'
                    "#{pusher}#{box.get 'label'}"
                .toJS()

    render: ->
        return div null unless @props.mailboxes?.size

        Dropdown
            valueLink: @props.valueLink
            className: 'btn-group btn-group-sm pull-left'
            btnClassName: 'btn'
            options: @makeOptions()
            defaultLabel: t 'mailbox pick one'
            undefinedLabel: t 'mailbox pick null'
            allowUndefined: @props.allowUndefined
            undefinedValue: null
