###

ContactMapper lib
===

Helpers for contact

###
Immutable = require 'immutable'

# Helper used in array#find method
# Returns a callback for array#find method
_byName = (name) ->
    return (object) ->
        return object.name is name

module.exports =
    # Returns an Immutable contact from a raw contact
    # rawContact: a contact as given by the Cozy data system
    toImmutable: (rawContact) ->
        return unless rawContact

        contact = Immutable.Map(rawContact).delete('docType')

        # Get avatar from binary if exists, or fallback to datapoint
        if rawContact._attachments?.picture
            avatar = """
                contacts/#{rawContact.id}/picture.jpg
            """
        else
            avatar = rawContact.datapoints?.find(_byName('avatar'))?.value

        if avatar
            contact = contact.set 'avatar', avatar

        rawContact
            .datapoints?.filter _byName 'email'
            .forEach (datapoint) ->
                if contact.has 'addresses'
                    addresses = contact.get('addresses').push datapoint.value
                else
                    addresses = Immutable.List [datapoint.value]
                    # first address found as default address
                    # We set a single address property to be legacy-compliant
                    contact = contact.set 'address', datapoint.value

                contact = contact.set 'addresses', addresses

        return contact


    # Returns a list of Immutable contacts from a list of raw contacts
    # rawContacts: an array of rawContacts
    toImmutables: (rawContacts) ->
        return unless rawContacts
        rawContacts = [ rawContacts ] unless Array.isArray rawContacts
        return rawContacts.map @toImmutable


    # Returns a mutator to be passed as parameter for Map#withMutations method
    # contacts: array of Immutable contacts
    toMapMutator: (contacts) ->
        return (map) ->
            return map unless contacts
            contacts.forEach (contact) ->
                return unless contact.has 'addresses'
                contact.get('addresses').forEach (address) ->
                    # FIXME: here we switch back to a single 'address' field
                    # to be legacy-compliant
                    map.set address, contact.set 'address', address


