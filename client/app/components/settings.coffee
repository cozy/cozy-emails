{div, h3, form, label, input, button} = React.DOM
classer = React.addons.classSet

SettingsActionCreator = require '../actions/SettingsActionCreator'
SettingsStore = require '../stores/SettingsStore'

module.exports = React.createClass
    displayName: 'AccountConfig'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    render: ->
        titleLabel = if @props.initialAccountConfig? then t "mailbox edit" else t "mailbox new"

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

                div className: 'form-group',
                    div className: 'col-sm-offset-2 col-sm-5 text-right',
                        button className: 'btn btn-cozy', onClick: @onSubmit, t "settings button save"
    onSubmit: (event) ->
        # prevents the page from reloading
        event.preventDefault()

        settingsValue = @state
        SettingsActionCreator.edit @state

    getInitialState: (forceDefault) ->
        settings = SettingsStore.get().toObject()

        return settings
