React = require 'react'
{div, span, i, p, button} = React.DOM

frame  = React.createFactory require '../components/frame'

module.exports = React.createClass
    displayName: 'MessageContent'


    displayImages: ->
        displayImages = true
        messageID = @props.messageID
        @props.doDisplayImages {displayImages, messageID}


    render: ->
        if @props.html?.length
            div null,
                if @props.imagesWarning
                    div
                        ref: "imagesWarning"
                        className: "imagesWarning alert alert-warning content-action",
                            i className: 'fa fa-shield'
                            t 'message images warning'
                            button
                                ref: 'imagesDisplay',
                                key: "imagesDisplay-#{@props.messageID}",
                                className: 'btn btn-xs btn-warning',
                                type: "button",
                                onClick: @displayImages,
                                t 'message images display'

                frame null,
                    span dangerouslySetInnerHTML: { __html: @props.html }
        else
            div className: 'row',
                div className: 'preview', ref: 'content',
                    p dangerouslySetInnerHTML: { __html: @props.rich }
