{
    div
    h3
    h4
    ul
    li
    a
    i
    button
    span
    fieldset
    legend
    label
    img
    form
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
            for tab, index of @props.tabs
                if tab.class?.indexOf('active') >= 0
                    url = null
                else
                    url = tab.url

                li className: tab.class,
                    a
                        href: url
                        key: "tab-#{index}"
                    ,
                        tab.text


ErrorLine = React.createClass

    render: ->
        div
            className: 'col-sm-5 col-sm-offset-2 control-label',
            @props.text


Form = React.createClass

    render: ->
        form
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
                span null, Spinner(white: true)
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



# Widget to display contact following these rules:
# If a name is provided => Contact Name <address@contact.com>
# If no name is provided => address@contact.com
AddressLabel = React.createClass

    render: ->

        if @props.contact.name? and @props.contact.name.length > 0
            key = @props.contact.address.replace /\W/g, ''

            result = span null,
                span null, "#{@props.contact.name} "
                span
                    className: 'contact-address'
                    key: key
                    ,
                        "<#{@props.contact.address}>"

        else
            result = span null, @props.contact.address

        return result

# Available properties:
# - values: {key -> value}
# - value: optional key of current value
Dropdown = React.createClass
    displayName: 'Dropdown'

    getInitialState: ->
        defaultKey = if @props.value? then @props.value else Object.keys(@props.values)[0]
        state=
            label: @props.values[defaultKey]

    render: ->

        renderFilter = (key, value) =>
            onChange = =>
                @setState label: value
                @props.onChange key
            li
                role: 'presentation'
                onClick: onChange
                key: key,
                    a
                        role: 'menuitem'
                        value

        div
            className: 'btn-group btn-group-sm dropdown pull-left',
                button
                    className: 'btn btn-default dropdown-toggle'
                    type: 'button'
                    'data-toggle': 'dropdown'
                    @state.label
                        span className: 'caret', ''
                ul className: 'dropdown-menu', role: 'menu',
                    for key, value of @props.values
                        renderFilter key, t "list filter #{key}"

# Widget to display a spinner.
# If property `white` is set to true, it will use the white version.
Spinner = React.createClass
    displayName: 'Spinner'

    protoTypes:
        white: React.PropTypes.bool

    render: ->
        suffix = if @props.white  then '-white' else ''

        img
            src: "images/spinner#{suffix}.svg"
            alt: 'spinner'
            className: 'button-spinner'


module.exports = {
    AddressLabel
    Container
    Dropdown
    ErrorLine
    Form
    FieldSet
    FormButton
    FormButtons
    FormDropdown
    Spinner
    SubTitle
    Title
    Tabs
}
