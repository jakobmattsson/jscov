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
  'throws',       'transient'
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



# Allowing ALL unicode characters is a little rough
# Would be nice to make this a bit more specific but I'm not sure how...
exports.isValidIdentifier = (name) ->
  name?.toString().match(/^[_$a-zA-Z\xA0-\uFFFF][_$a-zA-Z0-9\xA0-\uFFFF]*$/) &&
  !exports.isReservedWord(name)



exports.isReservedWord = do ->
  reservedWordsHash = reservedWords.reduce (acc, word) ->
    acc[word] = 1
    acc
  , {}
  (name) -> !!reservedWordsHash.hasOwnProperty(name)



exports.strToNumericEntity = (str) ->
  symbols = [0...str.length].map (i) ->
    charCode = str.charCodeAt(i)
    if charCode < 128
      str[i]
    else
      '&#' + charCode + ';'
  symbols.join('')
