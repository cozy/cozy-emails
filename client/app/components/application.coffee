# React components
{body, div, p, form, i, input, span} = React.DOM
Menu = require './menu'
EmailList = require './email-list'
EmailThread = require './email-thread'
Compose = require './compose'

# Fluxxor requirements
FluxMixin = Fluxxor.FluxMixin React
StoreWatchMixin = Fluxxor.StoreWatchMixin

###
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly

    About routing: it uses Backbone.Router as a source of truth for the layout.
    (based on: https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592)

    Fluxxor reference:
     - FluxMixin: http://fluxxor.com/documentation/flux-mixin.html
     - StoreWatchMixin: http://fluxxor.com/documentation/store-watch-mixin.html
###
module.exports = Application = React.createClass
    displayName: 'Application'

    mixins: [
        FluxMixin
        StoreWatchMixin("MailboxStore", "EmailStore", "LayoutStore")
    ]

    render: ->
        # Shortcut
        layout = @state.layout

        # is the layout a full-width panel or two panels sharing the width
        isFullWidth = @state.isLayoutFullWidth

        leftPanelLayoutMode = if isFullWidth then 'full' else 'left'

        # css classes are a bit long so we use a subfunction to get them
        panelClasses = @getPanelClasses isFullWidth
        # Actual layout
        div className: 'container-fluid',
            div className: 'row',

                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu mailboxes: @state.mailboxes

                div id: 'page-content', className: 'col-xs-12 col-md-11',

                    # The quick actions bar shoud be moved in its own component
                    # when its feature is implemented.
                    div id: 'quick-actions', className: 'row',
                        i className: 'fa fa-bars hidden-md hidden-lg pull-left'
                        form className: 'form-inline col-md-6 hidden-xs hidden-sm pull-left',
                            div className: 'form-group',
                                div className: 'input-group',
                                    input className: 'form-control', type: 'text', placeholder: 'Search...'
                                    div className: 'input-group-addon btn btn-cozy',
                                        span className: 'fa fa-search'

                    # Two layout modes: one full-width panel or two panels
                    div id: 'panels', className: 'row',
                        div className: panelClasses.leftPanel,
                            @getPanelComponent layout.leftPanel, leftPanelLayoutMode
                        if not isFullWidth
                            div className: panelClasses.rightPanel,
                                @getPanelComponent layout.rightPanel, 'right'


    # Panels CSS classes are a bit long so we get them from a this subfunction
    getPanelClasses: (isFullWidth) ->
        if isFullWidth
            classes = leftPanel: 'panel col-xs-12 col-md-12'
        else
            classes =
                leftPanel: 'panel col-xs-12 col-md-6'
                rightPanel: 'panel col-xs-12 col-md-6 hidden-xs hidden-sm'

        return classes


    # Factory of React components for panels
    getPanelComponent: (panelInfo, layout) ->

        # -- Generates a list of emails for a given mailbox
        if panelInfo.action is 'mailbox.emails'
            firstMailbox = @getFlux().store('MailboxStore').getDefault()

            # display emails of the selected mailbox
            if panelInfo.parameter?
                emailStore = @getFlux().store 'EmailStore'
                mailboxID = parseInt panelInfo.parameter
                return EmailList
                    emails: emailStore.getEmailsByMailbox mailboxID
                    layout: layout

            # default: display emails of the first mailbox
            else if not panelInfo.parameter? and firstMailbox?
                emailStore = @getFlux().store 'EmailStore'
                mailboxID = firstMailbox.id
                return EmailList
                    emails: emailStore.getEmailsByMailbox mailboxID
                    layout: layout

            # there is no mailbox and mailbox not found case
            else
                return div null, 'Handle empty mailbox case'

        # -- Generates a configuration window for a given mailbox
        # or the mailbox creation form.
        else if panelInfo.action is 'mailbox.config'
            return div null, 'Mailbox configuration/creation'

        # -- Generates an email thread
        else if panelInfo.action is 'email'
            email = @getFlux().store('EmailStore').getByID panelInfo.parameter
            return EmailThread
                email: email
                layout: layout

        # -- Generates the new email composition form
        else if panelInfo.action is 'compose'
            return Compose {layout}

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else return div null, 'Unknown component'


    # Result will be merged with `getInitialState` result.
    getStateFromFlux: ->
        flux = @getFlux()
        return {
            mailboxes: flux.store('MailboxStore').getAll()
            emails: flux.store('EmailStore').getAll()
            layout: flux.store('LayoutStore').getState()
            isLayoutFullWidth: flux.store('LayoutStore').isFullWidth()
        }


    # Listens to router changes. Renders the component on changes.
    componentWillMount: ->
        # Uses `forceUpdate` with the proper scope because React doesn't allow
        # to rebind its scope on the fly
        @onRoute = (route, params) =>
            #@forceUpdate()

        @props.router.on 'route', @onRoute


    # Stops listening to router changes
    componentWillUnmount: ->
        @props.router.off 'route', @onRoute
