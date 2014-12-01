{div, h3, form, label, input, button, fieldset, legend, ul, li, a} = React.DOM
classer = React.addons.classSet

SettingsActionCreator = require '../actions/settings_action_creator'
PluginUtils = require '../utils/plugin_utils'
ApiUtils = require '../utils/api_utils'

module.exports = React.createClass
    displayName: 'Settings'

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

                div className: 'form-group',
                    label htmlFor: 'settings-refresh', className: classLabel,
                        t "settings label refresh"
                    div className: 'col-sm-3',
                        input
                            id: 'settings-refresh',
                            value: @state.settings.refreshInterval,
                            onChange: @handleChange,
                            'data-target': 'refreshInterval',
                            type: 'number',
                            min: 1,
                            max: 15,
                            step: 1,
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

                # List style
                div className: 'form-group',
                    label htmlFor: 'settings-mpp', className: classLabel,
                        t "settings label listStyle"
                    div className: 'col-sm-3',
                        div className: "dropdown",
                            button
                                className: "btn btn-default dropdown-toggle"
                                type: "button"
                                "data-toggle": "dropdown",
                                t "settings label listStyle #{@state.settings.listStyle or 'default'}"
                            ul className: "dropdown-menu", role: "menu",
                                li
                                    role: "presentation",
                                    'data-target': 'listStyle',
                                    'data-style': 'default',
                                    onClick: @handleChange,
                                        a role: "menuitem", t "settings label listStyle default"
                                li
                                    role: "presentation",
                                    'data-target': 'listStyle',
                                    'data-style': 'compact',
                                    onClick: @handleChange,
                                        a role: "menuitem", t "settings label listStyle compact"

            @_renderOption 'displayConversation'
            @_renderOption 'composeInHTML'
            @_renderOption 'composeOnTop'
            @_renderOption 'messageDisplayHTML'
            @_renderOption 'messageDisplayImages'
            @_renderOption 'messageConfirmDelete'
            @_renderOption 'displayPreview'

            fieldset null,
                legend null, t 'settings plugins'
                for own pluginName, pluginConf of @state.settings.plugins
                    form className: 'form-horizontal', key: pluginName,
                        div className: 'form-group',
                            label
                                className: classLabel,
                                htmlFor: 'settings-plugin-' + pluginName,
                                pluginConf.name
                            div className: 'col-sm-3',
                                input
                                    id: 'settings-plugin-' + pluginName,
                                    checked: pluginConf.active,
                                    onChange: @handleChange,
                                    'data-target': 'plugin',
                                    'data-plugin': pluginName,
                                    type: 'checkbox'

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
                        type: 'checkbox'

    handleChange: (event) ->
        event.preventDefault()
        target = event.currentTarget
        switch target.dataset.target
            when 'messagesPerPage'
                settings = @state.settings
                settings.messagesPerPage = target.value
                @setState({settings: settings})
                SettingsActionCreator.edit settings
            when 'refreshInterval'
                settings = @state.settings
                settings.refreshInterval = target.value
                @setState({settings: settings})
                SettingsActionCreator.edit settings
                SettingsActionCreator.setRefresh target.value
            when 'composeInHTML'
            ,    'composeOnTop'
            ,    'displayConversation'
            ,    'messageDisplayHTML'
            ,    'messageDisplayImages'
            ,    'messageConfirmDelete'
            ,    'displayPreview'
                settings = @state.settings
                settings[target.dataset.target] = target.checked
                @setState({settings: settings})
                SettingsActionCreator.edit settings
            when 'lang'
                lang = target.dataset.lang
                settings = @state.settings
                settings.lang = lang
                @setState({settings: settings})
                ApiUtils.setLocale lang, true
                SettingsActionCreator.edit settings
            when 'listStyle'
                settings = @state.settings
                settings.listStyle = target.dataset.style
                @setState({settings: settings})
                SettingsActionCreator.edit settings
            when 'plugin'
                name = target.dataset.plugin
                settings = @state.settings
                if target.checked
                    PluginUtils.activate name
                else
                    PluginUtils.deactivate name
                for own pluginName, pluginConf of settings.plugins
                    settings.plugins[pluginName].active = window.plugins[pluginName].active
                @setState({settings: settings})
                SettingsActionCreator.edit settings

    getInitialState: (forceDefault) ->
        settings = @props.settings.toObject()
        return {
            settings: @props.settings.toObject()
        }
