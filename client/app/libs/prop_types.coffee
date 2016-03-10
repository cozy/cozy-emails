React     = require 'react'
Immutable = require 'immutable'

PropTypes = exports
PropTypes[key] = value for key, value of React.PropTypes

PropTypes.valueLink = (type) ->
    PropTypes.shape(
        value: type
        requestChange: React.PropTypes.func.isRequired
    )

PropTypes.immutableMapStringTo = (valueType) ->
    (props, name, cname, loc) ->
        err = PropTypes.instanceOf(Immutable.Map).isRequired.apply @, arguments
        return err if err

        values = props[name].values()
        for v, i of values
            err = valueType(values, i, cname, loc)
            return err if err

        return null

PropTypes.Mailbox = PropTypes.shape
    id: PropTypes.string
    label: PropTypes.string
    depth: PropTypes.number
    weight: PropTypes.number
    attribs: PropTypes.arrayOf PropTypes.string

PropTypes.mapOfMailbox = PropTypes.immutableMapStringTo(PropTypes.Mailbox)

PropTypes.Account = PropTypes.shape
    label        : PropTypes.string
    name         : PropTypes.string
    login        : PropTypes.string
    password     : PropTypes.string
    imapServer   : PropTypes.string
    imapPort     : PropTypes.string
    smtpServer   : PropTypes.string
    smtpPort     : PropTypes.string
    smtpMethod   : PropTypes.string
    draftMailbox : PropTypes.string
    sentMailbox  : PropTypes.string
    trashMailbox : PropTypes.string
