# ToDo:
# noop not as block-statement
# noop must have a name that wont clash with anything
# write a test for testing the actual code-coverage with and without using the expander


_ = require 'underscore'
estools = require './estools'
tools = require './tools'

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


wrapLogic = (isAnd, left, right) ->
  type: 'CallExpression'
  arguments: []
  callee:
    type: 'FunctionExpression'
    id: null
    rest: null
    generator: false
    expression: false
    params: []
    defaults: []
    body:
      type: 'BlockStatement'
      body: [{
        kind: 'var'
        type: 'VariableDeclaration'
        declarations: [{
          type: 'VariableDeclarator'
          id: { type: 'Identifier', name: '__lhs' }
          init:  left
        }]
      }, {
        type: 'IfStatement'
        test: { type: 'Identifier', name: '__lhs' }
        consequent:
          type: 'BlockStatement'
          body: [{
            type: 'ReturnStatement'
            argument: if isAnd then right else { type: 'Identifier', name: '__lhs' }
          }]
        alternate:
          type: 'BlockStatement'
          body: [{
            type: 'ReturnStatement'
            argument: if !isAnd then right else { type: 'Identifier', name: '__lhs' }
          }]
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

  estools.traverse ast, ['LogicalExpression'], (node) ->
    if node.operator == '&&' || node.operator == '||'
      tools.replaceProperties(node, wrapLogic(node.operator == '&&', node.left, node.right))
      delete node.operator
      delete node.left
      delete node.right

  if addNoop
    estools.traverse ast, ['Program'], (node) ->
      node.body = [noopDef].concat(node.body)

  ast
