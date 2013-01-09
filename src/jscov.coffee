fs = require 'fs'
path = require 'path'
_ = require 'underscore'
esprima = require 'esprima'
escodegen = require 'escodegen'
wrench = require 'wrench'
coffee = require 'coffee-script'
tools = require './tools'
estools = require './estools'
jscoverageFormatting = require './jscoverage-formatting'



writeFile = do ->
  sourceMappings = [
    (x) -> x.replace(/&/g, '&amp;')
    (x) -> x.replace(/</g, '&lt;')
    (x) -> x.replace(/>/g, '&gt;')
    (x) -> x.replace(/\\/g, '\\\\')
    (x) -> x.replace(/"/g, '\\"')
    (x) -> tools.strToNumericEntity(x)
    (x) -> '"' + x + '"'
  ]

  (originalCode, coveredCode, filename, trackedLines, coverageVar) ->

    originalSource = originalCode.split(/\r?\n/g).map (line) -> sourceMappings.reduce(((src, f) -> f(src)), line)
    originalSource = originalSource.slice(0, -1) if _.last(originalSource) == '""'

    output = []
    output.push "/* automatically generated by jscov - do not edit */"
    output.push "if (typeof #{coverageVar} === 'undefined') #{coverageVar} = {};"
    output.push "if (!#{coverageVar}['#{filename}']) {"
    output.push "  #{coverageVar}['#{filename}'] = [];"
    trackedLines.forEach (line) ->
      output.push "  #{coverageVar}['#{filename}'][#{line}] = 0;"
    output.push "}"
    output.push coveredCode
    output.push "#{coverageVar}['#{filename}'].source = [" + originalSource.join(",") + "];"

    output.join('\n') # should maybe windows style line-endings be used here in some cases?



exports.rewriteSource = (code, filename) ->

  injectList = {}
  coverageVar = '_$jscoverage'

  ast = esprima.parse(code, { loc: true })

  jscoverageFormatting.formatTree(ast)

  estools.addBeforeEveryStatement ast, (node) ->
    injectList[node.loc.start.line] = 1
    estools.coverageNode(node, filename, coverageVar)

  trackedLines = _.sortBy(Object.keys(injectList).map((x) -> parseInt(x, 10)), _.identity)
  outcode = escodegen.generate(ast, { indent: "  " })
  writeFile(code, outcode, filename, trackedLines, coverageVar)



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



exports.cover = (start, dir, file) ->
  path.join(start, process.env.JSCOV || dir, file)
