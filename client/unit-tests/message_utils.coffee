should = require 'should'

messageUtils = require '../app/utils/message_utils'


describe 'Message Utils', ->

    it 'displayAddress', ->
        contact =
            name: 'John Doe'
            address: 'john@gmail.com'
        address =
            address: 'john@gmail.com'
        fullAddress = '"John Doe" <john@gmail.com>'

        messageUtils.displayAddress(contact, true).should.equal fullAddress
        messageUtils.displayAddress(contact, false).should.equal 'John Doe'

        messageUtils.displayAddress(address, true).should.equal 'john@gmail.com'
        messageUtils.displayAddress(address, false).should.equal 'john'
