{div} = React.DOM

module.exports = ThinProgress = React.createClass
    displayName: 'ThinProgress'

    render: ->
        percent = 100 * (@props.done / @props.total) + '%'
        div className: "progress progress-thin",
            div
                className: 'progress-bar',
                style: width: percent
