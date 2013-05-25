Range = ace.require('ace/range').Range

editor = ace.edit 'code'
editor.setTheme 'ace/theme/monokai'
editor.getSession().setMode 'ace/mode/javascript'
editor.setShowPrintMargin false
editor.getSession().on 'change', (event) ->
	try
		options =
			format:
				indent:
					style: '\t'
		$('#output').html Codegen.generate parse(editor.getValue()), options
	catch err
		console.error err


parse = (code) ->
	ast = esprima.parse code,
		range: true
		loc: true
	console.dir ast
	return ast

console.dir Codegen
