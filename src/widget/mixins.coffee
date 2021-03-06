###
Template
###

TEMP_TEMPLATE = null

cola.TemplateSupport =
	_templateSupport: true

	destroy: ()->
		if @_templates
			delete @_templates[name] for name of @_templates
		return

	_parseTemplates: ()->
		return unless @_dom
		child = @_dom.firstElementChild
		while child
			if child.nodeName is "TEMPLATE"
				@regTemplate(child)
			child = child.nextElementSibling
		@_regDefaultTemplates()
		return

	_trimTemplate: (dom)->
		child = dom.firstChild
		while child
			next = child.nextSibling
			if child.nodeType is 3	# TEXT
				if $.trim(child.nodeValue) is ""
					dom.removeChild(child)
			child = next
		return

	regTemplate: (name, template)->
		if arguments.length is 1
			template = name
			if template.nodeType
				name = template.getAttribute("name")
			else
				name = template.name
		@_templates ?= {}
		@_templates[name or "default"] = template
		return

	_regDefaultTemplates: ()->
		for name, template of @constructor.templates
			if @_templates?.hasOwnProperty(name) or not template
				continue
			@regTemplate(name, template)

		superClass = @constructor.__super__?.constructor
		while superClass
			if superClass.templates
				for name, template of superClass.templates
					if @_templates?.hasOwnProperty(name) or not template
						continue
					@regTemplate(name, template)
			superClass = superClass.__super__?.constructor
		return

	trimTemplate: (template)->
		if template.nodeType
			if template.nodeName is "TEMPLATE"
				if not template.firstChild
					html = template.innerHTML
					if html
						TEMP_TEMPLATE ?= document.createElement("div")
						template = TEMP_TEMPLATE
						template.innerHTML = html
				@_trimTemplate(template)
				if template.firstChild == template.lastChild
					template = template.firstChild
				else
					templs = []
					child = template.firstChild
					while child
						templs.push(child)
						child = child.nextSibling
					template = templs
		else
			@_doms ?= {}
			template = $.xCreate(template, @_doms)
			if @_doms.widgetConfigs
				@_templateContext ?= {}
				if @_templateContext.widgetConfigs
					widgetConfigs = @_templateContext.widgetConfigs
					for k, c of @_doms.widgetConfigs
						widgetConfigs[k] = c
				else
					@_templateContext.widgetConfigs = @_doms.widgetConfigs
		template._trimed = true
		return template

	getTemplate: (name = "default", defaultName)->
		return null unless @_templates
		template = @_templates[name]
		if not template and defaultName
			name = defaultName
			template = @_templates[name]

		if not template and typeof name is "string" and name.match(/^\#[\w\-\$]*$/)
			template = cola.util.getGlobalTemplate(name)

		if template and not template._trimed
			template = @trimTemplate(template)

		return template

	_cloneTemplate: (template, supportMultiNodes)->
		if template instanceof Array
			if supportMultiNodes and template.length > 1
				fragment = document.createDocumentFragment()
				for templ in template
					fragment.appendChild($fly(templ).clone(true, true)[0])
				return fragment
			else
				return $fly(template[0]).clone(true, true)[0]
		else
			return $fly(template).clone(true, true)[0]

cola.DataWidgetMixin =
	_dataWidget: true

	_bindSetter: (bindStr)->
		return if @_bind is bindStr

		if @_bindInfo
			bindInfo = @_bindInfo
			if @_watchingPaths
				for path in @_watchingPaths
					@_scope.data.unbind(path.join("."), @_bindProcessor)
			delete @_bindInfo

		@_bind = bindStr

		if bindStr and @_scope
			@_bindInfo = bindInfo = {}

			bindInfo.expression = expression = cola._compileExpression(@_scope, bindStr)
			bindInfo.writeable = expression.writeable
			bindInfo.writeablePath = expression.writeablePath

			if expression.repeat or expression.setAlias
				throw new cola.Exception("Expression \"#{bindStr}\" must be a simple expression.")
			if bindInfo.writeable
				i = bindInfo.writeablePath.lastIndexOf(".")
				if i > 0
					bindInfo.entityPath = bindInfo.writeablePath.substring(0, i)
					bindInfo.property = bindInfo.writeablePath.substring(i + 1)
				else
					bindInfo.entityPath = null
					bindInfo.property = bindInfo.writeablePath

			if not @_bindProcessor
				@_bindProcessor = {
					processMessage: (bindingPath, path, type, arg)=>
						if @_filterDataMessage
							if not @_filterDataMessage(path, type, arg)
								return
						else
							unless cola.constants.MESSAGE_REFRESH <= type <= cola.constants.MESSAGE_CURRENT_CHANGE or @_watchingMoreMessage
								return

						if @_bindInfo.watchingMoreMessage
							cola.util.delay(@, "processMessage", 100, ()->
								if @_processDataMessage
									@_processDataMessage(@_bindInfo.watchingPaths[0], cola.constants.MESSAGE_REFRESH, {})
								else
									@_refreshBindingValue()
								return
							)
						else
							if @_processDataMessage
								@_processDataMessage(path, type, arg)
							else
								@_refreshBindingValue()
						return
				}

			paths = expression.paths
			bindInfo.watchingMoreMessage = not paths and expression.hasComplexStatement and not expression.hasDefinedPath

			if paths
				@_watchingPaths = watchingPaths = []
				for p, i in paths
					@_scope.data.bind(p, @_bindProcessor)
					watchingPaths[i] = p.split(".")

				if @_processDataMessage
					@_processDataMessage(null, cola.constants.MESSAGE_REFRESH, {})
				else
					@_refreshBindingValue()
		return

	destroy: ()->
		if @_watchingPaths
			for path in @_watchingPaths
				@_scope.data.unbind(path.join("."), @_bindProcessor)
		return

	readBindingValue: (dataCtx)->
		return unless @_bindInfo?.expression
		dataCtx ?= {}
		if @_bindInfo.entityPath
			entity = @_scope.get(@_bindInfo.entityPath, "async")
			if entity
				if entity instanceof cola.Entity
					return entity.get(@_bindInfo.property, "async")
				else if entity instanceof cola.EntityList
					if entity.current
						return entity.current.get(@_bindInfo.property, "async")
				else if typeof entity is "object"
					return entity[@_bindInfo.property]
			dataCtx.readOnly = true
			return undefined
		else
			return @_bindInfo.expression.evaluate(@_scope, "async", dataCtx)

	writeBindingValue: (value)->
		return unless @_bindInfo?.expression
		if not @_bindInfo.writeable
			throw new cola.Exception("Expression \"#{@_bind}\" is not writable.")
		@_scope.set(@_bindInfo.writeablePath, value)
		return

	getBindingProperty: ()->
		return unless @_bindInfo
		return @_bindInfo.bindingProperty if @_bindInfo.bindingProperty isnt undefined
		return unless @_bindInfo.expression and @_bindInfo.writeable
		return @_bindInfo.bindingProperty = @_scope.data.getProperty(@_bindInfo.writeablePath) or null

	getBindingDataType: ()->
		return unless @_bindInfo
		return @_bindInfo.bindingDataType if @_bindInfo.bindingDataType isnt undefined
		return unless @_bindInfo.expression and @_bindInfo.writeable
		return unless @_bindInfo
		return @_bindInfo.bindingDataType = @_scope.data.getDataType(@_bindInfo.writeablePath) or null

	getAbsoluteBindingPath: ()->
		if @_bindInfo?.writeable
			return @_scope.getAbsolutePath(@_bind)
		return @_bind

cola.DataItemsWidgetMixin =
	_dataItemsWidget: true
	_alias: "item"

	_bindSetter: (bindStr)->
		return if @_bind is bindStr

		@_bind = bindStr
		@_itemsRetrieved = false

		if bindStr
			expression = cola._compileExpression(@_scope, bindStr, "repeat")
			if not expression.repeat
				throw new cola.Exception("Expression \"#{bindStr}\" must be a repeat expression.")
			@_alias = expression.alias

			if expression.writeable
				@_simpleBindPath = expression.writeablePath
		else if @_dataLoading
			@_onItemsLoadingEnd?()

		@_itemsScope.setExpression(expression)
		return

	constructor: ()->
		@_itemsScope = @_createItemsScope()

	_createItemsScope: ()->
		itemsScope = new cola.ItemsScope(@_scope)

		itemsScope.onItemsRefresh = (arg = {})=>
			arg.scope = itemsScope
			@_onItemsRefresh(arg)
			return

		itemsScope.onItemRefresh = (arg = {})=>
			arg.scope = itemsScope
			@_onItemRefresh?(arg)
			return

		itemsScope.onItemInsert = (arg)=>
			arg.scope = itemsScope
			@_onItemInsert?(arg)
			return

		itemsScope.onItemRemove = (arg)=>
			arg.scope = itemsScope
			@_onItemRemove?(arg)
			return

		itemsScope.onItemsLoadingStart = (arg = {})=>
			arg.scope = itemsScope
			@_onItemsLoadingStart(arg)
			return

		itemsScope.onItemsLoadingEnd = (arg = {})=>
			arg.scope = itemsScope
			@_onItemsLoadingEnd(arg)
			return

		if @_onCurrentItemChange
			itemsScope.onCurrentItemChange = (arg)=>
				arg.scope = itemsScope
				@_onCurrentItemChange(arg)
				return

		return itemsScope

	_getItems: ()->
		if not @_itemsRetrieved
			@_itemsRetrieved = true
			dataCtx = {}
			@_itemsScope.retrieveData(dataCtx)
			if dataCtx.unloaded
				@_onItemsLoadingStart()
			else if @_dataLoading
				@_onItemsLoadingEnd?()
		else if @_dataLoading
			@_onItemsLoadingEnd?()

		items = @_items or @_itemsScope.items
		if @_convertItems and items
			items = @_convertItems(items)

		return {
			items: items
			originItems: @_itemsScope.originItems
		}

	_getBindDataType: ()->
		items = @_getItems().originItems
		if items
			if items instanceof cola.EntityList
				dataType = items.dataType
			else if items instanceof Array and items.length
				item = items[0]
				if item and item instanceof cola.Entity
					dataType = item.dataType
		else if @_simpleBindPath
			dataType = @_scope.data.getDataType(@_simpleBindPath)
		return dataType

	_onItemsLoadingStart: (arg)->
		@_dataLoading = true
		return @_doItemsLoadingStart?(arg)

	_onItemsLoadingEnd: (arg)->
		@_dataLoading = false
		return @_doItemsLoadingEnd?(arg)