'use strict';
const assert = require('chai').assert;
const Immutable = require('immutable');

const ActionTypes = require('../app/constants/app_constants').ActionTypes;
const contactMapper = require('../app/libs/mappers/contact');
const contactReducer = require('../app/reducers/contact');

const fixtures = {
  contact1: {
    id: 'c1',
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
    datapoints: [
      { name: 'email', value: 'john@cozy.io' },
    ],
  },
  contact3: {
    id: 'c3',
    datapoints: [
      { name: 'tel', value: '+33 7 12 42 49 87' },
      { name: 'email', value: 'test@cozy.io' },
    ],
  },
};


describe('ContactReducer', () => {

  describe('Actions', () => {

    describe('CREATE_CONTACT_SUCCESS', () => {

      it('should import created contact', () => {
        // arrange
        let state = null;

        // act
        let result = contactReducer(state, {
          type: ActionTypes.CREATE_CONTACT_SUCCESS,
          value: fixtures.contact1
        });

        // assert
        assert.equal(result.contacts.size, 2);

        assert.isTrue(result.contacts.has('test@right.com'));
        assert.isTrue(result.contacts.has('test2@right.com'));

        assert.equal(result.contacts.get('test@right.com').get('id'), 'c1');
        assert.equal(result.contacts.get('test2@right.com').get('id'), 'c1');
      });

    });;

    describe('CONTACT_LOCAL_SEARCH', () => {

      let initialContacts = [
        fixtures.contact1,
        fixtures.contact2,
        fixtures.contact3
      ];

      let initialState = {
        contacts: Immutable
          .Map()
          .withMutations(contactMapper.toMapMutator(initialContacts)),
        results: Immutable.OrderedMap()
      };

      it('should return matching contacts', () => {
        // arrange
        let query = 'test';

        // act
        let result = contactReducer(initialState, {
          type: ActionTypes.CONTACT_LOCAL_SEARCH,
          value: query
        });

        // assert
        assert.equal(result.results.size, 3);

        assert.isTrue(result.results.has('test@right.com'));
        assert.isTrue(result.results.has('test2@right.com'));
        assert.isTrue(result.results.has('test@cozy.io'));

        assert.equal(result.results.get('test@right.com').get('id'), 'c1');
        assert.equal(result.results.get('test2@right.com').get('id'), 'c1');
        assert.equal(result.results.get('test@cozy.io').get('id'), 'c3');

      });

      it('should not return any contacts when no query', () => {
        // arrange
        let query = ''
        // act
        let result = contactReducer(initialState, {
          type: ActionTypes.CONTACT_LOCAL_SEARCH,
          value: query
        });

        // assert
        assert.equal(result.results.size, 0);
      });

      it('should not return any contacts when query does not match', () => {
        // arrange
        let query = 'no match'
        // act
        let result = contactReducer(initialState, {
          type: ActionTypes.CONTACT_LOCAL_SEARCH,
          value: query
        });

        // assert
        assert.equal(result.results.size, 0);
      });

    });
  });
});
