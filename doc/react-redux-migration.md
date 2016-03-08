# React/Redux Migration


## Objectifs

Définir des règles pour que le code soit :
- lisible
- cohérent
- compréhensible
- robuste
- testable
- faciliter le transfert de compétences

### Plans alternatifs

**Approche from-scratch**

1. On part sur des bases saines (à définir)
2. le serveur est déjà là
3. le css aussi.

Fort de notre expérience React, on réimplémente toute la logique client fonction par fonction

**Approche give-up**

Si on renonce au _use-case_ que les autres apps accèdent aux email & que la recherche sur le cozy inclue les emails, il y a whiteout qui marche :smile:.


## Plan pour nettoyage du "socle" de Email

### Stores

#### Structure

Au final, la structure des _stores_ devrait être :

- AppStateStore
- LayoutStore (temporaire, avant routing)
- ModalStore
- NotifsStore
- RequestsInFlightStore
- AccountsStore
- MessagesStore
- ContactsStore
- CountersStore
- LastRefreshStore
- SettingsStore

#### Découpage

1. Diviser le LayoutStore :
     - ModalStore : contient les messages de confirmation
     - NotifStore
     - LayoutStore : store temporaie pour gérer les états de layouts avant la stabilisation des routes
2. Ne plus avoir de `_currentX` dans les stores de models (ils représentent un état, pas une donnée) ; les déplacer dans un `AppStateStore`
3. Séparer les _compteurs_ / _lastRefresh_ / _champs_ qui changent souvent : les isoler dans un store dédié pour éviter des refreshs trop agressifs
4. Avoir un store des _requêtes in flight_ : rassembler les références aux requêtes pour gérer un journal de transactions capable de _rollback_ / _undo_ / etc les actions serveur
5. Déplacer les alert des `action_creator` vers le `NotifStore`

#### Bonnes pratiques

- Utiliser des `Immutable.Record` pour les models
- Utiliser des `Immutable.OrderedMap` (`id` -> `object`) pour toutes les listes
- Mettre en place des `PropTypes` correct
- Mettre en place les tests unitaires des stores : prendre un store chargé ou pas, lui envoyer des actions et voir son nouvel état. _Next_ : Utiliser `afterEach: -> React.render(Application)` qui détectera si un état casse le render.
- Résoudre conflit dovecot-testing vm-dev & vm-vagrant avec cozy-dev


### Solidifier le Routing

_Note:_ pas de `react-router` qui met l'abstraction au mauvais endroit et ne gère pas les panels.

1. Diviser `panel.coffee` en `message-list-panel.coffee`, `compose-panel.coffee`… c'est à dire des composants _controllers_ indépendant qui gère leur état avec `getStateFromStore`, etc
2. Mettre le reste de la logique (i.e. choix du panel) dans `application.coffee`
3. Modifier `panel_router` : Faire `app.dispatch "ROUTE_CHANGE", panels` plutot que `LayoutActionCreator[pattern.fluxAction]`, l'AppStateStore handle `"ROUTE_CHANGE"` et change son état comme un store normal
4. Possibilité de remplacer  Backbone.router + panel_router par une lib (https://github.com/mjackson/history ?) si on trouve notre bonheur (gestion des panels + modal)
5. gestions des redirections implicites : e.g. AppStateStore handle `"MESSAGE_DELETE_SUCCESS"`, change `_currentMessage` dans son état, ça déclenche un render
6. Un composant `<NavBarURLChanger currentURL="xxxx">` fait le changement d'url: i.e. la navbar du browser est vue comme un composant de l'app
7. Considérer lier modal <-> URL : la modale est appelée via une `queryString`, elle représente un état transitoire d'une vue et est un composant transverse, pas une vue en soit
8. Déplacer les router.navigate des `action_creator` vers le `AppStateStore`
9. Finir de nettoyer les actions_creator
     - Supprimer les callback remplacer par des actions si nécessaire (MESSAGE_SEND_SUCCESS, MESSAGE_SEND_FAILLURE)
     - S'assurer que tous les appels de CHANGEMENT ont les 3 actions (REQUEST, SUCCESS, FAILURE)
     - Utiliser cozysdk pour tous les appels de READ & WRITE n'impliquant que le DS
     - Plus d'actions : Ne pas hésiter à avoir plusieurs actions plutôt que du bricolage avec les types
10. Mettre en place les tests unitaires du routing: identique à ceux des stores, on envoie des `"ROUTE_CHANGE"` et on regarde comment les stores réagissent ; on déclenche des action `"MESSAGE_DELETE_SUCCESS"` et on mock `NavBarURLChanger` pour voir si c'est bon.


### Séparer les getters

À faire store par store. La logique de getting est actuellement dans `components#getStateFromStore` & `store.getXXXX`.

1. Rassembler dans des fichiers getters/xxxxx par composant
2. Eventuellement quelques getters/common_xxxxx pour les getters utilsé par plusieurs composants
3. Préparer l'optimisation : les getters doivent permettre d'utiliser un _memoizer_ genre `lib/cached_transform` ou https://optimizely.github.io/nuclear-js/docs/07-api.html#-reactor-evaluate-getter-keypath- ou https://github.com/reactjs/reselect.
4. Rendre les variables des store publiques, mais s'interdire de les utiliser en dehors des getters.
5. Supprimer le mixinRouter & déplacer buildURL dans le getter ApplicationState
6. Corriger les tests unitaires des stores
7. Ajouter des tests sur les getters complexes

A la fin de cette étape, les store ne devraient plus être que:

```
state =
    _privateVar1

    _privateVar2


handle action, ->
    state._privateVar1 = yolo
```

ce qui simplifie la conversion en _reducers_ pour un passage ultérieur à Redux.


### Nettoyage des vues

Cleanup du reste des composants.

_Objectif :_ tous les composants sont des `PureRender`, beaucoup sont des https://facebook.github.io/react/docs/reusable-components.html#stateless-functions

1. Séparerles composants en 2 groupes : composants atomiques représentant un élément d'Ui ; composants de vue (i.e. _controllers_) qui sont un agrégat des composants atomiques
2. Modulariser les composant : si un problème peut-être résolu en manipulant du state / en faisant un map & bind ou en faisant un sous composant, préférer le sous composant (ex. dropdown items)
3. Découper les mixins : s'il y a un behaviour un peu complexe avec beaucoup de code, on peut le bouger dans un mixin pour garder le composant minimaliste (ex. selection)
4. Isoler les `StoreWatchMixin` : seul les composants "controllers", ie menu / message-list-panel / compose-panel / etc devraient avoir un `StoreWatchMixin`
5. Supprimer `ShouldUpdate.UnderscoreEqualitySlow` au profit de https://facebook.github.io/react/docs/pure-render-mixin.html
6. Retirer les modales dans les composants: appeler une action `"DELETE_BTN_CLICKED"`, que le ModalStore décide d'afficher (changement d'état) ou de convertir en `"DELETE"` en fonction de son état initial

