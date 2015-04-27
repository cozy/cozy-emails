should = require 'should'
React = require('react/addons')
TestUtils = React.addons.TestUtils

AccountInput = require '../app/components/account_config_input'

describe 'Account Config Input', ->

    component =  AccountInput
        name: 'imapServer'
        value: 'imap server default'
        errors: {}
        errorField: []
        onBlur: -> true
    renderTarget = document.getElementsByTagName('body')[0]
    renderedComponent = React.renderComponent component, renderTarget

    it 'buildMainClasses', ->
        classes = 'form-group account-item-test-name '
        builtClasses = renderedComponent.buildMainClasses({}, 'test-name')
        builtClasses.should.equal classes

    it 'render', ->
        labelComponent = TestUtils.findRenderedDOMComponentWithTag(
          renderedComponent,
          'label'
        )
        inputComponent = TestUtils.findRenderedDOMComponentWithTag(
          renderedComponent,
          'input'
        )

        should.exist labelComponent
        should.exist inputComponent
        inputComponent.props.type.should.equal 'text'
