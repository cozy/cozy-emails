React = require 'react'

frame  = React.createFactory require '../components/frame'
{div, span, i, p, button} = React.DOM


module.exports = MessageContent = React.createClass
    displayName: 'MessageContent'

    render: ->
        if @props.displayHTML and @props.html
            div null,
                if @props.imagesWarning
                    div
                        className: "imagesWarning alert alert-warning content-action",
                        ref: "imagesWarning",
                            i className: 'fa fa-shield'
                            t 'message images warning'
                            button
                                className: 'btn btn-xs btn-warning',
                                type: "button",
                                ref: 'imagesDisplay',
                                onClick: @props.displayImages,
                                t 'message images display'

                frame null,
                    span dangerouslySetInnerHTML: { __html: @props.html }

        else
            div className: 'row',
                div className: 'preview', ref: 'content',
                    p dangerouslySetInnerHTML: { __html: @props.rich }
