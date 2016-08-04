React = require 'react'
ReactDOM  = require 'react-dom'

{iframe} = React.DOM

module.exports =  Frame = React.createClass
    displayName: 'Frame'


    render: ->
        iframe
            className: 'content'
            src: 'about:blank'
            allowTransparency: false
            frameBorder: 0


    componentDidMount: ->
        @createContainer()
        @renderFrameContents()

    createContainer: ->
        doc = @getDocument()
        @container = doc.createElement('div')
        doc.body.appendChild @container

    setContainerContent: ->
        doc = @getDocument()
        ReactDOM.render @props.children, @container

        # Resize Iframe content
        # with ist content size
        el = ReactDOM.findDOMNode(@)
        el.setAttribute 'width', doc.body.scrollWidth
        el.setAttribute 'height', doc.body.scrollHeight

    getDocument: ->
        element = ReactDOM.findDOMNode @
        doc = element.contentDocument
        doc ?= element.contentWindow?.document
        doc


    onDocumentReady: (doc) ->
        ReactDOM.render @props.children, doc.body

        # Resize Iframe content
        # with ist content size
        el = ReactDOM.findDOMNode(@)
        el.setAttribute 'width', doc.body.scrollWidth
        el.setAttribute 'height', doc.body.scrollHeight


    renderFrameContents: ->
        doc = @getDocument()
        # TODO: Throw an error ?
        return unless doc

        # 'interactive' readyState seems to be also working, but as the previous
        # code was testing only 'complete', there is for sure a good reason.
        # So, there is still a little delay before displaying the message on
        # Firefox, but it could be fastened by displaying as soon as the
        # readyState is 'interactive'.
        if doc.readyState is 'complete'
            @onDocumentReady(doc)
        else
            # If ready state is not complete we wait for it by adding an event
            # listener on 'readyStateChange' event.

            # Reference the readyStateChange handler to be able to remove it
            # afterward.
            readyStateChangeHandler = =>
                if doc.readyState is 'complete'
                    @onDocumentReady(doc)
                    doc.removeEventListener 'readystatechange',
                        readyStateChangeHandler

            doc.addEventListener 'readystatechange', readyStateChangeHandler


    componentDidUpdate: ->
        @setContainerContent()


    componentWillUnmount: ->
        if (doc = @getDocument())
            ReactDOM.unmountComponentAtNode doc.body
