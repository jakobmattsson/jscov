_ = require 'underscore'
estools = require './estools'


noopDef = {
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
}


# ToDo:
# noop not as block-statement

exports.expand = (ast) ->


  addNoop = false

  estools.traverse ast, ['BlockStatement', 'Program'], (node) ->
    node.body.forEach (x, i) ->
      if x.type == 'IfStatement' && !x.alternate?
        addNoop = true
        x.alternate =
          type: 'BlockStatement'
          body: [{
            type: 'ExpressionStatement'
            expression:
              arguments: []
              type: 'CallExpression'
              callee:
                type: 'Identifier'
                name: 'noop'
          }]




  if addNoop
    estools.traverse ast, ['Program'], (node) ->
      node.body = [noopDef].concat(node.body)


  ast
