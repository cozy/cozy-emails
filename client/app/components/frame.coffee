React = require 'react'
ReactDOM  = require 'react-dom'

{iframe, div} = React.DOM

_counter = -1
_loadMax = 10

module.exports =  Frame = React.createClass
    displayName: 'Frame'

    render: ->
        iframe
            className: 'content'
            src: 'about:blank'
            allowTransparency: false
            frameBorder: 0

    componentDidMount: ->
        @renderFrameContents()

    getDocument: ->
        element = ReactDOM.findDOMNode @
        doc = element.contentDocument
        doc ?= element.contentWindow?.document
        doc

    renderFrameContents: ->
        # doc = @getDocument()
        if (doc = @getDocument())?.readyState is 'complete'
            ReactDOM.render @props.children, doc.body
        else if _loadMax < ++_counter
            setTimeout @renderFrameContents, 0

    componentDidUpdate: ->
        @renderFrameContents()

    componentWillUnmount: ->
        if (doc = @getDocument())
            ReactDOM.unmountComponentAtNode doc.body
