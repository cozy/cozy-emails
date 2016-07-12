'use strict';
const assert = require('chai').assert;

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const ActionTypes = require('../app/constants/app_constants').ActionTypes;

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


describe.skip('Contact Store', () => {
  let contactStore;
  let dispatcher;

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
    mockeryUtils.initForStores(['../app/stores/contact_store']);
    contactStore = require('../app/stores/contact_store');
  });

  describe('Actions', () => {
    const id1              = fixtures.contact1.id;
    const id2              = fixtures.contact2.id;
    const email1a          = fixtures.contact1.datapoints[0].value;
    const email1b          = fixtures.contact1.datapoints[1].value;
    const email1datapoints = fixtures.contact1.datapoints;
    const email2           = fixtures.contact2.datapoints[0].value;
    const email3           = fixtures.contact3.datapoints[1].value;

    it.skip('CREATE_CONTACT_SUCCESS', () => {
      dispatcher.dispatch({
        type: ActionTypes.CREATE_CONTACT_SUCCESS,
        value: [fixtures.contact1, fixtures.contact2, fixtures.contact3],
      });

      const _email1a = contactStore.getByAddress(email1a);
      const _email1b = contactStore.getByAddress(email1a);
      const _email2  = contactStore.getByAddress(email2);

      assert.equal(_email1a.get('id'), id1);
      assert.equal(_email1b.get('id'), id1);
      assert.equal(_email2.get('id'), id2);
      assert.sameDeepMembers(_email1b.get('datapoints'), email1datapoints);
    });

    it.skip('CONTACT_LOCAL_SEARCH', () => {
      let results = search('test');
      assert.isDefined(results);
      assert.equal(results.size, 3);
      assert.isDefined(results.get(email1a));
      assert.isDefined(results.get(email1b));
      assert.isDefined(results.get(email3));
      results = search('Doe');
      assert.equal(results.size, 1);
      assert.isDefined(results.get(email2));
      results = search(email2);
      assert.equal(results.size, 1);
      assert.isDefined(results.get(email2));
      results = search('test@wrong.com');
      assert.equal(results.size, 0);
    });
  });

  describe('Methods', () => {
    const id1 = fixtures.contact1.id;
    const email1a = fixtures.contact1.datapoints[0].value;
    it.skip('getByAddress', () => {
      const _contact = contactStore.getByAddress(email1a).toObject();
      assert.equal(_contact.fn, fixtures.contact1.fn)
      assert.sameDeepMembers(_contact.datapoints, fixtures.contact1.datapoints);
      assert.equal(_contact.address, email1a)

      assert.isUndefined(contactStore.getByAddress('test@wrong.com'));
    });
    it.skip('getAvatar', () => {
      assert.isUndefined(contactStore.getAvatar('test@wrong.com'));
      assert.equal(contactStore.getAvatar(email1a),
                   `contacts/${id1}/picture.jpg`);
    });
    it.skip('isExist', () => {
      assert.isFalse(contactStore.isExist('test@wrong.com'));
      assert.isTrue(contactStore.isExist(email1a));
    });
  });

  after(() => {
    mockeryUtils.clean();
  });
});
