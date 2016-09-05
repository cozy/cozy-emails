/* eslint-env mocha */
'use strict';
const assert = require('chai').assert;
const Immutable = require('immutable');

const ActionTypes = require('../app/constants/app_constants').ActionTypes;
const contactMapper = require('../app/libs/mappers/contact');
const contactReducer = require('../app/reducers/contact');
const contactSearchReducer = require('../app/reducers/contact_search');

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
        let initialState = null;

        // act
        let result = contactReducer(initialState, {
          type: ActionTypes.CREATE_CONTACT_SUCCESS,
          value: fixtures.contact1
        });

        // assert
        assert.equal(result.size, 2);

        assert.isTrue(result.has('test@right.com'));
        assert.isTrue(result.has('test2@right.com'));

        assert.equal(result.get('test@right.com').get('id'), 'c1');
        assert.equal(result.get('test2@right.com').get('id'), 'c1');
      });

    });;

    describe('CONTACT_LOCAL_SEARCH', () => {

      let initialContacts = [
        fixtures.contact1,
        fixtures.contact2,
        fixtures.contact3
      ];

      let appState = Immutable.Map({
        contacts: Immutable
          .Map()
          .withMutations(contactMapper.toMapMutator(initialContacts)),
        contact_search: null
      });

      it('should return matching contacts', () => {
        // arrange
        let query = 'test';

        // act
        let result = contactSearchReducer(null, {
          type: ActionTypes.CONTACT_LOCAL_SEARCH,
          value: query
      }, appState);

        // assert
        assert.equal(result.size, 3);

        assert.isTrue(result.has('test@right.com'));
        assert.isTrue(result.has('test2@right.com'));
        assert.isTrue(result.has('test@cozy.io'));

        assert.equal(result.get('test@right.com').get('id'), 'c1');
        assert.equal(result.get('test2@right.com').get('id'), 'c1');
        assert.equal(result.get('test@cozy.io').get('id'), 'c3');

      });

      it('should not return any contacts when no query', () => {
        // arrange
        let query = ''
        // act
        let result = contactSearchReducer(null, {
          type: ActionTypes.CONTACT_LOCAL_SEARCH,
          value: query
        }, appState);

        // assert
        assert.equal(result.size, 0);
      });

      it('should not return any contacts when query does not match', () => {
        // arrange
        let query = 'no match'
        // act
        let result = contactSearchReducer(null, {
          type: ActionTypes.CONTACT_LOCAL_SEARCH,
          value: query
        }, appState);

        // assert
        assert.equal(result.size, 0);
      });

    });
  });
});
