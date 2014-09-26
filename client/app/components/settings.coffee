{div, h3, form, label, input, button} = React.DOM
classer = React.addons.classSet

SettingsActionCreator = require '../actions/settings_action_creator'
SettingsStore = require '../stores/settings_store'

module.exports = React.createClass
    displayName: 'Settings'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    render: ->

        div id: 'mailbox-config',
            h3 className: null, t "settings title"

            if @props.error
                div className: 'error', @props.error

            form className: 'form-horizontal',
                div className: 'form-group',
                    label htmlFor: 'settings-mpp', className: 'col-sm-2 col-sm-offset-2 control-label', t "settings label mpp"
                    div className: 'col-sm-3',
                        input id: 'settings-mpp', valueLink: @linkState('messagesPerPage'), type: 'number', min: 5, max: 100, step: 5, className: 'form-control'

            form className: 'form-horizontal',
                div className: 'form-group',
                    label htmlFor: 'settings-compose', className: 'col-sm-2 col-sm-offset-2 control-label', t "settings label compose"
                    div className: 'col-sm-3',
                        input id: 'settings-compose', checkedLink: @linkState('composeInHTML'), type: 'checkbox', className: 'form-control'

            form className: 'form-horizontal',
                div className: 'form-group',
                    label htmlFor: 'settings-compose', className: 'col-sm-2 col-sm-offset-2 control-label', t "settings label html"
                    div className: 'col-sm-3',
                        input id: 'settings-compose', checkedLink: @linkState('messageDisplayHTML'), type: 'checkbox', className: 'form-control'

            form className: 'form-horizontal',
                div className: 'form-group',
                    label htmlFor: 'settings-compose', className: 'col-sm-2 col-sm-offset-2 control-label', t "settings label images"
                    div className: 'col-sm-3',
                        input id: 'settings-compose', checkedLink: @linkState('messageDisplayImages'), type: 'checkbox', className: 'form-control'

                div className: 'form-group',
                    div className: 'col-sm-offset-2 col-sm-5 text-right',
                        button className: 'btn btn-cozy', onClick: @onSubmit, t "settings button save"

    onSubmit: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        settingsValue = @state
        SettingsActionCreator.edit @state

    getInitialState: (forceDefault) ->
        settings = @props.settings

        return settings.toObject()
