"use strict";

const getUID = require('../utils/guid').getUID;
const getName = require('../utils/guid').getName;

const AccountFixture = require('./account');


// # TODO: il faudra tester les types des données
module.exports.createMessage = function createMessage(data) {

  const mailbox = AccountFixture.createMailbox()
  // let mailboxIDs = {};
  // mailboxIDs[mailbox.id] = 'PLOP';

  // TODO: voir pour créer les mailboxIDs
  // Regarder dasn les tests les types de données qui seront necessaires
  const date = (data.date || new Date()).toISOString();

  return {
    id: `message-${getUID()}`,

    messageID: "cozy/cozy-ui/pull/19@github.com",
    conversationID: "79348a40-f084-458b-9994-dfc85fc60eb5",
    accountID: "0d73a98a97651572eeb6e00c41f5817a",
    mailboxIDs: {},

    normSubject: "[cozy/cozy-ui] Add mixed checkbox style (#19)",
    subject: "[cozy/cozy-ui] Add mixed checkbox style (#19)",
    priority: "normal",

    // updated: date,
    createdAt: date,
    date: date,

    headers: {},
    html: "contenu de mon emails",
    text: "sqdd",
    attachments: [],
    hasAttachments: false,
    references: [],
    to: [],
    replyTo: [],
    bcc: [],
    cc: [],
    inReplyTo: [],
    flags: [],
    from: [],
    hasTwin: [],
    ignoreInCount: false,

    // settings
    _displayImages: data.images
  }
}


module.exports.createUnread = function UnreadMessage() {

}


module.exports.createFlagged = function FlaggedMessage() {

}


module.exports.createDeleted = function DeletedMessage() {

}


module.exports.createDraft = function DraftMessage() {

}


module.exports.createAttached = function AttachedMessage() {

}


// fullTestError: {
//   name: 'AccountConfigError',
//   field: 'error-field',
//   originalError: 'original-error',
//   originalErrorStack: 'original-error-stack',
//   causeFields: ['field1', 'field2'],
// },
// testError: 'test-error',
// unknownError: {
//   unknown: 'test-error',
// },
// account: {
//   label: 'test',
//   login: '',
//   password: '',
//   imapServer: '',
//   imapLogin: '',
//   smtpServer: '',
//   inboxMailbox: 'mb1',
//   trashMailbox: 'mb3',
//   draftMailbox: 'mb4',
//   id: 'a1',
//   smtpPort: 465,
//   smtpSSL: true,
//   smtpTLS: false,
//   smtpMethod: 'PLAIN',
//   imapPort: 993,
//   imapSSL: true,
//   imapTLS: false,
//   accountType: 'IMAP',
//   favoriteMailboxes: null,
//   mailboxes: [
//     {
//       id: 'mb1',
//       label: 'inbox',
//       attribs: '',
//       tree: ['inbox'],
//       accountID: 'a1',
//       nbTotal: 3253,
//       nbFlagged: 15,
//       nbUnread: 4,
//     },
//     { id: 'mb2', label: 'sent', accountID: 'a1' },
//     { id: 'mb3', label: 'trash', accountID: 'a1' },
//     { id: 'mb4', label: 'draft', accountID: 'a1' },
//   ],
// },
// // lastPage: {
// //   info: 'last-page',
// //   isComplete: true,
// // },
// modal: {
//   display: true,
// },
// message1: {
//   id: 'i1',
//   accountID: 'a1',
//   messageID: 'me1',
//   flags: [MessageFlags.SEEN],
//   conversationID: 'c1',
//   mailboxIDs: { mb1: 1 },
// },
// message2: {
//   id: 'i2',
//   accountID: 'a1',
//   messageID: 'me2',
//   flags: [MessageFlags.SEEN],
//   conversationID: 'c2',
//   mailboxIDs: { mb1: 1 },
// },
// message3: {
//   id: 'i3',
//   accountID: 'a1',
//   messageID: 'me3',
//   conversationID: 'c3',
//   mailboxIDs: { mb1: 1, mb3: 1 },
//   flags: [MessageFlags.FLAGGED, MessageFlags.ATTACH],
// },
// message4: {
//   id: 'i4',
//   accountID: 'a1',
//   messageID: 'me4',
//   conversationID: 'c4',
//   mailboxIDs: { mb4: 1 },
//   flags: [MessageFlags.FLAGGED, MessageFlags.ATTACH],
// },
// };
