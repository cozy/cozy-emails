{div, table, tbody, tr, td, i} = React.DOM

ParticipantMixin = require '../mixins/participant_mixin'


module.exports = React.createClass
    displayName: 'PopupMessageDetails'

    mixins: [
        ParticipantMixin,
        OnClickOutside
    ]


    getInitialState: ->
        showDetails: false


    toggleDetails: ->
        @setState showDetails: not @state.showDetails


    handleClickOutside: ->
        @setState showDetails: false


    render: ->
        from = @props.message.get('from')[0]
        to = @props.message.get 'to'
        cc = @props.message.get 'cc'
        reply = @props.message.get('reply-to')?[0]

        row = (id, value, label = false, rowSpan = false) ->
            items = []
            if label
                attrs = className: 'label'
                attrs.rowSpan = rowSpan if rowSpan
                items.push td attrs, t label
            items.push td key: "cell-#{id}", value
            return tr key: "row-#{id}", items...

        div
            className: 'metas details'
            'aria-expanded': @state.showDetails
            onClick: (event) -> event.stopPropagation()
            i className: 'fa fa-caret-down', onClick: @toggleDetails
            if @state.showDetails
                div className: 'popup', 'aria-hidden': not @state.showDetails,
                    table null,
                        tbody null,
                            row 'from', @formatUsers(from), 'headers from'
                            row 'to', @formatUsers(to[0]), 'headers to', to.length if to.length
                            row "destTo#{key}", @formatUsers(dest) for dest, key in to[1..] if to.length
                            row 'cc', @formatUsers(cc[0]), 'headers cc', cc.length if cc.length
                            row "destCc#{key}", @formatUsers(dest) for dest, key in cc[1..] if cc.length
                            row 'reply', @formatUsers(reply), 'headers reply-to' if reply?
                            row 'created', @props.message.get('createdAt'), 'headers date'
