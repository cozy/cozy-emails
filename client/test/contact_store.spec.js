'use strict';
const assert = require('chai').assert;

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const ActionTypes = require('../app/constants/app_constants').ActionTypes;


describe('Contact Store', () => {
  let contactStore;
  let dispatcher;
  let contact1;
  let contact2;
  let contact3;

  function search(query) {
    dispatcher.dispatch({
      type: ActionTypes.CONTACT_LOCAL_SEARCH,
      value: query,
    });
    return contactStore.getResults();
  }

  before(() => {
    dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(dispatcher);
    mockeryUtils.initForStores();
    contactStore = require('../app/stores/contact_store');
  });

  describe('Actions', () => {
    it('CREATE_CONTACT_SUCCESS', () => {
      contact1 = {
        id: 'c1',
        datapoints: [
          { name: 'email', value: 'test@right.com' },
          { name: 'email', value: 'test2@right.com' },
        ],
        _attachments: {
          picture: 'binary1',
        },
      };
      contact2 = {
        id: 'c2',
        fn: 'John,Doe',
        datapoints: [
          { name: 'email', value: 'john@cozy.io' },
        ],
      };
      contact3 = {
        id: 'c3',
        datapoints: [
          { name: 'tel', value: '+33 7 12 42 49 87' },
          { name: 'email', value: 'test@cozy.io' },
        ],
      };
      dispatcher.dispatch({
        type: ActionTypes.CREATE_CONTACT_SUCCESS,
        value: [contact1, contact2, contact3],
      });
      const contacts = contactStore.getAll();
      assert.deepEqual(contacts.get('test@right.com').get('id'), contact1.id);
      assert.deepEqual(contacts.get('test2@right.com').get('id'), contact1.id);
      assert.deepEqual(contacts.get('john@cozy.io').get('id'), contact2.id);
      assert.equal(
          contacts.get('test2@right.com').get('address'), 'test@right.com');
    });
    it('CONTACT_LOCAL_SEARCH', () => {
      let results = search('test');
      assert.isDefined(results);
      assert.equal(results.size, 3);
      assert.isDefined(results.get('test@right.com'));
      assert.isDefined(results.get('test2@right.com'));
      assert.isDefined(results.get('test@cozy.io'));
      results = search('Doe');
      assert.equal(results.size, 1);
      assert.isDefined(results.get('john@cozy.io'));
      results = search('john@cozy.io');
      assert.equal(results.size, 1);
      assert.isDefined(results.get('john@cozy.io'));
      results = search('test@wrong.com');
      assert.equal(results.size, 0);
    });
  });

  describe('Methods', () => {
    it('getByAddress', () => {
      assert.deepEqual(contactStore.getByAddress('test@right.com').toObject(),
                       contact1);
      assert.isUndefined(contactStore.getByAddress('test@wrong.com'));
    });
    it('getAvatar', () => {
      assert.isUndefined(contactStore.getAvatar('test@wrong.com'));
      assert.equal(contactStore.getAvatar('test@right.com'),
                   'contacts/c1/picture.jpg');
    });
    it('isExist', () => {
      assert.isFalse(contactStore.isExist('test@wrong.com'));
      assert.isTrue(contactStore.isExist('test@right.com'));
    });
  });

  after(() => {
    mockeryUtils.clean();
  });
});
