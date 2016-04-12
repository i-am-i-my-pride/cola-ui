class cola.DateGrid extends cola.RenderableElement
	@CLASS_NAME: "calendar"
	@attributes:
		columnCount:
			type: "number"
			defaultValue: 7
		rowCount:
			type: "number"
			defaultValue: 6
		cellClassName: null
		selectedCellClassName: ""
		rowClassName: null
		autoSelect:
			defaultValue: true
		tableClassName:
			defaultValue: "ui date-table"

	@events:
		cellClick: null
		refreshCellDom: null

	_initDom: (dom)->
		picker = @
		columnCount = @_columnCount
		rowCount = @_rowCount
		@_doms ?= {}
		allWeeks = cola.resource("cola.date.dayNamesShort")
		weeks = allWeeks.split(",")
		headerDom = $.xCreate({
			tagName: "div"
			content: [
				{
					tagName: "div"
					class: "header"
					contextKey: "header"
					content: [
						{
							tagName: "div"
							class: "month"
							content: [
								{
									tagName: "span"
									class: "button prev"
									contextKey: "prevMonthButton"
									click: ()->
										picker.prevMonth()
								}
								{
									tagName: "span"
									class: "button next"
									contextKey: "nextMonthButton"
									click: ()->
										picker.nextMonth()
								}
								{
									tagName: "div"
									class: "label"
									contextKey: "monthLabel"

								}
							]
						}
						{
							tagName: "div"
							class: "year"
							content: [
								{
									tagName: "span"
									class: "button prev"
									contextKey: "prevYearButton"
									click: ()->
										picker.prevYear()
								}
								{
									tagName: "span"
									class: "button next"
									contextKey: "nextYearButton"
									click: ()->
										picker.nextYear()
								}
								{
									tagName: "div"
									class: "label"
									contextKey: "yearLabel"
								}
							]
						}
					]
				}
				{
					tagName: "table"
					cellPadding: 0
					cellSpacing: 0
					border: 0
					class: "date-header"
					contextKey: "dateHeader"
					content: [
						{
							tagName: "tr"
							class: "header"
							content: [
								{
									tagName: "td"
									content: weeks[0]
								}
								{
									tagName: "td"
									content: weeks[1]
								}
								{
									tagName: "td"
									content: weeks[2]
								}
								{
									tagName: "td"
									content: weeks[3]
								}
								{
									tagName: "td"
									content: weeks[4]
								}
								{
									tagName: "td"
									content: weeks[5]
								}
								{
									tagName: "td"
									content: weeks[6]
								}
							]
						}
					]
				}
			]
		}, @_doms)
		table = $.xCreate({
			tagName: "table"
			cellSpacing: 0
			class: "#{picker._className || ""} #{picker._tableClassName || ""}"
			content: {
				tagName: "tbody",
				contextKey: "body"
			}
		}, @_doms)

		i = 0
		while i < rowCount
			tr = document.createElement("tr")
			j = 0
			while j < columnCount
				td = document.createElement("td")
				td.className = @_cellClassName if @_cellClassName
				@doRenderCell(td, i, j)
				tr.appendChild(td)
				j++
			tr.className = @_rowClassName if @_rowClassName
			@_doms.body.appendChild(tr)
			i++

		$fly(table).on("click", (event)->
			position = cola.calendar.getCellPosition(event)
			if position and position.element
				return if position.row >= picker._rowCount
				if picker._autoSelect
					picker.setSelectionCell(position.row, position.column)

				picker.fire("cellClick", picker, position)
		)
		dom.appendChild(headerDom)
		@_doms.tableWrapper = $.xCreate({
			tagName: "div"
			class: "date-table-wrapper"
		})
		@_doms.tableWrapper.appendChild(table)
		dom.appendChild(@_doms.tableWrapper)
		return dom

	doFireRefreshEvent: (eventArg) ->
		@fire("refreshCellDom", @, eventArg)
		return @
	refreshHeader: ()->
		if @_doms
			monthLabel = @_doms.monthLabel
			yearLabel = @_doms.yearLabel
			$fly(yearLabel).text(@_year || "")
			$fly(monthLabel).text(@_month + 1 || "")
	refreshGrid: ()->
		picker = @
		dom = @_doms.body
		columnCount = @_columnCount
		rowCount = @_rowCount
		lastSelectedCell = @_lastSelectedCell

		if lastSelectedCell
			$fly(lastSelectedCell).removeClass(@_selectedCellClassName || "selected")
			@_lastSelectedCell = null

		i = 0
		while i < rowCount
			rows = dom.rows[i]
			j = 0
			while j < columnCount
				cell = rows.cells[j]
				cell.className = picker._cellClassName if picker._cellClassName
				eventArg =
					cell: cell
					row: i
					column: j

				@doFireRefreshEvent(eventArg)

				@doRefreshCell(cell, i, j) if eventArg.processDefault != false
				j++
			i++
		return @
	_doRefreshDom: ()->
		super()
		return unless @_dom
		@refreshGrid()
		@refreshHeader()
	setSelectionCell: (row, column)->
		picker = this
		lastSelectedCell = @_lastSelectedCell

		unless @_dom
			@_selectionPosition = {row: row, column: column}
			return @
		if lastSelectedCell
			$fly(lastSelectedCell).removeClass(@_selectedCellClassName || "selected")
			@_lastSelectedCell = null
		tbody = picker._doms.body
		if tbody.rows[row]
			cell = tbody.rows[row].cells[column]
		return @ unless cell
		$fly(cell).addClass(@_selectedCellClassName || "selected")
		@_lastSelectedCell = cell
		return @
	getYMForState: (cellState)->
		month = @_month
		year = @_year
		if cellState.type == "prev-month"
			year = if month == 0 then year - 1 else year
			month = if month == 0 then 11 else month - 1
		else if cellState.type == "next-month"
			year = if month == 11 then year + 1 else year
			month = if month == 11 then 0 else month + 1

		return {
		year: year
		month: month
		}

	doFireRefreshEvent: (eventArg)->
		row = eventArg.row
		column = eventArg.column
		if @_state && @_year && @_month
			cellState = @_state[row * 7 + column]
			ym = @getYMForState(cellState)
			eventArg.date = new Date(ym.year, ym.month, cellState.text)
		@fire("refreshCellDom", @, eventArg)
		return @

	doRenderCell: (cell, row, column)->
		label = document.createElement("div")
		label.className = "label"
		cell.appendChild(label)

		return
	getDateCellDom: (date)->
		value = new XDate(date).toString("yyyy-M-d")
		return $(@_dom).find("td[cell-date='#{value}']")[0]

	setCurrentDate: (date)->
		month = date.getMonth()
		year = date.getFullYear()
		@setState(year, month)
		@selectCell(@getDateCellDom(date))

	selectCell: (cell)->
		lastSelectedCell = @_lastSelectedCell
		unless @_dom
			return @
		if lastSelectedCell
			$fly(lastSelectedCell).removeClass(@_selectedCellClassName || "selected")
			@_lastSelectedCell = null
		return @ unless cell
		$fly(cell).addClass(@_selectedCellClassName || "selected")
		@_lastSelectedCell = cell

	doRefreshCell: (cell, row, column) ->
		state = @_state
		return unless state

		cellState = state[row * 7 + column]
		$fly(cell).removeClass("prev-month next-month").addClass(cellState.type).find(".label").html(cellState.text)
		ym = @getYMForState(cellState)
		$fly(cell).attr("cell-date", "#{ym.year}-#{ym.month + 1}-#{cellState.text}")


	setState: (year, month)->
		oldYear = @_year
		oldMonth = @_month

		if oldYear != year || oldMonth != month
			@_year = year
			@_month = month

			@_state = cola.getDateTableState(new Date(year, month, 1))
			if @_dom
				@refreshGrid()
				@refreshHeader()
		@onCalDateChange()
	prevMonth: ()->
		year = @_year
		month = @_month

		if year != undefined && month != undefined
			newYear = if month == 0 then year - 1 else year
			newMonth = if month == 0 then 11 else month - 1

			@setState(newYear, newMonth)
		return @

	nextMonth: ()->
		year = @_year
		month = @_month

		if year != undefined && month != undefined
			newYear = if month == 11 then  year + 1 else year
			newMonth = if  month == 11 then 0 else month + 1

			@setState(newYear, newMonth)
		return @

	prevYear: ()->
		year = @_year
		month = @_month

		@setState(year - 1, month) if year != undefined && month != undefined
		return @

	setYear: (newYear)->
		year = @_year
		month = @_month
		@setState(newYear, month) if year != undefined && month != undefined

	nextYear: ()->
		year = @_year
		month = @_month

		@setState(year + 1, month) if year != undefined && month != undefined
		return @
	onCalDateChange: () ->
		return @ unless @_dom

		return @
