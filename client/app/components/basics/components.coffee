React = require 'react'
{createClass, createFactory, PropTypes, DOM} = React
classNames                                   = require 'classnames'

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
    img
    form
} = DOM

PropTypes = require '../../libs/prop_types'

registry = {}
factories = {}


registry.Container = createClass

    render: ->
        section
            id: @props.id
            key: @props.key
            'aria-expanded': @props.expand or 'false'
            className: 'panel'
        ,
            @props.children


registry.Title = createClass

    render: ->
        h3
            refs: @props.ref
            className: 'title'
        ,
            @props.text


registry.SubTitle = createClass

    render: ->
        h4 className: 'subtitle ' + @props.className, @props.children


registry.Tabs = createClass

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


registry.ErrorLine = createClass

    render: ->
        div
            className: 'col-sm-5 col-sm-offset-2 control-label',
            @props.text


registry.Form = createClass

    render: ->
        form
            id: @props.id
            className: @props.className
            method: 'POST'
        ,
            @props.children


registry.FieldSet = createClass

    render: ->
        fieldset null,
            legend null, @props.text
            @props.children


registry.FormButton = createClass

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
                span null, factories.Spinner(color: 'white')
            else
                span className: "fa fa-#{@props.icon}"
            span null, @props.text


registry.FormButtons = createClass

    render: ->
        div className: 'col-sm-offset-4', @props.children


registry.Menu = createClass

    render: ->
        div className: 'menu-action btn-group btn-group-sm',
            button
                className: "btn btn-default dropdown-toggle fa #{@props.icon}"
                type: 'button'
                'data-toggle': 'dropdown'
                ' ', span className: 'caret'
            ul
                className: "dropdown-menu dropdown-menu-#{@props.direction}"
                role: 'menu',
                @props.children


registry.LinkButton = createClass
    render: ->
        a
            className: "btn btn-default fa #{@props.icon}"
            onClick: @props.onClick
            'aria-describedby': @props['aria-describedby']
            'data-tooltip-direction': @props['data-tooltip-direction']


registry.Button = createClass

    render: ->
        className = "btn btn-default"
        className += " fa #{@props.icon}" if @props.icon
        className += " #{@props.className}" if @props.className
        button
            className: className
            onClick: @props.onClick


registry.MenuItem = createClass

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


registry.MenuHeader = createClass

    render: ->
        liOptions = role: 'presentation', className: 'dropdown-header'
        liOptions.key = @props.key if @props.key
        li liOptions, @props.children


registry.MenuDivider = createClass

    render: ->
        liOptions = role: 'presentation', className: 'divider'
        liOptions.key = @props.key if @props.key
        li liOptions


# @TODO : merge me with FormDropdown and Dropdown
registry.DropdownItem = createClass
    onClick: -> @props.requestChange @props.key
    render: ->
        li
            role: 'presentation'
            key: @props.key,
            onClick: @onClick
        ,
            a role: 'menuitem', @props.value


registry.Dropdown = createClass

    getDefaultProps: ->
        className: ''
        btnClassName: ''
        allowUndefined: false

    propTypes:
        valueLink: PropTypes.valueLink(PropTypes.string).isRequired
        allowUndefined: PropTypes.bool.isRequired
        options: PropTypes.object.isRequired
        className: PropTypes.string
        id: PropTypes.string
        btnClassName: PropTypes.string
        defaultLabel: PropTypes.string
        undefinedValue: PropTypes.string

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
                    factories.DropdownItem
                        key: null,
                        value: @props.undefinedValue
                        requestChange: valueLink.requestChange

                for key, value of @props.options
                    if key isnt valueLink.value
                        factories.DropdownItem
                            key: key,
                            value: value,
                            requestChange: valueLink.requestChange


# Widget to display contact following these rules:
# If a name is provided => Contact Name <address@contact.com>
# If no name is provided => address@contact.com
registry.AddressLabel = createClass

    propTypes: ->
        participant: React.PropTypes.shape(
            address: React.PropTypes.string.isRequired,
            name: React.PropTypes.string
        )

    render: ->
        meaninglessKey = 0

        if @props.participant.name?.length > 0 and @props.participant.address
            key = @props.participant.address.replace /\W/g, ''

            result = span null,
                span
                    className: 'highlight'
                    @props.participant.name
                span
                    className: 'participant-address'
                    key: key
                    ,
                        i className: 'fa fa-angle-left'
                        @props.participant.address
                        i className: 'fa fa-angle-right'

        else if @props.participant.name?.length > 0
            result = span key: "label-#{meaninglessKey++}",
                @props.participant.name

        else
            result = span null, @props.participant.address

        return result


# Widget to display a spinner.
# If property `white` is set to true, it will use the white version.
registry.Spinner = createClass
    displayName: 'Spinner'

    protoTypes:
        color: PropTypes.string

    render: ->
        suffix = if @props.color then "-#{@props.color}" else ''

        img
            src:       require "../../assets/images/spinner#{suffix}.svg"
            alt:       'spinner'
            className: 'button-spinner spin-animate'


# Module to display a loading progress bar. It takes a current value and a
# max value as paremeter.
registry.Progress = createClass
    displayName: 'Progress'

    propTypes:
        value: PropTypes.number.isRequired
        max: PropTypes.number.isRequired

    render: ->
        isActive = @props.value < @props.max
        width = if isActive then "0" else "100%"
        div className: 'progress',
            div
                className: classNames
                    'progress-bar': true
                    'actived': isActive
                style: {width}
                role: 'progressbar'
                "aria-valuenow": @props.value
                "aria-valuemin": '0'
                "aria-valuemax": @props.max


registry.Icon = createClass
    displayName: 'Icon'

    propTypes:
        type: PropTypes.string.isRequired

    render: ->

        className = "#{@props.className or ''} fa fa-#{@props.type}"
        i
            className: className
            onClick: @props.onClick


factories[name] = createFactory component for name, component of registry
module.exports = factories: factories
