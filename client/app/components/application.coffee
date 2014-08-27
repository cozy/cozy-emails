# React components
{body, div, p, form, i, input, span, a} = React.DOM
Menu = require './menu'
EmailList = require './email-list'
EmailThread = require './email-thread'
Compose = require './compose'
MailboxConfig = require './mailbox-config'
ImapFolderList = require './imap-folder-list'

# React addons
ReactCSSTransitionGroup = React.addons.CSSTransitionGroup
classer = React.addons.classSet

# React Mixins
RouterMixin = require '../mixins/RouterMixin'
StoreWatchMixin = require '../mixins/StoreWatchMixin'

# Flux stores
MailboxStore = require '../stores/MailboxStore'
EmailStore = require '../stores/EmailStore'
LayoutStore = require '../stores/LayoutStore'
ImapFolderStore = require '../stores/ImapFolderStore'

# Flux actions
LayoutActionCreator = require '../actions/LayoutActionCreator'


###
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly

    About routing: it uses Backbone.Router as a source of truth for the layout.
    (based on: https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592)
###
module.exports = Application = React.createClass
    displayName: 'Application'

    mixins: [
        StoreWatchMixin [MailboxStore, EmailStore, LayoutStore, ImapFolderStore]
        RouterMixin
    ]

    render: ->
        # Shortcut
        layout = @props.router.current

        if not layout?
            return div null, t "app loading"

        # is the layout a full-width panel or two panels sharing the width
        isFullWidth = not layout.rightPanel?

        leftPanelLayoutMode = if isFullWidth then 'full' else 'left'

        # css classes are a bit long so we use a subfunction to get them
        panelClasses = @getPanelClasses isFullWidth

        showMailboxConfigButton = @state.selectedMailbox? and
                                  layout.leftPanel.action isnt 'mailbox.new'
        if showMailboxConfigButton
            # the button toggles the mailbox config
            if layout.leftPanel.action is 'mailbox.config'
                configMailboxUrl = @buildUrl
                    direction: 'left'
                    action: 'mailbox.emails'
                    parameters: @state.selectedMailbox.get 'id'
                    fullWidth: true
            else
                configMailboxUrl = @buildUrl
                    direction: 'left'
                    action: 'mailbox.config'
                    parameters: @state.selectedMailbox.get 'id'
                    fullWidth: true

        responsiveBackUrl = @buildUrl
            leftPanel: layout.leftPanel
            fullWidth: true

        # classes for page-content
        responsiveClasses = classer
            'col-xs-12 col-md-11': true
            'pushed': @state.isResponsiveMenuShown

        # Actual layout
        div className: 'container-fluid',
            div className: 'row',

                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu
                    mailboxes: @state.mailboxes
                    selectedMailbox: @state.selectedMailbox
                    isResponsiveMenuShown: @state.isResponsiveMenuShown
                    layout: @props.router.current
                    favoriteImapFolders: @state.favoriteImapFolders

                div id: 'page-content', className: responsiveClasses,

                    # The quick actions bar shoud be moved in its own component
                    # when its feature is implemented.
                    div id: 'quick-actions', className: 'row',
                        # responsive menu icon
                        if layout.rightPanel
                            a href: responsiveBackUrl, className: 'responsive-handler hidden-md hidden-lg',
                                i className: 'fa fa-chevron-left hidden-md hidden-lg pull-left'
                                t "app back"
                        else
                            a onClick: @onResponsiveMenuClick, className: 'responsive-handler hidden-md hidden-lg',
                                i className: 'fa fa-bars pull-left'
                                t "app menu"


                        div className: 'col-md-6 hidden-xs hidden-sm pull-left',
                            form className: 'form-inline col-md-12',
                                ImapFolderList
                                    selectedMailbox: @state.selectedMailbox
                                    imapFolders: @state.imapFolders
                                    selectedImapFolder: @state.selectedImapFolder
                                div className: 'form-group pull-left',
                                    div className: 'input-group',
                                        input className: 'form-control', type: 'text', placeholder: t "app search", onFocus: @onFocusSearchInput, onBlur: @onBlurSearchInput
                                        div className: 'input-group-addon btn btn-cozy',
                                            span className: 'fa fa-search'

                        div id: 'contextual-actions', className: 'col-md-6 hidden-xs hidden-sm pull-left text-right',
                            ReactCSSTransitionGroup transitionName: 'fade',
                                if showMailboxConfigButton
                                    a href: configMailboxUrl, className: 'btn btn-cozy mailbox-config',
                                        i className: 'fa fa-cog'

                    # Two layout modes: one full-width panel or two panels
                    div id: 'panels', className: 'row',
                        div className: panelClasses.leftPanel, key: 'left-panel-' + layout.leftPanel.action + '-' + layout.leftPanel.parameters.join('-'),
                            @getPanelComponent layout.leftPanel, leftPanelLayoutMode
                        if not isFullWidth and layout.rightPanel?
                            div className: panelClasses.rightPanel, key: 'right-panel-' + layout.rightPanel.action + '-' + layout.rightPanel.parameters.join('-'),
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
                   _.difference(previous.rightPanel.parameters, layout.leftPanel.parameters).length is 0
                    classes.leftPanel += ' expandFromRight'

            # (default) when full-width panel is shown after a full-width panel
            else if previous?
                classes.leftPanel += ' moveFromLeft'


        # ... or a two panels layout.
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
                       _.difference(previous.leftPanel.parameters, right.parameters).length is 0
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

        # -- Generates a list of emails for a given mailbox
        if panelInfo.action is 'mailbox.emails'

            firstMailbox = MailboxStore.getDefault()

            # gets the selected email if any
            openEmail = null
            direction = if layout is 'left' then 'rightPanel' else 'leftPanel'
            otherPanelInfo = @props.router.current[direction]
            if otherPanelInfo?.action is 'email'
                openEmail = EmailStore.getByID otherPanelInfo.parameters[0]

            # display emails of the selected mailbox
            if panelInfo.parameters? and panelInfo.parameters.length > 0
                emailStore = EmailStore
                mailboxID = panelInfo.parameters[0]
                return EmailList
                    emails: emailStore.getEmailsByMailbox mailboxID
                    mailboxID: mailboxID
                    layout: layout
                    openEmail: openEmail

            # default: display emails of the first mailbox
            else if (not panelInfo.parameters? or panelInfo.parameters.length is 0) and firstMailbox?
                emailStore = EmailStore
                mailboxID = firstMailbox.id
                return EmailList
                    emails: emailStore.getEmailsByMailbox mailboxID
                    mailboxID: mailboxID
                    layout: layout
                    openEmail: openEmail

            # there is no mailbox or mailbox is not found
            else
                return div null, 'Handle no mailbox or mailbox not found case'

        # -- Generates a list of emails for a given mailbox and imap folder
        else if panelInfo.action is 'mailbox.imap.emails'
            mailboxID = panelInfo.parameters[0]
            imapFolderID = panelInfo.parameters[1]

            emailStore = EmailStore

            # gets the selected email if any
            openEmail = null
            direction = if layout is 'left' then 'rightPanel' else 'leftPanel'
            otherPanelInfo = @props.router.current[direction]
            if otherPanelInfo?.action is 'email'
                openEmail = EmailStore.getByID otherPanelInfo.parameters[0]

            return EmailList
                emails: emailStore.getEmailsByImapFolder imapFolderID
                mailboxID: mailboxID
                layout: layout
                openEmail: openEmail


        # -- Generates a configuration window for a given mailbox
        # or the mailbox creation form.
        else if panelInfo.action is 'mailbox.config'
            initialMailboxConfig = @state.selectedMailbox
            error = MailboxStore.getError()
            isWaiting = MailboxStore.isWaiting()
            return MailboxConfig {layout, error, isWaiting, initialMailboxConfig}

        # -- Generates a configuration window to create a new mailbox
        else if panelInfo.action is 'mailbox.new'
            error = MailboxStore.getError()
            isWaiting = MailboxStore.isWaiting()
            return MailboxConfig {layout, error, isWaiting}

        # -- Generates an email thread
        else if panelInfo.action is 'email'
            email = EmailStore.getByID panelInfo.parameters[0]
            thread = EmailStore.getEmailsByThread panelInfo.parameters[0]
            selectedMailbox = @state.selectedMailbox
            return EmailThread {email, thread, selectedMailbox, layout}

        # -- Generates the new email composition form
        else if panelInfo.action is 'compose'
            selectedMailbox = @state.selectedMailbox
            return Compose {selectedMailbox, layout}

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else return div null, 'Unknown component'

    getStateFromStores: ->

        selectedMailbox = MailboxStore.getSelected()
        selectedMailboxID = selectedMailbox?.get('id') or null

        leftPanelInfo = @props.router.current?.leftPanel
        if leftPanelInfo?.action is 'mailbox.imap.emails'
            selectedImapFolderID = leftPanelInfo.parameters[1]
        else
            selectedImapFolderID = null

        selectedImapFolder = ImapFolderStore.getSelected selectedMailboxID, selectedImapFolderID

        return {
            mailboxes: MailboxStore.getAll()
            selectedMailbox: selectedMailbox
            emails: EmailStore.getAll()
            isResponsiveMenuShown: LayoutStore.isMenuShown()
            imapFolders: ImapFolderStore.getByMailbox selectedMailboxID
            selectedImapFolder: selectedImapFolder
            favoriteImapFolders: ImapFolderStore.getFavorites selectedMailboxID
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

    # Toggle the menu in responsive mode
    onResponsiveMenuClick: (event) ->
        event.preventDefault()
        if @state.isResponsiveMenuShown
            LayoutActionCreator.hideReponsiveMenu()
        else
            LayoutActionCreator.showReponsiveMenu()
