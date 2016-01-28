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
PropTypes = require '../libs/prop_types'


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
        h4 className: 'subtitle ' + @props.className, @props.children


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

        if @props.className?
            className += @props.className

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
        div className: 'col-sm-offset-4', @props.children

MenuItem = React.createClass

    onClick: ->
        @props.onClick @props.onClickValue

    render: ->

        liOptions = role: 'presentation'
        liOptions.key = @props.key if @props.key
        liOptions.className = @props.liClassName if @props.liClassName

        aOptions =
            role: 'menuitemu'
        aOptions.onClick   = @onClick if @props.onClick
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

Dropdown = React.createClass

    getDefaultProps: ->
        className: ''
        btnClassName: ''
        allowUndefined: false

    propTypes:
        valueLink: PropTypes.valueLink(PropTypes.string).isRequired
        allowUndefined: React.PropTypes.bool.isRequired
        options: React.PropTypes.object.isRequired
        className: React.PropTypes.string
        id: React.PropTypes.string
        btnClassName: React.PropTypes.string
        defaultLabel: React.PropTypes.string
        undefinedValue: React.PropTypes.string

    render: ->
        valueLink = @props.valueLink or
            value: @props.value
            requestChange: @props.onChange

        className = 'dropdown ' + @props.className
        btnClassName = 'dropdown-toggle ' + @props.btnClassName
        selected = @props.options[valueLink.value]

        div className: className, id: @props.id,
            button
                className: btnClassName,
                'data-toggle': 'dropdown',
                selected or @props.defaultLabel
                span className: 'caret', ''
            ul className: 'dropdown-menu', role: 'menu',
                if @props.allowUndefined and selected?
                    DropdownItem
                        key: null,
                        value: @props.undefinedValue
                        requestChange: valueLink.requestChange

                for key, value of @props.options
                    if key isnt valueLink.value
                        DropdownItem
                            key: key,
                            value: value,
                            requestChange: valueLink.requestChange

# @TODO : merge me with FormDropdown and Dropdown
DropdownItem = React.createClass
    onClick: -> @props.requestChange @props.key
    render: ->
        li
            role: 'presentation'
            key: @props.key,
            onClick: @onClick
        ,
            a role: 'menuitem', @props.value


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

Icon = React.createClass
    displayName: 'Icon'

    propTypes:
        type: React.PropTypes.string.isRequired

    render: ->
        className = "#{@props.className or ''} fa fa-#{@props.type}"
        i
            className: className
            onClick: @props.onClick


module.exports = {
    AddressLabel
    Container
    Dropdown
    ErrorLine
    Form
    FieldSet
    FormButton
    FormButtons
    Icon
    MenuItem
    MenuHeader
    MenuDivider
    Progress
    Spinner
    SubTitle
    Title
    Tabs
}

