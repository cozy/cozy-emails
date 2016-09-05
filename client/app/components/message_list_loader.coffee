React = require 'react'

{div, p, strong} = React.DOM
{Spinner} = require('./basics/components').factories


module.exports = MessageListLoader = React.createClass
    displayName: 'MessageListLoader'

    render: ->
        div className: 'mailbox-loading',
            Spinner(color: 'blue')
            strong null, t('emails are fetching')
            p null, t('thanks for patience')
