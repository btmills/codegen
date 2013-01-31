/*function parse() {
	return esprima.parse($('#code').val());
}

var editor;

$(document).ready(function () {

	editor = ace.edit('editor');
	//editor.setTheme('ace/theme/monokai');
	//editor.getSession().setMode('ace/mode/javascript');

});*/

//var editor = ace.edit('editor');

//var code;
//var output;

//$(document).ready(function () {

var editor = ace.edit('code');
editor.setTheme('ace/theme/monokai');
editor.getSession().setMode('ace/mode/javascript');
editor.setShowPrintMargin(false);
editor.getSession().on('change', function (event) {
	try {
		output.setValue(JSON.stringify(esprima.parse(editor.getValue()), undefined, 2));
		output.clearSelection();
	} catch (err) { }
});

var output = ace.edit('output');
output.setTheme('ace/theme/monokai');
output.getSession().setMode('ace/mode/json');
output.setReadOnly(true);
output.setHighlightActiveLine(false);
output.setShowPrintMargin(false);

//});