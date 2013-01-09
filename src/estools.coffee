escodegen = require 'escodegen'
tools = require './tools'
_ = require 'underscore'



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



exports.isNumericLiteral = (node) ->
  if node.type == 'Literal'
    true
  else if node.type == 'UnaryExpression' && node.operator == '-' && node.argument.type == 'Literal' && typeof node.argument.value == 'number'
    true
  else
    false



exports.evalLiteral = (node) ->
  if node.type == 'Literal'
    node.value
  else if node.type == 'UnaryExpression' && node.operator == '-' && node.argument.type == 'Literal' && typeof node.argument.value == 'number'
    -node.argument.value
  else
    throw "not literal"



exports.evalLiterals = (ast, evals) ->
  format = true
  while format
    format = false
    escodegen.traverse ast,
      enter: (node) ->
        evals.forEach (n) ->
          if n.test(node)
            exports.replaceWithLiteral(node, n.eval(node))
            format = true



exports.replaceWithLiteral = (node, value) ->
  tools.replaceProperties(node, exports.createLiteral(value))



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
      property: exports.createLiteral(node.loc.start.line)
      object:
        type: 'MemberExpression'
        computed: true
        object:
          type: 'Identifier'
          name: identifier
        property: exports.createLiteral(filename)



exports.addBeforeEveryStatement = (ast, addback) ->

  # all optional blocks should be actual blocks (in order to make it possible to put coverage information in them)
  escodegen.traverse ast,
    enter: (node) ->
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
  escodegen.traverse ast,
    enter: (node) ->
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
