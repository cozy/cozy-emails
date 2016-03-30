React = require 'react'
_     = require 'underscore'

# Components
{Spinner}      = require('./basic_components').factories
Compose        = React.createFactory require './compose'
Settings       = React.createFactory require './settings'
SearchResult   = React.createFactory require './search_result'

RouterGetter = require '../getters/router'

{ComposeActions} = require '../constants/app_constants'

Panel = React.createClass
    displayName: 'Panel'
    render: ->

        if @props.action is 'search'
            key = encodeURIComponent @props.searchValue
            SearchResult
                key: "search-#{key}"

        # -- Display the settings form
        else if @props.action is 'settings'

            Settings
                key     : 'settings'
                ref     : 'settings'
                settings: @props.settings

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else
            console.error "Unknown action #{@props.action}"
            window.cozyMails.logInfo "Unknown action #{@props.action}"
            return React.DOM.div null, "Unknown component #{@props.action}"

    # Rendering the compose component requires several parameters. The main one
    # are related to the selected account, the selected mailbox and the compose
    # state (classic, draft, reply, reply all or forward).
    renderCompose: ->
        options =
            layout               : 'full'
            action               : null
            inReplyTo            : null
            settings             : @props.settings
            accounts             : @props.accounts
            selectedMailboxID    : @props.mailboxID
            useIntents           : @props.useIntents
            ref                  : 'message'
            key                  : @props.action or 'message'

        component = null

        # Generates an empty compose form
        if @props.action is 'message.new'
            message = null
            component = Compose options

        # Generates the edit draft composition form.
        else if @props.action is 'message.edit' or
                @props.action is 'message.show'
            component = Compose _.extend options,
                key: options.key + '-' + @props.messageID
                messageID: @props.messageID

        # Generates the reply composition form.
        else if @props.action is 'message.reply'
            options.action = ComposeActions.REPLY
            component = @getReplyComponent options

        # Generates the reply all composition form.
        else if @props.action is 'message.reply.all'
            options.action = ComposeActions.REPLY_ALL
            component = @getReplyComponent options

        # Generates the forward composition form.
        else if @props.action is 'message.forward'
            options.action = ComposeActions.FORWARD
            component = @getReplyComponent options
        else
            throw new Error "unknown message type : #{@prop.action}"

        return component


    # Configure the component depending on the given action.
    # Returns a spinner if the message is not available.
    getReplyComponent: (options) ->
        options.id = @props.messageID
        options.inReplyTo = @props.messageID
        component = Compose options
        return component

module.exports = Panel
