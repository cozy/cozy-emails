# Legacy

This document list legacy behaviors, and code and patterns from the **v1 version** of email application. Its purpose it to let future developments aware of the contexts of our previous choices.


## Routes

Every routes has a `/*secondPanel` suffixed version, which signify each route can be passed a second time as a _suffix_ of the main route and point to what content the app should display in the second (_right_) panel view (i.e. you can have the mailbox config open sided by a message with a url like `account/:accountID/config/:tab/message/:messageID` which is useless and unwanted, but still works).

- `/`
  : Default route, does nothing

- `account/new`
  : account creation

- `account/:accountID/config/:tab`
  : Account configuration, scoped to a given tab (account, folder, signature)

- `account/:accountID/mailbox/:mailboxID/sort/:sort/:type/:flag/before/:before/after/:after`
  : Messages list for a give account, eventually filtered and sorted

- `account/:accountID/search/:search`
  : Seach messages in an account

- `message/:messageID`
  : display a given message

- `conversation/:conversationID/:messageID/`
  : display conversation view, eventually scoped on a particular message

- `compose`
  : new composition message

- `compose/edit/:messageID`
  : edit message (as a draft) in composition

- `edit/:messageID`
  : same as `compose/edit/:messageID`

- `reply-all/:messageID`
  : compose message in _reply all_ mode

- `reply/:messageID`
  : compose message in _reply mode_

- `forward/:messageID`
  : compose message in forward mode

## Redirects

There's severals _redirects_ inside the application to switch to another view, generally after a successful action (which isn't what we want, as long as _requests_ should handle the success state - like creating a new account - which is considered as a new _action_ in flux pattern).

- `checkAccount`
  : when a new account is created, redirect to the main account message list view

- `Compose#finalRedirect`
  : when finish a _compose_, redirect the message if in a _reply_ context, or to the account message list if not

- `Compose#sendActionMessage`
  : if the message isn't sent after _compose_, redirect back to the compose edit view

- `MessageListItem`
  : redirect the whole view to a built URL in context when clicking on a message in the list

- `Message#onDelete`, `ToolbarMessage#onDelete`
  : redirect to the next conversation (or close the panel if there's not) after deletion

- `Panel#renderList`
  : redirect to the first available account if the requested account isn't available

- `SearchBar#onSearchTriggered`, `SearchBar#onAccountChanged`
  : redirect to the search view if account exists, or fallback to the first available account in list mode if there's not

- `ToolbarConversation#goto*`
  : redirect to the next / prev conversation into the list or close the panel if the target conversation isn't available

- `ToolbarMessagesList#onFilterChange`
  : redirect to the filter view according to the parameters when filters params changed
