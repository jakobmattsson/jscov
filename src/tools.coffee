exports.evalBinaryExpression = do ->
  # Tempting to use eval here,
  # but I went with a more verbose solution
  methods =
    '+': (x, y) -> x + y
    '-': (x, y) -> x - y
    '*': (x, y) -> x * y
    '%': (x, y) -> x % y
    '/': (x, y) -> x / y
    '<<': (x, y) -> x << y
    '>>': (x, y) -> x >> y
    '>>>': (x, y) -> x >>> y
  (arg1, op, arg2) ->
    method = methods[op]
    throw "operator not supported" if !method?
    method(arg1, arg2)



exports.replaceProperties = (node, newVal) ->
  props = Object.getOwnPropertyNames(node)
  props.forEach (prop) -> delete node[prop]

  Object.keys(newVal).forEach (prop) ->
    node[prop] = newVal[prop]



reservedWords = [
  'break'
  'case'
  'catch'
  'continue'
  'debugger'
  'default'
  'delete'
  'do'
  'else'
  'finally'
  'for'
  'function'
  'if'
  'in'
  'instanceof'
  'new'
  'return'
  'switch'
  'this'
  'throw'
  'try'
  'typeof'
  'var'
  'void'
  'while'
  'with'

  'null'
  'true'
  'false'

  # These are not keyword according to JavaScript, but JSCoverage treats them as if they were.
  # Just follow suit...
  'throws'
  'static'
  'abstract'
  'implements'
  'protected'
  'boolean'
  'public'
  'byte'
  'int'
  'short'
  'char'
  'interface'
  'double'
  'long'
  'synchronized'
  'native'
  'final'
  'transient'
  'float'
  'package'
  'goto'
  'private'
]



exports.isValidIdentifier = (name) ->
  name? && !(name in reservedWords) && (name.toString().match(/^[_a-zA-Z][_a-zA-Z0-9]*$/) || name.toString().match(/^[1-9][0-9]*$/))


exports.isReservedWord = (name) -> name in reservedWords




