{div, h3, form, label, input, button, fieldset, legend, ul, li, a} = React.DOM
classer = React.addons.classSet

SettingsActionCreator = require '../actions/settings_action_creator'
PluginUtils   = require '../utils/plugin_utils'

module.exports = React.createClass
    displayName: 'Settings'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    render: ->

        classLabel = 'col-sm-2 col-sm-offset-2 control-label'

        div id: 'mailbox-config',
            h3 className: null, t "settings title"

            if @props.error
                div className: 'error', @props.error

            form className: 'form-horizontal',
                div className: 'form-group',
                    label htmlFor: 'settings-mpp', className: classLabel,
                        t "settings label mpp"
                    div className: 'col-sm-3',
                        input
                            id: 'settings-mpp',
                            value: @state.settings.messagesPerPage,
                            onChange: @handleChange,
                            'data-target': 'messagesPerPage',
                            type: 'number',
                            min: 5,
                            max: 100,
                            step: 5,
                            className: 'form-control'

                # Lang
                div className: 'form-group',
                    label htmlFor: 'settings-mpp', className: classLabel,
                        t "settings lang"
                    div className: 'col-sm-3',
                        div className: "dropdown",
                            button
                                className: "btn btn-default dropdown-toggle"
                                type: "button"
                                "data-toggle": "dropdown",
                                t "settings lang #{@state.settings.lang}"
                            ul className: "dropdown-menu", role: "menu",
                                li
                                    role: "presentation",
                                    'data-target': 'lang',
                                    'data-lang': 'en',
                                    onClick: @handleChange,
                                        a role: "menuitem", t "settings lang en"
                                li
                                    role: "presentation",
                                    'data-target': 'lang',
                                    'data-lang': 'fr',
                                    onClick: @handleChange,
                                        a role: "menuitem", t "settings lang fr"

            @_renderOption 'composeInHTML'
            @_renderOption 'messageDisplayHTML'
            @_renderOption 'messageDisplayImages'

            fieldset null,
                legend null, t 'settings plugins'
                for own pluginName, pluginConf of @state.settings.plugins
                    form className: 'form-horizontal', key: pluginName,
                        div className: 'form-group',
                            label className: classLabel, pluginConf.name
                            div className: 'col-sm-3',
                                input
                                    checked: pluginConf.active,
                                    onChange: @handleChange,
                                    'data-target': 'plugin',
                                    'data-plugin': pluginName,
                                    type: 'checkbox',
                                    className: 'form-control'

    _renderOption: (option) ->
        classLabel = 'col-sm-2 col-sm-offset-2 control-label'
        form className: 'form-horizontal',
            div className: 'form-group',
                label
                    htmlFor: 'settings-' + option,
                    className: classLabel,
                    t "settings label " + option
                div className: 'col-sm-3',
                    input
                        id: 'settings-' + option,
                        checked: @state.settings[option],
                        onChange: @handleChange,
                        'data-target': option,
                        type: 'checkbox',
                        className: 'form-control'

    handleChange: (event) ->
        target = event.currentTarget
        switch target.dataset.target
            when 'messagesPerPage'
                settings = @state.settings
                settings.messagesPerPage = target.value
                @setState({settings: settings})
                SettingsActionCreator.edit settings
            when 'composeInHTML', 'messageDisplayHTML', 'messageDisplayImages'
                settings = @state.settings
                settings[target.dataset.target] = target.checked
                @setState({settings: settings})
                SettingsActionCreator.edit settings
            when 'lang'
                lang = target.dataset.lang
                settings = @state.settings
                settings.lang = lang
                @setState({settings: settings})
                moment.locale lang
                try
                    locales = require "../locales/#{lang}"
                catch err
                    console.log err
                    locales = require "../locales/en"
                polyglot = new Polyglot()
                polyglot.extend locales
                window.t = polyglot.t.bind polyglot
                SettingsActionCreator.edit settings
            when 'plugin'
                name = target.dataset.plugin
                settings = @state.settings
                if target.checked
                    PluginUtils.activate name
                else
                    PluginUtils.deactivate name
                for own pluginName, pluginConf of settings.plugins
                    pluginConf.active = window.plugins[pluginName].active
                @setState({settings: settings})
                SettingsActionCreator.edit settings

    getInitialState: (forceDefault) ->
        settings = @props.settings.toObject()
        return {
            settings: @props.settings.toObject()
        }
