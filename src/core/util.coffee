cola.util.createDeferredIf = (originDfd, failbackArgs)->
	return originDfd or $.Deferred().resolve(failbackArgs)

cola.util.wrapDeferredWith = (context, originDfd, failbackArgs)->
	if originDfd and (not originDfd.done or not originDfd.fail)
		return originDfd

	dfd = $.Deferred()
	if originDfd
		originDfd.done(()->
			dfd.resolveWith.apply(dfd, [context, arguments])
		).fail(()->
			dfd.rejectWith.apply(dfd, [context, arguments])
		).notify?(()->
			dfd.notifyWith.apply(dfd, [context, arguments])
		)
	else
		dfd.resolveWith(context, failbackArgs)
	return dfd

cola.util.findModel = (dom)->
	scope = cola.util.userData(dom, "scope")
	if scope
		return scope

	domBinding = cola.util.userData(dom, cola.constants.DOM_BINDING_KEY)
	if domBinding
		return domBinding.scope

	if dom.parentNode
		return cola.util.findModel(dom.parentNode)
	else
		return null

cola.util.trim = (text)->
	return if text? then String.prototype.trim.call(text) else ""

cola.util.capitalize = (text)->
	return text unless text
	return text.charAt(0).toUpperCase() + text.slice(1);

cola.util.isSimpleValue = (value)->
	if value == null or value == undefined then return true
	type = typeof value
	return type != "object" and type != "function" or value instanceof Date or value instanceof Array

cola.util.path = (parts...)->
	last = parts.length - 1
	for part, i in parts
		changed = false
		if i > 0 and part.charCodeAt(0) is 47 # `/`
			part = part.substring(1)
			changed = true

		if i < last and part.charCodeAt(part.length - 1) is 47 # `/`
			part = part.substring(0, part.length - 1)
			changed = true

		if changed then parts[i] = part
	return parts.join("/")

cola.util.each = (array, fn)->
	for item, i in array
		if fn(item, i) is false
			break
	return

cola.util.parseStyleLikeString = (styleStr, headerProp)->
	return false unless styleStr

	style = {}
	parts = styleStr.split(";")
	for part, i in parts
		j = part.indexOf(":")
		if j > 0
			styleProp = @trim(part.substring(0, j))
			styleExpr = @trim(part.substring(j + 1))
			if styleProp and styleExpr
				style[styleProp] = styleExpr
		else
			part = @trim(part)
			if not part then continue
			if i is 0 and headerProp
				style[headerProp] = part
			else
				style[part] = true
	return style

cola.util.parseFunctionArgs = (func)->
	argStr = func.toString().match(/\([^\(\)]*\)/)[0]
	rawArgs = argStr.substring(1, argStr.length - 1).split(",");
	args = []
	for arg, i in rawArgs
		arg = cola.util.trim(arg)
		if arg then args.push(arg)
	return args

cola.util.parseListener = (listener)->
	argsMode = 1
	argStr = listener.toString().match(/\([^\(\)]*\)/)[0]
	args = argStr.substring(1, argStr.length - 1).split(",");
	if args.length
		if cola.util.trim(args[0]) is "arg" then argsMode = 2
	listener._argsMode = argsMode
	return argsMode

cola.util.isCompatibleType = (baseType, type)->
	if type == baseType then return true
	while type.__super__
		type = type.__super__.constructor
		if type == baseType then return true
	return false

cola.util.delay = (owner, name, delay, fn)->
	cola.util.cancelDelay(owner, name)
	owner["_timer_" + name] = setTimeout(()->
		fn.call(owner)
		return
	, delay)
	return

cola.util.cancelDelay = (owner, name)->
	key = "_timer_" + name
	timerId = owner[key]
	if timerId
		delete owner[key]
		clearTimeout(timerId)
	return

cola.util.formatDate = (date, pattern)->
	return "" unless date?
	if not (date instanceof XDate)
		date = new XDate(date)
	return date.toString(pattern or cola.setting("defaultDateFormat"))

cola.util.formatNumber = (number, pattern)->
	return "" unless number?
	return number if isNaN(number)
	return formatNumber(pattern or cola.setting("defaultNumberFormat"), number)

cola.util.format = (value, format)->
	if value instanceof Date
		return cola.util.formatDate(value, format)
	else if isFinite(value)
		return cola.util.formatNumber(value, format)
	else if value and typeof value is "string"
		date = (new XDate(value)).toDate()
		if not isFinite(date)
			return value
		else
			return cola.util.formatDate(date, format)
	else if value is null or value is undefined
		return ""
	else
		return value

cola.util.getItemByItemDom = (dom)->
	scope = cola.util.userData(dom, "scope")
	if scope and scope instanceof cola.ItemScope
		return scope.data.getItemData()

	domBinding = cola.util.userData(dom, cola.constants.DOM_BINDING_KEY)
	if domBinding
		scope = domBinding.scope
		if scope and scope instanceof cola.ItemScope
			return scope.data.getItemData()

	if dom.parentNode
		return cola.util.getItemByItemDom(dom.parentNode)
	else
		return null

## URL

cola.util.queryParams = ()->

	decode = (str)-> decodeURIComponent((str || "").replace(/\+/g, " "))

	query = (window.location.search || "").substring(1)
	params = {}

	if query.length > 0
		for param, i in query.split("&")
			pair = param.split("=")
			key = decode(pair.shift())
			value = decode(if pair.length then pair.join("=") else null)

			if (params.hasOwnProperty(key))
				oldValue = params[key]
				if oldValue instanceof Array
					oldValue.push(value)
				else
					params[key] = [oldValue, value]
			else
				params[key] = value
	return params

cola.util.pathParams = (prefix, index = 0)->
	path = (window.location.pathname || "").replace(/^\//, "")
	parts = path.split("/")
	i = parts.indexOf(prefix)
	if i >= 0
		return parts[i + 1 + index]
	else
		return

## Dictionary

keyValuesMap = {}
dictionaryMap = {}

cola.util.dictionary = (name, keyValues)->
	if keyValues is null
		delete keyValuesMap[name]
		delete dictionaryMap[name]
		return
	else if keyValues is undefined
		return keyValuesMap[name]
	else if keyValues instanceof Array
		keyValuesMap[name] = keyValues
		dictionaryMap[name] = dictionary = {}
		for pair in keyValues
			dictionary[pair.key or ""] = pair.value
		return dictionary
	else
		keyValuesMap[name] = values = []
		for key, value of keyValues
			values.push(
				key: key
				value: value
			)
			dictionaryMap[name] = keyValues
		return keyValues

cola.util.translate = (dictionaryName, key)->
	return dictionaryMap[dictionaryName]?[key or ""]

# OO

cola.util.isSuperClass = (superCls, cls)->
	return false unless superCls
	while cls
		return true if cls.__super__ is superCls::
		cls = cls.__super__?.constructor
	return false