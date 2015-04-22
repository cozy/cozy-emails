{
    div
    h3
    h4
    ul
    li
    a
    button
    span
    fieldset
    legend
    label
    img
} = React.DOM


Container = React.createClass

    render: ->
        div
            id: @props.id
            key: @props.key
        ,
            @props.children


Title = React.createClass

    render: ->
        h3
            refs: @props.ref
            className: 'title'
        ,
            @props.text


SubTitle = React.createClass

    render: ->
        h4
            refs: @props.ref
            className: 'subtitle ' + @props.className
        ,
            @props.text


Tabs = React.createClass

    render: ->
        ul className: "nav nav-tabs", role: "tablist",
            for tab in @props.tabs
                li className: tab.class,
                    a
                        href: tab.url
                    ,
                        tab.text


ErrorLine = React.createClass

    render: ->
        div
            className: 'col-sm-5 col-sm-offset-2 control-label',
            @props.text


Form = React.createClass

    render: ->
        div
            id: @props.id
            className: @props.className
            method: 'POST'
        ,
            @props.children


FieldSet = React.createClass

    render: ->
        fieldset null,
            legend null, @props.text
            @props.children


FormButton = React.createClass

    render: ->
        className = 'btn '
        if @props.contrast
            className += 'btn-cozy-contrast '
        else if @props.default
            className += 'btn-cozy-default '
        else
            className += 'btn-cozy '

        if @props.danger
            className += 'btn-danger '

        if @props.class?
            className += @props.class

        button
            className: className
            onClick: @props.onClick
        ,
            if @props.spinner
                span null,
                    img
                        src: 'images/spinner-white.svg'
                        className: 'button-spinner'
            else
                span className: "fa fa-#{@props.icon}"
            span null, @props.text


FormButtons = React.createClass

    render: ->

        div null,
            div className: 'col-sm-offset-4',
                FormButton formButton for formButton in @props.buttons


FormDropdown = React.createClass

    render: ->

        div
            key: "account-input-#{@props.name}"
            className: "form-group account-item-#{@props.name} "
        ,
            label
                htmlFor: "#{@props.prefix}-#{@props.name}",
                className: "col-sm-2 col-sm-offset-2 control-label"
            ,
                @props.labelText
            div className: 'col-sm-3',
                div className: "dropdown",
                    button
                        id: "#{@props.prefix}-#{@props.name}"
                        name: "#{@props.prefix}-#{@props.name}"
                        className: "btn btn-default dropdown-toggle"
                        type: "button"
                        "data-toggle": "dropdown"
                    ,
                        @props.defaultText

                    ul className: "dropdown-menu", role: "menu",
                        @props.values.map (method) =>
                            li
                                role: "presentation",
                                    a
                                        'data-value': method
                                        role: "menuitem"
                                        onClick: @props.onClick
                                    ,
                                        t "#{@props.methodPrefix} #{method}"



module.exports = {
    Title, Tabs, Container, ErrorLine, Form, FieldSet, FormButton, FormButtons,
    SubTitle, FormDropdown
}
