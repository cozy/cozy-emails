
_ = require 'lodash'

ContactStore     = require '../stores/contact_store'

class ContactGetter

    getAvatar: ({address}) ->
        ContactStore.getAvatar address


    getByAddress: ({address}) ->
        ContactStore.getByAddress address

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


    getAll: ->
        ContactStore.getResults()


module.exports = new ContactGetter()
