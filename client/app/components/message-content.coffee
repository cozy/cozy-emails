React = require 'react'
{div, span, i, p, a, button, iframe} = React.DOM

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

                        i className: 'fa fa-shield',
                        t 'message images warning'

                        button
                            ref: 'imagesDisplay'
                            type: "button"
                            className: 'btn btn-xs btn-warning'
                            onClick: @displayImages,
                            t 'message images display'

                iframe
                    ref: 'content'
                    name: "frame-#{@props.messageID}"
                    className: 'content'
                    src: 'about:blank'
                    allowTransparency: false
                    frameBorder: 0
        else
            div className: 'row',
                div className: 'preview', ref: 'content',
                    p dangerouslySetInnerHTML: { __html: @props.rich }


    _initFrame: (type) ->
        # - resize the frame to the height of its content
        # - if images are not displayed, create the function to display them
        #   and resize the frame
        if @props.html?.length and @refs.content
            frame = @refs.content
            doc = frame.contentDocument or frame.contentWindow?.document
            checkResize = false # disabled for now
            step = 0
            # Function called on frame load
            # Inject HTML content of the message inside the frame, then
            # update frame height to remove scrollbar
            loadContent = (e) =>
                step = 0
                doc = frame.contentDocument or frame.contentWindow?.document
                if doc?
                    doc.documentElement.innerHTML = @props.html
                    updateHeight = (e) ->
                        height = doc.documentElement.scrollHeight
                        if height < 60
                            frame.style.height = "60px"
                        else if height > frame.style.height
                            frame.style.height = "#{height + 60}px"
                        step++
                        # Prevent infinite loop on onresize event
                        if checkResize and step > 10

                            doc.body.removeEventListener 'load', loadContent
                            frame.contentWindow?.removeEventListener 'resize'

                    updateHeight()
                    # some browsers don't fire event when remote fonts are loaded
                    # so we need to wait a little and check the frame height again
                    setTimeout updateHeight, 1000

                    # Update frame height on load
                    doc.body.onload = updateHeight

                    # disabled for now
                    if checkResize
                        frame.contentWindow.onresize = updateHeight
                        window.onresize = updateHeight
                        frame.contentWindow?.addEventListener 'resize', updateHeight, true
                else
                    # try to display text only
                    @props.html = null

            if type is 'mount' and doc.readyState isnt 'complete'
                frame.addEventListener 'load', loadContent
            else
                loadContent()


    componentDidMount: ->
        @_initFrame('mount')


    componentDidUpdate: ->
        @_initFrame('update')
