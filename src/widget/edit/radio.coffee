class cola.RadioGroup extends cola.AbstractEditor
	@tagName: "c-radio-group"
	@className: "ui radio-group"
	@attributes:
		items:
			expressionType: "repeat"
			setter: (items)->
				if typeof items is "string"
					items = items.split(/[,;]/)
					for item, i in items
						index = item.indexOf("=")
						if index >= 0
							items[i] =
								key: item.substring(0, index)
								value: item.substring(index + 1)

				if not @_valueProperty and not @_textProperty
					result = cola.util.decideValueProperty(items)
					if result
						@_valueProperty = result.valueProperty
						@_textProperty = result.textProperty

				@_items = items
				unless @_itemsTimestamp == items?.timestamp
					if items then @_itemsTimestamp = items.timestamp
					delete @_itemsIndex
				return

		valueProperty: null
		textProperty: null
		name: null

	_initDom: (dom)->
		super(dom)
		selector = @
		$(dom).delegate(">item", "click", ()->
			if selector._readOnly then return
			value = selector._getDomValue(this)
			if selector._setValue(value)
				selector._select(value)
		)

	_doRefreshDom: ()->
		super()
		@_classNamePool.toggle("readonly", !!@_finalReadOnly)
		itemsDom = @_getItemsDom()
		if itemsDom
			$fly(@_dom).empty().append(itemsDom)
		value = @_value
		@_select(value)
		return

	_select: (value)->
		if typeof value == "undefined"
			return
		dom = $(@_dom).find("[value='" + value + "']")
		if dom.length > 0
			dom[0].checked = true

	_getDomValue: (itemDom)->
		item = cola.util.userData(itemDom, "item")
		if not item
			item = cola.util.getItemByItemDom(itemDom)

		if item
			if item instanceof cola.Entity
				return item.get(@_valueProperty)
			return item[@_valueProperty]

	_getItemsDom: ()->
		attrBinding = @_elementAttrBindings?["items"]
		@_name ?= ("name_" + cola.sequenceNo());
		if attrBinding
			textProperty = "item." + (@_textProperty or "value")
			valueProperty = "item." + (@_valueProperty or "key")

			raw = attrBinding.expression.raw
			itemsDom = cola.xRender({
				tagName: "item",
				"c-repeat": "item in " + raw,
				content: [
					{
						tagName: "input",
						name: @_name,
						type: "radio",
						"c-value": valueProperty
					},
					{
						tagName: "label",
						"c-bind": textProperty
					}
				]
			}, attrBinding.scope)
		else
			if @_items
				itemsDom = document.createDocumentFragment()
				$itemsDom = $(itemsDom)
				for item in @_items
					$itemsDom.xAppend(
						tagName: "item",
						content: [
							{
								tagName: "input",
								name: @_name,
								type: "radio",
								value: item[@_valueProperty or "key"]
							},
							{
								tagName: "label",
								content: item[@_textProperty or "value"]
							}
						]
						userData:
							item: item
					)
		return itemsDom

cola.registerWidget(cola.RadioGroup)