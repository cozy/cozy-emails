{div, ul, li, span, i, button, input} = React.DOM
{Tooltips} = require '../constants/app_constants'


module.exports = DateRangePicker = React.createClass
    displayName: 'DateRangePicker'

    getInitialState: ->
        label: t 'daterangepicker placeholder'


    render: ->
        div
            role:                     'menuitem'
            className:                'dropdown date-range-picker'
            'aria-describedby':       Tooltips.FILTER_DATE_RANGE
            'data-tooltip-direction': 'bottom'

            button
                className:     'dropdown-toggle'
                'data-toggle': 'dropdown'

                i className: 'fa fa-calendar'
                span className: 'btn-label',
                    "#{@state.label} "
                span className: 'caret'

            div className: 'dropdown-menu',
                ul className: 'presets list-unstyled',
                    li role: 'presentation',
                        button
                            role: 'menuitem'
                            t 'daterangepicker presets yesterday'

                    li role: 'presentation',
                        button
                            role: 'menuitem'
                            t 'daterangepicker presets last week'

                    li role: 'presentation',
                        button
                            role: 'menuitem'
                            t 'daterangepicker presets last month'

                input
                    ref:  "date-range-picker-start"
                    id:   "date-range-picker-start"
                    name: "date-range-picker-start"
                    type: 'date'

                input
                    ref:  "date-range-picker-end"
                    id:   "date-range-picker-end"
                    name: "date-range-picker-end"
                    type: 'date'

    # Add third party datepicker to start and end date fields
    initDatepicker: ->
        options =
            staticPos:    true
            fillGrid:     true
            hideInput:    true

        datePickerController.createDatePicker _.extend {}, options,
            formElements: 'date-range-picker-start': '%d/%m/%Y'

        datePickerController.createDatePicker _.extend {}, options,
            formElements: 'date-range-picker-end': '%d/%m/%Y'

    componentDidMount: ->
        @initDatepicker()

    componentDidUpdate: ->
        @initDatepicker()
