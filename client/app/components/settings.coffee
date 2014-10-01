{div, h3, form, label, input, button, fieldset, legend} = React.DOM
classer = React.addons.classSet

SettingsActionCreator = require '../actions/settings_action_creator'
SettingsStore = require '../stores/settings_store'
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

            form className: 'form-horizontal',
                div className: 'form-group',
                    label
                        htmlFor: 'settings-compose',
                        className: classLabel,
                        t "settings label compose"
                    div className: 'col-sm-3',
                        input
                            id: 'settings-compose',
                            checked: @state.settings.composeInHTML,
                            onChange: @handleChange,
                            'data-target': 'composeInHTML',
                            type: 'checkbox',
                            className: 'form-control'

            form className: 'form-horizontal',
                div className: 'form-group',
                    label
                        htmlFor: 'settings-compose',
                        className: classLabel,
                        t "settings label html"
                    div className: 'col-sm-3',
                        input
                            id: 'settings-compose',
                            checkedLink: @linkState('messageDisplayHTML'),
                            type: 'checkbox',
                            className: 'form-control'

            form className: 'form-horizontal',
                div className: 'form-group',
                    label
                        htmlFor: 'settings-compose',
                        className: classLabel,
                        t "settings label images"
                    div className: 'col-sm-3',
                        input
                            id: 'settings-compose',
                            checkedLink: @linkState('messageDisplayImages'),
                            type: 'checkbox',
                            className: 'form-control'

                div className: 'form-group',
                    div className: 'col-sm-offset-2 col-sm-5 text-right',
                        button
                            className: 'btn btn-cozy',
                            onClick: @onSubmit,
                            t "settings button save"

            fieldset null,
                legend null, t 'settings plugins'
                for own pluginName, pluginConf of @state.plugins
                    form className: 'form-horizontal', key: pluginName,
                        div className: 'form-group',
                            label className: classLabel, pluginConf.name
                            div className: 'col-sm-3',
                                input
                                    checked: @state.plugins[pluginName].active,
                                    onChange: @handleChange,
                                    'data-target': 'plugin',
                                    'data-plugin': pluginName,
                                    type: 'checkbox',
                                    className: 'form-control'

    handleChange: (event) ->
        target = event.target
        switch target.dataset.target
            when 'messagesPerPage'
                settings = @state.settings
                settings.messagesPerPage = target.value
                @setState({settings: settings})
                SettingsActionCreator.edit settings
            when 'composeInHTML'
                settings = @state.settings
                settings.composeInHTML = target.checked
                @setState({settings: settings})
                SettingsActionCreator.edit settings
            when 'plugin'
                if target.checked
                    PluginUtils.activate target.dataset.plugin
                else
                    PluginUtils.deactivate target.dataset.plugin
                @setState({plugins: window.plugins})

    onSubmit: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        settingsValue = @state.settings
        SettingsActionCreator.edit @state.settings

    getInitialState: (forceDefault) ->
        return {
            settings: @props.settings.toObject()
            plugins: @props.plugins
        }
