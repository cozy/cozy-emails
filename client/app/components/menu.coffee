{div, ul, li, a, span, i} = React.DOM

classer = React.addons.classSet

RouterMixin = require '../mixins/RouterMixin'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not Immutable.is(nextProps.mailboxes, @props.mailboxes) or
               not Immutable.is(nextProps.selectedMailbox, @props.selectedMailbox) or
               not _.isEqual(nextProps.layout, @props.layout) or
               nextProps.isResponsiveMenuShown isnt @props.isResponsiveMenuShown or
               not Immutable.is(nextProps.favoriteImapFolders, @props.favoriteImapFolders)

    render: ->
        selectedMailboxUrl = @buildUrl
            direction: 'left'
            action: 'mailbox.emails'
            parameters: @props.selectedMailbox?.get('id')
            fullWidth: true

        # the button toggles the "compose" screen
        if @props.layout.leftPanel.action is 'compose' or
           @props.layout.rightPanel?.action is 'compose'
            composeUrl = selectedMailboxUrl
        else
            composeUrl = @buildUrl
                direction: 'right'
                action: 'compose'
                parameters: null
                fullWidth: false

        # the button toggle the "new mailbox" screen
        if @props.layout.leftPanel.action is 'mailbox.new'
            newMailboxUrl = selectedMailboxUrl
        else
            newMailboxUrl = @buildUrl
                direction: 'left'
                action: 'mailbox.new'
                fullWidth: true

        classes = classer
            'hidden-xs hidden-sm': not @props.isResponsiveMenuShown
            'col-xs-4 col-md-1': true

        div id: 'menu', className: classes,
            a href: composeUrl, className: 'menu-item compose-action',
                i className: 'fa fa-edit'
                span className: 'mailbox-label', t 'menu compose'

            ul id: 'mailbox-list', className: 'list-unstyled',
                @props.mailboxes.map (mailbox, key) =>
                    @getMailboxRender mailbox, key
                .toJS()

            a href: newMailboxUrl, className: 'menu-item new-mailbox-action',
                i className: 'fa fa-inbox'
                span className: 'mailbox-label', t 'menu account new'


    # renders a single mailbox and its submenu
    getMailboxRender: (mailbox, key) ->

        isSelected = (not @props.selectedMailbox? and key is 0) \
                     or @props.selectedMailbox?.get('id') is mailbox.get('id')

        mailboxClasses = classer active: isSelected
        url = @buildUrl
            direction: 'left'
            action: 'mailbox.emails'
            parameters: mailbox.get 'id'
            fullWidth: false

        li className: mailboxClasses, key: key,
            a href: url, className: 'menu-item ' + mailboxClasses,
                i className: 'fa fa-inbox'
                span className: 'badge', mailbox.get 'unreadCount'
                span className: 'mailbox-label', mailbox.get 'label'

            ul className: 'list-unstyled submenu',
                @props.favoriteImapFolders.map (imapFolder, key) =>
                    @getImapFolderRender imapFolder, key
                .toJS()

    getImapFolderRender: (imapFolder, key) ->
        imapFolderUrl = @buildUrl
            direction: 'left'
            action: 'mailbox.imap.emails'
            parameters: [imapFolder.get('mailbox'), imapFolder.get('id')]

        a href: imapFolderUrl, className: 'menu-item', key: key,
            # Something must be rethought about the icon
            i className: 'fa fa-star'
            span className: 'badge', Math.floor((Math.random() * 10) + 1) # placeholder
            span className: 'mailbox-label', imapFolder.get 'name'
