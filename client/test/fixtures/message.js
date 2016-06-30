"use strict";

const AccountFixture = require('./account')

// # TODO: il faudra tester les types des données
module.exports.createMessage = function createMessage() {

  const mailbox = AccountFixture.createMailbox()

  // let mailboxIDs = {};
  // mailboxIDs[mailbox.id] = 'PLOP';

  return {
    'id': 'bfcf4e2da3383533fb2b1dc1a807e114',
    'conversationID': 'aa036272-ab8f-4252-bdb6-d30986c4be35',
    'accountID': 'bfcf4e2da3383533fb2b1dc1a8049123',
    'mailboxID': 'bfcf4e2da3383533fb2b1dc1a804e5c1',
    'mailboxIDs': {},
    'messageID': 'CAFvPtfJP2UXp0B+jkCo0PSnxdPfM8=sVdyXBsPspCZeqDRu68Q@mail.gmail.com',
    'attachments': [],
    'date': '2016-04-26T08:19:08.000Z',
    'docType': 'message',
    'flags': [],

    // TODO: add test
    // about these properties
    // 'from': Array[1]
    // 'to': Array[1]
    // 'bcc': Array[0]
    // 'cc': Array[0]
    // 'replyTo': Array[0]
    // 'inReplyTo': Array[1]
    // 'hasTwin': Array[0]
    // 'headers': Object
    // 'subject': 'Re: Salut"
    // 'normSubject': 'Salut"
    // 'priority': 'normal"
    // 'html': 'test"
    // 'ignoreInCount': false
    // 'references': Array[7]
    // 'text': ''
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
