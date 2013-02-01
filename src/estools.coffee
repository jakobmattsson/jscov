escodegen = require 'escodegen'
tools = require './tools'
_ = require 'underscore'



numberProperty = (property) ->
  type: 'MemberExpression'
  computed: false
  object: { type: 'Identifier', name: 'Number' }
  property: { type: 'Identifier', name: property }



replaceAllNodes = ({ ast, predicate, replacement }) ->
  exports.traverse ast, (node) ->
    tools.replaceProperties(node, replacement(node)) if predicate(node)



nodeIsInfinity = (node) -> node.type == 'Literal' && node.value == Infinity
nodeIsNumericLiteral = (node) -> node.type == 'Literal' && typeof node.value == 'number'
nodeIsUnaryMinus = (node) -> node.type == 'UnaryExpression' && node.operator == '-'



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



exports.isNumericLiteral = (node) ->
  nodeIsNumericLiteral(node) || (nodeIsUnaryMinus(node) && nodeIsNumericLiteral(node.argument))



exports.evalLiteral = (node) ->
  if nodeIsNumericLiteral(node)
    node.value
  else if nodeIsUnaryMinus(node) && nodeIsNumericLiteral(node.argument)
    -node.argument.value
  else
    throw "not a numeric literal"



exports.evalLiterals = (ast, evals) ->
  format = true
  while format
    format = false
    exports.traverse ast, (node) ->
      evals.forEach (n) ->
        if n.test(node)
          exports.replaceWithLiteral(node, n.eval(node))
          format = true



exports.replaceWithLiteral = (node, value) ->
  tools.replaceProperties(node, exports.createLiteral(value))



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



exports.coverageNode = (node, filename, identifier) ->
  type: 'ExpressionStatement'
  expression:
    type: 'UpdateExpression'
    operator: '++'
    prefix: false
    argument:
      type: 'MemberExpression'
      computed: true
      property: exports.createLiteral(node.loc.start.line)
      object:
        type: 'MemberExpression'
        computed: true
        object:
          type: 'Identifier'
          name: identifier
        property: exports.createLiteral(filename)



exports.traverse = (ast, filter, callback) ->
  if !callback?
    callback = filter
    filter = []

  escodegen.traverse ast,
    enter: (node) ->
      if filter.length == 0 || node.type in filter
        callback(node)



exports.addBeforeEveryStatement = (ast, addback) ->

  # all optional blocks should be actual blocks (in order to make it possible to put coverage information in them)
  exports.traverse ast, (node) ->
    if node.type == 'IfStatement'
      ['consequent', 'alternate'].forEach (path) ->
        if node[path]? && node[path].type != 'BlockStatement'
          node[path] =
            type: 'BlockStatement'
            body: [node[path]]
    if node.type in ['ForInStatement', 'ForStatement', 'WhileStatement', 'WithStatement', 'DoWhileStatement'] && node.body? && node.body.type != 'BlockStatement'
      node.body =
        type: 'BlockStatement'
        body: [node.body]

  # insert the coverage information
  exports.traverse ast, (node) ->
    if node.type in ['BlockStatement', 'Program']
      node.body = _.flatten node.body.map (statement) ->
        if statement.expression?.type == 'FunctionExpression'
          [addback(statement.expression), statement]
        else if statement.expression?.type == 'CallExpression'
          [addback(statement.expression), statement]
        else if statement.type == 'FunctionDeclaration'
          [addback(statement.body), statement]
        else
          [addback(statement), statement]
    if node.type == 'SwitchCase'
      node.consequent = _.flatten node.consequent.map (statement) ->
        [addback(statement), statement]
