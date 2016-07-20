
_ = require 'lodash'

reduxStore = require '../reducers/_store'
colorhash = require '../libs/colorhash'

_getContacts = ->
    reduxStore.getState().contact.contacts

module.exports =

    getAvatar: (contact = {}) ->
        {address} = contact
        _getContacts().get(address)?.get 'avatar'


    getByAddress: (contact = {}) ->
        {address} = contact
        _getContacts().get address


    # From a text, build an `address` object (name and address).
    # Add a isValid field if the given email is well formed.
    parseAddress: (text) ->
        text = text.trim()
        if match = text.match /"{0,1}(.*)"{0,1} <(.*)>/
            address =
                name: match[1]
                address: match[2]
        else
            address =
                address: text.replace(/^\s*/, '')

        # Test email validity
        emailRe = /^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/
        address.isValid = address.address.match emailRe

        address


    # Build string showing address from an `adress` object. If a mail is given
    # in the `address` object, the string return this:
    #
    # Sender Name <email@sender.com>
    displayAddress: (contact, full = false) ->
        # console.log 'ADDRESS', contact
        if full
            if address.name? and address.name isnt ""
                return "\"#{contact.name}\" <#{contact.address}>"
            else
                return "#{contact.address}"
        else
            if contact.name? and contact.name isnt ""
                return contact.name
            else
                return contact.address.split('@')[0]


    # Build a string from a list of `adress` objects. Addresses are
    # separated by a coma. An address is either the email adress either this:
    #
    # Sender Name <email@sender.com>
    displayAddresses: (contacts=[], full=false) ->
        addresses = []
        for contact in contacts
            if (address = @displayAddress contact, full)
                result.push address
        addresses.join ", "


    getAll: (message) ->
        unless message
            return reduxStore.getState().contact.results

        _.zipObject (keys = ['from', 'to' , 'cc']), _.map keys, (key) =>
            _.map (contacts = message.get key), (value) =>
                model = @getByAddress value
                address = @displayAddress value
                {value, model, address}


    getTagColor: (tag) ->
        colorhash tag
