module.exports = EmailStore = Fluxxor.createStore
    initialize: ->
        @emails = [

            {
                id: 1
                title: 'Question application Email'
                sender: 'joseph.silvestre@cozycloud.cc'
                receivers: ['frank.rousseau@cozycloud.cc']
                content: '''
                Salut Frank,

                J'ai une question concernant l'application Email : jusqu'à quel niveau doit-on gérer le responsive ?

                J'ai commencé à vouloir le faire très proprement mais je me suis dit la chose suivante : personne n'utilise un navigateur sur mobile pour regarder ses emails. Où je me trompe ?
                '''
                date: '12:38'
                isRead: true
                mailbox: 1
            },
            {
                id: 2
                title: 'Question application Email'
                sender: 'frank.rousseau@cozycloud.cc'
                receivers: ['joseph.silvestre@cozycloud.cc']
                content: '''
                Je pense que ce n'est utile que pour la démo mais bon c'est ce que les gens regardent en premier. Notre expérience mobile est assez mauvaise aujourd'hui (j'ai testé ça ce week-end, il n'y que contacts de bien). Du coup pour emails ce serait pas mal d'avoir quelque chose qui passe aussi (mais vas-y bourrin, quand ça ne rentre pas enlève des éléments/features).

                Pour le responsive on a en gros quatre tailles :

                - 1900px de large pour les grands écrans
                - 1200px de large pour les portables (En général ce qui passe bien sur 1200px passe bien sur 1900px)
                - 960px de large pour les tablettes (en fait ici on fait pour 720px mais on actionne à partir de 960px les modifs).
                - 480px de large pour les téléphones
                '''
                date: '12:38'
                isRead: true
                mailbox: 1
            }
        ]

    getAll: ->
        return @emails

    getByID: (emailID) -> _.findWhere @emails, id: parseInt emailID

    getEmailsByMailbox: (mailboxID) ->
        _.filter @emails, (email) -> return email.mailbox is mailboxID
