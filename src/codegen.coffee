# Universal module definition supports node, AMD, script global
# from https://github.com/umdjs/umd/blob/master/returnExports.js
((root, factory) ->
	if typeof exports == 'object'
		module.exports = factory()
	else if typeof define == 'function' and define.amd
		define factory
	else
		root.Codegen = factory()
) this, ->

	'use strict'

	generate = (tree, options) ->
		options = $.extend true,
			format:
				indent:
					style: '    '
					base: 0
				#json: false
				#renumber: false
				#hexadecimal: false
				#quotes: 'single'
				#escapeless: false
				#compact: false
				#parentheses: true
				html: false
				semicolons: true
			#parse: null
			#comment: false
			#sourceMap: undefined
		, options
		console.dir options

		str = []
		indentation = options.format.indent.base

		between = (els, fn, bw) ->
			run = false
			for el in els
				if run
					if typeof bw == 'function'
						bw()
					else if typeof bw == 'string'
						str.push bw
				fn el
				run = true


		###
		Indent a new line to the correct level
		delta increases or decreases indentation level
		temp does not update indent level
		###
		indent = (delta, temp) ->
			terminals.newline()
			if options.format.html
				for i in [0...(indentation + (+delta || 0))]
					str.push '<span class="indent"></span>'
			else
				str.push (options.format.indent.style for i in [0...(indentation + (+delta || 0))]).join ''
			indentation += (+delta || 0) unless temp



		region = (type, content) ->
			str.push "<span class=\"region #{type}\">" if options.format.html
			content()
			str.push '</span>' if options.format.html

		syntax =
			ArrayExpression: ['elements']
			AssignmentExpression: ['left', 'operator', 'right']
			BinaryExpression: ['left', 'operator', 'right']
			BlockStatement: ['body']
			BreakStatement: ['label']
			CallExpression: ['callee', 'arguments']
			CatchClause: ['param', 'guard', 'body']
			ConditionalExpression: ['test', 'consequent', 'alternate']
			ContinueStatement: ['label']
			DebuggerStatement: []
			DoWhileStatement: ['body', 'test']
			EmptyStatement: []
			ExpressionStatement: ['expression']
			ForInStatement: ['left', 'right', 'body', 'each']
			ForOfStatement: ['left', 'right', 'body']
			ForStatement: ['init', 'test', 'update', 'body']
			FunctionDeclaration: ['id', 'params', 'defaults', 'rest', 'body']
			FunctionExpression: ['id', 'params', 'defaults', 'rest', 'body']
			Identifier: ['name']
			IfStatement: ['test', 'consequent', 'alternate']
			LabeledStatement: ['label', 'body']
			Literal: ['raw']
			LogicalExpression: ['left', 'operator', 'right']
			MemberExpression: ['object', 'property', 'computed']
			NewExpression: ['callee', 'arguments']
			ObjectExpression: ['properties']
			Pattern: []
			Program: ['body']
			Property: ['key', 'value']
			ReturnStatement: ['argument']
			SequenceExpression: ['expressions']
			SwitchCase: ['test', 'consequent']
			SwitchStatement: ['discriminant', 'cases']
			ThisExpression: []
			ThrowStatement: ['argument']
			TryStatement: ['block', 'handlers', 'guardedHandlers', 'finalizer']
			UnaryExpression: ['operator', 'argument']
			UpdateExpression: ['operator', 'argument', 'prefix']
			VariableDeclaration: ['kind', 'declarations']
			VariableDeclarator: ['id', 'init']
			WhileStatement: ['test', 'body']
			WithStatement: ['object', 'body']
			#'ArrayPattern': ['elements'], # Harmony
			#'ComprehensionBlock': ['left', 'right'], # Harmony
			#'ComprehensionExpression': ['blocks', 'filter'], # Harmony
			#'GeneratorExpression': ['blocks', 'filter'], # Harmony
			#'LetExpression': ['head', 'body'], # Harmony
			#'LetStatement': ['head', 'body'], # Harmony
			#'ObjectPattern': ['properties'], # Harmony
			#'YieldExpression': ['argument'] # Harmony


		terminals =
			keyword: (keyword) ->
				region 'keyword', ->
					str.push keyword
			literal: (raw) ->
				# TODO: Type of literals
				str.push raw
			newline: (->
				first = true # suppress the first newline as it is extraneous
				->
					if first
						first = false
					else
						str.push if options.format.html then '<br />' else '\n'
				)()
			operator: (operator) ->
				region 'operator', ->
					str.push operator
			punctuation: (symbol) ->
				region 'punctuation', ->
					str.push symbol
			semicolon: ->
				region 'punctuation', ->
					str.push ';' if options.format.semicolons
			space: ->
				str.push if options.format.html then '&nbsp;' else ' '


		generators =
			ArrayExpression: (elements) ->
				terminals.punctuation '['
				between elements, codegen, ->
					terminals.punctuation ','
					terminals.space()
				terminals.punctuation ']'

			AssignmentExpression: (left, operator, right) ->
				codegen left
				terminals.space()
				terminals.operator operator
				terminals.space()
				codegen right

			BinaryExpression: (left, operator, right) ->
				terminals.punctuation '(('
				codegen left
				terminals.punctuation ')'
				terminals.space()
				terminals.operator operator
				terminals.space()
				terminals.punctuation '('
				codegen right
				terminals.punctuation '))'

			###
			Generate the code for a block statement
			opts.inline suppresses newlines before and after
			###
			BlockStatement: (body, opts) ->
				indent -1, true unless opts.inline
				terminals.punctuation '{'
				codegen el for el in body
				indent -1, true
				terminals.punctuation '}'

			BreakStatement: (label, opts) ->
				throw 'BreakStatement#label not supported.' if label?
				indent() unless opts.inline
				terminals.keyword 'break'
				terminals.semicolon()

			CallExpression: (callee, _arguments) ->
				terminals.punctuation '(' if callee.type == 'FunctionExpression'
				codegen callee
				terminals.punctuation ')' if callee.type == 'FunctionExpression'
				terminals.punctuation '('
				between _arguments, codegen, ->
					terminals.punctuation ','
					terminals.space()
				terminals.punctuation ')'

			CatchClause: (param, guard, body) ->
				throw 'CatchClause#guard not supported.' if guard?
				terminals.space()
				terminals.keyword 'catch'
				terminals.space()
				terminals.punctuation '('
				codegen param
				terminals.punctuation ')'
				terminals.space()
				codegen body, inline: true

			ConditionalExpression: (test, consequent, alternate) ->
				codegen test
				terminals.space()
				terminals.operator '?'
				terminals.space()
				codegen consequent
				terminals.space()
				terminals.operator ':'
				terminals.space()
				codegen alternate

			ContinueStatement: (label, opts) ->
				throw 'ContinueStatement#label not supported.' if label?
				indent() unless opts.inline
				terminals.keyword 'continue'
				terminals.semicolon()

			DoWhileStatement: (body, test) ->
				indent()
				indentation++
				terminals.keyword 'do '
				codegen body, inline: true
				terminals.space()
				terminals.keyword 'while'
				terminals.space()
				terminals.punctuation '('
				codegen test
				terminals.punctuation ')'

			EmptyStatement: (opts) ->
				indent() unless opts.inline
				terminals.semicolon()

			ExpressionStatement: (expression, opts) ->
				indent() unless opts.inline
				codegen expression
				terminals.semicolon()

			ForInStatement: (left, right, body, each) ->
				indent()
				terminals.keyword 'for'
				terminals.space()
				if each
					terminals.keyword 'each'
					terminals.space()
				terminals.punctuation '('
				indentation++
				codegen left, init: true
				terminals.space()
				terminals.keyword 'in'
				terminals.space()
				codegen right
				terminals.punctuation ')'
				terminals.space()
				codegen body, inline: true
				indentation--

			ForOfStatement: (left, right, body) ->
				indent()
				terminals.keyword 'for'
				terminals.space()
				terminals.punctuation '('
				indentation++
				codegen left, init: true
				terminals.space()
				terminals.keyword 'of'
				terminals.space()
				codegen right
				terminals.punctuation ')'
				terminals.space()
				codegen body, inline: true
				indentation--

			ForStatement: (init, test, update, body) ->
				indent()
				terminals.keyword 'for'
				terminals.space()
				terminals.punctuation '('
				indentation++
				codegen init, init: true if init
				terminals.punctuation ';'
				terminals.space()
				codegen test if test
				terminals.punctuation ';'
				terminals.space()
				codegen update if update
				terminals.punctuation ')'
				terminals.space()
				codegen body, inline: true
				indentation--

			FunctionDeclaration: (id, params, defaults, rest, body) ->
				throw 'FunctionDeclaration#defaults not supported.' if defaults.length
				indent()
				indentation++
				terminals.keyword 'function'
				terminals.space()
				codegen id
				terminals.punctuation '('
				between params, codegen, ->
					terminals.punctuation ','
					terminals.space()
				terminals.punctuation ')'
				terminals.space()
				codegen body, inline: true
				indentation--

			FunctionExpression: (id, params, defaults, rest, body) ->
				throw 'FunctionExpression#defaults not supported.' if defaults.length
				indentation++
				terminals.keyword 'function'
				terminals.space()
				codegen id, indent if id?
				terminals.punctuation '('
				between params, codegen, ->
					terminals.punctuation ','
					terminals.space()
				terminals.punctuation ')'
				terminals.space()
				codegen body, inline: true
				indentation--

			Identifier: (name) ->
				str.push name

			IfStatement: (test, consequent, alternate, opts) ->
				unless opts.inline
					indent()
					indentation++
				terminals.keyword 'if'
				terminals.space()
				terminals.punctuation '('
				codegen test, indent
				terminals.punctuation ')'
				terminals.space()
				codegen consequent, inline: true
				if alternate?
					terminals.space()
					terminals.keyword 'else'
					terminals.space()
					codegen alternate, inline: true
				indentation-- unless opts.inline

			LabeledStatement: (label, body) ->
				throw 'LabeledStatement not supported.'

			Literal: (raw) ->
				terminals.literal raw

			LogicalExpression: (left, operator, right) ->
				terminals.punctuation '(('
				codegen left
				terminals.punctuation ')'
				terminals.space()
				str.push operator
				terminals.space()
				terminals.punctuation '('
				codegen right
				terminals.punctuation '))'

			MemberExpression: (object, property, computed) ->
				terminals.punctuation '(' if object.type == 'FunctionExpression'
				codegen object
				terminals.punctuation ')' if object.type == 'FunctionExpression'
				if computed
					terminals.punctuation '['
					codegen property
					terminals.punctuation ']'
				else
					terminals.punctuation '.'
					codegen property

			NewExpression: (callee, _arguments) ->
				terminals.keyword 'new'
				terminals.space()
				codegen callee
				terminals.punctuation '('
				between _arguments, codegen, ->
					terminals.punctuation ','
					terminals.space()
				terminals.punctuation ')'

			ObjectExpression: (properties) ->
				terminals.punctuation '{'
				if properties?.length
					indentation++
					between properties, codegen, -> terminals.punctuation ','
					indentation--
					indent()
				terminals.punctuation '}'

			Program: (body) ->
				codegen el for el in body

			Property: (key, value) ->
				indent()
				codegen key
				terminals.punctuation ':'
				terminals.space()
				codegen value

			ReturnStatement: (argument, opts) ->
				indent() unless opts.inline
				terminals.keyword 'return'
				if argument?
					terminals.space()
					codegen argument
				terminals.semicolon()

			SequenceExpression: (expressions) ->
				between expressions, codegen, ->
					terminals.punctuation ','
					terminals.space()

			SwitchCase: (test, consequent) ->
				indent -1, true
				if test == null
					terminals.keyword 'default'
				else
					terminals.keyword 'case'
					terminals.space()
					codegen test
				terminals.punctuation ':'
				codegen cons for cons in consequent

			SwitchStatement: (discriminant, cases) ->
				indent()
				terminals.keyword 'switch'
				terminals.space()
				terminals.punctuation '('
				codegen discriminant
				terminals.punctuation ')'
				terminals.space()
				terminals.punctuation '{'
				indentation++
				codegen _case for _case in cases
				indentation--

			ThisExpression: ->
				terminals.keyword 'this'

			ThrowStatement: (argument, opts) ->
				indent() unless opts.inline
				terminals.keyword 'throw'
				terminals.space()
				codegen argument
				semicolon()

			TryStatement: (block, handlers, guardedHandlers, finalizer) ->
				throw 'TryStatement#guardedHandlers not supported.' if guardedHandlers.length
				indent()
				indentation++
				terminals.keyword 'try'
				terminals.space()
				codegen block, inline: true
				codegen handler for handler in handlers
				codegen finalizer if finalizer
				indentation--

			UnaryExpression: (operator, argument) ->
				terminals.punctuation '('
				terminals.operator operator
				terminals.punctuation '('
				codegen argument
				terminals.punctuation '))'

			UpdateExpression: (operator, argument, prefix) ->
				terminals.operator operator if prefix
				codegen argument, indent
				terminals.operator operator unless prefix

			# opts.init means declarations are part of loop initialization
			VariableDeclaration: (kind, declarations, opts) ->
				indent() unless opts.init
				terminals.keyword kind
				terminals.space()
				between declarations, codegen, ->
					terminals.punctuation ','
					terminals.space()
				semicolon() unless opts.init

			VariableDeclarator: (id, init) ->
				codegen id
				if init?
					terminals.space()
					terminals.operator '='
					terminals.space()
					codegen init

			WithStatement: (object, body) ->
				indent()
				indentation++
				terminals.keyword 'with'
				terminals.space()
				terminals.punctuation '('
				codegen object
				terminals.punctuation ')'
				terminals.space()
				codegen body, inline: true

			WhileStatement: (test, body) ->
				indent()
				indentation++
				terminals.keyword 'while'
				terminals.space()
				terminals.punctuation '('
				codegen test
				terminals.punctuation ')'
				terminals.space()
				codegen body, inline: true
				indentation--

		# Convert a CamelCase type to a dash-case CSS class
		cssify = (name) ->
			name.replace(/\W+/g, '-')
			    .replace(/([a-z\d])([A-Z])/g, '$1-$2')
			    .toLowerCase()

		codegen = (code, opts) ->
			opts ?= {}

			if generators[code.type]? and syntax[code.type]?
				region cssify(code.type), ->
					generators[code.type].apply null, (code[prop] for prop in syntax[code.type]).concat opts
			else
				str.push '????'
				console.error "Unknown type #{code.type}", code
			return


		codegen tree
		return str.join('')

	return generate: generate
