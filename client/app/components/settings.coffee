{div, h3, form, label, input, button, fieldset, legend, ul, li, a, span, i} = React.DOM
classer = React.addons.classSet

LayoutActionCreator   = require '../actions/layout_action_creator'
SettingsActionCreator = require '../actions/settings_action_creator'
PluginUtils    = require '../utils/plugin_utils'
ApiUtils       = require '../utils/api_utils'
{Dispositions} = require '../constants/app_constants'

module.exports = React.createClass
    displayName: 'Settings'

    render: ->

        classLabel = 'col-sm-5 col-sm-offset-1 control-label'
        classInput = 'col-sm-6'

        div id: 'settings',
            h3 className: null, t "settings title"

            if @props.error
                div className: 'error', @props.error

            form className: 'form-horizontal',
                #div className: 'form-group',
                #    label htmlFor: 'settings-mpp', className: classLabel,
                #        t "settings label mpp"
                #    div className: classInput,
                #        input
                #            id: 'settings-mpp',
                #            value: @state.settings.messagesPerPage,
                #            onChange: @handleChange,
                #            'data-target': 'messagesPerPage',
                #            type: 'number',
                #            min: 5,
                #            max: 100,
                #            step: 5,
                #            className: 'form-control'

                # Lang
                #div className: 'form-group',
                #    label htmlFor: 'settings-mpp', className: classLabel,
                #        t "settings lang"
                #    div className: classInput,
                #        div className: "dropdown",
                #            button
                #                className: "btn btn-default dropdown-toggle"
                #                type: "button"
                #                "data-toggle": "dropdown",
                #                t "settings lang #{@state.settings.lang}"
                #            ul className: "dropdown-menu", role: "menu",
                #                li
                #                    role: "presentation",
                #                    'data-target': 'lang',
                #                    'data-lang': 'en',
                #                    onClick: @handleChange,
                #                        a role: "menuitem", t "settings lang en"
                #                li
                #                    role: "presentation",
                #                    'data-target': 'lang',
                #                    'data-lang': 'fr',
                #                    onClick: @handleChange,
                #                        a role: "menuitem", t "settings lang fr"

                # Layout style
                div className: 'form-group',
                    label htmlFor: 'settings-layoutStyle', className: classLabel,
                        t "settings label layoutStyle"
                    div className: classInput,
                        div className: "dropdown",
                            button
                                id: 'settings-layoutStyle'
                                className: "btn btn-default dropdown-toggle"
                                type: "button"
                                "data-toggle": "dropdown",
                                t "settings label layoutStyle #{@state.settings.layoutStyle or 'vertical'}"
                            ul className: "dropdown-menu", role: "menu",
                                li
                                    role: "presentation",
                                    'data-target': 'layoutStyle',
                                    'data-style': Dispositions.VERTICAL,
                                    onClick: @handleChange,
                                        a role: "menuitem", t "settings label layoutStyle vertical"
                                li
                                    role: "presentation",
                                    'data-target': 'layoutStyle',
                                    'data-style': Dispositions.HORIZONTAL,
                                    onClick: @handleChange,
                                        a role: "menuitem", t "settings label layoutStyle horizontal"
                                li
                                    role: "presentation",
                                    'data-target': 'layoutStyle',
                                    'data-style': Dispositions.THREE,
                                    onClick: @handleChange,
                                        a role: "menuitem", t "settings label layoutStyle three"

                # List style
                div className: 'form-group',
                    label htmlFor: 'settings-listStyle', className: classLabel,
                        t "settings label listStyle"
                    div className: classInput,
                        div className: "dropdown",
                            button
                                id: 'settings-listStyle'
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

            # SETTINGS
            @_renderOption 'displayConversation'
            @_renderOption 'composeInHTML'
            @_renderOption 'composeOnTop'
            @_renderOption 'messageDisplayHTML'
            @_renderOption 'messageDisplayImages'
            @_renderOption 'messageConfirmDelete'
            @_renderOption 'displayPreview'
            @_renderOption 'desktopNotifications'

            fieldset null,
                legend null, t 'settings plugins'
                for own pluginName, pluginConf of @state.settings.plugins
                    form className: 'form-horizontal', key: pluginName,
                        div className: 'form-group',
                            label
                                className: classLabel,
                                htmlFor: 'settings-plugin-' + pluginName,
                                t('plugin name ' + pluginConf.name, {_: pluginConf.name})
                            div className: 'col-sm-1',
                                if pluginConf.url?
                                    span
                                        className: 'clickable'
                                        onClick: @pluginDel
                                        'data-plugin': pluginName,
                                        title: t("settings plugin del"),
                                            i className: 'fa fa-trash-o'
                                else
                                    input
                                        id: 'settings-plugin-' + pluginName,
                                        checked: pluginConf.active,
                                        onChange: @handleChange,
                                        'data-target': 'plugin',
                                        'data-plugin': pluginName,
                                        type: 'checkbox'
                            if window.plugins[pluginName].onHelp
                                div className: 'col-sm-1 plugin-help',
                                    span
                                        className: 'clickable'
                                        onClick: @pluginHelp
                                        'data-plugin': pluginName,
                                        title: t("settings plugin help"),
                                            i className: 'fa fa-question-circle'
                form className: 'form-horizontal', key: pluginName,
                    div className: 'form-group',
                        div className: 'col-xs-4',
                            input
                                id: 'newpluginName',
                                name: 'newpluginName',
                                ref: 'newpluginName',
                                type: 'text',
                                className: 'form-control',
                                placeholder: t "settings plugin new name"
                        div className: 'col-xs-6',
                            input
                                id: 'newpluginUrl',
                                name: 'newpluginUrl',
                                ref: 'newpluginUrl',
                                type: 'text',
                                className: 'form-control',
                                placeholder: t "settings plugin new url"
                        span
                            className: "col-xs-1 clickable"
                            onClick: @pluginAdd
                            title: t("settings plugin add"),
                                i className: 'fa fa-plus'

    _renderOption: (option) ->
        classLabel = 'col-sm-5 col-sm-offset-1 control-label'
        classInput = 'col-sm-6'
        form className: 'form-horizontal',
            div className: 'form-group',
                label
                    htmlFor: 'settings-' + option,
                    className: classLabel,
                    t "settings label " + option
                div className: classInput,
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
            #when 'messagesPerPage'
            #    settings = @state.settings
            #    settings.messagesPerPage = target.value
            #    @setState({settings: settings})
            #    SettingsActionCreator.edit settings
            # SETTINGS
            when 'composeInHTML'
            ,    'composeOnTop'
            ,    'desktopNotifications'
            ,    'displayConversation'
            ,    'displayPreview'
            ,    'messageConfirmDelete'
            ,    'messageDisplayHTML'
            ,    'messageDisplayImages'
                settings = @state.settings
                settings[target.dataset.target] = target.checked
                @setState({settings: settings})
                SettingsActionCreator.edit settings
                if window.Notification? and settings.desktopNotifications
                    Notification.requestPermission (status) ->
                        # This allows to use Notification.permission with Chrome/Safari
                        if Notification.permission isnt status
                            Notification.permission = status
            #when 'lang'
            #    lang = target.dataset.lang
            #    settings = @state.settings
            #    settings.lang = lang
            #    @setState({settings: settings})
            #    ApiUtils.setLocale lang, true
            #    SettingsActionCreator.edit settings
            when 'layoutStyle'
                settings = @state.settings
                settings.layoutStyle = target.dataset.style
                LayoutActionCreator.setDisposition settings.layoutStyle
                @setState({settings: settings})
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

    pluginAdd: ->
        name = @refs.newpluginName.getDOMNode().value.trim()
        url  = @refs.newpluginUrl.getDOMNode().value.trim()
        PluginUtils.loadJS url, =>
            PluginUtils.activate name
            settings = @state.settings
            settings.plugins[name] =
                name: name
                active: true
                url: url
            @setState({settings: settings})
            SettingsActionCreator.edit settings

    pluginDel: (event) ->
        event.preventDefault()
        target = event.currentTarget
        pluginName = target.dataset.plugin
        settings = @state.settings
        PluginUtils.deactivate pluginName
        delete settings.plugins[pluginName]
        @setState({settings: settings})
        SettingsActionCreator.edit settings

    pluginHelp: (event) ->
        event.preventDefault()
        target = event.currentTarget
        pluginName = target.dataset.plugin
        window.plugins[pluginName].onHelp()

    getInitialState: (forceDefault) ->
        settings = @props.settings.toObject()
        return {
            settings: @props.settings.toObject()
        }
