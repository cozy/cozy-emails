React = require 'react'
{nav, div, button, a} = React.DOM

{Tooltips} = require '../constants/app_constants'
RouterActionCreator = require '../actions/router_action_creator'

RouterGetter = require '../getters/router'


module.exports = React.createClass
    displayName: 'ToolbarMessage'


    deleteMessage: ->
        RouterActionCreator.deleteMessage @props


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
