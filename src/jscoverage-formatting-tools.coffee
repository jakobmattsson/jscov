tools = require './tools'
estools = require './estools'

reservedWords = [
  # actual keywords
  'break',        'case',         'catch',        'continue',     'debugger'
  'default',      'delete',       'do',           'else',         'false'
  'finally',      'for',          'function',     'if',           'in'
  'instanceof',   'new',          'null',         'return',       'switch'
  'this',         'throw',        'true',         'try',          'typeof'
  'var',          'void',         'while',        'with'

  # reversed words
  'abstract',     'boolean',      'byte',         'char',         'double'
  'final',        'float',        'goto',         'implements',   'int'
  'interface',    'long',         'native',       'package',      'private'
  'protected',    'public',       'short',        'static',       'synchronized'
  'throws',       'transient',    'export'
]



nodeIsInfinity = (node) -> node.type == 'Literal' && node.value == Infinity
nodeIsNumericLiteral = (node) -> node.type == 'Literal' && typeof node.value == 'number'
nodeIsUnaryMinus = (node) -> node.type == 'UnaryExpression' && node.operator == '-'



numberProperty = (property) ->
  type: 'MemberExpression'
  computed: false
  object: { type: 'Identifier', name: 'Number' }
  property: { type: 'Identifier', name: property }



replaceAllNodes = ({ ast, predicate, replacement }) ->
  estools.traverse ast, (node) ->
    tools.replaceProperties(node, replacement(node)) if predicate(node)



replaceWithLiteral = (node, value) ->
  tools.replaceProperties(node, estools.createLiteral(value))



exports.isNumericLiteral = (node) ->
  nodeIsNumericLiteral(node) || (nodeIsUnaryMinus(node) && nodeIsNumericLiteral(node.argument))



exports.replaceNegativeInfinities = (ast) ->
  replaceAllNodes
    ast: ast
    predicate: (node) -> nodeIsUnaryMinus(node) && nodeIsInfinity(node.argument)
    replacement: -> numberProperty('NEGATIVE_INFINITY')



exports.replacePositiveInfinities = (ast) ->
  replaceAllNodes
    ast: ast
    predicate: nodeIsInfinity
    replacement: -> numberProperty('POSITIVE_INFINITY')



exports.isReservedWord = do ->
  reservedWordsHash = reservedWords.reduce (acc, word) ->
    acc[word] = 1
    acc
  , {}
  (name) -> !!reservedWordsHash.hasOwnProperty(name)



# Allowing ALL unicode characters is a little rough
# Would be nice to make this a bit more specific but I'm not sure how...
exports.isValidIdentifier = (name) ->
  name?.toString().match(/^[_$a-zA-Z\xA0-\uFFFF][_$a-zA-Z0-9\xA0-\uFFFF]*$/) &&
  !exports.isReservedWord(name)



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



exports.evalLiterals = (ast, evals) ->
  format = true
  while format
    format = false
    estools.traverse ast, (node) ->
      evals.forEach (n) ->
        if n.test(node)
          v = n.eval(node)
          if typeof v == 'number' && isNaN(v)
            tools.replaceProperties(node, {
              type: 'MemberExpression'
              computed: false
              object:
                type: 'Identifier'
                name: 'Number'
              property:
                type: 'Identifier'
                name: 'NaN'
            })
          else
            replaceWithLiteral(node, v)
          format = true



exports.evalLiteral = (node) ->
  if nodeIsNumericLiteral(node)
    node.value
  else if nodeIsUnaryMinus(node) && nodeIsNumericLiteral(node.argument)
    -node.argument.value
  else
    throw "not a numeric literal"
