# Routes

This documents lists for legacy and v2 app the routes and redirects in use. Its goal is to provide an exhausting view of contexts in the application and prevent bypass actions that'll break the app consistency.

## Routes

- `account/new`
  : creates a new account

- `:accountID/settings/:section`
  : access the settings for the given account, scoped to the specified section (e.g. `gmail/settings/general`)

- `mailbox/:mailboxID`
  : display the content of a mailbox (i.e. the conversations list). Can be customized using _queryString_ parameters:
  - `?filters=[:filters]`
    : filter conversations list, can be a list of filters (e.g. `flagged` AND/OR `attach` AND/OR `unread`)
  - `?sort=:column:[ASC|DESC]`
    : set the sorting order and on which criteria for the list (e.g. `gmail/inbox?sort=sender:ASC` sort messages from gmail's inbox by sender address, ascending)

- `mailbox/:mailboxID/new`
  : opens the compose editor to create a new message from the given account

- `mailbox/:mailboxID/:messageID`
  : open the requested message, i.e. the main view has the conversations list in the first pane, and the conversation which the message belongs to in the second pane, with the message open
    - `/reply`
      : open the composition view with the message's conversation context in reply mode
    - `/reply-all`
      : same as above, in reply-all mode
    - `/forward`
      : same as above, in forward mode

- `mailbox/:mailboxID/*?compose=[new|:messageID[::mode]]`
  : any URL can be queried with a `compose` param, which opens the composition's popup view. See _drafts_ section below for more informations.

- `search/[:accountID]`
  : switch the main view to the search results list. Can be filtered / sorted like a `:mailbox` list. If the `:accountID` is provided, then the search is scoped to this account. Else, the search is global across all mailboxes
  - `?q=:pattern`
    : the query pattern to search for


### _Drafts_ case
The URLs must reflect the application state, so that writing a message observes those 2 steps:

1. you first open the composer: `:mailbox/:mailboxID/new`,
2. 1rst change will trigger a 1rst save to get its `id`: `:mailbox/:mailboxID/:messageID`


<!-- You could open the composer in a popup view (see some [mockups](https://luc.cozycloud.cc/public/files/folders/1c8970b0935a9c8622cc2510ca0d7c2a#folders/1c8970b0935a9c8622cc2510ca0d8257)), using a `compose` query param. It can be specified to set the context: -->
<!-- - `:messageID::mode`: open the composer in a preset mode from the given message (e.g. `?compose=f45aec:reply` open the popup composer preset to _reply_ to the `f45aec` message) -->

### _Filters_ case

#### Fields
Messages list can be reduced by its:
 - date with `before` and `after` query parameters,
 - type with `flags` query parameters.

 #### Use cases
- a simple string: `?flags=unseen` returns the _unread_ messages in the list
- a comma-separated string: `?flags=unseen,attach` returns the _unread_ messages with _attachments_ in the list
- an inverted string: `?flags=!attach` returns messages _without attachments_
- which can be composed: `?flags=starred,!attach` returns _favorites_ messages _without attachment_

Complex filters (in opposite to boolean filters like previous) can have parameters by suffixing the filter name with params, separated with colons. E.g. with the _date_ filter :

- `??before=2016-04-03T22:00:00.000Z&after=2016-04-04T21:59:59.999Z`: returns messages from _2016-04-04_,
- `?before=2016-04-03T22:00:00.000Z`: returns messages since _2016/04/24_ included,
- `?before=2016-04-03T22:00:00.000Z&flags=unseen`: returns only _unread_ messages since _2016/04/24_ included.


## Redirection

Redirection is handled after updating `RouterStore`. Here is the list of properties that should update URL :
 - `action`: get from `routes` the right URL pattern,
 - `mailboxID`: the ID of the mailbox,
 - `MessageID`: the ID of selected message,
 - `query` : filters into messages list,
 - `tab` : change `tabComponent` (ie. `accountEdit`)

 Whats happening into `routerStore`:

 Each property related to route is changed after `ActionTypes.ROUTE_CHANGE` into `routerStore` file. After all updates are done, the URL is updated if needed :

 ```
 currentURL = @getCurrentURL isServer: false
 if location.hash isnt currentURL
     _router.navigate currentURL
```
