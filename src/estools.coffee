escodegen = require 'escodegen'
tools = require './tools'
estools = exports



numberProperty = (property) ->
  type: 'MemberExpression'
  computed: false
  object: { type: 'Identifier', name: 'Number' }
  property: { type: 'Identifier', name: property }



replaceAllNodes = ({ ast, predicate, replacement }) ->
  escodegen.traverse ast,
    enter: (node) ->
      if predicate(node)
        tools.replaceProperties(node, replacement(node))



nodeIsInfinity = (node) ->
  node.type == 'Literal' && node.value == Infinity



exports.createLiteral = (value) ->
  if typeof value == 'number' && value < 0
    type: 'UnaryExpression'
    operator: '-'
    argument:
      type: 'Literal'
      value: -value
  else
    type: 'Literal'
    value: value



exports.replaceWithLiteral = (node, value) ->
  tools.replaceProperties(node, estools.createLiteral(value))



# these two are not very sexy. try to refactor (in particular their usage!)
exports.mathable = (node) -> node.type == 'Literal' || (node.type == 'UnaryExpression' && node.operator == '-' && node.argument.type == 'Literal')
exports.getVal = (node) ->
  if node.type == 'Literal' && typeof node.value == 'number'
    node.value
  else if node.type == 'UnaryExpression' && node.operator == '-' && node.argument.type == 'Literal' && typeof node.argument.value == 'number'
    -node.argument.value
  else
    "nope"




exports.replaceNegativeInfinities = (ast) ->
  replaceAllNodes
    ast: ast
    predicate: (node) -> node.type == 'UnaryExpression' && node.operator == '-' && nodeIsInfinity(node.argument)
    replacement: -> numberProperty('NEGATIVE_INFINITY')


exports.replacePositiveInfinities = (ast) ->
  replaceAllNodes
    ast: ast
    predicate: nodeIsInfinity
    replacement: -> numberProperty('POSITIVE_INFINITY')




exports.coverageNode = (node, filename, identifier) ->
  type: 'ExpressionStatement'
  expression:
    type: 'UpdateExpression'
    operator: '++'
    prefix: false
    argument:
      type: 'MemberExpression'
      computed: true
      property: estools.createLiteral(node.loc.start.line)
      object:
        type: 'MemberExpression'
        computed: true
        object:
          type: 'Identifier'
          name: identifier
        property: estools.createLiteral(filename)
