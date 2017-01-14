_          = require 'underscore'
React      = require 'react'
classNames = require 'classnames'

{div, aside, nav, ul, li, span, a, i, button} = React.DOM

RouterActionCreator = require '../actions/router_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
AccountActionCreator = require '../actions/account_action_creator'

{Tooltips} = require '../constants/app_constants'


module.exports = React.createClass
    displayName: 'MenuMailboxItem'


    getInitialState: ->
        return target: false


    getDefaultProps: ->
        return {
            icon: {
                type: null
                value: 'fa-folder-o'
            }
        }


    getTitle: ->
        title = t "menu mailbox total", @props.total
        if @props.unread
            title += t "menu mailbox unread", @props.unread
        if @props.recent
            title += t "menu mailbox new", @props.recent
        return title


    render: ->
        classesParent = classNames
            active: @props.isActive
            target: @state.target

        classesChild = classNames
            target:  @state.target
            news:    @props.recent > 0

        displayError = @props.displayErrors.bind null, @props.progress

        li className: classesParent,
            a
                href: @props.url
                className: "#{classesChild} lv-#{@props.depth}"
                role: 'menuitem'
                'data-mailbox-id': @props.mailboxID
                title: @getTitle()
                'data-toggle': 'tooltip'
                'data-placement' : 'right'
                key: @props.key,
                    i className: 'fa ' + @props.icon.value
                    span
                        className: 'item-label',
                        "#{@props.label}"

                if @props.progress?.get('errors').length
                    span className: 'refresh-error', onClick: displayError,
                        i className: 'fa fa-warning', null


            if not @props.progress and @props.unread
                span className: 'badge', @props.unread
