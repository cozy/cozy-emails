React = require 'react'
{nav, div, button} = React.DOM

{Tooltips} = require '../constants/app_constants'

module.exports = React.createClass
    displayName: 'ToolbarMessage'


    deleteMessage: ->
        @props.onDeleteClicked(@props)


    render: ->
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
