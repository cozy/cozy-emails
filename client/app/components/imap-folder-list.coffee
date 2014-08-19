React = require 'react/addons'
{div, ul, li, span, a, button} = React.DOM

RouterMixin = require '../mixins/router'

module.exports = ImapFolderList = React.createClass
    displayName: 'ImapFolderList'

    mixins: [RouterMixin]

    render: ->

        if @props.imapFolders.length > 0
            firstItem = @props.selectedImapFolder
            div className: 'dropdown pull-left',
                button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown',
                    firstItem.name
                    span className: 'caret', ''
                ul className: 'dropdown-menu', role: 'menu',
                    @props.imapFolders.map (folder, key) =>
                        if folder.id isnt @props.selectedImapFolder.id
                            @getImapFolderRender folder, key
                    .toJS()
        else
            div null, 'Loading...'


    getImapFolderRender: (folder, key) ->
        url = @buildUrl
                direction: 'left'
                action: 'mailbox.imap.emails'
                parameters: [@props.selectedMailbox.get('id'), folder.id]

        li role: 'presentation', key: key,
            a href: url, role: 'menuitem', folder.name
