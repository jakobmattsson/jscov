# should sort these alphabetically to make it easier to read...
reservedWords = [
  # actual keywords
  'break',        'case',         'catch',        'continue',     'debugger'
  'default',      'delete',       'do',           'else',         'finally'
  'for',          'function',     'if',           'in',           'instanceof'
  'new',          'return',       'switch',       'this',         'throw'
  'try',          'typeof',       'var',          'void',         'while'
  'with',         'null',         'true',         'false'

  # reversed words
  'throws',       'static',       'abstract',     'implements',   'protected'
  'boolean',      'public',       'byte',         'int',          'short'
  'char',         'interface',    'double',       'long',         'synchronized'
  'native',       'final',        'transient',    'float',        'package'
  'goto',         'private'
]




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



exports.replaceProperties = (obj, newProps) ->
  props = Object.getOwnPropertyNames(obj)
  props.forEach (prop) -> delete obj[prop]

  Object.getOwnPropertyNames(newProps).forEach (prop) ->
    obj[prop] = newProps[prop]


# this regexp is not even correct. Identifiers can contain unicode characters.
# Write a test for it and fix it
exports.isValidIdentifier = (name) ->
  name?.toString().match(/^[_a-zA-Z][_a-zA-Z0-9]*$/) &&
  !exports.isReservedWord(name)



exports.isReservedWord = do ->
  reservedWordsHash = reservedWords.reduce (acc, word) ->
    acc[word] = 1
    acc
  , {}
  (name) -> !!reservedWordsHash[name]



exports.strToNumericEntity = (str) ->
  symbols = [0...str.length].map (i) ->
    charCode = str.charCodeAt(i)
    if charCode < 128
      str[i]
    else
      '&#' + charCode + ';'
  symbols.join('')
