escodegen = require 'escodegen'
tools = require './tools'
_ = require 'underscore'



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



computedMember = ({ property, object }) ->
  type: 'MemberExpression'
  computed: true
  property: property
  object: object



exports.coverageNode = (node, filename, identifier) ->
  type: 'ExpressionStatement'
  expression:
    type: 'UpdateExpression'
    operator: '++'
    prefix: false
    argument: computedMember
      property: exports.createLiteral(node.loc.start.line)
      object: computedMember
        property: exports.createLiteral(filename)
        object: { type: 'Identifier', name: identifier }



exports.traverse = (ast, filter, callback) ->
  if !callback?
    callback = filter
    filter = []

  escodegen.traverse ast,
    enter: (node) ->
      if filter.length == 0 || filter.indexOf(node.type) != -1
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
    if ['ForInStatement', 'ForStatement', 'WhileStatement', 'WithStatement', 'DoWhileStatement'].indexOf(node.type) != -1 && node.body? && node.body.type != 'BlockStatement'
      node.body =
        type: 'BlockStatement'
        body: [node.body]

  # insert the coverage information
  exports.traverse ast, (node) ->
    if ['BlockStatement', 'Program'].indexOf(node.type) != -1
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
