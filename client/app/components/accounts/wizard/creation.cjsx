{IMAP_OPTIONS} = require '../../../constants/defaults'

React = require 'react'

Form    = require '../../basics/form'
Servers = require '../servers'


module.exports = AccountWizardCreation = React.createClass

    displayName: 'AccountWizardCreation'


    getInitialState: ->
        isOAuth: false
        isDiscoverable: true


    render: ->
        <section className='settings'>
            <h1>{t('account wizard creation')}</h1>

            <Form ns="account-wizard-creation" className="content">
                <Form.Input type="text"
                            name="email"
                            label={t('account wizard creation email label')} />
                <Form.Input type="password"
                            name="password"
                            label={t('account wizard creation password label')} />

                <Servers expanded={!@state.isDiscoverable}
                         legend={t('account wizard creation advanced parameters')} />
            </Form>

            <footer>
                <nav>
                    <a role="button" href="#">{t('account wizard creation save')}</a>
                </nav>
            </footer>
        </section>
