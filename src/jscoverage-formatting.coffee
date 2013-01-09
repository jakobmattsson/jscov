_ = require 'underscore'
escodegen = require 'escodegen'
tools = require './tools'
estools = require './estools'



exports.formatTree = (ast) ->
  format = true

  while format
    format = false
    escodegen.traverse ast,
      enter: (node) ->
        if ['property', 'argument', 'test'].some((prop) -> node[prop]?.type == 'Literal')
          if node.type == 'MemberExpression' && node.computed && tools.isValidIdentifier(node.property.value)
            node.computed = false
            node.property = { type: 'Identifier', name: node.property.value }
          else if node.type == 'MemberExpression' && node.computed && node.property.value?.toString().match(/^[1-9][0-9]*$/)
            node.property = estools.createLiteral(parseInt(node.property.value, 10))
          else if node.type == 'UnaryExpression'
            if node.operator == '!'
              estools.replaceWithLiteral(node, !node.argument.value)
              format = true
            if node.operator == "~" && typeof node.argument.value == 'number'
              estools.replaceWithLiteral(node, ~node.argument.value)
              format = true
          else if node.type == 'ConditionalExpression'
            if typeof node.test.value == 'string' || typeof node.test.value == 'number' || typeof node.test.value == 'boolean'
              if node.test.value
                tools.replaceProperties(node, node.consequent)
              else
                tools.replaceProperties(node, node.alternate)
          else if node.type == 'WhileStatement'
            node.test.value = !!node.test.value
          else if node.type == 'DoWhileStatement'
            node.test.value = !!node.test.value
          else if node.type == 'ForStatement'
            if node.test.value
              node.test = null
            else
              node.test.value = false
        else
          if node.type == 'MemberExpression' && !node.computed && node.property.type == 'Identifier' && tools.isReservedWord(node.property.name)
            node.computed = true
            node.property = estools.createLiteral(node.property.name)
          else if node.type == 'BinaryExpression' && node.left.type == 'Literal' && node.right.type == 'Literal' && typeof node.left.value == 'string' && typeof node.right.value == 'string' && node.operator == '+'
            estools.replaceWithLiteral(node, node.left.value + node.right.value)
            format = true
          else if node.type == 'BinaryExpression' && estools.isLiteral(node.left) && estools.isLiteral(node.right)
            lv = estools.evalLiteral(node.left)
            rv = estools.evalLiteral(node.right)
            if typeof lv == 'number' && typeof rv == 'number' && node.operator in ['+', '-', '*', '%', '/', '<<', '>>', '>>>']
              binval = tools.evalBinaryExpression(lv, node.operator, rv)
              estools.replaceWithLiteral(node, binval)
              format = true

  # Replace infinities with named constants
  estools.replaceNegativeInfinities(ast)
  estools.replacePositiveInfinities(ast)

  # Remove empty statements trailing returns, declarations and expression without semicolons
  escodegen.traverse ast,
    enter: (node) ->
      if node.type in ['BlockStatement', 'Program']
        node.body = node.body.filter (x, i) ->
          !(x.type == 'EmptyStatement' && i-1 >= 0 && node.body[i-1].type in [
            'ReturnStatement'
            'VariableDeclaration'
            'ExpressionStatement'
          ] && node.body[i-1].loc.end.line == x.loc.start.line)

  # If-statements with literal tests should expand to their content
  escodegen.traverse ast,
    enter: (node) ->
      if node.type in ['BlockStatement', 'Program']
        node.body = _.flatten node.body.map (x, i) ->
          if x.type == 'IfStatement' && x.test.type == 'Literal'
            if x.test.value
              x.consequent.body
            else if x.alternate
              x.alternate.body
            else
              []
          else
            x