DEFAULT_DATE_DISPLAY_FORMAT = "yyyy-MM-dd"
DEFAULT_DATE_INPUT_FORMAT = "yyyyMMdd"
DEFAULT_TIME_DISPLAY_FORMAT = "HH:mm:ss"
DEFAULT_TIME_INPUT_FORMAT = "HHmmss"
class cola.DatePicker extends cola.CustomDropdown
	@attributes:
		displayFormat:
			defaultValue:DEFAULT_DATE_DISPLAY_FORMAT
		inputFormat:
			defaultValue:DEFAULT_DATE_DISPLAY_FORMAT
		icon:
			defaultValue: "calendar"
		content:
			$type: "calender"
		inputType:
			defaultValue: "date"
	@events:
		focus: null
		blur: null
		keyDown: null
		keyPress: null
	_initDom: (dom)->
		super(dom)
		doPost = ()=>
			readOnly = @_readOnly
			if !readOnly
				value = $(@_doms.input).val()
				inputFormat = @_inputFormat or @_displayFormat or DEFAULT_DATE_DISPLAY_FORMAT
				if inputFormat
					value = inputFormat + "||" + value
					xDate = new XDate(value)
					value = xDate.toDate()
					@set("value", value)
			return

		$(@_doms.input).on("change", ()=>
			doPost()
			return
		).on("focus", ()=>
			@_inputFocused = true
			@_refreshInputValue(@_value)
			@addClass("focused") if not @_finalReadOnly
			@fire("focus", @)
			return
		).on("blur", ()=>
			@_inputFocused = false
			@removeClass("focused")
			@_refreshInputValue(@_value)
			@fire("blur", @)

			if !@_value? or @_value is "" and @_bindInfo?.isWriteable
				propertyDef = @_getBindingProperty()
				if propertyDef?._required and propertyDef._validators
					entity = @_scope.get(@_bindInfo.entityPath)
					entity.validate(@_bindInfo.property) if entity
			return
		).on("keydown", (event)=>
			arg =
				keyCode: event.keyCode
				shiftKey: event.shiftKey
				ctrlKey: event.ctrlKey
				altlKey: event.altlKey
				event: event
			@fire("keyDown", @, arg)
		).on("keypress", (event)=>
			arg =
				keyCode: event.keyCode
				shiftKey: event.shiftKey
				ctrlKey: event.ctrlKey
				altlKey: event.altlKey
				event: event
			if @fire("keyPress", @, arg) == false then return

			if event.keyCode == 13 && isIE11 then doPost()
		)
		return
	_refreshInputValue: (value) ->
		inputType = @_inputType

		if value instanceof Date
			if inputType is "date"
				format = DEFAULT_DATE_DISPLAY_FORMAT
			else if inputType is "time"
				format = DEFAULT_TIME_DISPLAY_FORMAT

			value = (new XDate(value)).toString(format)
		return super(value)
	_refreshInput: ()->
		$inputDom = $fly(@_doms.input)
		$inputDom.attr("name", @_name) if @_name
		$inputDom.attr("placeholder", @get("placeholder"))
		$inputDom.prop("readOnly", @_finalReadOnly)
		@get("actionButton")?.set("disabled", @_finalReadOnly)
		$inputDom.prop("type", "text").css("text-align", "left")

		@_refreshInputValue(@_value)
		return
	open: () ->
		super()
		value = @get("value")
		unless value
			value = new Date()
		@_dataGrid.setCurrentDate(value)
	_getDropdownContent: () ->
		datePicker = @
		if !@_dropdownContent
			@_dataGrid = dateGrid = new cola.DateGrid({
				cellClick: (self, arg)=>
					value = $fly(arg.element).attr("cell-date")

					d = Date.parse(value)
					datePicker.close(new Date(d))
			})
			@_dropdownContent = dateGrid.getDom()


		return @_dropdownContent