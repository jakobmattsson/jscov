_ = require 'underscore'
esprima = require 'esprima'
escodegen = require 'escodegen'

rewrite = exports.rewrite = (code, filename) ->

  injectList = []

  inject = (x) ->
    injectList.push(x.loc.start.line)

    type: 'ExpressionStatement'
    expression:
      type: 'UpdateExpression'
      operator: '++'
      prefix: false
      argument:
        type: 'MemberExpression'
        computed: true
        property:
          type: 'Literal'
          value: x.loc.start.line
        object:
          type: 'MemberExpression'
          computed: true
          object:
            type: 'Identifier'
            name: '_$jscoverage'
          property:
            type: 'Literal'
            value: filename

  parsed = esprima.parse(code, { loc: true })

  escodegen.traverse parsed,
    enter: (node) ->
      if ['BlockStatement', 'Program'].indexOf(node.type) != -1
        node.body = _.flatten node.body.map (x) -> [inject(x), x]
      if node.type == 'SwitchCase'
        node.consequent = _.flatten node.consequent.map (x) -> [inject(x), x]
      if node.type == 'IfStatement'
        ['consequent', 'alternate'].forEach (src) ->
          if node[src]? && node[src].type != 'BlockStatement'
            node[src] =
              type: 'BlockStatement'
              body: [node[src]]
      if ['ForInStatement', 'ForStatement', 'WhileStatement', 'WithStatement', 'DoWhileStatement'].indexOf(node.type) != -1 && node.body? && node.body.type != 'BlockStatement'
        node.body =
          type: 'BlockStatement'
          body: [node.body]

  originalSource = code.split('\n').map((x) -> x.replace(/&/g, '&amp;')).map((x) -> x.replace(/</g, '&lt;')).map((x) -> x.replace(/>/g, '&gt;')).map((x) -> x.replace(/"/g, '\\"')).map((x) -> '"' + x + '"')
  originalSource = originalSource.slice(0, -1) if _.last(originalSource) == '""' # useless trimming - just to keep the semantics the same as for jscoverage

  output = []
  output.push "if (typeof _$jscoverage === 'undefined') _$jscoverage = {};"
  output.push "if (! _$jscoverage['#{filename}']) {"
  output.push "  _$jscoverage['#{filename}'] = [];"
  _.sortBy(_.unique(injectList), _.identity).forEach (line) ->
    output.push "  _$jscoverage['#{filename}'][#{line}] = 0;"
  output.push "}"
  output.push escodegen.generate(parsed, { indent: "  " })
  output.push "_$jscoverage['#{filename}'].source = [" + originalSource.join(",") + "];"

  output.join('\n')