#### Bonnes pratiques

- Pas de complexité dans `getStateFromStore` : la logique est dans les getters
- Limiter le state : avoir du state dans les composants cause des problèmes, ne pas hésiter à boucler par un store. (e.g. compose avec état du draft vs composant affiché ou pas = draft perdu)
- Préférer les sous composants si un composant devient trop gros : les sous composants interrompent le render inutile.
- Les props sont ce que l'on reçoit du parent, on ne peut pas changer les props.
- Pas de fetch de data dans le composant (e.g. https://github.com/cozy/cozy-emails/pull/772/files#diff-2d5b613f2377b82969f74c49bbab4995L231)
- Éviter au maximum les fonctions anonymes et bind
- Éviter de passer un trop grand nombre de `props`

#### Tests

Les tests unitaires ne sont pas utiles si les stores et getters sont bien testés. Tester les composants lors des tests de states doit être suffisant.


### Activités & plugins

Couche d'abstraction sur certaines fonctionnalités de l'app / interaction qui contreviennent à l'archi de l'app.

On peut imaginer offrir une vraie API de plugins pour étendre le core de l'app, mais les features natives (comme la nav clavier, l'éditeur, etc) ne doivent pas être dépendantes de cette API.


### Coté serveur

- Rétablir le serveur stateless (préparation partenariat hébergeurs premium)
- Supprimer toutes les routes qui ne sont que proxy au DS, remplacée par cozysdk ; ne devrait rester que les actions IMAP
- Eventuellement, changer l'API de CHANGEMENT pour matcher JMAP
- Transformer en service DS


## Evolutions

### Passage à Redux

Redux est cool pour la beauté des stores.

Le nettoyage permet de facilement convertir vers des reducers et les actions_creator facliteront la migration.

Le véritable intérêt est dansla traction offerte par la communauté ppour ajouter facilement des features qui ne serait pas triviales dans notre archi ou auxquelles on n'aurait pas pensé en amont (offline, etc).

Est-ce qu'on préfère thunk/promise middleware vs les actions creator tels qu'on les a actuellement (après nettoyage) ou même un simple helper `wrapActions('MESSAGE_FETCH', (cb) -> XHRUtils.fetchMessagesByFolder url, cb)` ?


### Réorganisation par sujet ?

```txt
store/message
getters/message-list
components/message-list
components/message
components/message-list-toolbar
```

vs

```txt
message/store
message/getters
message/message-list-component
message/message-list/item-component
message/message-list/toolbar-component
```


### Passage à JSX ?

**Pour**

- syntactic suger un peu (beaucoup) magique sur React
- suppression des createFactory
- Webpack hot replacement
- lisibilité du markup

**Contre**

- Beaucoup de réécriture

Dans la logique des faiblesse qui sont des force, rester en coffee nous oblige à avoir des composants propres & minimaux. Le passage à JSX est intéressant dans ce qu'il fait gagner en précision et en concision du code. La migration peut se faire au fil de l'eau en travaillant indépendamment sur chaque composant selon les besoins.


### Test fonctionnels

Les tests fonctionnels peuvent assurer du bon déroulement d'un scénario utilisateur une fois la feature développée pour assurer la non-régression mais ne constitue pas une priorité.
