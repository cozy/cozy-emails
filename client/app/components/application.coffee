{body, div, p} = React.DOM

module.exports = Application = React.createClass
    displayName: 'Application'

    render: ->
        body null,
            p null, 'coucou'
