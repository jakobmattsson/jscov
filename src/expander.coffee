_ = require 'underscore'
estools = require './estools'

exports.expand = (ast) ->

  estools.traverse ast, ['BlockStatement', 'Program'], (node) ->
    node.body.forEach (x, i) ->
      if x.type == 'IfStatement' && !x.alternate?
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

  ast
