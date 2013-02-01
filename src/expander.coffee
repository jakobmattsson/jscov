# ToDo:
# noop not as block-statement
# write a test for testing the actual code-coverage with and without using the expander


_ = require 'underscore'
estools = require './estools'
tools = require './tools'

noopDef = (name) ->
  kind: 'var'
  type: 'VariableDeclaration'
  declarations: [{
    type: 'VariableDeclarator'
    id: { type: 'Identifier', name: name }
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

noopExpression = (name) ->
  type: 'ExpressionStatement'
  expression:
    arguments: []
    type: 'CallExpression'
    callee:
      type: 'Identifier'
      name: name

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


wrapPred = (test, left, right) ->
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
        type: 'IfStatement'
        test: test
        consequent:
          type: 'BlockStatement'
          body: [{
            type: 'ReturnStatement'
            argument: left
          }]
        alternate:
          type: 'BlockStatement'
          body: [{
            type: 'ReturnStatement'
            argument: right
          }]
      }]

wrapLogic = (isAnd, left, right, tmpvar) ->
  l = if  isAnd then right else { type: 'Identifier', name: tmpvar }
  r = if !isAnd then right else { type: 'Identifier', name: tmpvar }
  res = wrapPred({ type: 'Identifier', name: tmpvar }, l, r)
  res.callee.body.body = [{
    kind: 'var'
    type: 'VariableDeclaration'
    declarations: [{
      type: 'VariableDeclarator'
      id: { type: 'Identifier', name: tmpvar }
      init:  left
    }]
  }].concat(res.callee.body.body)
  res



exports.expand = (ast) ->

  addNoop = false

  estools.traverse ast, ['IfStatement'], (node) ->
    if !node.alternate?
      addNoop = true
      node.alternate = noopExpression('__noop__')

  estools.traverse ast, ['LogicalExpression'], (node) ->
    if node.operator == '&&' || node.operator == '||'
      if node.left.type == 'Literal' || node.left.type == 'Identifier'
        tools.replaceProperties(node, wrapPred(node.left, node.right, node.left))
      else
        tools.replaceProperties(node, wrapLogic(node.operator == '&&', node.left, node.right, '__lhs__'))

      delete node.operator
      delete node.left
      delete node.right

  estools.traverse ast, ['ConditionalExpression'], (node) ->
    tools.replaceProperties(node, wrapPred(node.test, node.consequent, node.alternate))

    delete node.test
    delete node.consequent
    delete node.alternate

  if addNoop
    estools.traverse ast, ['Program'], (node) ->
      node.body = [noopDef('__noop__')].concat(node.body)

  ast
