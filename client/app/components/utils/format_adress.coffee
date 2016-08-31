# Build string showing address from an `adress` object. If a mail is given
# in the `address` object, the string return this:
#
# Sender Name <email@sender.com>
exports.displayAddress = (contact) ->
    if contact.name? and contact.name isnt ""
        return contact.name
    else
        return contact.address.split('@')[0]

# Build a string from a list of `adress` objects. Addresses are
# separated by a coma. An address is either the email adress either this:
#
# Sender Name <email@sender.com>
exports.displayAddresses = (contacts=[], full=false) ->
    addresses = []
    for contact in contacts
        if (address = @displayAddress contact, full)
            result.push address
    addresses.join ", "
