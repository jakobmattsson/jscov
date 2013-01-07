fs = require 'fs'
path = require 'path'
_ = require 'underscore'
esprima = require 'esprima'
escodegen = require 'escodegen'
wrench = require 'wrench'
coffee = require 'coffee-script'

reservedWords = [
  'break'
  'case'
  'catch'
  'continue'
  'debugger'
  'default'
  'delete'
  'do'
  'else'
  'finally'
  'for'
  'function'
  'if'
  'in'
  'instanceof'
  'new'
  'return'
  'switch'
  'this'
  'throw'
  'try'
  'typeof'
  'var'
  'void'
  'while'
  'with'

  # These are not keyword according to JavaScript, but JSCoverage treats them as if they were.
  # Just follow suit...
  'throws'
]

isValidIdentifier = (name) ->
  name? && (name.toString().match(/^[_a-zA-Z][_a-zA-Z0-9]*$/) || name.toString().match(/^[1-9][0-9]*$/)) && reservedWords.indexOf(name) == -1

exports.rewriteSource = (code, filename) ->

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


  replaceNode = (node, newVal) ->
    props = Object.getOwnPropertyNames(node)
    props.forEach (prop) -> delete node[prop]

    Object.keys(newVal).forEach (prop) ->
      node[prop] = newVal[prop]

  makeLiteral = (node, value) ->
    if typeof value == 'number' && value < 0
      replaceNode(node, {
        type: 'UnaryExpression'
        operator: '-'
        argument: {
          type: 'Literal'
          value: -value
        }
      })
    else
      node.type = 'Literal'
      node.value = value


  ast = esprima.parse(code, { loc: true })

  # formatting (no difference in result, just here to give it exactly the same semantics as JSCoverage)
  # this block should be part of the comparisons in the tests; not the source
  format = true

  while format
    format = false
    escodegen.traverse ast,
      enter: (node) ->
        if node.type == 'MemberExpression' && node.computed && node.property && node.property.type == 'Literal' && isValidIdentifier(node.property.value)
          if node.property.value.toString().match(/^[1-9][0-9]*$/)
            node.property = { type: 'Literal', value: parseInt(node.property.value, 10) }
          else
            node.computed = false
            node.property = { type: 'Identifier', name: node.property.value }
        if node.type == 'BinaryExpression' && node.left.type == 'Literal' && node.right.type == 'Literal'
          if node.operator == '+' && typeof node.left.value == 'string' && typeof node.right.value == 'string' ## put the "typeof" first (easier to read)
            makeLiteral(node, node.left.value + node.right.value)
            format = true
          else if ['+', '-', '*', '%', '/', '<<', '>>', '>>>'].indexOf(node.operator) != -1 && typeof node.left.value == 'number' && typeof node.right.value == 'number' ## put the "typeof" first (easier to read)
            makeLiteral(node, eval("#{node.left.value} #{node.operator} #{node.right.value}")) # OH NOES! Eval!
            format = true
        if node.type == 'UnaryExpression' && node.argument.type == 'Literal'
          if node.operator == '!'
            makeLiteral(node, !node.argument.value)
            format = true
          if ['~'].indexOf(node.operator) != -1 && typeof node.argument.value == 'number'
            makeLiteral(node, eval("#{node.operator} #{node.argument.value}")) # OH NOES! Eval!
            format = true
        if node.type == 'ConditionalExpression' && node.test.type == 'Literal'
          if typeof node.test.value == 'string' || typeof node.test.value == 'number' || typeof node.test.value == 'boolean'
            if node.test.value
              replaceNode(node, node.consequent)
            else
              replaceNode(node, node.alternate)


  # injecting coverage code
  escodegen.traverse ast,
    enter: (node) ->
      if ['BlockStatement', 'Program'].indexOf(node.type) != -1
        node.body = _.flatten node.body.map (x) ->
          if x.body && x.type == 'FunctionDeclaration' ## x.body should not be required here -- try to remove it
            [inject(x.body), x]
          else
            [inject(x), x]
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

  trackedLines = _.sortBy(_.unique(injectList), _.identity)

  sourceMappings = [
    (x) -> x.replace(/&/g, '&amp;')
    (x) -> x.replace(/</g, '&lt;')
    (x) -> x.replace(/>/g, '&gt;')
    (x) -> x.replace(/\\/g, '\\\\')
    (x) -> x.replace(/"/g, '\\"')
    (x) -> '"' + x + '"'
  ]

  originalSource = code.split('\n').map (line) -> sourceMappings.reduce(((src, f) -> f(src)), line)
  originalSource = originalSource.slice(0, -1) if _.last(originalSource) == '""' # useless trimming - just to keep the semantics the same as for jscoverage

  output = []
  output.push "/* automatically generated by jscov - do not edit */"
  output.push "if (typeof _$jscoverage === 'undefined') _$jscoverage = {};"
  output.push "if (! _$jscoverage['#{filename}']) {"
  output.push "  _$jscoverage['#{filename}'] = [];"
  trackedLines.forEach (line) ->
    output.push "  _$jscoverage['#{filename}'][#{line}] = 0;"
  output.push "}"
  output.push escodegen.generate(ast, { indent: "  " })
  output.push "_$jscoverage['#{filename}'].source = [" + originalSource.join(",") + "];"

  output.join('\n')


exports.rewriteFolder = (source, target, options, callback) ->
  try
    if !callback?
      callback = options
      options = {}

    wrench.rmdirSyncRecursive(target, true)

    wrench.readdirSyncRecursive(source).forEach (file) ->
      fullpath = path.join(source, file)
      return if fs.lstatSync(fullpath).isDirectory()

      data = fs.readFileSync(fullpath, 'utf8')

      if file.match(/\.coffee$/)
        data = coffee.compile(data)
      else if !file.match(/\.js$/)
        data = null

      if data != null
        output = exports.rewriteSource(data, file)
        outfile = path.join(target, file).replace(/\.coffee$/, '.js')
        wrench.mkdirSyncRecursive(path.dirname(outfile))
        fs.writeFileSync(outfile, output, 'utf8')

  catch ex
    callback(ex)
    return

  callback(null)
