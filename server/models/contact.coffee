americano = require 'americano-cozy'

module.exports = Contact = americano.getModel 'Contact',
    id            : String
    fn            : String
    n             : String
    datapoints    : (x) -> x
    note          : String
    tags          : (x) -> x
    _attachments  : Object

