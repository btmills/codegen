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

		newline = -> str.push '<br />'

		###
		Indent a new line to the correct level
		delta increases or decreases indentation level
		temp does not update indent level
		###
		indent = (delta, temp) ->
			newline()
			str.push (options.format.indent.style for i in [0...(indentation + (+delta || 0))]).join ''
			indentation += (+delta || 0) unless temp

		semicolon = ->
			str.push ';' if options.format.semicolons

		region = (type, cont) ->
			str.push "<span class=#{type}>"
			cont()
			str.push '</span>'

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


		generators =
			ArrayExpression: (elements) ->
				str.push '['
				between elements, codegen, ', '
				str.push ']'

			, AssignmentExpression: (left, operator, right) ->
				codegen left
				str.push ' '
				str.push operator
				str.push ' '
				codegen right

			, BinaryExpression: (left, operator, right) ->
				str.push '(('
				codegen left
				str.push ') '
				str.push operator
				str.push ' ('
				codegen right
				str.push '))'

			###
			Generate the code for a block statement
			opts.inline suppresses newlines before and after
			###
			, BlockStatement: (body, opts) ->
				indent -1, true unless opts.inline
				str.push '{'
				codegen el for el in body
				indent -1, true
				str.push '}'

			, BreakStatement: (label, opts) ->
				throw 'BreakStatement#label not supported.' if label?
				indent() unless opts.inline
				str.push 'break;'

			, CallExpression: (callee, _arguments) ->
				str.push '(' if callee.type == 'FunctionExpression'
				codegen callee
				str.push ')' if callee.type == 'FunctionExpression'
				str.push '('
				between _arguments, codegen, ', '
				str.push ')'

			, CatchClause: (param, guard, body) ->
				throw 'CatchClause#guard not supported.' if guard?
				str.push ' catch ('
				codegen param
				str.push ') '
				codegen body, inline: true

			, ConditionalExpression: (test, consequent, alternate) ->
				codegen test
				str.push ' ? '
				codegen consequent
				str.push ' : '
				codegen alternate

			, ContinueStatement: (label, opts) ->
				throw 'ContinueStatement#label not supported.' if label?
				indent() unless opts.inline
				str.push 'continue;'

			, DoWhileStatement: (body, test) ->
				indent()
				indentation++
				str.push 'do '
				codegen body, inline: true
				str.push ' while ('
				codegen test
				str.push ')';

			, EmptyStatement: (opts) ->
				indent() unless opts.inline
				semicolon()

			, ExpressionStatement: (expression, opts) ->
				indent() unless opts.inline
				codegen expression
				semicolon()

			, ForInStatement: (left, right, body, each) ->
				indent()
				str.push if each then 'for each (' else 'for ('
				indentation++
				codegen left, init: true
				str.push ' in '
				codegen right
				str.push ') '
				codegen body, inline: true
				indentation--

			, ForOfStatement: (left, right, body) ->
				indent()
				str.push 'for ('
				indentation++
				codegen left, init: true
				str.push ' of '
				codegen right
				str.push ') '
				codegen body, inline: true
				indentation--

			, ForStatement: (init, test, update, body) ->
				indent()
				str.push 'for ('
				indentation++
				codegen init, init: true if init
				str.push '; '
				codegen test if test
				str.push '; '
				codegen update if update
				str.push ') '
				codegen body, inline: true
				indentation--

			, FunctionDeclaration: (id, params, defaults, rest, body) ->
				region 'function-declaration', ->
					throw 'FunctionDeclaration#defaults not supported.' if defaults.length
					indent()
					indentation++
					str.push 'function '
					codegen id
					str.push '('
					between params, codegen, ', '
					str.push ') '
					codegen body, inline: true
					indentation--

			, FunctionExpression: (id, params, defaults, rest, body) ->
				throw 'FunctionExpression#defaults not supported.' if defaults.length
				indentation++
				str.push 'function '
				codegen id, indent if id?
				str.push '('
				between params, codegen, ', '
				str.push ') '
				codegen body, inline: true
				indentation--

			, Identifier: (name) ->
				region 'identifier', ->
					str.push name

			, IfStatement: (test, consequent, alternate, opts) ->
				unless opts.inline
					indent()
					indentation++
				str.push 'if ('
				codegen test, indent
				str.push ') '
				codegen consequent, inline: true
				if alternate?
					str.push ' else '
					codegen alternate, inline: true
				indentation-- unless opts.inline

			, LabeledStatement: (label, body) ->
				throw 'LabeledStatement not supported.'

			, Literal: (raw) ->
				str.push raw

			, LogicalExpression: (left, operator, right) ->
				str.push '(('
				codegen left
				str.push ') '
				str.push operator
				str.push ' ('
				codegen right
				str.push '))'

			, MemberExpression: (object, property, computed) ->
				str.push '(' if object.type == 'FunctionExpression'
				codegen object
				str.push ')' if object.type == 'FunctionExpression'
				if computed
					str.push '['
					codegen property
					str.push ']'
				else
					str.push '.'
					codegen property

			, NewExpression: (callee, _arguments) ->
				str.push 'new '
				codegen callee
				str.push '('
				between _arguments, codegen, ', '
				str.push ')'

			, ObjectExpression: (properties) ->
				str.push '{'
				if properties?.length
					indentation++
					between properties, codegen, ','
					indentation--
					indent()
				str.push '}'

			, Program: (body) ->
				codegen el for el in body

			, Property: (key, value) ->
				indent()
				codegen key
				str.push ': '
				codegen value

			, ReturnStatement: (argument, opts) ->
				indent() unless opts.inline
				str.push 'return'
				if argument?
					str.push ' '
					codegen argument
				semicolon()

			, SequenceExpression: (expressions) ->
				between expressions, codegen, ', '

			, SwitchCase: (test, consequent) ->
				indent -1, true
				if test == null
					str.push 'default'
				else
					str.push 'case '
					codegen test
				str.push ':'
				codegen cons for cons in consequent

			, SwitchStatement: (discriminant, cases) ->
				indent()
				str.push 'switch ('
				codegen discriminant
				str.push ') {'
				indentation++
				codegen _case for _case in cases
				indentation--

			, ThisExpression: ->
				str.push 'this'

			, ThrowStatement: (argument, opts) ->
				indent() unless opts.inline
				str.push 'throw '
				codegen argument
				semicolon()

			, TryStatement: (block, handlers, guardedHandlers, finalizer) ->
				throw 'TryStatement#guardedHandlers not supported.' if guardedHandlers.length
				indent()
				indentation++
				str.push 'try '
				codegen block, inline: true
				codegen handler for handler in handlers
				codegen finalizer if finalizer
				indentation--

			, UnaryExpression: (operator, argument) ->
				str.push '('
				str.push operator
				str.push '('
				codegen argument
				str.push '))'

			, UpdateExpression: (operator, argument, prefix) ->
				str.push operator if prefix
				codegen argument, indent
				str.push operator unless prefix

			# opts.init means declarations are part of loop initialization
			, VariableDeclaration: (kind, declarations, opts) ->
				region 'variable-declaration', ->
					indent() unless opts.init
					str.push kind
					str.push ' '
					between declarations, codegen, ', '
					semicolon() unless opts.init

			, VariableDeclarator: (id, init) ->
				codegen id
				if init?
					str.push ' = '
					codegen init

			, WithStatement: (object, body) ->
				indent()
				indentation++
				str.push 'with ('
				codegen object
				str.push ') '
				codegen body, inline: true

			, WhileStatement: (test, body) ->
				indent()
				indentation++
				str.push 'while ('
				codegen test
				str.push ') '
				codegen body, inline: true
				indentation--



		codegen = (code, opts) ->
			opts ?= {}
			#console.log code

			if generators[code.type]? and syntax[code.type]?
				generators[code.type].apply null, (code[prop] for prop in syntax[code.type]).concat opts
			else
				str.push '????'
				console.error "Unknown type #{code.type}", code
			return


		try
			codegen tree
		catch err
			console.error err
			return ''
		console.log str
		return str.slice(1).join('') # Slice off newline at beginning

	return generate: generate
