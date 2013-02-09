_ = require 'underscore'
escodegen = require 'escodegen'
tools = require './tools'
estools = require './estools'
ftools = require './jscoverage-formatting-tools'



exports.formatTree = (ast) ->

  # Preevaluate literal operators
  ftools.evalLiterals ast, [{
    test: (node) -> node.type == 'UnaryExpression' && node.argument.type == 'Literal' && node.operator == '!'
    eval: (node) -> !node.argument.value
  }, {
    test: (node) -> node.type == 'UnaryExpression' && node.argument.type == 'Literal' && node.operator == "~" && typeof node.argument.value == 'number'
    eval: (node) -> ~node.argument.value
  }, {
    test: (node) -> node.type == 'BinaryExpression' && node.left.type == 'Literal' && node.right.type == 'Literal' && typeof node.left.value == 'string' && typeof node.right.value == 'string' && node.operator == '+'
    eval: (node) -> node.left.value + node.right.value
  }, {
    test: (node) -> node.type == 'BinaryExpression' && ftools.isNumericLiteral(node.left) && ftools.isNumericLiteral(node.right) && node.operator in ['+', '-', '*', '%', '/', '<<', '>>', '>>>'] && typeof ftools.evalLiteral(node.left) == 'number' && typeof ftools.evalLiteral(node.right) == 'number'
    eval: (node) -> ftools.evalBinaryExpression(ftools.evalLiteral(node.left), node.operator, ftools.evalLiteral(node.right))
  }]

  # Ensure member expressions are on the correct format
  estools.traverse ast, ['MemberExpression'], (node) ->
    if node.property.type == 'Literal' && ftools.isValidIdentifier(node.property.value)
      node.computed = false
      node.property = { type: 'Identifier', name: node.property.value }
    if node.property.type == 'Literal' && node.property.value?.toString().match(/^[1-9][0-9]*$/)
      node.computed = true
      node.property = estools.createLiteral(parseInt(node.property.value, 10))
    if node.property.type == 'Identifier' && ftools.isReservedWord(node.property.name)
      node.computed = true
      node.property = estools.createLiteral(node.property.name)

  # Preevaluate literal tests in loops and conditionals
  estools.traverse ast, (node) ->
    if node.test?.type == 'Literal'
      if node.type == 'ConditionalExpression'
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

  # Replace infinities with named constants
  ftools.replaceNegativeInfinities(ast)
  ftools.replacePositiveInfinities(ast)

  # Remove empty statements trailing returns, declarations and expression without semicolons
  estools.traverse ast, ['BlockStatement', 'Program'], (node) ->
    node.body = node.body.filter (x, i) ->
      !(x.type == 'EmptyStatement' && i-1 >= 0 && node.body[i-1].type in [
        'ReturnStatement'
        'VariableDeclaration'
        'ExpressionStatement'
      ] && node.body[i-1].loc.end.line == x.loc.start.line)

  # If-statements with literal tests should expand to their content
  estools.traverse ast, ['BlockStatement', 'Program'], (node) ->
    node.body = _.flatten node.body.map (x, i) ->
      if x.type == 'IfStatement' && x.test.type == 'Literal'
        if x.test.value
          if x.consequent.type == 'BlockStatement' then x.consequent.body else _.extend({}, x.consequent, { loc: x.loc })
        else if x.alternate
          if x.alternate.type == 'BlockStatement' then x.alternate.body else _.extend({}, x.alternate, { loc: x.loc })
        else
          []
      else
        x

  # Rewrite all "let"-statements found in global scope and function scope to "var"-statements (if js 1.8)
  estools.traverse ast, ['FunctionExpression', 'FunctionDeclaration', 'Program'], (node) ->
    body = if node.type == 'Program' then node.body else node.body.body
    body.filter((x) -> x.type == 'VariableDeclaration' && x.kind == 'let').forEach (stm) ->
      stm.kind = 'var'



exports.postFormatTree = (ast) ->

  # Wrap all blocks containing "let"-declarations in yet another outer block
  stored = []
  estools.traverse ast, ['BlockStatement'], (node) ->
    if node.body.some((stm) -> stm.type == 'VariableDeclaration' && stm.kind == 'let')
      stored.push(node)

  stored.forEach (node) ->
    node.body = [{
      type: 'BlockStatement'
      body: node.body
      loc: node.loc
    }]
