{
    div
    section
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

classer = React.addons.classSet


Container = React.createClass

    render: ->
        section
            id: @props.id
            key: @props.key
            className: 'panel'
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
            for index, tab of @props.tabs
                if tab.class?.indexOf('active') >= 0
                    url = null
                else
                    url = tab.url

                li key: "tab-li-#{index}", className: tab.class,
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
                for formButton, index in @props.buttons
                    formButton.key = index
                    FormButton formButton

MenuItem = React.createClass

    render: ->

        liOptions = role: 'presentation'
        liOptions.key = @props.key if @props.key
        liOptions.className = @props.liClassName if @props.liClassName

        aOptions =
            role: 'menuitemu'
            onClick: @props.onClick
        aOptions.className = @props.className if @props.className
        aOptions.href      = @props.href if @props.href
        aOptions.target    = @props.href if @props.target

        li liOptions,
            a aOptions,
                @props.children

MenuHeader = React.createClass

    render: ->
        liOptions = role: 'presentation', className: 'dropdown-header'
        liOptions.key = @props.key if @props.key
        li liOptions, @props.children


MenuDivider = React.createClass

    render: ->
        liOptions = role: 'presentation', className: 'divider'
        liOptions.key = @props.key if @props.key
        li liOptions


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
        meaninglessKey = 0

        if @props.contact.name?.length > 0 and @props.contact.address
            key = @props.contact.address.replace /\W/g, ''

            result = span null,
                span
                    className: 'highlight'
                    @props.contact.name
                span
                    className: 'contact-address'
                    key: key
                    ,
                        i className: 'fa fa-angle-left'
                        @props.contact.address
                        i className: 'fa fa-angle-right'

        else if @props.contact.name?.length > 0
            result = span key: "label-#{meaninglessKey++}",
                @props.contact.name

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
            className: 'dropdown',
                button
                    className: 'dropdown-toggle'
                    type: 'button'
                    'data-toggle': 'dropdown'
                    "#{@state.label} "
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


# Module to display a loading progress bar. It takes a current value and a
# max value as paremeter.
Progress = React.createClass
    displayName: 'Progress'

    propTypes:
        value: React.PropTypes.number.isRequired
        max: React.PropTypes.number.isRequired

    render: ->
        div className: 'progress',
            div
                className: classer
                    'progress-bar': true
                    'actived': @props.value > 0
                style: width: 0
                role: 'progressbar'
                "aria-valuenow": @props.value
                "aria-valuemin": '0'
                "aria-valuemax": @props.max


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
    MenuItem
    MenuHeader
    MenuDivider
    Progress
    Spinner
    SubTitle
    Title
    Tabs
}

