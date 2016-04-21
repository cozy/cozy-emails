React = require 'react'
{nav, div, button, a} = React.DOM

{MessageActions, Tooltips} = require '../constants/app_constants'
RouterActionCreator = require '../actions/router_action_creator'

RouterGetter = require '../getters/router'



module.exports = React.createClass
    displayName: 'ToolbarMessage'

    deleteMessage: ->
        messageID = @props.messageID
        RouterActionCreator.delete {messageID}

    render: ->
        messageID = @props.messageID
        cBtnGroup = 'btn-group btn-group-sm pull-right'
        cBtn      = 'btn btn-default fa'

        nav
            className: 'toolbar toolbar-message btn-toolbar',

            if @props.isFull
                div className: cBtnGroup,
                    button
                        className: "#{cBtn} fa-trash"
                        onClick: @deleteMessage
                        'aria-describedby': Tooltips.REMOVE_MESSAGE
                        'data-tooltip-direction': 'top'

            if @props.isFull
                div className: cBtnGroup,
                    a
                        className: "#{cBtn} fa-mail-reply mail-reply"
                        href: RouterGetter.getURL {action: MessageActions.REPLY, messageID}
                        'aria-describedby': Tooltips.REPLY
                        'data-tooltip-direction': 'top'

                    a
                        className: "#{cBtn} fa-mail-reply-all mail-reply-all"
                        href: RouterGetter.getURL {action: MessageActions.REPLY_ALL, messageID}
                        'aria-describedby': Tooltips.REPLY_ALL
                        'data-tooltip-direction': 'top'

                    a
                        className: "#{cBtn} fa-mail-forward mail-forward"
                        href: RouterGetter.getURL {action: MessageActions.FORWARD, messageID}
                        'aria-describedby': Tooltips.FORWARD
                        'data-tooltip-direction': 'top'
