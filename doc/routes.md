# Routes

This documents lists for legacy and v2 app the routes and redirects in use. Its goal is to provide an exhausting view of contexts in the application and prevent bypass actions that'll break the app consistency.

The v2 refactoring introduces a new router pattern[^1] which sets new routes, and forbid redirects inside components.

## Routes

- `account/new`
  : creates a new account

- `:accountID/settings/:section`
  : access the settings for the given account, scoped to the specified section (e.g. `gmail/settings/general`)

- `:accountID/:mailbox`
  : display the content of a mailbox in an account (i.e. the conversations list). Can be customized using _queryString_ parameters:
  - `?filters=[:filters]`
    : filter conversations list, can be a list of filters (e.g. `gmail/inbox?filters=starred,unread` display gmail's _inbox_ messages which are both _unread_ and _starred_)
  - `?sort=:column:[ASC|DESC]`
    : set the sorting order and on which criteria for the list (e.g. `gmail/inbox?sort=sender:ASC` sort messages from gmail's inbox by sender address, ascending)

- `:accountID/new`
  : opens the compose editor to create a new message from the given account

- `:accountID/message/:messageID`
  : open the requested message, i.e. the main view has the conversations list in the first pane, and the conversation which the message belongs to in the second pane, with the message open
    - `/reply`
      : open the composition view with the message's conversation context in reply mode
    - `/reply-all`
      : same as above, in reply-all mode
    - `/forward`
      : same as above, in forward mode

- `:accountID/*?compose=[new|:messageID[::mode]]`
  : any URL can be queried with a `compose` param, which opens the composition's popup view. See _drafts_ section below for more informations.

- `search/[:accountID]`
  : switch the main view to the search results list. Can be filtered / sorted like a `:mailbox` list. If the `:accountID` is provided, then the search is scoped to this account. Else, the search is global across all mailboxes
  - `?q=:pattern`
    : the query pattern to search for

- `settings/:section`
  : access the global settings view, scoped to the specified section.

### _Drafts_ case

Writing a message observes the same UX path:

1. you'll want to send a new message: you first open the composer; which'll create a new draft at first (auto-)save; then send it
2. you'll want to reply or forward a message: you open the composer in the conversation context (quoted message(s)), preset with right recipients; it'll create a new draft at first (auto-)save; then send it

So, the URLs should reflect this path. You can so open the composer from given URLs:

1. new message: `:accountID/new`
2. reply-like: `:accountID/message/:messageID/[reply|reply-all|forward]`

The second one open the composer preset in the conversation context.

Then, first draft save occurs (can be manual or automatic), except if you send the message faster than the auto-save. You then have a draft saved, on which you're currently working. The URL then update's *using a `replaceState`* (not a `pushState`) to reflect the new state to `:accountID/message/:draftID/edit` (where `:draftID` is a `:messageID` which point to the current draft).

It introduces the `edit` URL message's suffix: it can _only_ concerns _drafts messages_, and means the draft is open in the composer view (so in write mode). Without it, the message is open in consult mode, like any other message in any other mailbox. If you try to add the `edit` suffix to any other message than a draft, it'll fallback to the URL without `edit`, say in read mode.

You can open the composer in a popup view (see some [mockups](https://luc.cozycloud.cc/public/files/folders/1c8970b0935a9c8622cc2510ca0d7c2a#folders/1c8970b0935a9c8622cc2510ca0d8257)), using a `compose` query param. It can be specified to set the context:

- `new` or _empty_: open an empty composer popup to create a new message
- `:draftID`: open the composer with the content of the draft (where `:draftID` is the draft's `:messageID`)
- `:messageID::mode`: open the composer in a preset mode from the given message (e.g. `?compose=f45aec:reply` open the popup composer preset to _reply_ to the `f45aec` message)

### _Filters_ case

Filters let user reduce its message list. It uses a query param (`filters`) to set which filters activate or not. It can be:

- a simple string: `?filters=unseen` returns the _unread_ messages in the list
- a comma-separated string: `?filters=unseen,attach` returns the _unread_ messages with _attachments_ in the list
- an inverted string: `?filters=!attach` returns messages _without attachments_
- which can be composed: `?filters=starred,!attach` returns _favorites_ messages _without attachment_

Complex filters (in opposite to boolean filters like previous) can have parameters by suffixing the filter name with params, separated with colons. E.g. with the _date_ filter :

- `?filters=date:20160227:20160301` returns messages between _2016/02/27_ and _2016/03/01_ included
- `?filters=date:20160227` returns messages since _2016/02/27_ included
- `?filters=date:20160227,unseen` returns only _unread_ messages since _2016/02/27_ included



[^1]: _Note_: what about a `NavBarURL` component that updates the browser URL bar according to the stores?
