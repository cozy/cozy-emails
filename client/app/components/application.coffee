# React components
{body, div, p, form, i, input, span, a} = React.DOM
Menu = require './menu'
EmailList = require './email-list'
EmailThread = require './email-thread'
Compose = require './compose'
MailboxConfig = require './mailbox-config'

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup

# React mixins
FluxMixin = Fluxxor.FluxMixin React
StoreWatchMixin = Fluxxor.StoreWatchMixin

# Custom mixins
RouterMixin = require '../mixins/router'

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
        RouterMixin
    ]

    render: ->
        # Shortcut
        #layout = @state.layout
        layout = @props.router.current

        if not layout?
            return div null, "Loading..."

        # is the layout a full-width panel or two panels sharing the width
        isFullWidth = not layout.rightPanel?

        leftPanelLayoutMode = if isFullWidth then 'full' else 'left'

        # css classes are a bit long so we use a subfunction to get them
        panelClasses = @getPanelClasses isFullWidth

        showMailboxConfigButton = @state.selectedMailbox? and
                                  layout.leftPanel.action isnt 'mailbox.new'
        if showMailboxConfigButton
            configMailboxUrl = @buildUrl
                direction: 'left'
                action: 'mailbox.config'
                parameter: @state.selectedMailbox.id
                fullWidth: true

        responsiveBackUrl = @buildUrl
            leftPanel: layout.leftPanel
            fullWidth: true

        # Actual layout
        div className: 'container-fluid',
            div className: 'row',

                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu
                    mailboxes: @state.mailboxes
                    selectedMailbox: @state.selectedMailbox

                div id: 'page-content', className: 'col-xs-12 col-md-11',

                    # The quick actions bar shoud be moved in its own component
                    # when its feature is implemented.
                    div id: 'quick-actions', className: 'row',
                        # responsive menu icon
                        if layout.rightPanel
                            a href: responsiveBackUrl, className: 'responsive-handler hidden-md hidden-lg',
                                i className: 'fa fa-chevron-left hidden-md hidden-lg pull-left'
                                'Back'
                        else
                            a onClick: @onResponsiveMenuClick, className: 'responsive-handler hidden-md hidden-lg',
                                i className: 'fa fa-bars pull-left'
                                'Menu'



                        form className: 'form-inline col-md-6 hidden-xs hidden-sm pull-left',
                            div className: 'form-group',
                                div className: 'input-group',
                                    input className: 'form-control', type: 'text', placeholder: 'Search...'
                                    div className: 'input-group-addon btn btn-cozy',
                                        span className: 'fa fa-search'

                        div id: 'contextual-actions', className: 'col-md-6 hidden-xs hidden-sm pull-left text-right',
                            ReactCSSTransitionGroup transitionName: 'fade',
                                if showMailboxConfigButton
                                    a href: configMailboxUrl, className: 'btn btn-cozy mailbox-config',
                                        i className: 'fa fa-cog'

                    # Two layout modes: one full-width panel or two panels
                    div id: 'panels', className: 'row',
                        div className: panelClasses.leftPanel, key: 'left-panel-' + layout.leftPanel.action + '-' + layout.leftPanel.parameter,
                            @getPanelComponent layout.leftPanel, leftPanelLayoutMode
                        if not isFullWidth and layout.rightPanel?
                            div className: panelClasses.rightPanel, key: 'right-panel-' + layout.rightPanel.action + '-' + layout.rightPanel.parameter,
                                @getPanelComponent layout.rightPanel, 'right'


    # Panels CSS classes are a bit long so we get them from a this subfunction
    # Also, it manages transitions between screens by adding relevant classes
    getPanelClasses: (isFullWidth) ->
        previous = @props.router.previous
        layout = @props.router.current
        left = layout.leftPanel
        right = layout.rightPanel

        # Two cases: the layout has a full-width panel...
        if isFullWidth
            classes = leftPanel: 'panel col-xs-12 col-md-12'

            # custom case for mailbox.config action (top right cog button)
            if previous? and left.action is 'mailbox.config'
                classes.leftPanel += ' moveFromTopRightCorner'

            # (default) when full-width panel is shown after a two-panels structure
            else if previous? and previous.rightPanel

                # if the full-width panel was on right right before, it expands
                if previous.rightPanel.action is layout.leftPanel.action and
                   previous.rightPanel.parameter is layout.leftPanel.parameter
                    classes.leftPanel += ' expandFromRight'

            # (default) when full-width panel is shown after a full-width panel
            else if previous?
                classes.leftPanel += ' moveFromLeft'


        # ... or a two panels.
        else
            classes =
                leftPanel: 'panel col-xs-12 col-md-6 hidden-xs hidden-sm'
                rightPanel: 'panel col-xs-12 col-md-6'

            # we don't animate in the first render
            if previous?
                wasFullWidth = not previous.rightPanel?

                # transition from full-width to two-panels layout
                if wasFullWidth and not isFullWidth

                    # expanded right panel collapses
                    if previous.leftPanel.action is right.action and
                       previous.leftPanel.parameter is right.parameter
                        classes.leftPanel += ' moveFromLeft'
                        classes.rightPanel += ' slide-in-from-left'

                    # (default) opens right panel sliding from the right
                    else
                        classes.rightPanel += ' slide-in-from-right'

                # (default) opens right panel sliding from the left
                else if not isFullWidth
                    classes.rightPanel += ' slide-in-from-left'

        return classes


    # Factory of React components for panels
    getPanelComponent: (panelInfo, layout) ->

        flux = @getFlux()

        # -- Generates a list of emails for a given mailbox
        if panelInfo.action is 'mailbox.emails'
            firstMailbox = flux.store('MailboxStore').getDefault()

            # gets the selected email if any
            openEmail = null
            direction = if layout is 'left' then 'rightPanel' else 'leftPanel'
            otherPanelInfo = @props.router.current[direction]
            if otherPanelInfo?.action is 'email'
                openEmail = flux.store('EmailStore').getByID otherPanelInfo.parameter

            # display emails of the selected mailbox
            if panelInfo.parameter?
                emailStore = flux.store 'EmailStore'
                mailboxID = panelInfo.parameter
                return EmailList
                    emails: emailStore.getEmailsByMailbox mailboxID
                    mailboxID: mailboxID
                    layout: layout
                    openEmail: openEmail

            # default: display emails of the first mailbox
            else if not panelInfo.parameter? and firstMailbox?
                emailStore = flux.store 'EmailStore'
                mailboxID = firstMailbox.id
                return EmailList
                    emails: emailStore.getEmailsByMailbox mailboxID
                    mailboxID: mailboxID
                    layout: layout
                    openEmail: openEmail

            # there is no mailbox or mailbox is not found
            else
                return div null, 'Handle no mailbox or mailbox not found case'

        # -- Generates a configuration window for a given mailbox
        # or the mailbox creation form.
        else if panelInfo.action is 'mailbox.config'
            initialMailboxConfig = @state.selectedMailbox
            error = flux.store('MailboxStore').getError()
            isWaiting = flux.store('MailboxStore').isWaiting()
            return MailboxConfig {layout, error, isWaiting, initialMailboxConfig}

        # -- Generates a configuration window to create a new mailbox
        else if panelInfo.action is 'mailbox.new'
            error = flux.store('MailboxStore').getError()
            isWaiting = flux.store('MailboxStore').isWaiting()
            return MailboxConfig {layout, error, isWaiting}

        # -- Generates an email thread
        else if panelInfo.action is 'email'
            email = flux.store('EmailStore').getByID panelInfo.parameter
            thread = flux.store('EmailStore').getEmailsByThread panelInfo.parameter
            selectedMailbox = flux.store('MailboxStore').getSelectedMailbox()
            return EmailThread {email, thread, selectedMailbox, layout}

        # -- Generates the new email composition form
        else if panelInfo.action is 'compose'
            selectedMailbox = flux.store('MailboxStore').getSelectedMailbox()
            return Compose {selectedMailbox, layout}

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else return div null, 'Unknown component'


    # Result will be merged with `getInitialState` result.
    getStateFromFlux: ->
        flux = @getFlux()
        return {
            mailboxes: flux.store('MailboxStore').getAll()
            selectedMailbox: flux.store('MailboxStore').getSelectedMailbox()
            emails: flux.store('EmailStore').getAll()
            #layout: flux.store('LayoutStore').getState()
            isLayoutFullWidth: flux.store('LayoutStore').isFullWidth()
        }


    # Listens to router changes. Renders the component on changes.
    componentWillMount: ->
        # Uses `forceUpdate` with the proper scope because React doesn't allow
        # to rebind its scope on the fly
        @onRoute = (params) =>
            {leftPanelInfo, rightPanelInfo} = params
            @forceUpdate()

        @props.router.on 'fluxRoute', @onRoute


    # Stops listening to router changes
    componentWillUnmount: ->
        @props.router.off 'fluxRoute', @onRoute

    # dirty, dirty, very dirty hack to handle the menu in smaller devices
    # only thing that depends on jQuery
    # we could use the layout store to handle the menu state...
    onResponsiveMenuClick: ->
        $('#menu').removeClass 'hidden-xs hidden-sm'
        $('body').click ->
            $('#menu').addClass 'hidden-xs hidden-sm'
