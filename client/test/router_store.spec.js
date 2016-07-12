'use strict';
const assert = require('chai').assert;
const Immutable = require('immutable');
const map = Immutable.Map;
const _ = require('lodash');

const mockeryUtils = require('./utils/mockery_utils');
const SpecDispatcher = require('./utils/specs_dispatcher');
const SpecRouter = require('./utils/specs_router');

const UtilConstants = require('../../server/utils/constants');
const Constants = require('../app/constants/app_constants');
const ActionTypes = Constants.ActionTypes;
const AccountActions = Constants.AccountActions;
const MessageActions = Constants.MessageActions;
const MessageFlags = Constants.MessageFlags;
const MessageFilter = Constants.MessageFilter;


const AccountFixture = require('./fixtures/account')
const MessageFixture = require('./fixtures/message')


describe('Router Store', () => {
  let RouterStore;
  let AccountStore;
  let MessageStore;
  let dispatcher;

  let account;

  /*
   * Problem noticed:
   *
   * * FIXME: Private methods are melted with public ones.
   * * FIXME: Some events require a value while it's never used
   *          (ex: EDIT_ACCOUNT_REQUEST).
   * * FIXME: EDIT_ACCOUNT_SUCCESS clears errors after creating some. Don't
   *          know what to test.
   * * FIXME: Code is shared between client and server.
   * * FIXME: getPreviousConversation and getNextConversation looks confusing.
   * * FIXME: Search and filter didn't look implemented yet. Tests about it
   *          should be added later (via ROUTE_CHANGE event tests).
   */

  before(() => {
    dispatcher = new SpecDispatcher();
    mockeryUtils.initDispatcher(dispatcher);

    mockeryUtils.initForStores([
      '../stores/account_store',
      '../app/stores/account_store',
      '../stores/message_store',
      '../app/stores/message_store',
      '../stores/requests_store',
      '../app/stores/router_store',
      '../../../server/utils/constants',
    ]);
    AccountStore = require('../app/stores/account_store');
    MessageStore = require('../app/stores/message_store');
    RouterStore = require('../app/stores/router_store');

    dispatcher.dispatch({
      type: ActionTypes.ROUTES_INITIALIZE,
      value: new SpecRouter(),
    });
  });


  beforeEach(() => {
    account = AccountFixture.create()
    dispatcher.dispatch({
      type: ActionTypes.ADD_ACCOUNT_SUCCESS,
      value: { account },
    });
  });


  afterEach(() => {
    dispatcher.dispatch({
      type: ActionTypes.ACCOUNT_RESET_REQUEST
    });
  });


  after(() => {
    mockeryUtils.clean();
  });


  describe('Get States From Stores:', () => {

    // TODO: tester lorsqu'on ne trouve aucun comptes
    describe('AccountStore', () => {

      //  TODO: tester la valeur de mailboxID
      // - lorsque l'on va créer un compte
      // -> il ne devrait pas y avoir de valeur (undefined)
      it.skip('Select Mailbox', () => {
        const accountID = account[0].id;
        const mailboxID = account[0].inboxMailbox;

        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: { accountID, mailboxID}
        });

        assert.equal(RouterStore.getAccountID(), accountID);
        assert.equal(RouterStore.getAccount().get('id'), accountID);

        assert.equal(RouterStore.getMailboxID(), mailboxID);
        assert.equal(RouterStore.getMailbox().get('id'), mailboxID);
      });


      it.skip('Select Tab from AccountEdit page', () => {
        const accountID = account[0].id;
        const mailboxID = account[0].inboxMailbox;
        const accountAction = AccountActions.EDIT;
        const messageAction = MessageActions.SHOW;

        // Tab doesnt exist for none account pages
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: account[0].id,
            mailboxID: account[0].inboxMailbox,
          }
        });
        assert.isNull(RouterStore.getSelectedTab());

        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: account[0].id,
            mailboxID: account[0].inboxMailbox,
            action: messageAction,
          }
        });
        assert.isNull(RouterStore.getSelectedTab());

        // Tab default value is account
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: account[0].id,
            mailboxID: account[0].inboxMailbox,
            action: accountAction,
          }
        });
        assert.equal(RouterStore.getSelectedTab(), 'account');

        // Specify a value for Tab
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: account[0].id,
            mailboxID: account[0].inboxMailbox,
            action: accountAction,
            tab: 'selected'
          }
        });
        assert.equal(RouterStore.getSelectedTab(), 'selected');
      });
    });


    describe('MessageStore', () => {

      it.skip('Select Mailbox', () => {

        const message = MessageFixture.createMessage();


        // // Read/Unread
        // // Flagged/Unflagged
        // // Attached/NoAttached
        // // Deleted/NoDeleted
        // const defaultMessage = MessageFixture.createMessage();
        // const unreadMessage = MessageFixture.createUnread();
        // const flaggedMessage = MessageFixture.createFlagged();
        // const deletedMessage = MessageFixture.createDeleted();
        // const draftMessage = MessageFixture.createDraft();
        // const attachedMessage = MessageFixture.createAttached();

        const messageID = message.id;
        const conversationID = message.conversationID;
        const accountID = message.accountID;
        const mailboxID = _.keys(message.mailboxIDs)[0];
        const action = MessageActions.SHOW;


        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: message.accountID,
            mailboxID: message.mailboxIDs[0],
            messageID: message.id,
            conversationID: message.conversationID,
            action,
          }
        });
        assert.equal(RouterStore.getConversationID(), conversationID);
        assert.equal(RouterStore.getMessageID(), messageID);
        assert.equal(RouterStore.getAction(), action);

        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID,
            mailboxID,
            messageID,
          }
        });
        assert.isNull(RouterStore.getConversationID());
        assert.isNull(RouterStore.getMessageID());
        assert.equal(RouterStore.getAction(), MessageActions.SHOW_ALL);

        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID,
            mailboxID,
            action,
          }
        });
        assert.equal(RouterStore.getConversationID(), undefined);
        assert.equal(RouterStore.getMessageID(), undefined);
        assert.equal(RouterStore.getAction(), MessageActions.SHOW_ALL);
      });

      it.skip('getInboxTotal', () => {
        const total = account[0].mailboxes[0].nbTotal
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: account[0].id,
            mailboxID: account[0].inboxMailbox,
          }
        });
        assert.equal(RouterStore.getMailboxTotal(), total);
      });

      it.skip('getFlagboxTotal', () => {
        const total = account[0].mailboxes[0].nbFlagged
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: account[0].id,
            mailboxID: account[0].inboxMailbox,
            query: {flags: MessageFilter.FLAGGED},
          }
        });
        assert.equal(RouterStore.getMailboxTotal(), total);
      });

      it.skip('getUnreadTotal', () => {
        const total = account[0].mailboxes[0].nbUnread
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: account[0].id,
            mailboxID: account[0].inboxMailbox,
            query: {flags: MessageFilter.UNSEEN},
          }
        });
        assert.equal(RouterStore.getMailboxTotal(), total);
      });
    });


    describe('RouterStore', () => {

      let messages=[];
      let start = ["1995-12-17T03:24:00", "1995-12-17T00:24:00",
        "1995-12-16T03:24:00", "1995-12-15", "1998-10-1"].map((date) => {
            return Date.parse(date);
          });

      before(() => {

        // // Create fake Messages
        // // no need of mailboxIDs or flags properties
        // const perPage = RouterStore.getMessagesPerPage();
        // const pageLength = 3.5;
        // const messagesLength = perPage * pageLength
        //
        //
        // const message = MessageFixture.createMessage();
        // const keys = _.keys(message);
        // const values = _.values(message);
        // const accountID = message.accountID
        //
        // for (let i = 0; i < messagesLength; i++) {
        //   let message = {};
        //   for (let ii = 0; ii < keys.length; ii++) {
        //
        //     //  TODO: ajouter une valeur pour mailboxID
        //     //  sinon erreur dans getMessagesList
        //     if ('mailboxIDs' == keys[ii] || 'flags' == keys[ii]) continue;
        //     if ('accountID' == keys[ii]) message[keys[ii]] = accountID;
        //     else message[keys[ii]] = `${values[ii]}-${i}`;
        //   }
        //   if (!_.isEmpty(message)) messages.push(message);
        // }
      });

      // TODO: test getURL

      it.skip('GetMoreMessages workflow', () => {
        // TODO: add more complex tests
        // when testing RouterActionCreator.gotoNextPage()
        // ie. navigate thew several mailbox (including flagged ones)
        // to chake if hasNextPage is still coherent

        // Goto MailboxList
        dispatcher.dispatch({
          type: ActionTypes.ROUTE_CHANGE,
          value: {
            accountID: account[0].id,
            mailboxID: account[0].inboxMailbox,
          },
        });

        // Fetch 1rst page of messages
        let lastPage = { start: start[0], isComplete: false };
        dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FETCH_SUCCESS,
          value: { lastPage },
        });
        assert.equal(RouterStore.getLastPage(), lastPage);
        assert.equal(RouterStore.hasNextPage(), true);
        assert.equal(RouterStore.getURI(), account[0].inboxMailbox);

        // Fetch 2nd page of messages
        lastPage = { start: start[1], isComplete: true };
        dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FETCH_SUCCESS,
          value: { lastPage },
        });
        assert.equal(RouterStore.getLastPage(), lastPage);
        assert.equal(RouterStore.hasNextPage(), false);
      });


      // TODO: test AccountStore.getInbox

      it.skip('Navigate from Message to Messages', () => {

        dispatcher.dispatch({
          type: ActionTypes.MESSAGE_FETCH_SUCCESS,
          value: {
            result: { messages },
            lastPage: {
              start: start[0],
              isComplete: false,
            }
          },
        });

        // Check that all messages have been stores
        assert.equal(MessageStore.getAll().size, messages.length);

        // TODO: ajouter un compte
        // const messagesPerPage = RouterStore.getMessagesPerPage();


        // FIXME: AccountStore.getInbox est cassé
        // -> FIX: ajout d'une props tree à chaque message
        // FIXME: déduire mailboxIDs de la valeur de tree?!
        // -> les fake data n'ont pas les bonnes valeurs

        const list = RouterStore.getMessagesList();
        // console.log(list)

        // TODO: ajouter bcp de messages
        // et vérifier que le nombre de messages par page
        // est bien respecté
        //  TODO testster ces méthodes
        // isPageComplete: ->
        // console.log('MESSAGES', MessageStore.getAll().size, messages.length);

        // TODO: en profiter pour vérifier le fctionnement des flags

          // TODO: here test isPageComplete with getMessagesList
          // it.skip('getMessagesList', () => {
          //   const msgs = [];
          //   for (let i = 0; i < UtilConstants.MSGBYPAGE + 3; i++) {
          //     const message = _.clone(fixtures.message1);
          //     message.id = `id${i}`;
          //     message.messageID = `meid${i}`;
          //     message.conversationID = `c${i}`;
          //     msgs.push(message);
          //   }
          //   msgs[12].flags = [];
          //   msgs[14].flags = [MessageFlags.FLAGGED];
          //   msgs[15].flags = [MessageFlags.FLAGGED, MessageFlags.ATTACH];
          //   changeRoute({ });
          //   loadMessages(msgs);
          //   assert.equal(RouterStore.getMessagesList().size, msgs.length);
          //   changeRoute({ flags: MessageFilter.UNSEEN });
          //   assert.equal(RouterStore.getMessagesList().size, 3);
          //   changeRoute({ flags: MessageFilter.FLAGGED });
          //   assert.equal(RouterStore.getMessagesList().size, 2);
          //   changeRoute({ flags: MessageFilter.ATTACH });
          //   assert.equal(RouterStore.getMessagesList().size, 1);
          // });



          // it.skip('getConversation', () => {
          //   const msgs = generateMessages();
          //   msgs[16].conversationID = 'c5';
          //   msgs[17].conversationID = 'c5';
          //   msgs[18].conversationID = 'c5';
          //
          //   changeRoute({ });
          //   loadMessages(msgs);
          //   assert.equal(RouterStore.getConversation('c5').length, 4);
          // });
          // it.skip('getConversationLength', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ });
          //   loadMessages(msgs, { c5: 6 });
          //   assert.equal(RouterStore.getConversationLength({
          //     conversationID: 'c5',
          //   }), 6);
          // });
          // it.skip('getNextConversation', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ });
          //   msgs[7].conversationID = 'c7';
          //   msgs[8].conversationID = 'c7';
          //   msgs[9].conversationID = 'c7';
          //   loadMessages(msgs);
          //   changeRoute({ }, msgs[7]);
          //   assert.equal(RouterStore.getNextConversation().get('messageID'),
          //                msgs[6].messageID);
          // });
          // it.skip('getPreviousConversation', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ });
          //   msgs[7].conversationID = 'c7';
          //   msgs[8].conversationID = 'c7';
          //   msgs[9].conversationID = 'c7';
          //   loadMessages(msgs);
          //   changeRoute({ }, msgs[7]);
          //   assert.equal(RouterStore.getPreviousConversation().get('messageID'),
          //                msgs[10].messageID);
          // });
          // it.skip('gotoNextMessage', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ }, msgs[0]);
          //   loadMessages(msgs);
          //   assert.equal(RouterStore.gotoPreviousMessage().get('me2'));
          //   assert.equal(RouterStore.gotoPreviousMessage().get('me3'));
          // });
          // it.skip('gotoPreviousMessage', () => {
          //   const msgs = generateMessages();
          //   changeRoute({ }, msgs[4]);
          //   RouterStore.gotoPreviousMessage();
          //   RouterStore.gotoPreviousMessage();
          //   RouterStore.gotoPreviousMessage();
          //   assert.equal(RouterStore.gotoNextMessage().get('me3'));
          // });
      });

    });
  });
});
