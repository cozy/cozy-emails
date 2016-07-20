
'use strict';
const assert = require('chai').assert;
const Immutable = require('immutable');

const contactMapper = require('../app/libs/mappers/contact')

const fixtures = {
  contact1: {
    id: 'c1',
    docType: 'contact',
    datapoints: [
      { name: 'email', value: 'test@right.com' },
      { name: 'email', value: 'test2@right.com' },
    ],
    _attachments: {
      picture: 'binary1',
    },
  },
  contact2: {
    id: 'c2',
    fn: 'John,Doe',
    docType: 'contact',
    datapoints: [
      { name: 'avatar', value: 'avatar.jpg' },
      { name: 'email', value: 'john@cozy.io' },
    ],
  },
  contact3: {
    id: 'c3',
    docType: 'contact',
    datapoints: [
      { name: 'tel', value: '+33 7 12 42 49 87' },
      { name: 'email', value: 'test@cozy.io' },
    ],
  },
};

describe('ContactMapper', () => {

  describe('Methods', () => {

    describe('toImmutable', () => {

      it('should return undefined when no contact is given', () => {
        // arrange
        // act
        let result = contactMapper.toImmutable()
        // assert
        assert.isUndefined(result);
      });

      it('shoud skip docType', () => {
        // arrange
        let contact = fixtures.contact1;
        // act
        let result = contactMapper.toImmutable(contact);
        // assert
        assert.isFalse(result.has('docType'));
      });

      it('should map avatar when contact has attachment', () => {
        // arrange
        let contact = fixtures.contact1;
        let expectedAvatar = 'contacts/c1/picture.jpg';
        // act
        let result = contactMapper.toImmutable(contact);
        // assert
        assert.equal(result.get('avatar'), expectedAvatar);
      });

      it('should map avatar when contact has avatar datapoint', () => {
        // arrange
        let contact = fixtures.contact2;
        let expectedAvatar = 'avatar.jpg';
        // act
        let result = contactMapper.toImmutable(contact);
        // assert
        assert.equal(result.get('avatar'), expectedAvatar);
      });

      it('should not map avatar', () => {
        // arrange
        let contact = fixtures.contact3;
        // act
        let result = contactMapper.toImmutable(contact);
        // assert
        assert.isFalse(result.has('avatar'));
      });

      it('should map one address', () => {
        // arrange
        let contact = fixtures.contact2;
        let expectedAddress = 'john@cozy.io';
        let expectedAddresses = [expectedAddress];
        // act
        let result = contactMapper.toImmutable(contact);
        // assert
        assert.equal(result.get('address'), expectedAddress);
        assert.deepEqual(result.get('addresses').toArray(), expectedAddresses);
      });

      it('should map several addresses', () => {
        // arrange
        let contact = fixtures.contact1;
        let expectedAddress = 'test@right.com';
        let expectedAddresses = ['test@right.com', 'test2@right.com'];
        // act
        let result = contactMapper.toImmutable(contact);
        // assert
        assert.equal(result.get('address'), expectedAddress);
        assert.deepEqual(result.get('addresses').toArray(), expectedAddresses);
      });

    });

    describe('toImmutables', () => {

      it('should return undefined when no contacts are given', () => {
        // arrange
        // act
        let result = contactMapper.toImmutables();
        // assert
        assert.isUndefined(result);
      });

      it('should map contacts array to immutables array', () => {
        // arrange
        let rawContacts = [
          fixtures.contact1,
          fixtures.contact2,
          fixtures.contact3
        ];

        // act
        let result = contactMapper.toImmutables(rawContacts);

        // assert
        assert.equal(result.length, 3);

        assert.isFunction(result[0].get);
        assert.equal(result[0].get('id'), 'c1');

        assert.isFunction(result[1].get);
        assert.equal(result[1].get('id'), 'c2');

        assert.isFunction(result[2].get);
        assert.equal(result[2].get('id'), 'c3');
        // We assume that toImmutable covers other inidividual assertions.
      });

    });

    describe('toMapMutator', () => {

      it('should return a function', () => {
        // arrange
        let contacts = [
          contactMapper.toImmutable(fixtures.contact1),
          contactMapper.toImmutable(fixtures.contact2),
          contactMapper.toImmutable(fixtures.contact3)
        ];

        // act
        let result = contactMapper.toMapMutator(contacts);

        // assert
        assert.isFunction(result);
      });

      it('should return expected mutator', () => {
        // arrange
        let contacts = [
          contactMapper.toImmutable(fixtures.contact1),
          contactMapper.toImmutable(fixtures.contact2),
          contactMapper.toImmutable(fixtures.contact3)
        ];

        let mutator = contactMapper.toMapMutator(contacts);

        let map = Immutable.Map();

        // act
        let result = map.withMutations(mutator);

        // assert
        assert.isTrue(Immutable.Map.isMap(result));

        assert.equal(result.size, 4);

        assert.isTrue(result.has('test@right.com'));
        assert.isTrue(result.has('test2@right.com'));
        assert.isTrue(result.has('john@cozy.io'));
        assert.isTrue(result.has('test@cozy.io'));

        assert.equal(result.get('test@right.com').get('address'), 'test@right.com');
        assert.equal(result.get('test@right.com').get('id'), 'c1');
        assert.equal(result.get('test2@right.com').get('address'), 'test2@right.com');
        assert.equal(result.get('test2@right.com').get('id'), 'c1');
        assert.equal(result.get('john@cozy.io').get('address'), 'john@cozy.io');
        assert.equal(result.get('john@cozy.io').get('id'), 'c2');
        assert.equal(result.get('test@cozy.io').get('address'), 'test@cozy.io');
        assert.equal(result.get('test@cozy.io').get('id'), 'c3');
      });

    });

  });

});
