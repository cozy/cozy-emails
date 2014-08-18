React = require 'react/addons'
{div, ul, li, span, a, button} = React.DOM

RouterMixin = require '../mixins/router'

module.exports = ImapFolderList = React.createClass
    displayName: 'ImapFolderList'

    mixins: [RouterMixin]

    render: ->

        folders = ['Favorite', 'Spam', 'Trash', 'Draft']

        div className: 'dropdown pull-left',
            button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown',
                'Boite de réception'
                span className: 'caret', ''
            ul className: 'dropdown-menu', role: 'menu',
                for folder, key in folders
                    @getImapFolderRender folder, key


    getImapFolderRender: (folder, key) ->
        url = @buildUrl
                direction: 'left'
                action: 'mailbox.imap.emails'
                parameters: [@props.selectedMailbox.id, folder.toLowerCase()]

        li role: 'presentation', key: key,
            a href: url, role: 'menuitem',
                #span className: 'fa fa-folder'
                folder
