should = require('chai').Should

router = require '../app/router'

describe '#Router', ->

    describe 'Pattern loading', ->

        describe 'When a pattern is declared', ->
            it 'it should load the pattern itself'
            it 'it should load the extend pattern'

    describe 'Subrouting', ->
        describe 'Single route with no parameter'
        describe 'Single route with one parameter'
        describe 'Single route with multiple parameters'

        describe 'Dual routes with no parameter vs no parameter'
        describe 'Dual routes with one parameter vs no parameter'
        describe 'Dual routes with multiple parameters vs no parameter'

        describe 'Dual routes with no parameter vs one parameter'
        describe 'Dual routes with one parameter vs one parameter'
        describe 'Dual routes with multiple parameters vs one parameter'

        describe 'Dual routes with no parameter vs multiple parameters'
        describe 'Dual routes with one parameter vs multiple parameters'
        describe 'Dual routes with multiple parameters vs multiple parameters'

