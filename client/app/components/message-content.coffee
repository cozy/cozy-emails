React = require 'react'
{div, span, i, p, button} = React.DOM

frame  = React.createFactory require '../components/frame'

SettingsActionCreator = require '../actions/settings_action_creator'


module.exports = MessageContent = React.createClass
    displayName: 'MessageContent'

    displayImages: ->
        displayImages = true
        SettingsActionCreator.edit {displayImages}

    render: ->
        if @props.html?.length
            div null,
                if @props.imagesWarning
                    div
                        ref: "imagesWarning"
                        className: "imagesWarning alert alert-warning content-action",
                        ref: "imagesWarning",
                            i className: 'fa fa-shield'
                            t 'message images warning'
                            button
                                className: 'btn btn-xs btn-warning',
                                type: "button",
                                ref: 'imagesDisplay',
                                onClick: @displayImages,
                                t 'message images display'

                frame null,
                    span dangerouslySetInnerHTML: { __html: @props.html }
        else
            div className: 'row',
                div className: 'preview', ref: 'content',
                    p dangerouslySetInnerHTML: { __html: @props.rich }
