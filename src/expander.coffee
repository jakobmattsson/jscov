# ToDo:
# noop not as block-statement



_ = require 'underscore'
estools = require './estools'

noopDef =
  kind: 'var'
  type: 'VariableDeclaration'
  declarations: [{
    type: 'VariableDeclarator'
    id: { type: 'Identifier', name: 'noop' }
    init:
      type: 'FunctionExpression'
      id: null
      params: []
      defaults: []
      body: 
        type: 'BlockStatement'
        body: [{
          type: 'ReturnStatement'
          argument: { type: 'Literal', value: null }
        }]
    rest: null
    generator: false
    expression: false
  }]

noopExpression = 
  type: 'ExpressionStatement'
  expression:
    arguments: []
    type: 'CallExpression'
    callee:
      type: 'Identifier'
      name: 'noop'

wrapExpression = (exp) ->
  type: 'CallExpression'
  arguments: []
  callee: 
    rest: null
    generator: false
    expression: false
    type: 'FunctionExpression'
    id: null
    params: []
    defaults: []
    body: 
      type: 'BlockStatement'
      body: [{
        type: 'ReturnStatement'
        argument: exp
      }]

exports.expand = (ast) ->

  addNoop = false

  estools.traverse ast, ['IfStatement'], (node) ->
    if !node.alternate?
      addNoop = true
      node.alternate =
        type: 'BlockStatement'
        body: [noopExpression]

  estools.traverse ast, ['ConditionalExpression'], (node) ->
    ['consequent', 'alternate'].forEach (name) ->
      node[name] = wrapExpression(node[name])

  if addNoop
    estools.traverse ast, ['Program'], (node) ->
      node.body = [noopDef].concat(node.body)

  ast
